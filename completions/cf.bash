_cf_config_file() {
    if [ -f "${HOME}/.config/easy-config/config.conf" ]; then
        printf '%s' "${HOME}/.config/easy-config/config.conf"
    elif [ -f "/etc/easy-config/config.conf" ]; then
        printf '%s' "/etc/easy-config/config.conf"
    fi
}

_cf_names() {
    _cf_cfg=$(_cf_config_file)
    [ -z "$_cf_cfg" ] && return
    awk -F'=' '
        /^\[targets\]$/ { section="targets"; next }
        /^\[aliases\]$/ { section="aliases"; next }
        /^\[/ { section=""; next }
        section != "" && NF && $1 != "" { print $1 }
    ' "$_cf_cfg"
}

_cf_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --list --config -r --refresh"

    case "$prev" in
        cf)
            COMPREPLY=( $(compgen -W "$opts $(_cf_names)" -- "$cur") )
            return 0
            ;;
        --config)
            COMPREPLY=( $(compgen -W "restore" -- "$cur") )
            return 0
            ;;
        restore)
            COMPREPLY=( $(compgen -W "settings targets aliases cache" -- "$cur") )
            return 0
            ;;
    esac

    case "$cur" in
        -*)
            COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            ;;
        *)
            COMPREPLY=( $(compgen -W "$(_cf_names)" -- "$cur") )
            ;;
    esac
}

complete -F _cf_completions cf
