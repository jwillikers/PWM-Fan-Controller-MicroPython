{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-update-scripts = {
      url = "github:jwillikers/nix-update-scripts";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-unstable.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      # deadnix: skip
      self,
      nix-update-scripts,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = import ./overlays { };
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit pkgs treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      with pkgs;
      {
        apps = {
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv;
          install = {
            micropython =
              let
                script = pkgs.writeShellApplication {
                  name = "install-micropython";
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
                  text = ''
                    set -euxo pipefail
                    tty=$(${pkgs.mpremote}/bin/mpremote devs \
                      | awk -F' ' '/MicroPython Board in FS mode/ {print $1; exit;}')
                    port_option=""
                    if [ -n "''${tty+x}" ]; then
                      port_option="port:$tty"
                    fi
                    ${pkgs.mpremote}/bin/mpremote connect "$port_option" fs cp ${
                      self.packages.${system}.pwm-fan-controller
                    }/bin/main.py :
                  '';
                };
              in
              {
                type = "app";
                program = "${script}/bin/install-pwm-fan-controller";
              };
          };
          default = self.apps.${system}.install.pwm-fan-controller;
        };
        devShells.default = mkShell {
          nativeBuildInputs =
            with pkgs;
            [
              asciidoctor
              fish
              just
              lychee
              micropython
              nil
              nushell
              # todo Should everything be pulled in via Nix or pip-tools?
              # mpremote
              python3Packages.python
              python3Packages.pip-tools
              python3Packages.venvShellHook
              treefmtEval.config.build.wrapper
              (builtins.attrValues treefmtEval.config.build.programs)
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
          inherit (pkgs) micropython;
          pwm-fan-controller = callPackage ./package.nix { };
        };
        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
