default: install

alias c := check

check:
    .venv/bin/yamllint .
    .venv/bin/ruff check --fix .
    .venv/bin/pyright --warnings
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

install-micropython file="RPI_PICO-20240602-v1.23.0.uf2":
    curl --location \
        --output-dir /run/media/$(id --name --user)/RPI-RP2 \
        --remote-name "https://micropython.org/resources/firmware/{{ file }}"

install device="":
    #!/usr/bin/env sh
    tty=$(.venv/bin/mpremote devs | awk -F' ' '/MicroPython Board in FS mode/ {print $1; exit;}')
    .venv/bin/mpremote connect {{ if device == "" { "port:$tty" } else { device } }} fs cp main.py :

sync:
    source .venv/bin/activate && pip-sync --python-executable .venv/bin/python requirements-dev.txt

alias u := update
alias up := update

update:
    source .venv/bin/activate && pip-compile requirements-dev.in
