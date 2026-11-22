#!/usr/bin/env bash
#
# env_install.sh - set up a basic Python development environment.
#
# Steps: detect the OS, make sure python3 and pip are there, install Jupyter
# Notebook, and on macOS check that Homebrew is healthy.
#
# Usage:  chmod +x env_install.sh && ./env_install.sh

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# Feature 1 - pretty printing: takes a message as argument and prints it with
# a blank line before and after (printf is more portable than echo).
pretty_print() {
    printf '\n%s\n\n' "$1"
}

# Stop with an explicit message when something we cannot recover from happens.
die() {
    pretty_print "Error: $1" >&2
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

# The package manager depends on the OS.
if [[ "$OS" == "linux" ]]; then
    command -v apt-get >/dev/null 2>&1 || die "apt-get not found (Debian/Ubuntu only)"
    sudo apt-get update -y || die "apt-get update failed"
else
    command -v brew >/dev/null 2>&1 || die "Homebrew is required on macOS: https://brew.sh"
fi

# Feature 3 - python3 check: install it if missing, otherwise show the version.
if command -v python3 >/dev/null 2>&1; then
    pretty_print "python3 is installed: $(python3 --version)"
else
    pretty_print "python3 not found, installing it..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt-get install -y python3 || die "could not install python3"
    else
        brew install python3 || die "could not install python3"
    fi
fi

# Feature 4 - pip check: install it if missing, then show its version.
if ! python3 -m pip --version >/dev/null 2>&1; then
    pretty_print "pip not found, installing it..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt-get install -y python3-pip || die "could not install pip"
    else
        python3 -m ensurepip --upgrade || die "could not install pip"
    fi
fi
pretty_print "pip version: $(python3 -m pip --version)"

# Feature 5 - Jupyter Notebook. The command differs by OS: on Debian/Ubuntu pip
# refuses system-wide installs (PEP 668), so we use the distribution package.
pretty_print "Installing Jupyter Notebook..."
if [[ "$OS" == "linux" ]]; then
    sudo apt-get install -y jupyter-notebook || die "could not install Jupyter"
else
    brew install jupyter || die "could not install Jupyter"
fi

# Feature 6 - macOS only: check that Homebrew is healthy.
if [[ "$OS" == "macos" ]]; then
    pretty_print "Running brew doctor..."
    brew doctor
fi

pretty_print "Done. Check it with: python3 --version, python3 -m pip --version, jupyter notebook"
