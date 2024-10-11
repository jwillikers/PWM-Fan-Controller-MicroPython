#!/usr/bin/env nu
use update-nix-direnv.nu update_nix_direnv_in_envrc

use std assert
use std log

def test_update_nix_direnv_in_envrc [] {
    for t in [
        [text version hash expected];
        [
'if ! has nix_direnv_version || ! nix_direnv_version 3.0.6; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-RYcUJaRMf8oF5LznDrlCXbkOQrywm0HDv1VjYGaJGdM="
fi

use flake' "3.0.7" "TEsTJaRMf8oF5LznDrlCXbkOQrywm0IHv1VjYGaTesT="
'if ! has nix_direnv_version || ! nix_direnv_version 3.0.7; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.7/direnvrc" "sha256-TEsTJaRMf8oF5LznDrlCXbkOQrywm0IHv1VjYGaTesT="
fi

use flake']
    ] {
        assert equal ($t.text | update_nix_direnv_in_envrc $t.version $t.hash) $t.expected
    }
}

def main [] [] {
    test_update_nix_direnv_in_envrc
    echo "All tests passed!"
}
