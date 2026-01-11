# Multi-architecture Dockerfile for CODESYS Control for Linux (x86)
# Supports: linux/amd64, linux/386

FROM debian:bullseye-slim

# Build arguments for architecture-specific installer selection
ARG TARGETARCH
ARG CODESYS_VERSION=3.5.19.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    CODESYS_HOME=/opt/codesys \
    CODESYS_PROJECTS=/var/opt/codesys/projects \
    CODESYS_LICENSE=/var/opt/codesys/license

# Install required dependencies
RUN apt-get update && \
    apt-get install -y \
    wget \
    ca-certificates \
    libssl1.1 \
    libcap2-bin \
    libatomic1 \
    libc6 \
    procps \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p ${CODESYS_HOME} \
    ${CODESYS_PROJECTS} \
    ${CODESYS_LICENSE} \
    /var/opt/codesys/PlcLogic

# Copy installer download script (if included)
# The installer should be downloaded from GitHub releases
# Architecture mapping: amd64 -> x64, 386 -> x86
COPY scripts/download-installer.sh /tmp/
RUN chmod +x /tmp/download-installer.sh

# Download and install CODESYS runtime based on architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        INSTALLER_ARCH="x64"; \
    elif [ "$TARGETARCH" = "386" ]; then \
        INSTALLER_ARCH="x86"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; \
        exit 1; \
    fi && \
    # Download installer from GitHub releases
    # Format: codesyscontrol-linux-${INSTALLER_ARCH}-${CODESYS_VERSION}.tar.gz
    INSTALLER_URL="https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v${CODESYS_VERSION}/codesyscontrol-linux-${INSTALLER_ARCH}-${CODESYS_VERSION}.tar.gz" && \
    wget -O /tmp/codesys-installer.tar.gz "${INSTALLER_URL}" && \
    tar -xzf /tmp/codesys-installer.tar.gz -C /tmp/ && \
    # Install CODESYS runtime
    cd /tmp && \
    chmod +x ./install.sh && \
    ./install.sh --accept-license --install-dir=${CODESYS_HOME} --skip-service && \
    # Cleanup
    rm -rf /tmp/*

# Set capabilities for real-time scheduling (required for PLC runtime)
RUN setcap cap_sys_nice,cap_net_raw,cap_net_admin,cap_sys_time+ep ${CODESYS_HOME}/bin/codesyscontrol

# Create codesys user for running the runtime
RUN groupadd -r codesys && \
    useradd -r -g codesys -d ${CODESYS_HOME} -s /bin/bash codesys && \
    chown -R codesys:codesys ${CODESYS_HOME} ${CODESYS_PROJECTS} ${CODESYS_LICENSE} /var/opt/codesys

# Copy configuration files
COPY kubernetes/configmap.yaml /tmp/
# Default configuration will be mounted via ConfigMap

# Expose ports
# 11740 - CODESYS PLC communication
# 2455 - Web visualization
# 1217 - OPC UA (optional)
# 4840 - OPC UA Secure (optional)
EXPOSE 11740 2455 1217 4840

# Set working directory
WORKDIR ${CODESYS_HOME}

# Switch to codesys user
USER codesys

# Volume for persistent data
VOLUME ["${CODESYS_PROJECTS}", "${CODESYS_LICENSE}"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pidof codesyscontrol || exit 1

# Start CODESYS Control runtime
CMD ["${CODESYS_HOME}/bin/codesyscontrol", "--run-as-service"]
