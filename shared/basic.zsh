if [[ x${name} = x ]]; then
    echo "You must define ‘name’"
    exit 3
fi

local abs_src_tarball_dir=`realpath "${PWD}/src_tarballs"`
local abs_bin_tarball_dir=`realpath "${PWD}/bin_tarballs"`
local abs_srcdirs_dir=`realpath "${PWD}/srcdirs"`

local targeted_host="${2}"
local jobs="${JOBS:-24}"
local silence="${SILENT_RULES:-yes}"
local check="${3}"
local tar=tar
local version="${1}"
local packname="${name}-${version}"
local src_tarball="${abs_src_tarball_dir}/${packname}.tar.xz"
local bin_tarball="${abs_bin_tarball_dir}/${packname}-binary-for-${targeted_host}.tar.xz"
local abs_srcdir="${abs_srcdirs_dir}/${packname}"
local abs_builddir="${abs_srcdir}/«build»"
local abs_destdir="${abs_srcdir}/«dest»"
local bail_out="exit 1"

rm -R -f "${packname}" || ${bail_out}
mkdir -p "${abs_srcdirs_dir}"
${tar} -f "${src_tarball}" -C "${abs_srcdirs_dir}" -x || ${bail_out}
mkdir -p "${abs_builddir}" || ${bail_out}
(
    cd "${abs_builddir}" || ${bail_out}
    env TARGETED_HOST="${targeted_host}" \
	"${(@)environment_variables}" \
	"${abs_srcdir}"/configure \
	--prefix=/usr/local \
	--enable-silent-rules="${silence}" \
	"${(@)configure_arguments}" || ${bail_out}
    make -j"${jobs}" || ${bail_out}
    if [[ "${check}" != "no" ]] && [[ "${check}" != "false" ]]; then
       make -j"${jobs}" check || ${bail_out}
    fi
    make install DESTDIR="${abs_destdir}" || ${bail_out}
) || ${bail_out}
mkdir -p "${abs_bin_tarball_dir}" || ${bail_out}
${tar} --format=posix -cvaf "${bin_tarball}" -C "${abs_destdir}" usr \
       || ${bail_out}
exit 0
