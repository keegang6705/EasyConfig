#compdef cf

_cf_config_file() {
    if [ -f "${HOME}/.config/easy-config/config.conf" ]; then
        printf '%s' "${HOME}/.config/easy-config/config.conf"
    elif [ -f "/etc/easy-config/config.conf" ]; then
        printf '%s' "/etc/easy-config/config.conf"
    fi
}

_cf_names() {
    local cfg
    cfg=$(_cf_config_file)
    [ -z "$cfg" ] && return
    awk -F'=' '
        /^\[targets\]$/ { section="targets"; next }
        /^\[aliases\]$/ { section="aliases"; next }
        /^\[/ { section=""; next }
        section != "" && NF && $1 != "" { print $1 }
    ' "$cfg"
}

_cf() {
    local -a names opts
    opts=('--help' '--version' '--list' '--config' '-r' '--refresh')
    names=(${(f)"$(_cf_names)"})

    if [ "$CURRENT" -eq 2 ]; then
        compadd -a opts
        compadd -a names
        return
    fi

    case "${words[2]}" in
        --config)
            if [ "$CURRENT" -eq 3 ]; then
                compadd restore
            elif [ "$CURRENT" -eq 4 ]; then
                compadd settings targets aliases cache
            fi
            ;;
        *)
            compadd -a names
            ;;
    esac
}

_cf "$@"
