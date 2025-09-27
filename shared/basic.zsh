if [[ x${name} = x ]]; then
    echo "You must define ‘name’"
    exit 3
fi

abs_src_tarball_dir=`realpath "${PWD}/src_tarballs"`
abs_bin_tarball_dir=`realpath "${PWD}/bin_tarballs"`
abs_srcdirs_dir=`realpath "${PWD}/srcdirs"`

targeted_host="${2}"
jobs="${jobs:-24}"
check_jobs="${check_jobs:-"${jobs}"}"
silent_rules="${silent_rules:-yes}"
check="${3}"
tar=tar
version="${1}"
packname="${name}-${version}"
bin_tarball="${abs_bin_tarball_dir}/${packname}-binary-for-${targeted_host}.tar.xz"
abs_srcdir="${abs_srcdirs_dir}/${packname}"
abs_builddir="${abs_srcdir}/«build»"
abs_destdir="${abs_srcdir}/«dest»"
bail_out="exit 1"

if [[ -e "${abs_src_tarball_dir}/${packname}.tar.xz" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.xz"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.gz" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.gz"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.bz2" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.bz2"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.zst" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.zst"
else
    echo "What is the source tarball?"
    exit 4
fi

mkdir -p "${abs_srcdirs_dir}"
rm -R -f "${abs_srcdirs_dir}/${packname}" || ${bail_out}
${tar} -f "${src_tarball}" -C "${abs_srcdirs_dir}" -x || ${bail_out}
mkdir -p "${abs_builddir}" || ${bail_out}
(
    cd "${abs_builddir}" || ${bail_out}
    local -a default_configure_arguments
    if [[ "${ban_prefix}" != yes ]]; then
	default_configure_arguments=(
	    "${(@)default_configure_arguments}"
	    --prefix=/usr/local
	)
    fi
    if [[ "${ban_enable_silent_rules}" != yes ]]; then
	default_configure_arguments=(
	    "${(@)default_configure_arguments}"
	    --enable-silent-rules="${silent_rules}"
	)
    fi
    env TARGETED_HOST="${targeted_host}" \
	"${(@)environment_variables}" \
	"${abs_srcdir}"/configure \
	"${(@)default_configure_arguments}" \
	"${(@)configure_arguments}" || ${bail_out}
    make -j"${jobs}" || ${bail_out}
    if [[ "${check}" != "no" ]] && [[ "${check}" != "false" ]]; then
       make -j"${check_jobs}" check || ${bail_out}
    fi
    make install DESTDIR="${abs_destdir}" || ${bail_out}
)
[[ $? -ne 0 ]] && ${bail_out}
mkdir -p "${abs_bin_tarball_dir}" || ${bail_out}
${tar} --format=posix -cvaf "${bin_tarball}" -C "${abs_destdir}" usr \
       || ${bail_out}
exit 0
