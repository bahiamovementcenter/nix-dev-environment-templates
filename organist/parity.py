#!/usr/bin/env python3
"""Check that each Organist template gives the same shell as its original.

Every template under organist/ is a port of a plain-Nix template in the repo
root (listed in parity.json). For each pair, both development shells are
evaluated against the *same* Nixpkgs revision and compared on what a user
actually gets:

1. Commands: for every command on PATH, which package provides it (the first
   PATH entry wins, so this also catches ordering problems).
2. Variables: the shell variables and functions the environment defines,
   after removing the ones that only reflect how the shell is built.
3. Smoke tests: the commands listed in parity.json are run in both shells, in
   the same scratch directory, and their exit codes and output must match.

A template that merges several modules (listed with "composes" instead of
"original") is checked against each of the templates those modules come
from: every command each one provides must come from the same package, and
each one's smoke tests must give the same output.

The Organist templates take their modules (organist/modules) and the
packages those use from the dev-templates flake input; it's pointed at this
checkout, so a change is checked before it's published.

Differences that are intended are listed per template in parity.json.

Environment variables:
  PARITY_NIXPKGS     Flake reference for the Nixpkgs used by both sides.
                     Defaults to the nixpkgs input locked in the root
                     flake.lock.
  PARITY_NIX_ARGS    Extra arguments for every nix invocation.
  PARITY_ORGANIST_NIX_ARGS
                     Extra arguments for nix invocations on Organist
                     templates only, e.g. to override Organist's own inputs.
"""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
NIX = ["nix", "--extra-experimental-features", "nix-command flakes"]

STORE_PATH = re.compile(r"/nix/store/[0-9a-z]{32}-")

# Variables that only reflect how the shell derivation is built (mkShell vs.
# Organist's raw derivation with structured attributes), not what a user of
# the shell sees. Compared variables are everything else.
IGNORED_VARIABLES = {
    # Derivation plumbing
    "__structuredAttrs", "allowSubstitutes", "args", "builder", "buildCommand",
    "buildPhase", "env", "name", "out", "outputs", "passAsFile", "phases",
    "preferLocalBuild", "stdenv", "system", "version",
    "NIX_ATTRS_JSON_FILE", "NIX_ATTRS_SH_FILE",
    # Dependency lists: their effect is checked through commands and flags
    "buildInputs", "nativeBuildInputs", "propagatedBuildInputs",
    "propagatedNativeBuildInputs", "depsBuildBuild", "depsBuildBuildPropagated",
    "pkgsBuildBuild", "pkgsBuildHost", "pkgsBuildTarget", "pkgsHostHost",
    "pkgsHostTarget", "pkgsTargetTarget",
    "depsBuildTarget", "depsBuildTargetPropagated", "depsHostHost",
    "depsHostHostPropagated", "depsTargetTarget", "depsTargetTargetPropagated",
    # Build-sandbox and stdenv bookkeeping
    "cmakeFlags", "configureFlags", "mesonFlags", "patches", "doCheck",
    "doInstallCheck", "dontAddDisableDepTrack", "strictDeps",
    "NIX_BUILD_CORES", "NIX_BUILD_TOP", "NIX_ENFORCE_PURITY", "NIX_LOG_FD",
    "NIX_STORE", "SOURCE_DATE_EPOCH", "CONFIG_SHELL", "HOME", "PWD", "TEMP",
    "TEMPDIR", "TERM", "TMP", "TMPDIR", "TZ", "PAGER", "IN_NIX_SHELL", "shell",
    # Loop variables left behind by stdenv's setup script
    "envVar", "outputName",
    # Compared separately
    "PATH", "shellHook",
}

# Functions stdenv defines only for one way of building the shell: Organist
# builds with structured attributes, mkShell doesn't
IGNORED_FUNCTIONS = {
    "_exportOutputsByName",
}


def nix(args, extra, **kwargs):
    cmd = NIX + args + extra
    return subprocess.run(cmd, text=True, capture_output=True, **kwargs)


def strip_hash(value):
    return STORE_PATH.sub("", value)


def package_name(path_entry):
    """'ncurses-6.6-dev/bin' -> 'ncurses', 'bash-interactive-5.3p20' -> 'bash-interactive'."""
    name = strip_hash(path_entry).lstrip("/").split("/")[0]
    return re.split(r"-(?=\d)", name, maxsplit=1)[0]


def default_nixpkgs():
    lock = ROOT / "flake.lock"
    expr = (
        f'let l = (builtins.fromJSON (builtins.readFile {lock})).nodes.nixpkgs.locked; '
        f'in (builtins.fetchTree (removeAttrs l [ "lastModified" "revCount" ])).outPath'
    )
    res = nix(["eval", "--impure", "--raw", "--expr", expr], [])
    if res.returncode != 0:
        sys.exit(f"could not fetch the root flake's nixpkgs:\n{res.stderr}")
    return f"path:{res.stdout}"


class Side:
    def __init__(self, label, directory, extra_args):
        self.label = label
        self.ref = f"path:{directory}"
        self.extra = extra_args

    def dev_env(self):
        res = nix(["print-dev-env", "--json", self.ref], self.extra)
        if res.returncode != 0:
            raise RuntimeError(f"{self.label}: nix print-dev-env failed:\n{res.stderr[-3000:]}")
        return json.loads(res.stdout)

    def run(self, script, cwd):
        res = nix(["develop", self.ref], self.extra + ["--command", "bash", script], cwd=cwd)
        return res


def resolve_commands(env):
    """Map each command name to the PATH entry that provides it."""
    path = env["variables"].get("PATH", {}).get("value", "")
    commands = {}
    for entry in path.split(":"):
        if not entry.startswith("/nix/store/") or not os.path.isdir(entry):
            continue
        for name in sorted(os.listdir(entry)):
            full = os.path.join(entry, name)
            if name not in commands and os.path.isfile(full) and os.access(full, os.X_OK):
                commands[name] = strip_hash(entry)
    return commands


def normalize(env):
    """Variables and functions as strings, with build-specific values masked.

    Arrays are joined with spaces: Organist builds with structured attributes,
    so some variables that are plain strings under mkShell become arrays.
    Trailing newlines are dropped (Nickel's multiline strings have none).
    """
    variables = env["variables"]
    out = variables.get("out", {}).get("value", "")

    def clean(value):
        if out:
            value = value.replace(out, "$out")
        return re.sub(r"-frandom-seed=\S+", "-frandom-seed=X", value).rstrip("\n")

    result = {}
    for name, var in variables.items():
        value = var.get("value")
        if name in IGNORED_VARIABLES:
            continue
        if var.get("type") == "array":
            value = " ".join(value)
        elif var.get("type") == "associative":
            value = " ".join(f"{k}={v}" for k, v in sorted(value.items()))
        result[name] = clean(value)
    for name, body in env.get("bashFunctions", {}).items():
        if name not in IGNORED_FUNCTIONS:
            result[f"function {name}"] = clean(body)
    return result


def hook_lines(env, drop_organist_lines):
    hook = env["variables"].get("shellHook", {}).get("value", "")
    lines = [line.strip() for line in hook.splitlines() if line.strip()]
    if drop_organist_lines:
        # Organist regenerates nickel.lock.ncl on entry; that's expected
        lines = [line for line in lines if not line.endswith("/bin/regenerate-files")]
    return lines


def tokens(value, allowed_extra=frozenset()):
    """Entries of a path list or flag list, minus those of allowed extra packages."""
    return Counter(
        t for t in re.split(r"[:\s]+", value)
        if t and not (STORE_PATH.search(t) and package_name(STORE_PATH.split(t)[-1]) in allowed_extra)
    )


def short(value, limit=160):
    value = value.replace("\n", "\\n")
    return value if len(value) <= limit else value[:limit] + "…"


def compare_envs(orig, port, allowed_extra, allowed_replacements, allowed_vars):
    failures, notes = [], []

    a, b = resolve_commands(orig), resolve_commands(port)
    for name in sorted(set(a) | set(b)):
        if name not in b:
            failures.append(f"command `{name}` missing (original: {a[name]})")
        elif name not in a:
            if package_name(b[name]) not in allowed_extra:
                failures.append(f"command `{name}` only in Organist shell (from {b[name]})")
        elif a[name] != b[name]:
            if allowed_replacements.get(package_name(a[name])) == package_name(b[name]):
                continue
            failures.append(f"command `{name}` comes from {b[name]}, original: {a[name]}")

    va, vb = normalize(orig), normalize(port)
    for name in sorted(set(va) | set(vb)):
        x, y = va.get(name), vb.get(name)
        if x == y:
            continue
        if name in allowed_vars:
            notes.append(f"{name} differs (allowed: {allowed_vars[name]})")
        elif x is not None and y is not None and tokens(x, allowed_extra) == tokens(y, allowed_extra):
            if tokens(x) == tokens(y):
                notes.append(f"{name}: same entries, different order or spacing")
        elif x is None:
            failures.append(f"{name} only in Organist shell: {short(y)}")
        elif y is None:
            failures.append(f"{name} missing (original: {short(x)})")
        else:
            ta, tb = tokens(x, allowed_extra), tokens(y, allowed_extra)
            if len(ta) > 1 or len(tb) > 1:
                # A path or flag list: show which entries differ
                only_a = sorted(strip_hash(t) for t in (ta - tb).elements())
                only_b = sorted(strip_hash(t) for t in (tb - ta).elements())
                failures.append(
                    f"{name} differs\n      only in original: {short(' '.join(only_a) or '-', 400)}"
                    f"\n      only in organist: {short(' '.join(only_b) or '-', 400)}"
                )
            else:
                failures.append(f"{name} differs\n      original: {short(x)}\n      organist: {short(y)}")

    ha, hb = hook_lines(orig, False), hook_lines(port, True)
    if ha != hb:
        failures.append(
            "shellHook differs\n      original: " + short(" ⏎ ".join(ha), 400)
            + "\n      organist: " + short(" ⏎ ".join(hb), 400)
        )
    return failures, notes


SMOKE_MARK = "@@parity"


def smoke_script(commands):
    parts = []
    for i, cmd in enumerate(commands):
        parts.append(f"echo '{SMOKE_MARK} {i}'\n( {cmd}\n) 2>&1\necho \"{SMOKE_MARK} rc $?\"")
    return "\n".join(parts) + "\n"


def parse_smoke(stdout, count):
    results, current, lines = {}, None, []
    for line in stdout.splitlines():
        if line.startswith(f"{SMOKE_MARK} rc "):
            results[current] = ("\n".join(lines), int(line.split()[-1]))
            current, lines = None, []
        elif line.startswith(f"{SMOKE_MARK} "):
            current, lines = int(line.split()[-1]), []
        elif current is not None:
            lines.append(line)
    return [results.get(i, ("<did not run>", None)) for i in range(count)]


def run_smoke(orig, port, commands, scratch):
    if not commands:
        return []
    script = scratch / "smoke.sh"
    script.write_text(smoke_script(commands))
    work = scratch / "work"  # same path for both sides, so outputs compare
    outputs = []
    for side in (orig, port):
        shutil.rmtree(work, ignore_errors=True)
        work.mkdir()
        res = side.run(str(script), work)
        if res.returncode != 0 and SMOKE_MARK not in res.stdout:
            return [f"{side.label}: nix develop failed:\n{res.stderr[-2000:]}"]
        outputs.append(parse_smoke(res.stdout, len(commands)))
    failures = []
    for cmd, x, y in zip(commands, *outputs):
        if x != y:
            failures.append(
                f"smoke `{cmd}` differs\n      original (rc {x[1]}): {short(x[0], 300)}"
                f"\n      organist (rc {y[1]}): {short(y[0], 300)}"
            )
        elif x[1] != 0:
            failures.append(f"smoke `{cmd}` failed in both shells (rc {x[1]}): {short(x[0], 300)}")
    return failures


def check_composed(name, spec, templates, config, common, organist_extra, no_smoke):
    """A template merging several modules: each original's commands must come
    from the same packages in it, and each original's smoke commands must
    give the same output in it."""
    parts = spec["composes"]
    print(f"\n== organist/{name} vs {' + '.join(templates[p]['original'] for p in parts)}")
    port = Side("organist", HERE / name, common + organist_extra)
    failures = []
    try:
        composed = resolve_commands(port.dev_env())
        for part in parts:
            part_spec = templates[part]
            orig = Side(part_spec["original"], ROOT / part_spec["original"], common)
            replacements = config.get("allowed_replacements", {}) | part_spec.get("allowed_replacements", {})
            for cmd, provider in sorted(resolve_commands(orig.dev_env()).items()):
                if cmd not in composed:
                    failures.append(f"command `{cmd}` of {orig.label} missing (from {provider})")
                elif composed[cmd] != provider and replacements.get(package_name(provider)) != package_name(composed[cmd]):
                    failures.append(f"command `{cmd}` comes from {composed[cmd]}, in {orig.label}: {provider}")
            if not no_smoke:
                with tempfile.TemporaryDirectory(prefix="parity-") as scratch:
                    failures += run_smoke(orig, port, part_spec.get("smoke", []), Path(scratch))
    except RuntimeError as err:
        failures.append(str(err))
    for failure in failures:
        print(f"  FAIL: {failure}")
    return failures


def main():
    config = json.loads((HERE / "parity.json").read_text())
    templates = config["templates"]

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("templates", nargs="*", help=f"templates to check (default: all of {', '.join(templates)})")
    parser.add_argument("--no-smoke", action="store_true", help="skip the smoke tests")
    args = parser.parse_args()

    unknown = set(args.templates) - set(templates)
    if unknown:
        sys.exit(f"unknown templates: {', '.join(sorted(unknown))}")

    nixpkgs = os.environ.get("PARITY_NIXPKGS") or default_nixpkgs()
    print(f"Comparing against nixpkgs {nixpkgs}")
    common = ["--no-write-lock-file", "--override-input", "nixpkgs", nixpkgs]
    common += shlex.split(os.environ.get("PARITY_NIX_ARGS", ""))
    # The Organist templates are built from this checkout's modules and
    # packages, not the published ones their flake.nix points at
    organist_extra = ["--override-input", "dev-templates", f"git+file://{ROOT}?shallow=1"]
    organist_extra += shlex.split(os.environ.get("PARITY_ORGANIST_NIX_ARGS", ""))

    failed = []
    for name in args.templates or templates:
        spec = templates[name]
        if "composes" in spec:
            failures = check_composed(name, spec, templates, config, common, organist_extra, args.no_smoke)
            if failures:
                failed.append(name)
            else:
                print("  ok")
            continue
        print(f"\n== organist/{name} vs {spec['original']}")
        orig = Side("original", ROOT / spec["original"], common)
        port = Side("organist", HERE / name, common + organist_extra)
        allowed_extra = set(config.get("allowed_extra_packages", [])) | set(spec.get("allowed_extra_packages", []))
        allowed_replacements = config.get("allowed_replacements", {}) | spec.get("allowed_replacements", {})
        allowed_vars = spec.get("allowed_differences", {})
        try:
            failures, notes = compare_envs(
                orig.dev_env(), port.dev_env(), allowed_extra, allowed_replacements, allowed_vars
            )
            if not args.no_smoke:
                with tempfile.TemporaryDirectory(prefix="parity-") as scratch:
                    failures += run_smoke(orig, port, spec.get("smoke", []), Path(scratch))
        except RuntimeError as err:
            failures, notes = [str(err)], []
        for note in notes:
            print(f"  note: {note}")
        for failure in failures:
            print(f"  FAIL: {failure}")
        if failures:
            failed.append(name)
        else:
            print("  ok")

    if failed:
        print(f"\nParity check failed for: {', '.join(failed)}")
        return 1
    print("\nAll Organist templates match their originals")
    return 0


if __name__ == "__main__":
    sys.exit(main())
