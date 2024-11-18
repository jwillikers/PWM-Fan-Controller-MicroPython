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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
            micropython = {
              type = "app";
              program = builtins.toString (
                pkgs.writers.writeNu "install-micropython" ''
                  cp ${pkgs.micropython}/bin/RPI_PICO.uf2 (["/run/media/" (^id --name --user) "RPI-RP2"] | path join)
                ''
              );
            };
            pwm-fan-controller = {
              type = "app";
              program = builtins.toString (
                pkgs.writers.writeNu "install-pwm-fan-controller" ''
                  let serial_device = (
                    ^${pkgs.lib.getExe mpremote} devs |
                    parse '{device} {serial_number} {vendor_id}:{product_id} {description}' |
                    where description == "MicroPython Board in FS mode" |
                    get device |
                    first
                  )
                  let port_option = (
                    if not ($serial_device | is-empty) {
                      $"port:($serial_device)"
                    } else {
                      ""
                    }
                  )
                  ^${pkgs.lib.getExe mpremote} connect $port_option fs cp ${
                    self.packages.${system}.pwm-fan-controller
                  }/bin/main.py :
                ''
              );
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
              # todo Migrate everything over to Nix eventually.
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
