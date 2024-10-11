default: install

alias c := check

check: && format
    yamllint .
    ruff check --fix .
    pyright --warnings
    asciidoctor **/*.adoc
    lychee --cache **/*.html

alias f := format
alias fmt := format

format:
    treefmt

init-dev: && sync
    [ -d .venv ] || python -m venv .venv
    .venv/bin/python -m pip install pip-tools
    .venv/bin/python -m pip install --requirement requirements-dev.txt

install device="":
    #!/usr/bin/env sh
    set -euxo pipefail
    tty=$(.venv/bin/mpremote devs | awk -F' ' '/MicroPython Board in FS mode/ {print $1; exit;}')
    port_option=""
    if [ -n "${tty+x}" ]; then
        port_option="port:$tty"
    fi
    .venv/bin/mpremote connect {{ if device == "" { "\"$port_option\"" } else { device } }} fs cp main.py :

install-micropython file="RPI_PICO-20240602-v1.23.0.uf2":
    curl --location \
        --output-dir /run/media/$(id --name --user)/RPI-RP2 \
        --remote-name "https://micropython.org/resources/firmware/{{ file }}"

# Mount the local repository on the device and execute commands.
# By default, the main.py file is executed on the device.
run command='exec "import main"' device="":
    #!/usr/bin/env sh
    set -euxo pipefail
    tty=$(.venv/bin/mpremote devs | awk -F' ' '/MicroPython Board in FS mode/ {print $1; exit;}')
    port_option=""
    if [ -n "${tty+x}" ]; then
        port_option="port:$tty"
    fi
    .venv/bin/mpremote connect {{ if device == "" { "\"$port_option\"" } else { device } }} mount . {{ command }}

sync:
    source .venv/bin/activate && pip-sync --python-executable .venv/bin/python requirements-dev.txt

alias t := test

test:
    nu update-nix-direnv-tests.nu

alias u := update
alias up := update

update:
    nix flake update
    nu update-nix-direnv.nu
    source .venv/bin/activate && pip-compile requirements-dev.in
