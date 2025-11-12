FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Base build tools and dependencies
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl ca-certificates cmake make pkg-config\
    bsdutils util-linux bsdmainutils\
    python3 python3-pip python3-venv python3-serial\
    gnat gcc g++ flex bison autoconf automake libtool \
    libgmp-dev libmpfr-dev libmpc-dev \
    clang clang-format lldb lld \
    verilator yosys \
    ghdl ghdl-common ghdl-llvm\
    llvm-18 llvm-20 llvm-18-dev \
    gcc-powerpc64le-linux-gnu \
    vim iproute2 \
    plocate \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# LLVM + GHDL fixes (from fixingllvm.txt)
# ------------------------------------------------------------------------------
ENV LD_LIBRARY_PATH="/usr/lib/llvm-18/lib:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
RUN ln -s /usr/lib/x86_64-linux-gnu/libLLVM-18.so /usr/lib/x86_64-linux-gnu/libLLVM-18.so.18.1

# ------------------------------------------------------------------------------
# Environment setup
# ------------------------------------------------------------------------------
WORKDIR /workspace
ENV PATH="/workspace/.local/bin:${PATH}"

CMD ["/bin/bash"]

