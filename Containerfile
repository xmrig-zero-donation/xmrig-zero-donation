FROM alpine:3.22 as xmrig-build

ARG XMRIG_VERSION=v6.24.0

RUN apk -U add \
    git \
    make \
    cmake \
    libstdc++ \
    gcc \
    g++ \
    automake \
    libtool \
    autoconf \
    linux-headers

ENV XMRIG_VERSION=${XMRIG_VERSION}
    
RUN git clone https://github.com/xmrig/xmrig && cd xmrig && git checkout $XMRIG_VERSION

WORKDIR /xmrig

RUN --mount=type=bind,source=./patches,target=/patches \
    find /patches -name '*.patch' -print0 | xargs -0 -n1 git apply --unidiff-zero

RUN <<EOF
    mkdir build
    cd scripts && ./build_deps.sh && cd ../build
    cmake .. -DXMRIG_DEPS=scripts/deps -DBUILD_STATIC=ON
    make -j$(nproc)
EOF

RUN chmod +x build/xmrig && build/xmrig --version

RUN mkdir -p /out && cp /xmrig/build/xmrig /out

FROM scratch
COPY --from=xmrig-build /out /