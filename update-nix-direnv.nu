#!/usr/bin/env nu

# https://github.com/nix-community/nix-direnv

# Get the newest version of nix-direnv.
def get_latest_nix_direnv_version [] [ nothing -> string ] {
  http get https://api.github.com/repos/nix-community/nix-direnv/releases/latest | get name
}

# Get the SHA-256 hash of the direnvrc file for a particular version of nix-direnv.
def get_direnvrc_hash [
  version: string # The version of nix-direnv, i.e. 3.0.6
] [ nothing -> string ] {
  http get $"https://raw.githubusercontent.com/nix-community/nix-direnv/($version)/direnvrc" | hash sha256 --binary | encode new-base64
}

# Replace the current version of nix-direnv with the given version and update the SHA-256 checksum of the direnvrc file.
#
# This function takes as input the content of a .envrc file, like the following.
#
# if ! has nix_direnv_version || ! nix_direnv_version 3.0.6; then
#   source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-RYcUJaRMf8oF5LznDrlCXbkOQrywm0HDv1VjYGaJGdM="
# fi
#
# use flake
#
export def update_nix_direnv_in_envrc [
  version: string # nix-direnv version, i.e. 3.0.6
  hash: string # The sha256 checksum of the release
] [ string -> string ] {
  (
    $in
    | str replace --regex "nix_direnv_version [0-9]+\\.[0-9]+\\.[0-9]+"
      $"nix_direnv_version ($version)"
    | str replace --regex "source_url \"https://raw.githubusercontent.com/nix-community/nix-direnv/[0-9]+\\.[0-9]+\\.[0-9]+/direnvrc\" \"sha256-[[:alnum:]]+=\""
      $'source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/($version)/direnvrc" "sha256-($hash)"'
  )
}

def main [
  files: list<path> = [] # A list of `.envrc` files to operate on.
] {
  let files = (
    if ($files | is-empty) {
      glob **/.envrc
    } else {
      $files
    }
  )

  let version = get_latest_nix_direnv_version
  let hash = get_direnvrc_hash $version

  for file in $files {
    $file | open | update_nix_direnv_in_envrc $version $hash | save --force $file
  }

  exit 0
}
