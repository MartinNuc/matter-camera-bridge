# Stage 1: Build connectedhomeip SDK (cached layer)
FROM ubuntu:24.04 AS sdk-builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    pkg-config \
    libssl-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libavahi-client-dev \
    ninja-build \
    python3-venv \
    python3-dev \
    python3-pip \
    unzip \
    libgirepository1.0-dev \
    libcairo2-dev \
    libreadline-dev \
    generate-ninja \
    cmake \
    curl \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var

# Clone and build connectedhomeip SDK (this layer will be cached)
RUN git clone --depth 1 --branch v1.5.0.0 https://github.com/project-chip/connectedhomeip.git

WORKDIR /var/connectedhomeip

RUN git submodule update --init --depth 1
RUN ./scripts/checkout_submodules.py --shallow --platform linux
RUN bash ./scripts/bootstrap.sh

# Pre-build the SDK base, camera-app, and lighting-app (this is the expensive part we want to cache)
RUN bash -c 'source ./scripts/activate.sh && \
    export NINJA_FLAGS="-j2" && \
    scripts/examples/gn_build_example.sh examples/camera-app/linux out/camera-app chip_config_network_layer_ble=false && \
    scripts/examples/gn_build_example.sh examples/lighting-app/linux out/lighting-app chip_config_network_layer_ble=false'

# Stage 2: Build our camera bridge app (changes frequently)
FROM sdk-builder AS app-builder

WORKDIR /var/connectedhomeip

# Copy our source code
COPY src/ /app/src/
COPY build.sh /app/build.sh

RUN chmod +x /app/build.sh
RUN /app/build.sh

# Stage 3: Runtime image (minimal)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    libssl3 \
    libdbus-1-3 \
    libglib2.0-0 \
    libavahi-client3 \
    libcairo2 \
    libgirepository-1.0-1 \
    bash \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libavcodec60 \
    libavformat60 \
    libavutil58 \
    libcurl4 \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install go2rtc and yt-dlp
RUN curl -L https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64 -o /usr/local/bin/go2rtc \
    && chmod +x /usr/local/bin/go2rtc

RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp

WORKDIR /app

# Copy compiled binaries from builder
COPY --from=app-builder /app/matter-camera-bridge /app/matter-camera-bridge
COPY --from=app-builder /app/matter-light /app/matter-light

# Copy runtime files
COPY go2rtc.yaml /app/go2rtc.yaml
COPY run.sh /run.sh
COPY check-ipv6.sh /app/check-ipv6.sh
COPY test-matter-connection.sh /app/test-matter-connection.sh

RUN chmod +x /run.sh /app/matter-camera-bridge /app/matter-light /app/check-ipv6.sh /app/test-matter-connection.sh

CMD ["/run.sh"]
