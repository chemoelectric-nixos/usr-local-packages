function git_check_out
{
    local repo="${1}"
    local revision="${2}"

    if [[ "${revision}" = "«live»" ]]; then
        echo "Checking out ${1} live."

        (cd "${repo}" &&
             git fetch &&
             git checkout -q || exit 1) || exit 1
    else
        echo "Checking out ${1} revision ${revision}"

        (cd "${repo}" &&
             git fetch &&
             git checkout -q "${revision}" || exit 1) || exit 1
    fi
}
