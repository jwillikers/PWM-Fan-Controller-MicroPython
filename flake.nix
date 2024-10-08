{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          (final: prev: {
            # Build MicroPython for the rp2-pico
            micropython = prev.micropython.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ [
                pkgs.cmake
                pkgs.gcc-arm-embedded
              ];
              dontUseCmakeConfigure = true;
              doCheck = false;
              makeFlags = [
                "-C"
                "ports/rp2"
              ];
              installPhase = ''
                runHook preInstall
                mkdir --parents $out/bin
                install -Dm755 ports/rp2/build-RPI_PICO/firmware.uf2 $out/bin/RPI_PICO.uf2
                runHook postInstall
              '';
            });
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        nativeBuildInputs = with pkgs; [
          fish
          just
          micropython
          nushell
          # todo Should everything be pulled in via Nix or pip-tools?
          # mpremote
          # pyright
          python3Packages.python
          python3Packages.pip-tools
          python3Packages.venvShellHook
          # ruff
          # yamllint
        ];
        buildInputs =
          with pkgs;
          [
          ];
        treefmt.config = {
          programs = {
            actionlint.enable = true;
            # jsonfmt.enable = true;
            just.enable = true;
            # todo
            # mypy.enable = true;
            nixfmt.enable = true;
            ruff-check.enable = true;
            ruff-format.enable = true;
            taplo.enable = true;
            # yamlfmt.enable = true;
          };
          projectRootFile = "flake.nix";
          settings.formatter = {
            "strip-gps-metadata" = {
              command = "${pkgs.bash}/bin/bash";
              options = [
                "-euc"
                ''
                  for file in "$@"; do
                    ${pkgs.exiftool}/bin/exiftool -duplicates -overwrite_original "-gps*=" "$file"
                  done
                ''
                "--" # bash swallows the second argument when using -c
              ];
              includes = [
                "*.avif"
                "*.bmp"
                "*.gif"
                "*.jpeg"
                "*.jpg"
                "*.png"
                "*.svg"
                "*.tiff"
                "*.webp"
              ];
            };
          };
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs treefmt.config;
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            check-executables-have-shebangs.enable = true;
            check-json.enable = true;
            check-toml.enable = true;
            check-yaml.enable = true;

            # todo Not integrated with Nix?
            check-format = {
              enable = true;
              entry = "${treefmtEval.config.build.wrapper}/bin/treefmt --fail-on-change";
            };

            detect-private-keys.enable = true;
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            flake-checker.enable = true;
            mixed-line-endings.enable = true;

            pip-compile = {
              enable = true;
              package = pkgs.python3Packages.pip-tools;
              entry = "${pkgs.python3Packages.pip-tools}/bin/pip-compile requirements-dev.in";
              description = "Automatically compile requirements.";
              name = "pip-compile";
              files = "^requirements-dev\\.(in|txt)$";
              pass_filenames = false;
            };

            pyright = {
              args = [
                "--pythonpath"
                ".venv/bin/python"
              ];
              enable = true;
            };
            trim-trailing-whitespace.enable = true;
            yamllint.enable = true;
          };
        };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          inherit buildInputs;
          nativeBuildInputs =
            nativeBuildInputs
            ++ [
              treefmtEval.config.build.wrapper
              # Make formatters available for IDE's.
              (lib.attrValues treefmtEval.config.build.programs)
            ]
            ++ pre-commit.enabledPackages;
          venvDir = "./.venv";
          postVenvCreation = ''
            pip-sync --python-executable .venv/bin/python requirements-dev.txt
          '';
          # https://github.com/NixOS/nixpkgs/issues/223151
          postShellHook =
            ''
              export LC_ALL="C.UTF-8";
              pip-sync --python-executable .venv/bin/python requirements-dev.txt
            ''
            + pre-commit.shellHook;
        };
        packages = {
          default = pkgs.micropython;
          micropython = pkgs.micropython;
          pwm-fan-controller = callPackage ./default.nix { };
        };
        apps = {
          install = {
            micropython =
              let
                script = pkgs.writeShellApplication {
                  name = "install-micropython";
                  runtimeInputs = with pkgs; [ micropython ];
                  text = ''
                    cp ${pkgs.micropython}/bin/RPI_PICO.uf2 "/run/media/$(id --name --user)/RPI-RP2/"
                  '';
                };
              in
              {
                type = "app";
                program = "${script}/bin/install-micropython";
              };
            pwm-fan-controller =
              let
                script = pkgs.writeShellApplication {
                  name = "install-pwm-fan-controller";
                  runtimeInputs = with pkgs; [ mpremote ];
                  text = ''
                    tty=$(${pkgs.mpremote}/bin/mpremote devs | awk -F' ' '/MicroPython Board in FS mode/ {print $1; exit;}')
                    ${pkgs.mpremote}/bin/mpremote connect "port:$tty" fs cp ${
                      self.packages.${system}.pwm-fan-controller-micropython
                    }/bin/main.py :
                  '';
                };
              in
              {
                type = "app";
                program = "${script}/bin/install-pwm-fan-controller";
              };
          };
          default = apps.install.pwm-fan-controller;
        };
        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
