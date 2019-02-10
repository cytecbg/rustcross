FROM rust:latest

RUN rustup target add x86_64-apple-darwin \
 && rustup target add x86_64-pc-windows-gnu

FROM multiarch/crossbuild

WORKDIR /root/

# Copy rust
COPY --from=0 /usr/local/rustup /usr/local/rustup
COPY --from=0 /usr/local/cargo /usr/local/cargo

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# Copy cargo config
COPY cargo_config /usr/local/cargo/config

RUN rustup --version; \
    cargo --version; \
    rustc --version;

ENV MACOSX_DEPLOYMENT_TARGET="10.7"

# These tell the CC crate the correct cc and ar to use when cross compiling
ENV PATH=/usr/osxcross/bin:$PATH
ENV CC_x86_64_apple_darwin=x86_64-apple-darwin14-clang
ENV AR_x86_64_apple_darwin=x86_64-apple-darwin14-ar
ENV CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc
ENV AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc-ar

CMD /bin/bash
