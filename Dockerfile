FROM rust:1.34.0

RUN rustup target add x86_64-apple-darwin              \
 && rustup target add x86_64-pc-windows-gnu            \
 && rustup target add x86_64-unknown-linux-gnu

FROM buildpack-deps:stretch-curl

# Install deps
RUN set -x; \
    dpkg --add-architecture arm64                      \
 && dpkg --add-architecture armel                      \
 && dpkg --add-architecture armhf                      \
 && dpkg --add-architecture i386                       \
 && dpkg --add-architecture mips                       \
 && dpkg --add-architecture mipsel                     \
 && dpkg --add-architecture powerpc                    \
 && dpkg --add-architecture ppc64el                    \
 && apt-get update                                     \
 && apt-get install -y -q                              \
        autoconf                                       \
        automake                                       \
        autotools-dev                                  \
        bc                                             \
        binfmt-support                                 \
        binutils-multiarch                             \
        binutils-multiarch-dev                         \
        build-essential                                \
        clang                                          \
        crossbuild-essential-arm64                     \
        crossbuild-essential-armel                     \
        crossbuild-essential-armhf                     \
        crossbuild-essential-mipsel                    \
        crossbuild-essential-ppc64el                   \
        curl                                           \
        devscripts                                     \
        gdb                                            \
        git-core                                       \
        libtool                                        \
        llvm                                           \
        patch                                          \
        wget                                           \
        xz-utils                                       \
        cmake                                          \
        qemu-user-static                               \
        mingw-w64                                      \
        libc6:i386                                     \
        libstdc++6:i386                                \
        lib32gcc1                                      \
&& apt-get clean

# Install OSx cross-tools

# Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="6525b2b7d33abc371ad889f205377dc5cf81f23e"
ARG darwin_sdk_version="10.10"
ARG darwin_osx_version_min="10.6"
ARG darwin_version="14"
ARG darwin_sdk_url="https://www.dropbox.com/s/yfbesd249w10lpc/MacOSX${darwin_sdk_version}.sdk.tar.xz"
ARG macosx_deployment_target="10.7"

# ENV available in docker image
ENV OSXCROSS_REPO="${osxcross_repo}"                   \
    OSXCROSS_REVISION="${osxcross_revision}"           \
    DARWIN_SDK_VERSION="${darwin_sdk_version}"         \
    DARWIN_VERSION="${darwin_version}"                 \
    DARWIN_OSX_VERSION_MIN="${darwin_osx_version_min}" \
    DARWIN_SDK_URL="${darwin_sdk_url}"                 \
    MACOSX_DEPLOYMENT_TARGET="${macosx_deployment_target}"

RUN mkdir -p "/tmp/osxcross"                                                                                   \
 && cd "/tmp/osxcross"                                                                                         \
 && curl -sLo osxcross.tar.gz "https://codeload.github.com/${OSXCROSS_REPO}/tar.gz/${OSXCROSS_REVISION}"       \
 && tar --strip=1 -xzf osxcross.tar.gz                                                                         \
 && rm -f osxcross.tar.gz                                                                                      \
 && curl -sLo tarballs/MacOSX${DARWIN_SDK_VERSION}.sdk.tar.xz "${DARWIN_SDK_URL}"                              \
 && SDK_VERSION="${DARWIN_SDK_VERSION}" OSX_VERSION_MIN="${DARWIN_OSX_VERSION_MIN}" UNATTENDED=1 ./build.sh    \
 && mv target /usr/osxcross                                                                                    \
 && mv tools /usr/osxcross/                                                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/omp                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-macports                                      \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-mp                                            \
 && rm -rf /tmp/osxcross                                                                                       \
 && rm -rf "/usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

# Copy rust
COPY --from=0 /usr/local/rustup /usr/local/rustup
COPY --from=0 /usr/local/cargo /usr/local/cargo

# Copy cargo config
COPY cargo_config /usr/local/cargo/config

# These tell the CC crate the correct cc and ar to use when cross compiling
ENV CC_x86_64_apple_darwin=x86_64-apple-darwin14-clang  \
    AR_x86_64_apple_darwin=x86_64-apple-darwin14-ar     \
    CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc     \
    AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc-ar  \
    CXX_x86_64_apple_darwin=x86_64-apple-darwin14-clang \
    CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc    \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/osxcross/bin:/usr/local/cargo/bin:$PATH

RUN rustup --version; \
    cargo --version; \
    rustc --version;

WORKDIR /root/
