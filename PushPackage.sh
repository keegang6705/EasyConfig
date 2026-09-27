#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AUR_DIR="$(mktemp -d)"

cleanup() {
    rm -rf -- "$AUR_DIR"
}

trap cleanup EXIT

KEY_FILE="$HOME/.ssh/id_ed25519_pc"

read -rp "Commit message: " msg

if [[ -z "$msg" ]]; then
    echo "Commit message required"
    exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
    echo "SSH key not found: $KEY_FILE"
    exit 1
fi

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    eval "$(ssh-agent -s)"
fi

KEY_FINGERPRINT="$(ssh-keygen -lf "$KEY_FILE" | awk '{print $2}')"

if ! ssh-add -l 2>/dev/null | grep -q "$KEY_FINGERPRINT"; then
    ssh-add "$KEY_FILE"
fi

git clone "ssh://aur@aur.archlinux.org/easy-config.git" "$AUR_DIR"

find "$AUR_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf -- {} +

cp -a "$SCRIPT_DIR/." "$AUR_DIR/"

cd "$AUR_DIR"

makepkg --printsrcinfo > .SRCINFO

git add .

if git diff --cached --quiet; then
    echo "No changes to commit"
    exit 0
fi

git commit -m "$msg"
git push

echo "Done"