# nixtrobox

[Distrobox](https://distrobox.it) containers of other Linux distributions, with each image pinned in Nix: everyone who uses this flake, people and agents alike, enters byte-identical images, and updating them is an explicit, reviewable change to `pins.json`.

```shell
nix run .#fedora                     # interactive shell in Fedora 43
nix run .#debian -- apt-get install … # run one command in Debian 13
```

| Box         | Image                                   | Systems                       |
| :---------- | :-------------------------------------- | :---------------------------- |
| `archlinux` | `docker.io/library/archlinux:latest`    | `x86_64-linux`                |
| `debian`    | `docker.io/library/debian:trixie`       | `x86_64-linux`, `aarch64-linux` |
| `fedora`    | `registry.fedoraproject.org/fedora:43`  | `x86_64-linux`, `aarch64-linux` |
| `ubuntu`    | `docker.io/library/ubuntu:24.04`        | `x86_64-linux`, `aarch64-linux` |

## Requirements

- Linux, with Podman or Docker installed and usable (for Docker, the daemon running). Podman is used when both are present; set `DBX_CONTAINER_MANAGER` to choose.
- Rootful Docker inside a container (for example a Claude cloud session) also needs shared mount propagation, or distrobox can't start the box (`path /dev is mounted on /dev but it is not a shared or slave mount`):

  ```shell
  mount --make-rshared /
  ```

## How it works

- **`distros.json`** lists the boxes: image, tag, the systems to pin it for, and how to add extra CA certificates (below).
- **`pins.json`** records, per box and system, the image's manifest digest and the Nix hash of the image. It's written by `nix run .#update-pins` and read by the flake.
- **`nix run .#<box>`** downloads the pinned image through Nix (a fixed-output `dockerTools.pullImage`), loads it as `nixtrobox/<box>:<tag>-<digest>`, creates the distrobox `nixtrobox-<box>` from it if needed, and enters it. Because the digest is part of the tag, a box whose pin has changed is detected and recreated on its next use.
- `nix flake check` builds every pinned image, so CI catches a pin that no longer downloads or matches.

## Updating or adding a distribution

1. Edit `distros.json` (to add a box, copy an entry from the same family, whose `caAnchor` and `preInit` already fit).
2. Run `nix run .#update-pins` in this directory, which resolves each tag to its current digest and writes `pins.json`.
3. Review and commit both files.

## Proxies and extra CA certificates

When the host sets proxy variables (`HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY` and their lowercase forms), they're passed into the box, and when it sets `SSL_CERT_FILE`, that bundle is added to the box's trust store. This is what makes package managers work in boxes on hosts behind an intercepting proxy, such as Claude cloud sessions.

The bundle is mounted at the distribution's `caAnchor` path (an extra trust anchor, not the distribution's own bundle, which its `ca-certificates` package rewrites), and `preInit` runs before distrobox installs anything:

- Fedora and Arch: `update-ca-trust` adds the anchor to the trust store.
- Debian and Ubuntu: `apt` is pointed at the bundle (the base images have no `ca-certificates` yet), and the anchor is added once `ca-certificates` is installed. Debian also switches its package sources to HTTPS, since proxies like Claude cloud sessions' reject plain HTTP.

## Working directory

Distrobox shares `$HOME` with the box. When a box is created from a directory outside `$HOME`, that directory is shared at its own path too, and later commands run from inside it start there. From other directories outside `$HOME`, the box starts in the host's view of the directory under `/run/host`.

## Declaring boxes with home-manager

On your own machines, home-manager's [`programs.distrobox`](https://github.com/nix-community/home-manager/blob/master/modules/programs/distrobox.nix) module can declare boxes (extra packages, init hooks, exported apps) and build them with a systemd user service. It doesn't pin images, so to combine the two, load the image with `nix run .#<box>` once and use its `nixtrobox/<box>:<tag>-<digest>` tag as the box's `image`. Agents in cloud sessions have no systemd, so for them `nix run .#<box>` is the way in.
