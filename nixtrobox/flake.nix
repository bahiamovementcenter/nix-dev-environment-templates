{
  description = "Distrobox containers of other Linux distributions, pinned with Nix";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      inherit (inputs.nixpkgs) lib;

      # Distrobox only runs on Linux
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );

      # Which distributions exist, where extra CA certificates go, and the
      # commands that set the box up to use them (see README.md)
      distros = lib.importJSON ./distros.json;

      # Image digests and hashes, written by `nix run .#update-pins`
      pins = lib.importJSON ./pins.json;

      architectures = {
        x86_64-linux = "amd64";
        aarch64-linux = "arm64";
      };

      # The distributions pinned for a system
      distrosFor = system: lib.filterAttrs (name: _: (pins.${name} or { }) ? ${system}) distros;
    in
    {
      packages = forEachSupportedSystem (
        { pkgs, system }:
        let
          image =
            name: distro:
            let
              pin = pins.${name}.${system};
            in
            pkgs.dockerTools.pullImage {
              imageName = distro.image;
              inherit (pin) imageDigest hash;
              arch = architectures.${system};
              os = "linux";
              # The digest is part of the tag, so a new pin gives a new box
              finalImageName = "nixtrobox/${name}";
              finalImageTag = "${distro.tag}-${lib.substring 7 12 pin.imageDigest}";
            };

          box =
            name: distro:
            let
              img = image name distro;
            in
            pkgs.writeShellApplication {
              name = "nixtrobox-${name}";
              runtimeInputs = [ pkgs.distrobox ];
              # podman or docker come from the host: they need a daemon or
              # system configuration that a Nix package can't provide
              text = ''
                name="nixtrobox-${name}"
                image="${img.imageName}:${img.imageTag}"

                manager="''${DBX_CONTAINER_MANAGER:-}"
                if [ -z "$manager" ]; then
                  if command -v podman >/dev/null; then
                    manager=podman
                  elif command -v docker >/dev/null; then
                    manager=docker
                  else
                    echo "nixtrobox: podman or docker is needed" >&2
                    exit 1
                  fi
                fi
                export DBX_CONTAINER_MANAGER="$manager"

                if ! "$manager" image inspect "$image" >/dev/null 2>&1; then
                  echo "nixtrobox: loading pinned image $image" >&2
                  "$manager" load --input ${img} >&2
                fi

                # Recreate the box when its pin has changed
                current="$("$manager" inspect --format '{{.Config.Image}}' "$name" 2>/dev/null || true)"
                if [ -n "$current" ] && [ "$current" != "$image" ]; then
                  echo "nixtrobox: $name uses $current; recreating it with $image" >&2
                  distrobox rm --force "$name" >&2
                  current=""
                fi

                if [ -z "$current" ]; then
                  flags=()
                  hooks=()
                  # Proxy settings and the CA certificates that go with them, so
                  # package managers in the box work behind the same proxy as
                  # the host (as in Claude cloud sessions)
                  for var in HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy; do
                    if [ -n "''${!var:-}" ]; then
                      flags+=(--env "$var=''${!var}")
                    fi
                  done
                  if [ -n "''${SSL_CERT_FILE:-}" ] && [ -f "$SSL_CERT_FILE" ]; then
                    # Added as an extra trust anchor, not over the distribution's
                    # own bundle, which its ca-certificates package rewrites
                    flags+=(--volume "$SSL_CERT_FILE:${distro.caAnchor}:ro")
                    hooks=(--pre-init-hooks ${lib.escapeShellArg distro.preInit})
                  fi
                  # Distrobox shares $HOME; share the current directory too when
                  # it is elsewhere, e.g. a project checked out outside $HOME
                  case "$PWD/" in
                    "$HOME"/*) ;;
                    *) flags+=(--volume "$PWD:$PWD" --label "nixtrobox.shared=$PWD") ;;
                  esac

                  distrobox create --yes --name "$name" --image "$image" "''${hooks[@]}" \
                    --additional-flags "''${flags[*]}" >&2
                fi

                opts=()
                if [ ! -t 0 ] || [ ! -t 1 ]; then
                  opts+=(--no-tty)
                fi

                case "$PWD/" in
                  "$HOME"/*)
                    if [ "$#" -eq 0 ]; then
                      exec distrobox enter "''${opts[@]}" "$name"
                    fi
                    exec distrobox enter "''${opts[@]}" "$name" -- "$@"
                    ;;
                esac

                # Outside $HOME, distrobox starts in /run/host$PWD. When the box
                # shares this directory at its own path, start there instead, so
                # paths match the host's
                shared="$("$manager" inspect --format '{{index .Config.Labels "nixtrobox.shared"}}' "$name" 2>/dev/null || true)"
                target="/run/host$PWD"
                if [ -n "$shared" ]; then
                  case "$PWD/" in
                    "$shared"/*) target="$PWD" ;;
                  esac
                fi
                if [ "$#" -eq 0 ]; then
                  # shellcheck disable=SC2016
                  exec distrobox enter "''${opts[@]}" "$name" -- \
                    sh -c 'cd "$1" && exec "''${SHELL:-/bin/sh}" -l' sh "$target"
                fi
                # shellcheck disable=SC2016
                exec distrobox enter "''${opts[@]}" "$name" -- \
                  sh -c 'cd "$1" && shift && exec "$@"' sh "$target" "$@"
              '';
            };

          boxes = lib.mapAttrs box (distrosFor system);
        in
        boxes
        // lib.mapAttrs' (name: distro: lib.nameValuePair "${name}-image" (image name distro)) (
          distrosFor system
        )
        // {
          update-pins = pkgs.writeShellApplication {
            name = "update-pins";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
              pkgs.nix-prefetch-docker
              pkgs.skopeo
            ];
            text = ''
              if [ ! -f distros.json ]; then
                echo "update-pins: run this in the directory that has distros.json" >&2
                exit 1
              fi

              pins='{}'
              for name in $(jq -r 'keys[]' distros.json); do
                image="$(jq -r --arg n "$name" '.[$n].image' distros.json)"
                tag="$(jq -r --arg n "$name" '.[$n].tag' distros.json)"
                # The digest of the image's manifest (list) is the hash of its
                # raw bytes; resolving it once pins every architecture to the
                # same release of the image
                digest="sha256:$(skopeo inspect --raw "docker://$image:$tag" | sha256sum | cut -d ' ' -f 1)"
                # The image tarball records its name and tag, so the hash has
                # to be computed for the name the flake gives it
                final_name="nixtrobox/$name"
                final_tag="$tag-''${digest:7:12}"
                for system in $(jq -r --arg n "$name" '.[$n].systems[]' distros.json); do
                  case "$system" in
                    x86_64-linux) arch=amd64 ;;
                    aarch64-linux) arch=arm64 ;;
                    *) echo "update-pins: unsupported system $system" >&2; exit 1 ;;
                  esac
                  echo "update-pins: $image:$tag@$digest ($arch)" >&2
                  pin="$(nix-prefetch-docker --json --quiet \
                    --image-name "$image" --image-tag "$tag" --image-digest "$digest" \
                    --final-image-name "$final_name" --final-image-tag "$final_tag" \
                    --arch "$arch" --os linux)"
                  pins="$(jq --arg n "$name" --arg s "$system" --argjson p "$pin" \
                    '.[$n][$s] = { imageDigest: $p.imageDigest, hash: $p.hash }' <<<"$pins")"
                done
              done
              jq --sort-keys . <<<"$pins" > pins.json
              echo "update-pins: wrote pins.json" >&2
            '';
          };
        }
      );

      apps = forEachSupportedSystem (
        { system, ... }:
        lib.mapAttrs (name: package: {
          type = "app";
          program = lib.getExe package;
          meta.description =
            if name == "update-pins" then
              "Update pins.json from distros.json"
            else
              "Enter the pinned ${lib.removePrefix "nixtrobox-" package.name} box";
        }) (lib.filterAttrs (name: _: !(lib.hasSuffix "-image" name)) self.packages.${system})
      );

      # Building the images checks that every pin still downloads and matches
      checks = forEachSupportedSystem (
        { system, ... }: lib.filterAttrs (name: _: lib.hasSuffix "-image" name) self.packages.${system}
      );

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          # Tools for editing the boxes. The boxes themselves are entered with
          # `nix run .#<distro>`, which downloads only that distribution's image
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.distrobox
              self.packages.${system}.update-pins
              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
