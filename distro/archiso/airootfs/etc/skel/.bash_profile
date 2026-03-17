if [ -z "${DISPLAY:-}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
    if [ -x /usr/local/bin/abora-live-extensions ]; then
        /usr/local/bin/abora-live-extensions
    fi
    exec startplasma-wayland
fi
