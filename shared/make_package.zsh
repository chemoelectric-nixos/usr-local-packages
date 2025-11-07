source shared/adjust_runpaths.zsh

function make_blake3_hash
{
    printf 'blake3-' || exit 1
    b3sum --raw "${@}" | base64 | head --bytes=-1 || exit 1
}

function store_package_hash
{
    local hash=`make_blake3_hash "${1}" || exit 1` || exit 1
    setfattr -n 'user.hash' -v "${hash}" "${1}" || exit 1
}

function make_package
{
    local bin_tarball=`realpath "${1}" || exit 1` || exit 1
    local abs_destdir=`realpath "${2}" || exit 1` || exit 1

    if [[ "${3}" != "ban-adjust_runpaths" ]]; then
        adjust_runpaths "${abs_destdir}"/usr/local
    fi

    mkdir -p `dirname "${bin_tarball}"` || exit 1
    rm -f "${bin_tarball}" || exit 1
    tar --format=posix -cvaf "${bin_tarball}" -C "${abs_destdir}" usr || exit 1
    store_package_hash "${bin_tarball}" || exit 1
}
