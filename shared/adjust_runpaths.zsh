function adjust_runpaths
{
    #
    # Try to ensure ELF files have /usr/local/lib in the RUNPATH.
    # Also clean out any /tmp entries.
    #

    local dir="${1}"
    local f

    echo "Adding /usr/local/lib to RUNPATHs and then shrinking them."
    for f in `find ${dir} -xtype f`; do
        if [[ -x "${f}" ]]; then
            patchelf --add-rpath /usr/local/lib "${f}" 2> /dev/null
            patchelf --shrink-rpath \
                     --allowed-rpath-prefixes /usr/local:/nix/store \
                     "${f}" 2> /dev/null
        fi
    done

    exit 0
}
