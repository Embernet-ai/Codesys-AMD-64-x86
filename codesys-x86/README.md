# CODESYS Control for Linux - x86 Deployment

> **Production-ready containerized CODESYS PLC runtime for x86 architectures (amd64 and 386) on K3s/Kubernetes**

⚠️ **Note**: This deployment is **separate** from ARM architecture deployments. For ARM-based systems, refer to the ARM deployment documentation.

## 📋 Overview

This project provides a complete solution for deploying CODESYS Control for Linux runtime in a containerized K3s environment, supporting both 64-bit (amd64) and 32-bit (386) x86 architectures. It's designed for controls engineers who need to run PLC applications in modern cloud-native infrastructure.

### Features

- ✅ Multi-architecture Docker images (linux/amd64, linux/386)
- ✅ Production-ready Kubernetes manifests for K3s
- ✅ **Helm charts for simplified deployment**
- ✅ Automated CI/CD with GitHub Actions
- ✅ Persistent storage for PLC projects and configuration
- ✅ Health monitoring with liveness and readiness probes
- ✅ Configurable resource limits and requests
- ✅ Support for CODESYS licensing
- ✅ Web visualization and OPC UA support
- ✅ Comprehensive deployment scripts

### Architecture Support

| Architecture | Platform | Status |
|-------------|----------|--------|
| x86_64 (amd64) | 64-bit Intel/AMD | ✅ Fully Supported |
| x86 (i386) | 32-bit Intel/AMD | ✅ Fully Supported |

## 🚀 Quick Start

### Prerequisites

- K3s or Kubernetes cluster (v1.24+)
- kubectl configured to access your cluster
- Helm 3.x (for Helm deployment) or kubectl (for manual deployment)
- Docker with Buildx support (for building images)
- CODESYS Control for Linux installer files

### 1. Upload CODESYS Installers to GitHub Releases

First, obtain the CODESYS Control for Linux installers and upload them to your GitHub repository releases.

#### Installer Naming Convention

Installers **must** follow this naming convention:

```
codesyscontrol-linux-<arch>-<version>.tar.gz
```

Examples:
- `codesyscontrol-linux-x64-3.5.19.0.tar.gz` (for 64-bit)
- `codesyscontrol-linux-x86-3.5.19.0.tar.gz` (for 32-bit)

#### Steps to Upload

1. **Create a new release** in your GitHub repository
2. **Tag the release** with the CODESYS version (e.g., `v3.5.19.0`)
3. **Upload the installer files** following the naming convention above
4. Optionally, upload SHA256 checksum files (e.g., `codesyscontrol-linux-x64-3.5.19.0.tar.gz.sha256`)

Example using GitHub CLI:
```bash
# Create release
gh release create v3.5.19.0 \
  --title "CODESYS Control v3.5.19.0" \
  --notes "CODESYS Control for Linux installers"

# Upload installers
gh release upload v3.5.19.0 \
  codesyscontrol-linux-x64-3.5.19.0.tar.gz \
  codesyscontrol-linux-x86-3.5.19.0.tar.gz
```

### 2. Configure Your Environment

Update the following files with your organization/repository details:

**In `Dockerfile`** (line 47):
```dockerfile
INSTALLER_URL="https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v${CODESYS_VERSION}/..."
```

**In `scripts/download-installer.sh`** (lines 17-18):
```bash
GITHUB_ORG="${GITHUB_ORG:-YOUR_ORG}"
GITHUB_REPO="${GITHUB_REPO:-YOUR_REPO}"
```

**In `kubernetes/deployment.yaml`** (line 41):
```yaml
image: ghcr.io/YOUR_ORG/codesys-control-x86:latest
```

### 3. Build Multi-Architecture Docker Images

```bash
# Navigate to the project directory
cd codesys-x86

# Make scripts executable
chmod +x scripts/*.sh

# Build images (without pushing)
./scripts/build.sh false latest

# Build and push to GitHub Container Registry
./scripts/build.sh true latest
```

The build script will:
- Create a Docker Buildx builder for multi-arch builds
- Build images for both linux/amd64 and linux/386
- Tag images appropriately
- Push to GitHub Container Registry (if specified)

### 4. Deploy to K3s Cluster

#### Option A: Using Helm (Recommended)

```bash
# Deploy for amd64 architecture
./scripts/deploy-helm.sh amd64

# Or deploy for 32-bit x86
./scripts/deploy-helm.sh 386

# Deploy with custom values file
./scripts/deploy-helm.sh amd64 my-values.yaml
```

#### Option B: Using kubectl

```bash
# Deploy for amd64 architecture
./scripts/deploy.sh amd64

# Or deploy for 32-bit x86
./scripts/deploy.sh 386
```

The deployment will:
1. Create the `codesys-x86` namespace
2. Apply ConfigMaps for runtime configuration
3. Create PersistentVolumeClaims for storage
4. Deploy the CODESYS runtime
5. Expose services via NodePort
6. Display connection information

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -n codesys-x86

# View logs
kubectl logs -n codesys-x86 -l app=codesys-runtime -f

# Check services
kubectl get svc -n codesys-x86
```

## 📦 Project Structure

```
codesys-x86/
├── Dockerfile                      # Multi-arch Dockerfile
├── README.md                       # This file
├── helm/
│   └── codesys-x86/                # Helm chart
│       ├── Chart.yaml              # Chart metadata
│       ├── values.yaml             # Default configuration values
│       ├── .helmignore             # Helm ignore patterns
│       └── templates/              # Kubernetes templates
│           ├── _helpers.tpl        # Template helpers
│           ├── NOTES.txt           # Post-install notes
│           ├── namespace.yaml      # Namespace template
│           ├── deployment.yaml     # Deployment template
│           ├── service.yaml        # Service template
│           ├── serviceaccount.yaml # ServiceAccount template
│           ├── configmap.yaml      # ConfigMap template
│           └── pvc.yaml            # PVC template
├── kubernetes/
│   ├── namespace.yaml              # Namespace definition
│   ├── deployment.yaml             # Deployment manifests (amd64 & 386)
│   ├── service.yaml                # Service exposing ports
│   ├── configmap.yaml              # Runtime configuration
│   └── pvc.yaml                    # PersistentVolumeClaims
├── scripts/
│   ├── build.sh                    # Build multi-arch images
│   ├── deploy.sh                   # Deploy to K3s (kubectl)
│   ├── deploy-helm.sh              # Deploy to K3s (Helm)
│   └── download-installer.sh       # Download installers from GitHub
└── .github/
    └── workflows/
        └── build-and-push.yaml     # GitHub Actions CI/CD
```

## 🔧 Configuration

### Using Helm Values

The easiest way to configure the deployment is through Helm values. Edit [`helm/codesys-x86/values.yaml`](helm/codesys-x86/values.yaml) or create a custom values file:

```yaml
# Custom values example
architecture: amd64  # or 386

image:
  repository: YOUR_ORG/codesys-control-x86
  tag: "latest"

resources:
  amd64:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi

service:
  plc:
    nodePort: 31740
  webvisu:
    nodePort: 32455

persistence:
  projects:
    size: 10Gi
  license:
    size: 100Mi
```

Deploy with custom values:
```bash
helm install codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace \
  --values my-values.yaml
```

### Runtime Configuration

Edit runtime configuration via Helm values or directly in [`kubernetes/configmap.yaml`](kubernetes/configmap.yaml):

```yaml
config:
  codesysControl: |
    [CmpBlkDrvTcp]
    TcpPort=11740              # PLC communication port
    
    [CmpWebServer]
    WebServerPort=2455         # Web visualization port
    
    [CmpOPCUAServer]
    ServerPort=4840            # OPC UA port
    Enabled=1
```

### Resource Limits

Adjust resource limits in [`kubernetes/deployment.yaml`](kubernetes/deployment.yaml) or via Helm values:

```yaml
resources:
  amd64:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
```

### Persistent Storage

The deployment uses two PersistentVolumeClaims:

1. **codesys-projects-pvc** (5Gi) - Stores PLC applications and projects
2. **codesys-license-pvc** (100Mi) - Stores license files

To modify storage size via Helm:
```yaml
persistence:
  projects:
    size: 10Gi
  license:
    size: 200Mi
```

Or edit [`kubernetes/pvc.yaml`](kubernetes/pvc.yaml) directly.

## 🔐 CODESYS Licensing

### Installing a License File

#### Option 1: Using Helm with Secret

```bash
# Create secret from license file
kubectl create secret generic codesys-license \
  -n codesys-x86 \
  --from-file=license.lic=/path/to/license.lic

# Deploy with license secret
helm install codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace \
  --set license.useSecret=true \
  --set license.secretName=codesys-license
```

#### Option 2: Copy to Running Pod

```bash
kubectl cp /path/to/your/license.lic \
  codesys-x86/$(kubectl get pod -n codesys-x86 -l app=codesys-runtime -o jsonpath='{.items[0].metadata.name}'):/var/opt/codesys/license/
```

#### Option 3: Manual Secret Mount

Create secret and add to [`kubernetes/deployment.yaml`](kubernetes/deployment.yaml):
```bash
# Create secret from license file
kubectl create secret generic codesys-license \
  -n codesys-x86 \
  --from-file=license.lic=/path/to/license.lic
```

```yaml
volumeMounts:
  - name: license
    mountPath: /var/opt/codesys/license
volumes:
  - name: license
    secret:
      secretName: codesys-license
```

### Demo/Evaluation Mode

CODESYS Control for Linux can run in demo mode with limitations:
- 2 hours runtime per session
- Application must be restarted after 2 hours

For production use, obtain a proper license from CODESYS.

## 🌐 Accessing the Runtime

### From CODESYS Development System

1. Open CODESYS IDE
2. Go to **Tools > Update Raspberry Pi**... or **Scan Network**
3. Or manually configure connection:
   - **Gateway**: Select "CODESYS Control for Linux SL"
   - **IP Address**: `<NODE_IP>`
   - **Port**: `<PLC_PORT>` (default: 31740)

### Web Visualization

Access the web visualization at:
```
http://<NODE_IP>:<WEB_PORT>
```

Example: `http://192.168.1.100:32455`

### Connection Details

After deployment, the script displays connection information:

```bash
Access URLs:
  - CODESYS IDE: Connect to 192.168.1.100:31740
  - Web Visualization: http://192.168.1.100:32455
```

## � Helm Chart Usage

### Installation

```bash
# Install with default values
helm install codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace

# Install for specific architecture
helm install codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace \
  --set architecture=amd64

# Install with custom values file
helm install codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace \
  --values my-custom-values.yaml
```

### Upgrading

```bash
# Upgrade with new values
helm upgrade codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --set resources.amd64.limits.memory=2Gi

# Upgrade with custom values file
helm upgrade codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --values my-custom-values.yaml \
  --wait
```

### Managing Releases

```bash
# List releases
helm list -n codesys-x86

# Get release status
helm status codesys-x86 -n codesys-x86

# Get values used in the release
helm get values codesys-x86 -n codesys-x86

# Get all computed values
helm get values codesys-x86 -n codesys-x86 --all

# View release history
helm history codesys-x86 -n codesys-x86

# Rollback to previous revision
helm rollback codesys-x86 -n codesys-x86
```

### Customization Examples

#### Example 1: Production Configuration

Create `production-values.yaml`:
```yaml
architecture: amd64

image:
  pullPolicy: IfNotPresent
  tag: "3.5.19.0"

resources:
  amd64:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi

persistence:
  storageClass: "fast-ssd"
  projects:
    size: 20Gi
  license:
    size: 100Mi

service:
  type: NodePort
  plc:
    nodePort: 31740
  webvisu:
    nodePort: 32455

license:
  useSecret: true
  secretName: codesys-production-license

nodeSelector:
  environment: production
```

Deploy:
```bash
helm install codesys-prod ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --create-namespace \
  --values production-values.yaml
```

#### Example 2: Development/Testing Configuration

Create `dev-values.yaml`:
```yaml
architecture: amd64

replicaCount: 1

resources:
  amd64:
    limits:
      cpu: 1000m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi

persistence:
  projects:
    size: 5Gi

service:
  type: NodePort

nodeSelector:
  environment: development
```

Deploy:
```bash
helm install codesys-dev ./helm/codesys-x86 \
  --namespace codesys-dev \
  --create-namespace \
  --values dev-values.yaml
```

### Packaging and Distribution

```bash
# Package the chart
helm package ./helm/codesys-x86

# This creates codesys-x86-1.0.0.tgz

# Install from package
helm install codesys-x86 codesys-x86-1.0.0.tgz \
  --namespace codesys-x86 \
  --create-namespace

# Push to OCI registry (optional)
helm push codesys-x86-1.0.0.tgz oci://ghcr.io/YOUR_ORG/charts
```

## �🏗️ CI/CD with GitHub Actions

The project includes automated builds via GitHub Actions.

### Workflow Triggers

- **Push to main**: Automatically builds and pushes images
- **Pull requests**: Builds images for testing (doesn't push)
- **Manual dispatch**: Build with custom CODESYS version

### Manual Workflow Dispatch

```bash
# Via GitHub CLI
gh workflow run build-and-push.yaml \
  -f codesys_version=3.5.19.0 \
  -f push_to_registry=true
```

### Workflow Configuration

Edit [`.github/workflows/build-and-push.yaml`](.github/workflows/build-and-push.yaml) to customize:
- Registry (default: GitHub Container Registry)
- Platforms (currently: linux/amd64, linux/386)
- Build arguments

## 🛠️ Development & Customization

### Building Locally

```bash
# Build for specific architecture
docker buildx build \
  --platform linux/amd64 \
  --build-arg CODESYS_VERSION=3.5.19.0 \
  -t codesys-control-x86:amd64 \
  .

# Build for both architectures
docker buildx build \
  --platform linux/amd64,linux/386 \
  --build-arg CODESYS_VERSION=3.5.19.0 \
  -t codesys-control-x86:latest \
  --push \
  .
```

### Testing Changes

```bash
# Build and load locally (single architecture only)
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t codesys-control-x86:test \
  .

# Run container
docker run -d \
  -p 11740:11740 \
  -p 2455:2455 \
  --name codesys-test \
  codesys-control-x86:test
```

### Modifying Configuration

#### Using Helm

```bash
# Update values and upgrade
helm upgrade codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --set architecture=amd64 \
  --set resources.amd64.limits.memory=2Gi

# Or with custom values file
helm upgrade codesys-x86 ./helm/codesys-x86 \
  --namespace codesys-x86 \
  --values my-values.yaml
```

#### Using kubectl

After modifying manifests, apply changes:

```bash
# Apply specific manifest
kubectl apply -f kubernetes/deployment.yaml

# Or redeploy everything
./scripts/deploy.sh amd64
```

## 📊 Monitoring & Debugging

### View Logs

```bash
# Follow logs
kubectl logs -n codesys-x86 -l app=codesys-runtime -f

# View logs from specific pod
kubectl logs -n codesys-x86 <pod-name>

# View logs from all containers
kubectl logs -n codesys-x86 -l app=codesys-runtime --all-containers=true
```

### Shell Access

```bash
# Get shell in running container
kubectl exec -it -n codesys-x86 deployment/codesys-runtime-amd64 -- /bin/bash

# Check runtime status
kubectl exec -n codesys-x86 deployment/codesys-runtime-amd64 -- ps aux | grep codesys
```

### Health Checks

The deployment includes three types of probes:

- **Startup Probe**: Ensures runtime starts within 60 seconds
- **Liveness Probe**: Checks if codesyscontrol process is running
- **Readiness Probe**: Verifies PLC port (11740) is accepting connections

### Common Issues

#### Pod not starting
```bash
# Check pod events
kubectl describe pod -n codesys-x86 -l app=codesys-runtime

# Check if PVC is bound
kubectl get pvc -n codesys-x86
```

#### Cannot connect from CODESYS IDE
```bash
# Verify service is running
kubectl get svc -n codesys-x86

# Check if port is accessible
telnet <NODE_IP> <PLC_PORT>

# Verify firewall rules on K3s node
```

#### License issues
```bash
# Check license file
kubectl exec -n codesys-x86 deployment/codesys-runtime-amd64 -- \
  ls -la /var/opt/codesys/license/

# View runtime logs for license errors
kubectl logs -n codesys-x86 -l app=codesys-runtime | grep -i license
```

## 🔄 Updating CODESYS Version

1. **Upload new installer** to GitHub releases with appropriate version tag
2. **Update version** in build script:
   ```bash
   export CODESYS_VERSION=3.5.20.0
   ./scripts/build.sh true latest
   ```
3. **Update deployment**:
   
   **Using Helm:**
   ```bash
   helm upgrade codesys-x86 ./helm/codesys-x86 \
     --namespace codesys-x86 \
     --set image.tag=3.5.20.0
   ```
   
   **Using kubectl:**
   ```bash
   kubectl set image deployment/codesys-runtime-amd64 \
     -n codesys-x86 \
     codesys-runtime=ghcr.io/YOUR_ORG/codesys-control-x86:3.5.20.0
   ```

## 🗑️ Cleanup

### Using Helm

```bash
# Uninstall the release (keeps PVCs by default)
helm uninstall codesys-x86 -n codesys-x86

# Delete namespace
kubectl delete namespace codesys-x86
```

### Using kubectl

```bash
# Delete everything in namespace
kubectl delete namespace codesys-x86
```

### Remove PVCs (if needed)
```bash
# Delete PVCs manually if they weren't deleted with namespace
kubectl delete pvc -n codesys-x86 codesys-projects-pvc codesys-license-pvc
```

### Remove Docker images
```bash
# Remove local images
docker rmi ghcr.io/YOUR_ORG/codesys-control-x86:latest
```

## 📚 Additional Resources

- [CODESYS Official Documentation](https://help.codesys.com/)
- [CODESYS Control for Linux](https://store.codesys.com/codesys-control-for-linux-sl.html)
- [K3s Documentation](https://docs.k3s.io/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)

## ⚠️ Important Notes

### Separation from ARM Deployment

This deployment is **completely separate** from any ARM-based CODESYS deployments:
- Uses different namespace (`codesys-x86` vs ARM namespace)
- Different container images (x86 architectures only)
- Different node selectors (amd64/386 vs arm/arm64)
- Can coexist in the same cluster without conflicts

### Production Considerations

- **Licensing**: Ensure proper CODESYS licenses for production
- **Security**: Review and harden security contexts as needed
- **Networking**: Configure firewall rules appropriately
- **Backup**: Implement backup strategy for PVC data
- **Monitoring**: Integrate with your monitoring stack (Prometheus, Grafana, etc.)
- **High Availability**: For critical applications, consider StatefulSet with multiple replicas

## 📝 License

This deployment configuration is provided as-is. CODESYS Control for Linux is a commercial product from CODESYS GmbH and requires appropriate licensing.

## 🤝 Contributing

For issues, improvements, or questions, please open an issue in the repository.

---

**Architecture**: x86 only (amd64, 386) | **Status**: Production Ready | **Maintained**: Yes
