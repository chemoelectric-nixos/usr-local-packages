function is_no
{
    [[ x${1} = x ]] || [[ "${1}" = "no" ]] || [[ "${1}" = "false" ]]
}

function is_yes
{
    ! is_no "${1}"
}

function find_src_tarball
{
    local prefix="${1}"
    local src_tarball
    if [[ -n "${_src_tarball}" ]]; then
        src_tarball="${_src_tarball}"
    elif [[ -e "${prefix}.tar.xz" ]]; then
        src_tarball="${prefix}.tar.xz"
    elif [[ -e "${prefix}.tar.gz" ]]; then
        src_tarball="${prefix}.tar.gz"
    elif [[ -e "${prefix}.source.tar.gz" ]]; then
        src_tarball="${prefix}.source.tar.gz"
    elif [[ -e "${prefix}.tgz" ]]; then
        src_tarball="${prefix}.tgz"
    elif [[ -e "${prefix}-src.tgz" ]]; then
        src_tarball="${prefix}-src.tgz"
    elif [[ -e "${prefix}.tar.bz2" ]]; then
        src_tarball="${prefix}.tar.bz2"
    elif [[ -e "${prefix}.tar.zst" ]]; then
        src_tarball="${prefix}.tar.zst"
    elif [[ -e "${prefix}.tar.lz" ]]; then
        src_tarball="${prefix}.tar.lz"
    elif [[ -e "${prefix}.tar.lzma" ]]; then
        src_tarball="${prefix}.tar.lzma"
    elif [[ -e "${prefix}.tar.lzo" ]]; then
        src_tarball="${prefix}.tar.lzo"
    elif [[ -e "${prefix}.tar.lzop" ]]; then
        src_tarball="${prefix}.tar.lzop"
    elif [[ -e "${prefix}.tzo" ]]; then
        src_tarball="${prefix}.tzo"
    elif [[ -e "${prefix}.tar" ]]; then
        src_tarball="${prefix}.tar"
    else
        echo "What is the source tarball?" >&2
        exit 1
    fi
    echo "${src_tarball}"
}
