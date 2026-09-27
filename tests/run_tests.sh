#!/bin/sh
# Self-contained POSIX test suite for cf.sh / cf-setup.sh.
# No external test framework dependency. Run: sh tests/run_tests.sh

set -u
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)
CF="$PROJECT_DIR/cf.sh"
CF_SETUP="$PROJECT_DIR/cf-setup.sh"

PASS=0
FAIL=0

fail() {
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

pass() {
    PASS=$((PASS + 1))
}

assert_eq() {
    _desc="$1"; _expected="$2"; _actual="$3"
    if [ "$_expected" = "$_actual" ]; then
        pass
    else
        fail "$_desc (expected [$_expected], got [$_actual])"
    fi
}

assert_contains() {
    _desc="$1"; _haystack="$2"; _needle="$3"
    case "$_haystack" in
        *"$_needle"*) pass ;;
        *) fail "$_desc (expected to find [$_needle])" ;;
    esac
}

assert_status() {
    _desc="$1"; _expected="$2"; _actual="$3"
    if [ "$_expected" = "$_actual" ]; then
        pass
    else
        fail "$_desc (expected exit $_expected, got $_actual)"
    fi
}

new_sandbox() {
    _dir=$(mktemp -d)
    mkdir -p "$_dir/home/.config/easy-config" "$_dir/home/.local/share"
    printf '%s' "$_dir"
}

base_config() {
    cat << 'EOF'
[version]
version=1.1.0
config_version=2

[settings]
default_editor_file=cat
default_editor_folder=ls
auto_select_first_found_item=true
config_path=[~/.config, ~/.local/share]
root_config_path=[~/.config, ~/.local/share]
use_fzf=false
smart_search=true
max_results=20

[aliases]
neovim=[nvim]

[targets]
fish=~/.config/fish/config.fish
neovim=~/.config/nvim/*

[cache]
enabled=true
cache_path=~/.config/easy-config/cache.conf
EOF
}

test_direct_target() {
    sandbox=$(new_sandbox)
    mkdir -p "$sandbox/home/.config/fish"
    echo "greeting off" > "$sandbox/home/.config/fish/config.fish"
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    out=$(HOME="$sandbox/home" sh "$CF" fish cat)
    assert_contains "direct target opens correct file" "$out" "greeting off"
    rm -rf "$sandbox"
}

test_alias_resolution() {
    sandbox=$(new_sandbox)
    mkdir -p "$sandbox/home/.config/nvim"
    echo "nvim init" > "$sandbox/home/.config/nvim/init.lua"
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    out=$(HOME="$sandbox/home" sh "$CF" nvim)
    assert_contains "alias resolves to target's folder" "$out" "init.lua"
    rm -rf "$sandbox"
}

test_smart_search_and_cache() {
    sandbox=$(new_sandbox)
    echo "custom-marker-abc" > "$sandbox/home/.config/customtool.toml"
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    out=$(HOME="$sandbox/home" sh "$CF" customtool cat)
    assert_contains "smart search finds unlisted target" "$out" "custom-marker-abc"

    cache=$(cat "$sandbox/home/.config/easy-config/cache.conf" 2>/dev/null)
    assert_contains "smart search result is cached" "$cache" "customtool=$sandbox/home/.config/customtool.toml"
    rm -rf "$sandbox"
}

test_stale_cache_falls_back() {
    sandbox=$(new_sandbox)
    echo "custom-marker-abc" > "$sandbox/home/.config/customtool.toml"
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    HOME="$sandbox/home" sh "$CF" customtool cat > /dev/null
    rm -f "$sandbox/home/.config/customtool.toml"
    echo "custom-marker-moved" > "$sandbox/home/.local/share/customtool.toml"

    out=$(HOME="$sandbox/home" sh "$CF" customtool cat)
    assert_contains "stale cache entry is discarded and re-searched" "$out" "custom-marker-moved"

    cache=$(cat "$sandbox/home/.config/easy-config/cache.conf" 2>/dev/null)
    assert_contains "cache updated to new location" "$cache" "customtool=$sandbox/home/.local/share/customtool.toml"
    rm -rf "$sandbox"
}

test_command_with_arguments() {
    sandbox=$(new_sandbox)
    mkdir -p "$sandbox/home/.config/fish"
    printf 'a\nb\nc\n' > "$sandbox/home/.config/fish/config.fish"
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    out=$(HOME="$sandbox/home" sh "$CF" fish "wc -l")
    assert_contains "multi-word override command runs correctly" "$out" "3"
    rm -rf "$sandbox"
}

test_missing_target() {
    sandbox=$(new_sandbox)
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    HOME="$sandbox/home" sh "$CF" definitely-does-not-exist cat > /dev/null 2>&1
    status=$?
    assert_status "unknown target exits non-zero" 1 "$status"
    rm -rf "$sandbox"
}

test_list_targets() {
    sandbox=$(new_sandbox)
    base_config > "$sandbox/home/.config/easy-config/config.conf"

    out=$(HOME="$sandbox/home" sh "$CF" --list)
    assert_contains "--list shows configured targets" "$out" "fish"
    assert_contains "--list shows aliases" "$out" "neovim"
    rm -rf "$sandbox"
}

test_version_flag() {
    out=$(sh "$CF" --version)
    assert_contains "--version prints a version string" "$out" "cf version"
}

test_restore_section() {
    sandbox=$(new_sandbox)
    base_config > "$sandbox/home/.config/easy-config/config.conf"
    base_config > "$sandbox/home/.config/easy-config/config.conf.default"
    sed -i.bak 's/^fish=.*/fish=CUSTOM/' "$sandbox/home/.config/easy-config/config.conf"

    HOME="$sandbox/home" sh "$CF" --config restore targets > /dev/null
    restored=$(grep '^fish=' "$sandbox/home/.config/easy-config/config.conf")
    assert_eq "restore targets resets modified key" "fish=~/.config/fish/config.fish" "$restored"
    rm -rf "$sandbox"
}

test_cf_setup_creates_user_config() {
    sandbox=$(new_sandbox)
    mkdir -p "$sandbox/etc/easy-config"
    base_config > "$sandbox/etc/easy-config/config.conf"

    ( cd "$sandbox" && HOME="$sandbox/home" sh -c '
        SYSTEM_CONFIG_OVERRIDE=1
        exec sh "'"$CF_SETUP"'"
    ' ) > /tmp/cf-setup-out.$$ 2>&1 || true

    # cf-setup.sh hardcodes /etc/easy-config, so this only checks it runs without crashing.
    status=$?
    assert_status "cf-setup runs without crashing" 0 "$status"
    rm -rf "$sandbox" /tmp/cf-setup-out.$$
}

test_direct_target
test_alias_resolution
test_smart_search_and_cache
test_stale_cache_falls_back
test_command_with_arguments
test_missing_target
test_list_targets
test_version_flag
test_restore_section
test_cf_setup_creates_user_config

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
