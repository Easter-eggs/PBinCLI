#!/bin/bash
# vim: shiftwidth=4 tabstop=4 expandtab

INSTALL_BUILD_DEPS=0
INSTALL_BUILD_DEPS_ONLY=0
PURGE_SOURCE_DIRECTORY=0
BUILD_WHEEL=0
PACKAGE_NAME=ee-paste-cli
BUILD_DEPS=(
  git sed python3-all python3-dev python3-pip dpkg-dev build-essential
  debhelper dh-python lsb-release wget bash-completion python3-argcomplete
)
PYTHON_BUILD_DEPS=( stdeb wheel GitPython )

function usage() {
    [[ $# -gt 0 ]] && echo -e "$@\n" > /dev/stderr
    cat << EOF
Usage: $0 [-h|I|-O|-P|-x]
    -h|--help                       Show this message
    -I|--install-build-deps         Install build dependencies before building package
    -O|--install-build-deps-only    Only install build dependencies
    -W|--build-wheel                Enable wheel package building
    -P|--purge-sources-directory    Purge debian package sources directory after building package
    -x|--trace                      Enable bash tracing (set -x)
EOF
    [[ -n "$@" ]] && exit 1
}

idx=1
while [[ $idx -le $# ]]; do
    OPT=${!idx}
    case $OPT in
        -h|--help)
            usage
            ;;
        -I|--install-build-deps)
            INSTALL_BUILD_DEPS=1
            ;;
        -O|--install-build-deps-only)
            INSTALL_BUILD_DEPS=1
            INSTALL_BUILD_DEPS_ONLY=1
            ;;
        -P|--purge-sources-directory)
            PURGE_SOURCE_DIRECTORY=1
            ;;
        -W|--build-wheel)
            BUILD_WHEEL=1
            ;;
        -x|--trace)
            set -x
            ;;
        *)
            usage "Unknown parameter '$OPT'"
    esac
    let idx=idx+1
done

# Enter source directory
cd $( dirname $0 )

# Install build dependencies
if [[ $INSTALL_BUILD_DEPS -eq 1 ]]; then
    MISSING_PACKAGES=()
    for package in "${BUILD_DEPS[@]}"; do
      dpkg-query -s "$package" > /dev/null 2>&1 || MISSING_PACKAGES+=( "$package" )
    done
    if [[ "${#MISSING_PACKAGES[@]}" -gt 0 ]]; then
        apt-get update
        apt-get install --no-install-recommends --yes "${MISSING_PACKAGES[@]}"
    fi
    python3 -m pip install --break-system-packages "${PYTHON_BUILD_DEPS[@]}"
fi

# Compute EE debian codename
DEBIAN_RELEASE=$( lsb_release -r -s|sed 's/\..*$//' )
DEBIAN_CODENAME=$( lsb_release -c -s )
[[ $DEBIAN_RELEASE -ge 9 ]] && DEBIAN_CODENAME="${DEBIAN_CODENAME}-ee"

# Check gitdch is installed
GITDCH=$(which gitdch)
set -e
if [[ -z "$GITDCH" ]]; then
    TMP_GITDCH=$(mktemp -d)
    echo "Temporary install gitdch in $TMP_GITDCH"
    wget -O $TMP_GITDCH/gitdch https://gitea.zionetrix.net/bn8/gitdch/raw/master/gitdch
    chmod +x $TMP_GITDCH/gitdch
    GITDCH=$TMP_GITDCH/gitdch
else
    TMP_GITDCH=""
fi

# Install GPG key (if provided)
if [[ -n "$GPG_KEY" ]]; then
    [[ $INSTALL_BUILD_DEPS -eq 1 ]] && apt-get install --no-install-recommends --yes gnupg2
    [[ $INSTALL_BUILD_DEPS_ONLY -eq 0 ]] && base64 -d <<< "$GPG_KEY" | gpg --import
fi

# Stop here on install build deps only mode
[[ $INSTALL_BUILD_DEPS_ONLY -eq 1 ]] && exit 0

# Detect maintainer info from environment or eepastecli/__init__.py file
if [[ -n "$DEBFULLNAME" ]]; then
    MAINTAINER_NAME="$DEBFULLNAME"
else
    MAINTAINER_NAME="$(
        grep __author__ < eepastecli/__init__.py | cut -d '"' -f 2 | sed 's/^\(.*\) <.*$/\1/'
    )"
    if [[ $? -ne 0 ]] || [[ -z "$MAINTAINER_NAME" ]]; then
        echo "Fail to detect maintainer name from eepastecli/__init__.py file."
        exit 1
    fi
fi

if [[ -n "$DEBEMAIL" ]]; then
    MAINTAINER_EMAIL="$DEBEMAIL"
else
    MAINTAINER_EMAIL="$(
        grep __author__ < eepastecli/__init__.py | cut -d '"' -f 2 | sed 's/^.*<\(.*\)>.*$/\1/'
    )"
    if [[ $? -ne 0 ]] || [[ -z "$MAINTAINER_EMAIL" ]]; then
        echo "Fail to detect maintainer email eepastecli/__init__.py file."
        exit 1
    fi
fi

# Clean previous build
rm -fr build *.egg-info *.tar.gz dist

# Compute version using git describe
# Note : If no tag exist, git describe will fail: in this case, compute a 0.0 version with same
# format as git describe
VERSION="$( git describe --tags 2> /dev/null )" || \
    VERSION="0.0-$( git log --oneline|wc -l )-$( git describe --tags --always )"

# Fix version format to match with Python specs
# See: https://peps.python.org/pep-0440/
VERSION=$( sed 's/[^0-9]*\([0-9][^-]*\)-\(.*\)/\1+\2/' <<< "$VERSION" )

# Build python whl package using setup.py bdist_wheel command
[[ $BUILD_WHEEL -eq 1 ]] && python3 setup.py bdist_wheel --dist-dir dist

# Compute debian package version by adding EE debian version suffix
DEB_VERSION_SUFFIX="-1~ee${DEBIAN_RELEASE}0"
DEB_VERSION="${VERSION}${DEB_VERSION_SUFFIX}"

# Build debian source package
python3 setup.py --command-packages=stdeb.command sdist_dsc \
    --maintainer "$MAINTAINER_NAME <$MAINTAINER_EMAIL>" \
    --compat 10 \
    --section net \
    --dist-dir dist \
    --source "$PACKAGE_NAME" \
    --package3 "$PACKAGE_NAME" \
    --forced-upstream-version "$VERSION"

# Keep only debian package directory and orig.tar.gz archive
find dist/ -maxdepth 1 -type f ! -name '*.orig.tar.gz' ! -name '*.whl' -delete

DIST_DIR=dist/$PACKAGE_NAME-$VERSION

# Compute gitdch extra args
GITDCH_EXTRA_ARGS=()
[[ -n "$DEBFULLNAME" ]] && GITDCH_EXTRA_ARGS+=( "--maintainer-name" "$DEBFULLNAME" )
[[ -n "$DEBEMAIL" ]] && GITDCH_EXTRA_ARGS+=( "--maintainer-email" "$DEBEMAIL" )

# Generate debian changelog using generate_debian_changelog.py
python3 $GITDCH \
    --package-name $PACKAGE_NAME \
    --version="${DEB_VERSION}" \
    --version-suffix="${DEB_VERSION_SUFFIX}" \
    --code-name $DEBIAN_CODENAME \
    --output $DIST_DIR/debian/changelog \
    --release-notes dist/release-notes.md \
    --exclude "^CI: " \
    --exclude "\.gitlab-ci\.yml" \
    --exclude "build\.sh" \
    --exclude "build_deb\.sh" \
    --exclude "tests\.sh" \
    --exclude "README\.md" \
    --exclude "^Merge branch " \
    --verbose "${GITDCH_EXTRA_ARGS[@]}"

#
# Generate bash completion file
#

# Enable debhelper bash-completion in debian/rules
sed -i 's/\(dh \$@.*\)/\1 --with bash-completion/' $DIST_DIR/debian/rules
# Locate register-python-argcomplete command (name changed between Bullseye & Bookworm)
REGISTER_PYTHON_ARGCOMPLETE=$(
    command -v register-python-argcomplete3 register-python-argcomplete
)
# Generate bash-completion file
$REGISTER_PYTHON_ARGCOMPLETE -s bash ee-paste > $DIST_DIR/debian/${PACKAGE_NAME}.bash-completion

# Add custom python3 dependencies Debian package names
cat << EOF > $DIST_DIR/debian/py3dist-overrides
pycryptodome python3-pycryptodome
sjcl python3-sjcl
setuptools python3-setuptools
EOF

# Clean temporary gitdch installation
[[ -n "$TMP_GITDCH" ]] && rm -fr $TMP_GITDCH

# Build debian package
BUILD_ARGS="-b"
if [[ -z "$GPG_KEY" ]]; then
    BUILD_ARGS="--no-sign"
else
    echo "GPG key provide, enable package signing."
fi
cd $DIST_DIR
dpkg-buildpackage $BUILD_ARGS

# Handle PURGE_SOURCE_DIRECTORY option
if [[ $? -eq 0 ]] && [[ $PURGE_SOURCE_DIRECTORY -eq 1 ]]; then
    rm -fr "../../$DIST_DIR"
fi
