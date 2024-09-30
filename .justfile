default: install

alias f := format
alias fmt := format

format:
    venv/bin/ruff format .
    just --fmt --unstable

init-dev: && sync
    [ -d venv ] || python -m venv venv
    venv/bin/python -m pip install --requirement requirements-dev.txt
    venv/bin/pre-commit install

install-micropython file="RPI_PICO-20240602-v1.23.0.uf2":
    curl --location --output-dir /run/media/$(id --name --user)/RPI-RP2 --remote-name https://micropython.org/resources/firmware/{{ file }}

install tty="/dev/ttyACM0":
    curl --location --remote-name https://raw.githubusercontent.com/micropython/micropython/master/tools/pyboard.py
    python pyboard.py --device {{ tty }} --filesystem cp main.py :

alias l := lint

lint:
    venv/bin/yamllint .
    venv/bin/ruff check --fix .
    venv/bin/pyright --warnings .

sync:
    venv/bin/pip-sync requirements-dev.txt

alias u := update
alias up := update

update:
    venv/bin/pip-compile \
        --allow-unsafe \
        --generate-hashes \
        --reuse-hashes \
        --upgrade \
        requirements-dev.in
    venv/bin/pre-commit autoupdate
