# CODESYS Control for Linux x86/AMD64 - README

**Current Version:** CODESYS Control for Linux SL 4.18.0.0

**GitHub Release:** [AMD64-X86 Release](https://github.com/fireball-industries/CodesysControlLinuxAMD64X86/releases/tag/AMD64-X86)

## Service Type Configuration Guide

### Understanding Kubernetes Service Types

The CODESYS chart supports multiple service types for different deployment scenarios. Choose the right service type based on your infrastructure and access requirements.

#### Service Type: LoadBalancer (Default)

**Best for:** Production, k3s with MetalLB, cloud providers, multi-node clusters

```yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: industrial  # For MetalLB
    # loadBalancerIP: 192.168.1.100  # Optional: specific IP
  plc:
    port: 11740
    targetPort: 11740
  webvisu:
    port: 2455
    targetPort: 2455
  opcua:
    port: 4840
    targetPort: 4840
```

**Access Pattern:**
- CODESYS IDE: `<load-balancer-ip>:11740`
- WebVisu: `http://<load-balancer-ip>:2455`
- OPC UA: `opc.tcp://<load-balancer-ip>:4840`

**Advantages:**
- ✅ Standard industrial ports (no NodePort range limits)
- ✅ Automatic IP assignment
- ✅ Professional appearance
- ✅ Easier firewall rules
- ✅ Works with Traefik/Ingress integration
- ✅ Consistent with CODESYS ARM chart

**Disadvantages:**
- ❌ Requires load balancer (MetalLB for bare-metal)
- ❌ May consume scarce IP addresses
- ❌ Cloud providers may charge per LoadBalancer

**MetalLB Configuration Example:**
```yaml
# Install MetalLB first:
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Create IP address pool:
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: industrial
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.110  # Your factory network IPs
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: industrial
  namespace: metallb-system
```

#### Service Type: NodePort

**Best for:** Development, single-node clusters, direct access from factory network

```yaml
service:
  type: NodePort
  plc:
    port: 11740
    nodePort: 31740  # Accessible on every node at this port
  webvisu:
    port: 2455
    nodePort: 32455
  opcua:
    port: 4840
    nodePort: 34840
```

**Access Pattern:**
- CODESYS IDE: `<any-node-ip>:31740`
- WebVisu: `http://<any-node-ip>:32455`
- OPC UA: `opc.tcp://<any-node-ip>:34840`

**Advantages:**
- ✅ Simple configuration
- ✅ No external load balancer required
- ✅ Works on any Kubernetes cluster
- ✅ Fixed port numbers for firewall rules

**Disadvantages:**
- ❌ Ports 30000-32767 range only
- ❌ Must know node IP addresses
- ❌ No automatic failover
- ❌ External firewall may block high ports

#### Service Type: LoadBalancer

**Best for:** Production, k3s with MetalLB, cloud providers, multi-node clusters

```yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: industrial  # For MetalLB
    # loadBalancerIP: 192.168.1.100  # Optional: specific IP
  plc:
    port: 1217  # Standard CODESYS port
    targetPort: 11740
  webvisu:
    port: 8080  # Standard HTTP alt port
    targetPort: 2455
  opcua:
    port: 4840  # Standard OPC UA port
    targetPort: 4840
```

**Access Pattern:**
- CODESYS IDE: `<load-balancer-ip>:1217`
- WebVisu: `http://<load-balancer-ip>:8080`
- OPC UA: `opc.tcp://<load-balancer-ip>:4840`

**Advantages:**
- ✅ Standard industrial ports
- ✅ Automatic IP assignment
- ✅ Professional appearance
- ✅ Easier firewall rules
- ✅ Works with Traefik/Ingress integration

**Disadvantages:**
- ❌ Requires load balancer (MetalLB for bare-metal)
- ❌ May consume scarce IP addresses
- ❌ Cloud providers may charge per LoadBalancer

**MetalLB Configuration Example:**
```yaml
# Install MetalLB first:
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Create IP address pool:
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: industrial
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.110  # Your factory network IPs
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: industrial
  namespace: metallb-system
```

#### Service Type: ClusterIP

**Best for:** Internal-only access, when using Ingress/Traefik, microservices architecture

```yaml
service:
  type: ClusterIP
  plc:
    port: 1217
    targetPort: 11740
  webvisu:
    port: 8080
    targetPort: 2455
  opcua:
    port: 4840
    targetPort: 4840
```

**Access Pattern:**
- Only accessible from within cluster
- Use Ingress or Traefik for external access
- Ideal for WebVisu with TLS termination

**Ingress Configuration for WebVisu:**
```yaml
ingress:
  enabled: true
  className: "traefik"  # or "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: plc-webvisu.example.com
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: codesys-x86
              port:
                number: 8080
  tls:
    - secretName: plc-webvisu-tls
      hosts:
        - plc-webvisu.example.com
```

**Advantages:**
- ✅ Most secure (not directly exposed)
- ✅ No IP address consumption
- ✅ Works with Ingress controllers
- ✅ TLS termination at ingress
- ✅ Best for WebVisu/web interfaces

**Disadvantages:**
- ❌ CODESYS IDE cannot connect directly (requires VPN or NodePort)
- ❌ More complex configuration
- ❌ Requires Ingress controller or Traefik

## Integration with Other Services

### Database Connectivity

Connect your PLC program to databases for data logging, recipe management, or reporting.

#### InfluxDB Integration

```yaml
database:
  enabled: true
  influxdb:
    enabled: true
    host: "influxdb-pod"  # Service name in cluster
    port: 8086
    database: "industrial_data"
    organization: "fireball-industries"
    bucket: "plc_data"
```

**In your CODESYS program:**
```iecst
(* Install IoTLibrary or OSCAT InfluxDB client *)
PROGRAM PLC_PRG
VAR
    influxClient: InfluxDB_Client;
    sHost: STRING := '${INFLUXDB_HOST}';  (* From environment *)
    nPort: UINT := ${INFLUXDB_PORT};
    sDatabase: STRING := '${INFLUXDB_DATABASE}';
END_VAR

(* Write measurement *)
influxClient.WriteMeasurement(
    measurement := 'temperature',
    tags := 'sensor=tank1,location=building2',
    fields := 'value=72.5',
    timestamp := NOW()
);
```

#### TimescaleDB/PostgreSQL Integration

```yaml
database:
  enabled: true
  timescaledb:
    enabled: true
    host: "timescaledb-pod"
    port: 5432
    database: "industrial_data"
    schema: "plc_metrics"
    username: "postgres"
    password: "yourpassword"  # Or use existingSecret
```

**In your CODESYS program:**
```iecst
(* Install PostgreSQL OSCAT library *)
PROGRAM PLC_PRG
VAR
    pgClient: PostgreSQL_Client;
    sHost: STRING := '${TIMESCALEDB_HOST}';
    nPort: UINT := ${TIMESCALEDB_PORT};
    sDatabase: STRING := '${TIMESCALEDB_DATABASE}';
END_VAR

(* Execute query *)
pgClient.ExecuteQuery(
    query := 'INSERT INTO plc_metrics.sensor_data (timestamp, sensor, value) VALUES (NOW(), $1, $2)',
    params := ['tank1_temp', '72.5']
);
```

### MQTT Integration

Connect to MQTT broker for publish/subscribe messaging with other systems.

```yaml
mqtt:
  enabled: true
  broker:
    host: "mosquitto-mqtt-pod"
    port: 1883
    username: ""  # Optional
    password: ""  # Optional
    clientIdPrefix: "codesys-x86"
  topics:
    base: "factory/plc/codesys-x86"
    status: "factory/plc/codesys-x86/status"
    data: "factory/plc/codesys-x86/data"
    command: "factory/plc/codesys-x86/command"
```

**In your CODESYS program:**
```iecst
(* Install IoTMQTT library from CODESYS Store *)
PROGRAM PLC_PRG
VAR
    mqttClient: IoTMQTT.MqttClient;
    sHost: STRING := '${MQTT_HOST}';
    nPort: UINT := ${MQTT_PORT};
    sBaseTopic: STRING := '${MQTT_TOPIC_BASE}';
END_VAR

(* Publish sensor data *)
mqttClient.Publish(
    topic := CONCAT(sBaseTopic, '/data/temperature'),
    payload := '{"sensor":"tank1","value":72.5}',
    qos := 1,
    retain := FALSE
);

(* Subscribe to commands *)
mqttClient.Subscribe(
    topic := CONCAT(sBaseTopic, '/command/#'),
    qos := 1
);
```

### Prometheus Monitoring

Enable metrics export for monitoring and alerting.

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
  metrics:
    enabled: true
    port: 9273
    path: /metrics
```

**Metrics Exposed:**
- PLC cycle time
- Task execution duration
- I/O update time
- Memory usage
- CPU usage per task
- Application runtime

**Note:** Requires CODESYS CmpPrometheus library or custom exporter.

## Advanced Deployment Scenarios

### Scenario 1: Factory Edge with LoadBalancer (k3s + MetalLB)

```yaml
architecture: amd64
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: factory-floor
  plc:
    port: 1217
  webvisu:
    port: 8080
database:
  enabled: true
  timescaledb:
    enabled: true
    host: "timescaledb-pod"
mqtt:
  enabled: true
  broker:
    host: "mosquitto-mqtt-pod"
monitoring:
  serviceMonitor:
    enabled: true
persistence:
  enabled: true
  projects:
    size: 10Gi
resources:
  amd64:
    requests:
      cpu: "1000m"
      memory: "1Gi"
    limits:
      cpu: "2000m"
      memory: "2Gi"
```

**Use Case:** Production factory floor automation with data logging, MQTT messaging, and monitoring.

### Scenario 2: Development Environment (NodePort)

```yaml
architecture: amd64
service:
  type: NodePort
  plc:
    nodePort: 31740
  webvisu:
    nodePort: 32455
persistence:
  enabled: true
  projects:
    size: 5Gi
resources:
  amd64:
    requests:
      cpu: "250m"
      memory: "256Mi"
```

**Use Case:** Development and testing on local cluster.

### Scenario 3: Multi-Site with Ingress (ClusterIP)

```yaml
architecture: amd64
service:
  type: ClusterIP
ingress:
  enabled: true
  className: "traefik"
  hosts:
    - host: plc-site1.factory.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: plc-site1-tls
      hosts:
        - plc-site1.factory.com
database:
  enabled: true
  postgresql:
    enabled: true
grafana:
  dashboards:
    enabled: true
```

**Use Case:** Multiple sites with centralized monitoring and secure web access.

## Troubleshooting

### Cannot Connect from CODESYS IDE

**If using ClusterIP:**
- ClusterIP is internal-only
- Switch to NodePort or LoadBalancer
- Or use `kubectl port-forward`

```bash
kubectl port-forward -n codesys-x86 svc/codesys-x86 1217:11740
# Then connect to localhost:1217
```

**If using LoadBalancer but no IP assigned:**
```bash
# Check if LoadBalancer service has external IP
kubectl get svc -n codesys-x86

# If EXTERNAL-IP shows <pending>:
# - Install MetalLB (bare-metal)
# - Or switch to NodePort
```

### WebVisu Not Accessible

**Check service type and ports:**
```bash
kubectl get svc -n codesys-x86 -o wide
```

**For LoadBalancer:**
- Access via `http://<EXTERNAL-IP>:<webvisu-port>`

**For NodePort:**
- Access via `http://<node-ip>:<nodePort>`

**For ClusterIP:**
- Configure Ingress or use port-forward

### Database Connection Fails

**Verify database service is running:**
```bash
kubectl get pods -n <database-namespace>
kubectl logs -n <database-namespace> <database-pod>
```

**Check connectivity from PLC pod:**
```bash
kubectl exec -n codesys-x86 <plc-pod> -- ping influxdb-pod
kubectl exec -n codesys-x86 <plc-pod> -- nc -zv influxdb-pod 8086
```

**Environment variables present:**
```bash
kubectl exec -n codesys-x86 <plc-pod> -- env | grep -i influx
```

## Support and Documentation

- **CODESYS Documentation:** https://www.codesys.com
- **IEC 61131-3 Programming:** CODESYS Help System
- **Library Downloads:** CODESYS Store
- **Fireball Industries:** Contact your support representative

---

**Author:** Patrick Ryan, Fireball Industries  
**Chart Version:** See Chart.yaml  
**Last Updated:** January 2026
