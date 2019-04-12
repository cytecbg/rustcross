# rustcross
Docker image containing all the necessary tools for cross compiling rust code inside a single container.  

This image copies [rust/latest](https://hub.docker.com/_/rust) on top of a modified version of [multiarch/crossbuild](https://hub.docker.com/r/multiarch/crossbuild) and enables `x86_64-apple-darwin` and `x86_64-pc-windows-gnu` targets.
