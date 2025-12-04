source shared/helpers.zsh
source shared/make_package.zsh

if [[ x${name} = x ]]; then
    echo "You must define ‘name’"
    exit 3
fi

_package_version="${package_version:-${1?}}"
_targeted_host="${targeted_host:-${2?}}"
if is_yes "${ban_check}"; then
    _check=no
else
    _check="${check:-${3?}}"
fi

_build_name="${build_name:-___build___}"
_dest_name="${dest_name:-___dest___}"

bail_out=( exit 1 )
if [[ x${check_arguments} = x ]]; then
    check_arguments=( check )
fi

abs_src_tarball_dir=`realpath "${PWD}/src_tarballs"`
abs_bin_tarball_dir=`realpath "${PWD}/bin_tarballs"`
abs_srcdirs_dir=`realpath "${PWD}/srcdirs"`

if is_yes "${ban_parallel_make}"; then
    jobs=1
    check_jobs=1
else
    jobs="${jobs:-24}"
    check_jobs="${check_jobs:-"${jobs:?}"}"
fi

silent_rules="${silent_rules:-yes}"

packname="${name}-${_package_version}"
src_tarball=`find_src_tarball "${abs_src_tarball_dir}/${packname}"` || ${bail_out}
bin_tarball="${abs_bin_tarball_dir}/${packname}-binary-for-${_targeted_host}.tar.zst"
abs_srcdir="${abs_srcdirs_dir}/${packname}"
abs_builddir="${abs_srcdir}/${_build_name}"
if is_yes "${ban_out_of_source_build}"; then
    abs_builddir="${abs_srcdir}"
fi
abs_destdir="${abs_srcdir}/${_dest_name}"

mkdir -p "${abs_srcdirs_dir}"
rm -R -f "${abs_srcdir}" || ${bail_out}
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
    if is_no "${ban_prefix}"; then
        default_configure_arguments+=( --prefix=/usr/local )
    fi
    if is_no "${ban_enable_silent_rules}"; then
        default_configure_arguments+=(
            --enable-silent-rules="${silent_rules}"
        )
    fi
    if is_no "${ban_configure}"; then
        env TARGETED_HOST="${_targeted_host}" \
            "${(@)environment_variables}" \
            "${abs_srcdir}"/configure \
            "${(@)default_configure_arguments}" \
            "${(@)configure_arguments}" || ${bail_out}
    fi
    make -j"${jobs}" "${(@)make_arguments}" || ${bail_out}
    if is_yes "${_check}"; then
       make -j"${check_jobs}" "${(@)check_arguments}" || ${bail_out}
    fi
    make install DESTDIR="${abs_destdir}" "${(@)install_arguments}" \
        || ${bail_out}

) || ${bail_out}

if is_no "${ban_make_package}"; then
    make_package "${bin_tarball}" "${abs_destdir}" || ${bail_out}
fi
