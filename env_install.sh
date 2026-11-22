#!/usr/bin/env bash
#
# env_install.sh - set up a basic Python development environment.
#
# Steps: detect the OS, make sure python3 and pip are there, install Jupyter
# Notebook, and on macOS check that Homebrew is healthy.
#
# Usage:  ./env_install.sh [--dry-run]
#   --dry-run   print the commands that would be run, change nothing

# Strict mode: stop on any error, on unset variables, and on failures inside pipes.
set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# Feature 1 - pretty printing: message in $1, optional colour name in $2.
# Blank lines before and after, printf for portability.
pretty_print() {
    local message="$1"
    local colour="${2:-}"
    local start="" end=""
    case "$colour" in
        green)  start=$'\033[32m'; end=$'\033[0m' ;;
        yellow) start=$'\033[33m'; end=$'\033[0m' ;;
        red)    start=$'\033[31m'; end=$'\033[0m' ;;
    esac
    printf '\n%s%s%s\n\n' "$start" "$message" "$end"
}

# Run a command, or only show it in dry-run mode.
run() {
    if (( DRY_RUN )); then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# Stop with an explicit message when something we cannot recover from happens.
die() {
    pretty_print "Error: $1" red >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

# Feature 2 - OS detection with $OSTYPE (linux-gnu, darwin23, ...).
case "$OSTYPE" in
    linux*)  OS="linux" ;;
    darwin*) OS="macos" ;;
    *)       die "unsupported operating system: $OSTYPE" ;;
esac
pretty_print "Detected operating system: $OS"

# Package manager commands depend on the OS.
if [[ "$OS" == "linux" ]]; then
    command -v apt-get >/dev/null 2>&1 || die "apt-get not found (Debian/Ubuntu only)"
    SUDO=""
    if [[ $EUID -ne 0 ]]; then SUDO="sudo"; fi
    install_pkg() { run $SUDO apt-get install -y "$@"; }
    run $SUDO apt-get update -y
else
    command -v brew >/dev/null 2>&1 || die "Homebrew is required on macOS: https://brew.sh"
    install_pkg() { run brew install "$@"; }
fi

# Feature 3 - python3 check: install if missing, otherwise show the version.
if command -v python3 >/dev/null 2>&1; then
    pretty_print "python3 is installed: $(python3 --version)" green
else
    pretty_print "python3 not found, installing it..." yellow
    install_pkg python3
fi

# Feature 4 - pip check: install if missing, then show its version.
if ! python3 -m pip --version >/dev/null 2>&1; then
    pretty_print "pip not found, installing it..." yellow
    if [[ "$OS" == "linux" ]]; then
        install_pkg python3-pip
    else
        run python3 -m ensurepip --upgrade
    fi
fi
if (( DRY_RUN )); then
    pretty_print "pip version: (skipped in dry-run)"
else
    pretty_print "pip version: $(python3 -m pip --version)" green
fi

# Feature 5 - Jupyter Notebook. The command differs by OS: on Debian/Ubuntu pip
# refuses system-wide installs (PEP 668), so we use the distribution package.
pretty_print "Installing Jupyter Notebook..."
if [[ "$OS" == "linux" ]]; then
    install_pkg jupyter-notebook
else
    install_pkg jupyter
fi

# Feature 6 - macOS only: check that Homebrew is healthy.
if [[ "$OS" == "macos" ]]; then
    pretty_print "Running brew doctor..."
    run brew doctor
fi

pretty_print "Done. Check it with: python3 --version, python3 -m pip --version, jupyter notebook" green
