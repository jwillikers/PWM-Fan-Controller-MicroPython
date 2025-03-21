default: install

alias c := check

check: && format
    yamllint .
    ruff check --fix .
    pyright --warnings
    asciidoctor **/*.adoc
    lychee --cache **/*.html
    nix flake check

alias f := format
alias fmt := format

format:
    treefmt

init-dev: && sync
    [ -d .venv ] || python -m venv .venv
    .venv/bin/python -m pip install pip-tools
    .venv/bin/python -m pip install --requirement requirements-dev.txt

install device="":
    #!/usr/bin/env nu
    let serial_device = (
        if ( "{{ device }}" | is-empty) {(
            ^.venv/bin/mpremote devs |
            parse '{device} {serial_number} {vendor_id}:{product_id} {description}' |
            where description == "MicroPython Board in FS mode" |
            get device |
            first
        )} else {
            "{{ device }}"
        }
    )
    let port_option = (
        if not ($serial_device | is-empty) {
            $"port:($serial_device)"
        } else {
            ""
        }
    )
    ^.venv/bin/mpremote connect $port_option fs cp main.py :

# todo Automate updating this.
install-micropython file="RPI_PICO-20241025-v1.24.0.uf2":
    curl --location \
        --output-dir /run/media/$(id --name --user)/RPI-RP2 \
        --remote-name "https://micropython.org/resources/firmware/{{ file }}"

# Mount the local repository on the device and execute commands.

# By default, the main.py file is executed on the device.
run command='exec "import main"' device="":
    #!/usr/bin/env nu
    let serial_device = (
        if ( "{{ device }}" | is-empty) {(
            ^.venv/bin/mpremote devs |
            parse '{device} {serial_number} {vendor_id}:{product_id} {description}' |
            where description == "MicroPython Board in FS mode" |
            get device |
            first
        )} else {
            "{{ device }}"
        }
    )
    let port_option = (
        if not ($serial_device | is-empty) {
            $"port:($serial_device)"
        } else {
            ""
        }
    )
    ^.venv/bin/mpremote connect $port_option mount . {{ command }}

sync:
    source .venv/bin/activate && pip-sync --python-executable .venv/bin/python requirements-dev.txt

alias u := update
alias up := update

update:
    nix run ".#update-nix-direnv"
    nix run ".#update-nixos-release"
    nix flake update
    source .venv/bin/activate && pip-compile requirements-dev.in
