# CODESYS Control for Linux x86/AMD64

> **"Because ARM processors are great, but sometimes you just need a good old x86 box that can run Crysis AND your PLC code."**  
> — Patrick Ryan, Fireball Industries

## Overview

**CODESYS Control for Linux x86** brings the power of professional PLC runtime to Intel/AMD architectures. Whether you're running on a beefy AMD64 server or resurrecting a legacy 386 box (we won't judge), this chart gives you full IEC 61131-3 automation capabilities on x86 hardware.

Perfect for industrial PCs, edge servers, and that old Dell Optiplex you found in the back of the server room.

### Key Features

- **Dual Architecture Support**: AMD64 (64-bit) and 386 (32-bit) x86 processors
- **IEC 61131-3 Compliant**: Full PLC programming environment (ST, LD, FBD, SFC, IL)
- **Multi-Protocol**: CODESYS V3 programming, OPC UA server, Modbus TCP/RTU
- **Web Visualization**: Built-in WebVisu server for HMI development
- **Real-Time Capable**: Deterministic execution with configurable cycle times
- **Persistent Storage**: Projects and licenses survive pod restarts
- **Industrial Grade**: SYS_NICE capability for real-time priority scheduling

---

## Architecture Support

### AMD64 (x86-64) 🚀

**Modern 64-bit Intel/AMD processors**

**Ideal Hardware:**
- Industrial PCs (Advantech, Beckhoff, OnLogic)
- Intel NUCs
- Modern servers
- Fanless edge computers
- Virtually any x86 box from the last decade

**Resource Profile:**
- CPU: 250m request, 1000m limit
- Memory: 256Mi request, 1Gi limit
- Better performance for complex logic
- More addressable memory for large projects

**Use Cases:**
- Complex automation with thousands of I/O points
- High-speed data processing
- Multi-protocol gateway applications
- Edge computing with ML/AI workloads
- Modern industrial infrastructure

### 386 (i386) 🦕

**Legacy 32-bit Intel/AMD processors**

**Ideal Hardware:**
- Older industrial PCs (pre-2010)
- Legacy embedded systems
- Atom-based systems
- That crusty old box in the control cabinet that refuses to die

**Resource Profile:**
- CPU: 100m request, 500m limit
- Memory: 128Mi request, 512Mi RAM limit
- Lower resource requirements
- Compatibility with older hardware

**Use Cases:**
- Retrofitting legacy equipment
- Simple automation tasks
- Resource-constrained environments
- "If it ain't broke, don't replace it" scenarios
- Budget-friendly deployments

---

## Why Choose x86 Over ARM?

| Feature | x86/AMD64 | ARM (Raspberry Pi) |
|---------|-----------|-------------------|
| **Performance** | Higher clock speeds, more cores | Lower power, adequate for most tasks |
| **Industrial PCs** | Wide availability, rugged options | Growing but limited industrial options |
| **Legacy Support** | Run on existing hardware | Requires new hardware |
| **Power Consumption** | 15-65W typical | 5-15W typical |
| **Cost** | $200-2000+ | $50-200 |
| **Best For** | Complex automation, edge servers | Distributed I/O, remote sites |

**TL;DR**: Choose x86 when you need raw power or have existing hardware. Choose ARM when you need low power consumption or cost-effective distributed deployments.

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Industrial PC / Server                    │
│                        (x86/AMD64)                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │            K3s Kubernetes Cluster                  │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │  CODESYS Control x86 Pod                     │ │    │
│  │  │                                               │ │    │
│  │  │  ┌─────────────────────────────────────────┐ │ │    │
│  │  │  │  PLC Runtime Process                    │ │ │    │
│  │  │  │  - IEC 61131-3 execution engine        │ │ │    │
│  │  │  │  - Real-time scheduler (SYS_NICE)      │ │ │    │
│  │  │  │  - Task manager                         │ │ │    │
│  │  │  └─────────────────────────────────────────┘ │ │    │
│  │  │                                               │ │    │
│  │  │  ┌──────────────┐  ┌──────────────┐         │ │    │
│  │  │  │  WebVisu     │  │  OPC UA      │         │ │    │
│  │  │  │  Server      │  │  Server      │         │ │    │
│  │  │  │  :2455       │  │  :4840       │         │ │    │
│  │  │  └──────────────┘  └──────────────┘         │ │    │
│  │  │                                               │ │    │
│  │  │  Persistent Volumes:                         │ │    │
│  │  │  📁 /var/opt/codesys/projects (5Gi)         │ │    │
│  │  │  📄 /var/opt/codesys/license (100Mi)        │ │    │
│  │  └───────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │  NodePort Services                           │ │    │
│  │  │  - PLC Programming: 31740 → 11740           │ │    │
│  │  │  - WebVisu: 32455 → 2455                    │ │    │
│  │  │  - OPC UA: 34840 → 4840                     │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  Network Interfaces:                                        │
│  🌐 Ethernet (industrial protocols)                         │
│  📡 Optional: Serial ports (Modbus RTU)                     │
└──────────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
   CODESYS IDE    Web Browser    SCADA System
   (Programming)  (WebVisu HMI)  (OPC UA Client)
```

---

## Quick Start

### Prerequisites

1. **x86 Hardware** running K3s/K8s
2. **CODESYS Container Image** (commercial license required from CODESYS)
3. **Rancher Apps & Marketplace** installed

### Installation Steps

1. **Navigate to Apps & Marketplace** in Rancher
2. **Find "CODESYS Control x86"** in the Fireball Industries catalog
3. **Choose Architecture**:
   - Select **amd64** for modern 64-bit systems (recommended)
   - Select **386** for legacy 32-bit systems
4. **Configure Resources**:
   - AMD64: Defaults to 250m-1000m CPU, 256Mi-1Gi RAM
   - 386: Defaults to 100m-500m CPU, 128Mi-512Mi RAM
5. **Set Network Ports**:
   - PLC: 31740 (NodePort) → 11740 (container)
   - WebVisu: 32455 → 2455
   - OPC UA: 34840 → 4840
6. **Enable Persistent Storage** (recommended):
   - Projects: 5Gi
   - License: 100Mi
7. **Click Install** and wait for deployment

### First Connection

**CODESYS IDE:**
```
Gateway: <node-ip>:31740
User: (configured in runtime)
Password: (configured in runtime)
```

**WebVisu:**
```
http://<node-ip>:32455
```

**OPC UA:**
```
opc.tcp://<node-ip>:34840
```

---

## Configuration Guide

### Architecture Selection

```yaml
architecture: amd64  # or "386"
```

**How to Choose:**
- **amd64**: Any Intel/AMD processor from ~2008 onwards (Core 2, i3/i5/i7, Ryzen, Xeon, EPYC)
- **386**: Ancient Intel/AMD 32-bit processors (pre-2008, Pentium, early Atom)

Run this on your node to check:
```bash
uname -m
# x86_64 = amd64
# i686 or i386 = 386
```

### Resource Tuning

**For Simple Automation (< 100 I/O points):**
```yaml
resources:
  amd64:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

**For Complex Automation (1000+ I/O points):**
```yaml
resources:
  amd64:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "2Gi"
```

**For Gateway Applications (multi-protocol):**
```yaml
resources:
  amd64:
    requests:
      cpu: "1000m"
      memory: "1Gi"
    limits:
      cpu: "4000m"
      memory: "4Gi"
```

### Service Port Configuration

**Default NodePort Mapping:**
```yaml
service:
  type: NodePort
  plc:
    port: 11740
    nodePort: 31740      # CODESYS IDE programming
  webvisu:
    port: 2455
    nodePort: 32455      # Web visualization
  opcua:
    port: 4840
    nodePort: 34840      # OPC UA server
```

**LoadBalancer (if available):**
```yaml
service:
  type: LoadBalancer
  # NodePort values ignored
```

**ClusterIP (internal only):**
```yaml
service:
  type: ClusterIP
  # Access only from within cluster
```

### Persistent Storage

**K3s Local Path (default):**
```yaml
persistence:
  enabled: true
  storageClass: ""  # Uses K3s local-path
  projects:
    enabled: true
    size: "5Gi"
  license:
    enabled: true
    size: "100Mi"
```

**NFS Storage:**
```yaml
persistence:
  enabled: true
  storageClass: "nfs-client"
  projects:
    size: "10Gi"
  license:
    size: "100Mi"
```

**Disable Persistence (testing only):**
```yaml
persistence:
  enabled: false
# ⚠️ Projects and license lost on pod restart!
```

### License Management

**Option 1: Persistent Volume (automatic)**
```yaml
license:
  useSecret: false
persistence:
  license:
    enabled: true
    size: "100Mi"
```

Upload license via CODESYS IDE after first connection.

**Option 2: Kubernetes Secret (pre-configured)**
```bash
# Create secret with your license file
kubectl create secret generic codesys-license \
  --from-file=3SLicense.dat=/path/to/your/3SLicense.dat \
  -n codesys-x86
```

```yaml
license:
  useSecret: true
  secretName: "codesys-license"
```

---

## Network Access

### From CODESYS IDE (Development)

1. **Scan for Device**: IDE → Tools → Gateway → Scan
2. **Add Manually**: `<node-ip>:31740`
3. **Login**: Use configured credentials
4. **Download Project**: Transfer PLC program to runtime

### From Web Browser (HMI)

1. **Navigate to**: `http://<node-ip>:32455`
2. **Select Visualization**: Choose WebVisu project
3. **Interact**: Touch-screen friendly interface

### From SCADA (OPC UA)

1. **Connect to**: `opc.tcp://<node-ip>:34840`
2. **Browse Address Space**: Discover PLC variables
3. **Subscribe**: Real-time data updates

---

## Industrial Use Cases

### 1. Edge Gateway

**Scenario**: Connect legacy Modbus/Profinet devices to modern OPC UA/MQTT systems

**Configuration**:
- AMD64 industrial PC
- CODESYS for protocol conversion
- Node-RED for MQTT publishing
- 1000m CPU, 1Gi RAM

**Benefits**:
- Single hardware platform for multiple protocols
- Web-based configuration
- K3s orchestration

### 2. Production Line Controller

**Scenario**: Control conveyor systems, robots, packaging equipment

**Configuration**:
- AMD64 fanless PC
- Digital I/O via Modbus TCP
- WebVisu for operator interface
- 500m CPU, 512Mi RAM

**Benefits**:
- IEC 61131-3 proven automation
- Built-in HMI
- Persistent project storage

### 3. Building Automation

**Scenario**: HVAC control, lighting, energy management

**Configuration**:
- AMD64 NUC or industrial PC
- BACnet/Modbus integration
- OPC UA for Building Management System
- 250m CPU, 256Mi RAM

**Benefits**:
- Low resource usage
- Multi-protocol support
- Cloud connectivity via OPC UA

### 4. Test Bench Automation

**Scenario**: Automated testing of manufactured products

**Configuration**:
- AMD64 desktop-class PC
- High-speed I/O acquisition
- Data logging to PostgreSQL
- 2000m CPU, 2Gi RAM

**Benefits**:
- High performance
- Complex test sequences
- Integration with databases

---

## Troubleshooting

### Pod Not Starting

**Check Architecture Match:**
```bash
# On Kubernetes node
uname -m

# Should match your selected architecture:
# x86_64 → use architecture: amd64
# i686/i386 → use architecture: 386
```

**Check Logs:**
```bash
kubectl logs -n codesys-x86 -l app.kubernetes.io/name=codesys-x86
```

**Common Issues:**
- **Image pull errors**: Verify CODESYS container image exists
- **Permission denied**: Check securityContext and capabilities
- **Crash loop**: Verify license file or check liveness probe settings

### Cannot Connect from CODESYS IDE

**Check Service:**
```bash
kubectl get svc -n codesys-x86
```

Verify NodePort 31740 is listed.

**Check Firewall:**
```bash
# On Kubernetes node
sudo firewall-cmd --list-ports
# Should include 31740/tcp
```

**Test Connectivity:**
```bash
telnet <node-ip> 31740
# Should connect (Ctrl+] then quit to exit)
```

### WebVisu Not Loading

**Check Service Port:**
```bash
kubectl get svc -n codesys-x86 -o yaml | grep -A5 webvisu
```

**Verify Pod is Ready:**
```bash
kubectl get pods -n codesys-x86
# STATUS should be "Running", READY should be "1/1"
```

**Check WebVisu Configuration in CODESYS:**
- Ensure WebVisu server is enabled in runtime config
- Port 2455 must be configured
- Visualization must be built and downloaded

### Performance Issues

**Check Resource Limits:**
```bash
kubectl top pod -n codesys-x86
```

If CPU/Memory near limits, increase resources:

```yaml
resources:
  amd64:
    limits:
      cpu: "2000m"    # Increase from 1000m
      memory: "2Gi"   # Increase from 1Gi
```

**Check Node Load:**
```bash
kubectl top nodes
```

### License Issues

**Verify License Mount:**
```bash
kubectl exec -n codesys-x86 deployment/codesys-x86 -- \
  ls -la /var/opt/codesys/license/
```

**Check License File:**
```bash
kubectl exec -n codesys-x86 deployment/codesys-x86 -- \
  cat /var/opt/codesys/license/3SLicense.dat
```

**Upload New License** (if using persistent volume):
1. Connect via CODESYS IDE
2. Online → Communication → License Manager
3. Upload new 3SLicense.dat

### Real-Time Performance

**Jitter in PLC Cycle Time:**

Enable real-time scheduling (requires privileged pod):

```yaml
securityContext:
  capabilities:
    add:
      - SYS_NICE
      - SYS_TIME
  # Note: Already enabled by default in this chart
```

Check kernel scheduler:
```bash
# On node
cat /sys/kernel/realtime
# Should be "1" for RT kernel, "0" for standard
```

---

## Integration Examples

### With Prometheus (Metrics Collection)

```yaml
# Add annotations to pod
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"    # If CODESYS exposes metrics
  prometheus.io/path: "/metrics"
```

### With Node-RED (MQTT Bridge)

```yaml
# Deploy Node-RED in same namespace
# Connect to CODESYS via Modbus TCP or OPC UA
# Publish to MQTT broker
```

### With Grafana (Visualization)

```yaml
# Configure OPC UA data source in Grafana
# OPC UA endpoint: opc.tcp://<service-name>:4840
# Create dashboards for process monitoring
```

### With Industrial IOT Pod (Home Assistant)

```yaml
# Home Assistant integration via OPC UA
# or Modbus TCP from CODESYS
# Unified dashboard for industrial + building automation
```

---

## Comparison: x86 vs ARM Charts

| Feature | x86 Chart (This One) | ARM Chart |
|---------|---------------------|-----------|
| **Chart Name** | codesys-amd64-x86 | codesys-runtime |
| **Architecture** | amd64, 386 | arm64, armv7 |
| **Hardware** | Intel/AMD PCs | Raspberry Pi, etc. |
| **Default CPU** | 250m-1000m | 100m-500m |
| **Default RAM** | 256Mi-1Gi | 128Mi-512Mi |
| **Best For** | Industrial PCs, edge servers | Distributed I/O, cost-sensitive |
| **Power** | 15-65W typical | 5-15W typical |
| **Cost** | $200-2000+ | $50-200 |

**When to use x86 chart:**
- ✅ You have existing x86 hardware
- ✅ Complex automation requiring more CPU/RAM
- ✅ Industrial PC deployment
- ✅ Multi-protocol gateway with heavy processing

**When to use ARM chart:**
- ✅ New deployment where you can choose hardware
- ✅ Cost-sensitive applications
- ✅ Low power consumption required
- ✅ Simple automation tasks

---

## Security Considerations

### Capabilities

This chart requires elevated capabilities:

```yaml
securityContext:
  capabilities:
    add:
      - SYS_NICE      # Real-time process priority
      - NET_RAW       # Raw socket access (some protocols)
      - NET_ADMIN     # Network configuration
      - SYS_TIME      # System time adjustment (optional)
```

**Why?**
- **SYS_NICE**: Allows PLC runtime to use real-time scheduling for deterministic execution
- **NET_RAW**: Required for certain industrial protocols
- **NET_ADMIN**: Network interface configuration for advanced scenarios
- **SYS_TIME**: Allows runtime to synchronize system clock (can be disabled)

### Network Isolation

```yaml
# Recommended: Deploy in isolated namespace
namespace:
  name: "codesys-x86"
  create: true

# Optional: NetworkPolicy to restrict access
# (Create manually if needed)
```

### Service Account

```yaml
# Default: Uses default service account
serviceAccount:
  create: false

# For advanced scenarios requiring API access
serviceAccount:
  create: true
  name: "codesys-runtime"
```

---

## Uninstall

### Via Rancher UI

1. Navigate to Apps & Marketplace
2. Find CODESYS Control x86 deployment
3. Click **Delete**
4. Confirm deletion

### Via Helm CLI

```bash
helm uninstall codesys-x86 -n codesys-x86
```

### Clean Up Persistent Volumes

⚠️ **Warning**: This deletes all PLC projects and license files!

```bash
kubectl delete pvc -n codesys-x86 --all
```

---

## Support & Resources

### CODESYS Resources

- **Official Documentation**: https://help.codesys.com
- **CODESYS Store**: https://store.codesys.com (purchase licenses)
- **CODESYS Forums**: https://forge.codesys.com

### Fireball Industries

- **GitHub**: https://github.com/fireballindustries
- **Issues**: Report bugs via GitHub Issues
- **Email**: support@fireballindustries.com

### Community

- **Kubernetes**: https://kubernetes.io/docs
- **K3s**: https://docs.k3s.io
- **Rancher**: https://rancher.com/docs

---

## License

This Helm chart is provided by **Fireball Industries** under the MIT License.

**CODESYS Control for Linux** is a commercial product from CODESYS GmbH requiring a valid license. This chart does not include the CODESYS software or license.

---

## About Fireball Industries

> *"We automate stuff so you don't have to. Usually with more sarcasm than strictly necessary."*

**Fireball Industries Pod Store** brings industrial-grade automation to Kubernetes. Because someone had to do it, and apparently, that someone is us.

**Other Pods You Might Like:**
- **Codesys Runtime (ARM Class Devices)**: For Raspberry Pi deployments
- **CODESYS TargetVisu**: HMI/SCADA visualization platform
- **CODESYS Edge Gateway**: PLC connectivity and management
- **Industrial IOT**: Smart factory automation with Home Assistant
- **Node-RED**: Low-code programming for industrial workflows
- **InfluxDB**, **TimescaleDB**: Time-series data storage for industrial metrics
- **Mosquitto MQTT**: Message broker with Sparkplug B support

---

**Questions? Issues? Existential Dread?**

Open an issue on GitHub. We'll get back to you faster than a PLC cycle time (usually).

Happy automating! 🏭🚀
