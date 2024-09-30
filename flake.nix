{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
         let
          overlays = [
            (final: prev: {
              # Build MicroPython for the rp2-pico
              micropython = prev.micropython.overrideAttrs (old: {
                nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.cmake pkgs.gcc-arm-embedded ];
                dontUseCmakeConfigure = true;
                doCheck = false;
                makeFlags = [ "-C" "ports/rp2" ];
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
            # pre-commit
            # pyright
            python312Packages.pip
            python312Packages.pip-tools
            python312Packages.python
            # python312Packages.venv
            python312Packages.venvShellHook
            # rshell
            # ruff
            # yamllint
          ];
          buildInputs = with pkgs; [
          ];
        in
        with pkgs;
        {
          devShells.default = mkShell {
            inherit buildInputs nativeBuildInputs;
            venvDir = "./.venv";
            postShellHook = ''
              PYTHONPATH=\$PWD/\.venv/\${python312Packages.python.sitePackages}/:\$PYTHONPATH
              pip-sync requirements-dev.txt
            '';
          };
          packages = {
            default = pkgs.micropython;
            micropython = pkgs.micropython;
            pwm-fan-controller = callPackage ./default.nix {};
          };
          apps = {
            install = {
              micropython = let
                script = pkgs.writeShellApplication {
                  name = "install-micropython";
                  runtimeInputs = with pkgs; [micropython];
                  text = ''
                    cp ${pkgs.micropython}/bin/RPI_PICO.uf2 "/run/media/$(id --name --user)/RPI-RP2/"
                  '';
                };
                in {
                  type = "app";
                  program = "${script}/bin/install-micropython";
                };
              pwm-fan-controller = let
                script = pkgs.writeShellApplication {
                  name = "install-pwm-fan-controller";
                  runtimeInputs = with pkgs; [rshell];
                  text = ''
                    ${pkgs.rshell}/bin/rshell cp ${self.packages.${system}.pwm-fan-controller-micropython}/bin/main.py /pyboard/
                  '';
                };
                in {
                  type = "app";
                  program = "${script}/bin/install-pwm-fan-controller";
                };
              };
            default = apps.install.pwm-fan-controller;
          };
        }
      );
}
