function __cf_config_file
    if test -f "$HOME/.config/easy-config/config.conf"
        printf '%s\n' "$HOME/.config/easy-config/config.conf"
    else if test -f /etc/easy-config/config.conf
        printf '%s\n' /etc/easy-config/config.conf
    end
end

function __cf_names
    set -l cfg (__cf_config_file)
    test -n "$cfg"; or return
    awk -F'=' '
        /^\[targets\]$/ { section="targets"; next }
        /^\[aliases\]$/ { section="aliases"; next }
        /^\[/ { section=""; next }
        section != "" && NF && $1 != "" { print $1 }
    ' "$cfg"
end

complete -c cf -f -n '__fish_use_subcommand' -a '(__cf_names)'
complete -c cf -f -n '__fish_use_subcommand' -l help -d 'Show help message'
complete -c cf -f -n '__fish_use_subcommand' -l version -d 'Show version'
complete -c cf -f -n '__fish_use_subcommand' -l list -d 'List configured targets'
complete -c cf -f -n '__fish_use_subcommand' -l config -d 'Restore configuration defaults'
complete -c cf -f -n '__fish_use_subcommand' -l refresh -s r -d 'Skip cache and re-search'
complete -c cf -f -n '__fish_seen_subcommand_from --config' -a restore
complete -c cf -f -n '__fish_seen_subcommand_from restore' -a 'settings targets aliases cache'