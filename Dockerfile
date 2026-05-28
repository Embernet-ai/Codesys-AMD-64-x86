# =============================================================================
# CODESYS Control SL Runtime — prebuilt container image (AMD64)
# =============================================================================
# Bakes the codesyscontrol .deb + a codemeter-lite equivs shim into a
# debian:bookworm-slim base. Designed to replace the install-at-pod-start
# pattern in charts/codesys-pod/templates/deployment.yaml so pod starts
# go from ~90s (download + unzip + dpkg + deps) down to ~3s (pull cached
# image + exec).
#
# Build arg CODESYS_PACKAGE_URL points at a public .package release on
# github.com/Embernet-ai/codesys-linux-x86; the GH Actions workflow at
# .github/workflows/build-image.yml pins the URL per release tag.
# =============================================================================
ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE} AS build

ARG CODESYS_PACKAGE_URL=https://github.com/Embernet-ai/codesys-linux-x86/releases/download/v4.20.0.0/CODESYS.Control.for.Linux.SL.4.20.0.0.package
ARG CODESYS_VERSION=4.20.0.0

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Build-time deps: equivs (for the codemeter-lite shim), unzip (to crack
# the .package ZIP), ca-certs/curl (to fetch it).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip equivs file \
    && rm -rf /var/lib/apt/lists/*

# ---- codemeter-lite shim ---------------------------------------------------
# The codesyscontrol .deb declares: Depends: codemeter | codemeter-lite
# Neither is in Debian repos. Without a shim, `apt-get install -f` resolves
# the dep by REMOVING the half-installed codesyscontrol — silently. Demo
# mode does not require the real CodeMeter daemon, so an empty equivs
# package is the cleanest fix (this matches the chart's runtime install
# path so behavior is identical whether you use the prebuilt image or the
# installer-pattern chart).
WORKDIR /tmp/shim
RUN cat > codemeter-lite.ctrl <<'CTRL' \
 && equivs-build codemeter-lite.ctrl \
 && mv codemeter-lite_*_all.deb /tmp/codemeter-lite-shim.deb
Package: codemeter-lite
Version: 99.0-codesys-pod-shim
Section: misc
Priority: optional
Architecture: all
Maintainer: codesys-pod chart <support@embernet.ai>
Description: Empty shim that satisfies codesyscontrol's codemeter-lite dep.
 Demo mode does not require the CodeMeter daemon; this package only
 exists so dpkg's dependency check passes without apt-get pulling
 the half-installed codesyscontrol back out.
CTRL

# ---- fetch + crack the CODESYS .package -----------------------------------
WORKDIR /tmp/cds
RUN curl -fSL --retry 3 -o codesys.package "${CODESYS_PACKAGE_URL}" \
 && [ "$(stat -c%s codesys.package)" -ge 1048576 ] \
 && unzip -q codesys.package -d extracted \
 && CDS_DEB=$(find extracted/Delivery -name 'codesyscontrol_*amd64.deb' -print -quit) \
 && [ -n "${CDS_DEB}" ] \
 && cp "${CDS_DEB}" /tmp/codesyscontrol.deb \
 && rm -rf /tmp/cds

# ---- install shim then codesyscontrol -------------------------------------
# Order matters: shim first so the dep check passes, then real deb so its
# postinst runs (which is what registers CmpRetain in
# /etc/codesyscontrol/CODESYSControl_User.cfg). Hard assertion after install
# — if the binary isn't on disk, the build fails loud rather than producing
# a "looks fine" image with no runtime.
RUN dpkg -i /tmp/codemeter-lite-shim.deb \
 && dpkg -i /tmp/codesyscontrol.deb \
 && test -x /opt/codesys/bin/codesyscontrol.bin \
 && test -f /etc/codesyscontrol/CODESYSControl.cfg \
 && test -f /etc/codesyscontrol/CODESYSControl_User.cfg \
 && grep -q '^Component\..*=CmpRetain' /etc/codesyscontrol/CODESYSControl_User.cfg \
 && rm -f /tmp/codemeter-lite-shim.deb /tmp/codesyscontrol.deb \
 && rm -rf /var/lib/apt/lists/*

# ---- runtime stage --------------------------------------------------------
# Copy from build so we don't ship equivs/curl/unzip. Runtime deps only.
FROM ${BASE_IMAGE}

ARG CODESYS_VERSION=4.20.0.0
LABEL org.opencontainers.image.title="CODESYS Control SL (AMD64)"
LABEL org.opencontainers.image.description="Prebuilt CODESYS Control for Linux SL runtime — IEC 61131-3 SoftPLC"
LABEL org.opencontainers.image.source="https://github.com/Embernet-ai/Codesys-AMD-64-x86"
LABEL org.opencontainers.image.version="${CODESYS_VERSION}"
LABEL org.opencontainers.image.licenses="Proprietary-CODESYS"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcap2-bin iptables net-tools iproute2 procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/codesys /opt/codesys
COPY --from=build /etc/codesyscontrol /etc/codesyscontrol
COPY --from=build /etc/init.d/codesyscontrol /etc/init.d/codesyscontrol
COPY --from=build /etc/default/codesyscontrol /etc/default/codesyscontrol
COPY --from=build /var/opt/codesys /var/opt/codesys
COPY --from=build /var/opt/codesyscontrolapi /var/opt/codesyscontrolapi
COPY --from=build /var/lib/dpkg/info/codesyscontrol.list /var/lib/dpkg/info/codesyscontrol.list
COPY --from=build /var/lib/dpkg/info/codemeter-lite.list /var/lib/dpkg/info/codemeter-lite.list

# Ports the runtime listens on (informational; podman/k8s does the real
# binding via hostPort/service):
#   11740/tcp  CODESYS direct comms (IDE download/debug + UDP broadcast discovery)
#   4840/tcp   OPC-UA server
#   1217/tcp   Gateway (only present if a Gateway sidecar is added)
EXPOSE 11740/tcp 4840/tcp

WORKDIR /var/opt/codesys
# Invocation taken verbatim from /etc/init.d/codesyscontrol:65 of the .deb.
ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin", "/etc/codesyscontrol/CODESYSControl.cfg"]
