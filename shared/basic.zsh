source shared/make_package.zsh

if [[ x${name} = x ]]; then
    echo "You must define ‘name’"
    exit 3
fi

_package_version="${package_version:-${1}}"
_targeted_host="${targeted_host:-${2}}"
if [[ "${ban_check}" = yes ]]; then
    _check=no
else
    _check="${3}"
fi

_build_name="${build_name:-«build»}"
_dest_name="${dest_name:-«dest»}"

bail_out=( exit 1 )
if [[ x${check_arguments} = x ]]; then
    check_arguments=( check )
fi

abs_src_tarball_dir=`realpath "${PWD}/src_tarballs"`
abs_bin_tarball_dir=`realpath "${PWD}/bin_tarballs"`
abs_srcdirs_dir=`realpath "${PWD}/srcdirs"`

if [[ "${ban_parallel_make}" = "yes" ]]; then
    jobs=1
    check_jobs=1
else
    jobs="${jobs:-24}"
    check_jobs="${check_jobs:-"${jobs}"}"
fi

silent_rules="${silent_rules:-yes}"

packname="${name}-${_package_version}"
if [[ -e "${abs_src_tarball_dir}/${packname}.tar.xz" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.xz"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.gz" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.gz"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.bz2" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.bz2"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tar.zst" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tar.zst"
elif [[ -e "${abs_src_tarball_dir}/${packname}.tgz" ]]; then
    src_tarball="${abs_src_tarball_dir}/${packname}.tgz"
else
    echo "What is the source tarball?"
    exit 4
fi
bin_tarball="${abs_bin_tarball_dir}/${packname}-binary-for-${_targeted_host}.tar.zst"
abs_srcdir="${abs_srcdirs_dir}/${packname}"
abs_builddir="${abs_srcdir}/${_build_name}"
if [[ "${ban_out_of_source_build}" = yes ]]; then
    abs_builddir="${abs_srcdir}"
fi
abs_destdir="${abs_srcdir}/${_dest_name}"

mkdir -p "${abs_srcdirs_dir}"
rm -R -f "${abs_srcdirs_dir}/${packname}" || ${bail_out}
tar -f "${src_tarball}" -C "${abs_srcdirs_dir}" -x || ${bail_out}
mkdir -p "${abs_builddir}" || ${bail_out}
if [[ `whence -w patch_function` = 'patch_function: function' ]]; then
    (
        cd "${abs_srcdir}" || ${bail_out}
        patch_function || ${bail_out}
    ) || ${bail_out}
fi
(
    cd "${abs_builddir}" || ${bail_out}
    default_configure_arguments=( )
    if [[ "${ban_prefix}" != yes ]]; then
        default_configure_arguments+=( --prefix=/usr/local )
    fi
    if [[ "${ban_enable_silent_rules}" != yes ]]; then
        default_configure_arguments+=(
            --enable-silent-rules="${silent_rules}"
        )
    fi
    if [[ "${ban_configure}" != yes ]]; then
        env TARGETED_HOST="${_targeted_host}" \
            "${(@)environment_variables}" \
            "${abs_srcdir}"/configure \
            "${(@)default_configure_arguments}" \
            "${(@)configure_arguments}" || ${bail_out}
    fi
    make -j"${jobs}" "${(@)make_arguments}" || ${bail_out}
    if [[ "${_check}" != "no" ]] && [[ "${_check}" != "false" ]]; then
       make -j"${check_jobs}" "${(@)check_arguments}" || ${bail_out}
    fi
    make install DESTDIR="${abs_destdir}" "${(@)install_arguments}" \
        || ${bail_out}

) || ${bail_out}

make_package "${bin_tarball}" "${abs_destdir}" || ${bail_out}
