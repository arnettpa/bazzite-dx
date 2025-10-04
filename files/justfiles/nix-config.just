# Setup Nix package manager
nix-setup:
    #!/usr/bin/env bash
    set -euo pipefail

    NIX_DAEMON_SCRIPT="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    NIX_INSTALLER="https://install.determinate.systems/nix"

    echo "Setting up Nix package manager..."
    curl --proto '=https' --tlsv1.2 -sSf -L "$NIX_INSTALLER" | sh -s -- install --no-confirm
    [ -f "$NIX_DAEMON_SCRIPT" ] && . "$NIX_DAEMON_SCRIPT"
    echo "Nix setup complete."

# Install only Nix packages
nixpkgs-install:
    #!/usr/bin/env bash
    set -euo pipefail

    NIX_PROFILE="/nix/var/nix/profiles/default"
    NIX_DAEMON_SCRIPT="$NIX_PROFILE/etc/profile.d/nix-daemon.sh"
    OPENGL_PROFILE="/nix/var/nix/profiles/opengl-driver"
    OPENGL_PROFILE_32="/nix/var/nix/profiles/opengl-driver-32"
    OPENGL_SYMLINK_CONF="/etc/tmpfiles.d/nix-opengl-driver.conf"

    # Source Nix daemon if available
    [ -f "$NIX_DAEMON_SCRIPT" ] && . "$NIX_DAEMON_SCRIPT"
    command -v nix &>/dev/null || ujust nix-setup

    echo "Installing Nix system fonts..."
    sudo -i nix profile install nixpkgs#nerd-fonts.{hack,ubuntu,ubuntu-mono,ubuntu-sans}

    echo "Installing Nix system drivers..."
    sudo -i nix profile install --profile "$OPENGL_PROFILE" nixpkgs#{amdvlk,mesa,mesa.opencl,rocmPackages.clr,rocmPackages.clr.icd}

    echo "Installing Nix system 32-bit drivers..."
    sudo -i nix profile install --profile "$OPENGL_PROFILE_32" nixpkgs#driversi686Linux.{amdvlk,mesa}

    echo "Setting up drivers symlink..."
    sudo rm -f "$OPENGL_SYMLINK_CONF"
    printf "L+ /run/opengl-driver - - - - %s\nL+ /run/opengl-driver-32 - - - - %s\n" "$OPENGL_PROFILE" "$OPENGL_PROFILE_32" | sudo tee "$OPENGL_SYMLINK_CONF"
    sudo systemd-tmpfiles --create "$OPENGL_SYMLINK_CONF"

    echo "Nix packages installation complete."
