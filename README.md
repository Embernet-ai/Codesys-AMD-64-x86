# CODESYS Control SL Helm Chart

Run the CODESYS Control SL Runtime on Kubernetes (K3s, Rancher) using the **Installer Download Pattern**.

![CODESYS Logo](https://www.helpme-codesys.com//icons/CODESYS-logo.svg)

## Overview

This chart deploys a standard Debian container that:
1.  **Downloads** the official CODESYS Control SL package (Zip) from GitHub Releases during initialization.
2.  **Installs** the `.deb` files automatically on first boot.
3.  **Persists** logic and configuration to a PVC (`/var/opt/codesys`).

## Installation

### Add Repository
```bash
helm repo add codesys-control-sl https://embernet-ai.github.io/Codesys-AMD-64-x86
helm repo update
```

### Install Chart
```bash
helm install my-codesys codesys-control-sl/codesys-control-sl --set persistence.enabled=true
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installerUrl` | URL to the .package ZIP file | (See values.yaml) |
| `persistence.enabled` | Enable data persistence | `true` |
| `persistence.size` | Size of the PVC | `5Gi` |
| `securityContext.privileged` | Run in privileged mode (Required for PLC hardware access) | `true` |
| `service.gatewayPort` | CODESYS Gateway Port | `1217` |
| `service.webVisuPort` | Web Visualization Port | `8080` |
| `image.tag` | Base Debian image tag | `bullseye` |

## Architecture

- **InitContainer**: Uses `curlimages/curl` to fetch the installer.
- **Main Container**: `debian:bullseye`. Installs runtime dependencies (`libcap2-bin`, `iptables`, etc.) and the CODESYS `.deb` packages.

## License

This Helm Chart is open source. The CODESYS Runtime provided by the installer is subject to the CODESYS End User License Agreement (EULA).
