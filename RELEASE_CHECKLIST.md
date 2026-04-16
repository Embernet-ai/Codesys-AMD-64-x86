# 🔥 Release Checklist — codesys-pod (AMD64/x86)

**EmberNET Helm Chart Release Protocol**
*Fireball Industries — Production Deployment Standard*

---

> **Purpose:** This checklist must be completed before every chart version release to `main`. It ensures the CODESYS Control SL (AMD64/x86) chart remains aligned with the canonical EmberNET template, passes all validation gates, and integrates correctly with the Industrial Dashboard.

---

## How This Repo Integrates Into the Industrial Dashboard

The EmberNET Industrial Dashboard discovers apps by scanning pod and service labels for `embernet.ai/store-app: "true"`. When found, it reads the companion labels (`gui-type`, `app-name`, `gui-port`) to determine how to render the app in the embedded App Store.

**CODESYS AMD64-specific integration flow:**

1. Dashboard scans for pods with `embernet.ai/store-app: "true"` → finds `codesys-pod`
2. Dashboard reads `embernet.ai/gui-type: "web"` → renders as iframe-able web app
3. Dashboard reads `embernet.ai/gui-port: "8080"` (or `"8081"` with sidecar) → proxies to correct port
4. Dashboard embeds CODESYS WebVisu via iframe through Rancher's K8s API proxy
5. **Sidecar proxy** (when enabled) rewrites absolute asset paths to relative, preventing 404s through the proxy chain

**CODESYS AMD64-specific considerations:**
- CODESYS uses an **installer pattern** — no public Docker image. The initContainer downloads a `.package` file from GitHub Releases and installs via `dpkg` at runtime.
- This is the **AMD64/x86 variant** — the installer URL and architecture annotation differ from the ARM32 sibling (`codesys_arm_64`). Ensure `catalog.cattle.io/arch` is set to `amd64` only.
- CODESYS WebVisu is a **server-rendered HTML5 HMI**, not a complex SPA. Sidecar proxy is **disabled by default** — enable only if WebVisu assets break through the Dashboard proxy.
- Three critical ports must all be reachable: **Gateway (1217)** for IDE connections, **OPC UA (4840)** for industrial protocol, and **WebVisu (8080)** for the web HMI.
- CODESYS requires **privileged security context** for hardware interfaces, fieldbus protocols (EtherCAT, PROFINET), and raw network sockets.

**Critical path:** Any change to labels, ports, or sidecar config directly affects Dashboard integration. Test through the Dashboard, not just direct access.

---

## Pre-Release Validation

### 1. Version Verification

- [ ] `charts/codesys-pod/Chart.yaml` → `version` has been bumped appropriately
  - Patch (`x.x.+1`): bug fixes, config tweaks
  - Minor (`x.+1.0`): new features, non-breaking config additions
  - Major (`+1.0.0`): breaking changes, image version jumps
- [ ] `charts/codesys-pod/Chart.yaml` → `appVersion` matches the latest stable CODESYS release
  - Format: `"<VERSION>"` (e.g., `"4.20.0.0"`)
- [ ] `charts/codesys-pod/values.yaml` → `installerUrl` matches the version in `appVersion`
- [ ] `catalog.cattle.io/upstream-version` annotation in `Chart.yaml` matches `appVersion`
- [ ] CODESYS installer package URL verified to exist:
  ```bash
  curl -sI "https://github.com/Embernet-ai/Codesys-AMD-64-x86/releases/download/v<VERSION>/CODESYS.Control.for.Linux.SL.<VERSION>.package" | head -1
  # Expected: HTTP/2 200 or 302 redirect
  ```
- [ ] Base image `debian:bullseye` verified for `amd64`:
  ```bash
  docker manifest inspect debian:bullseye
  ```

### 2. EmberNET Store Labels (The Big Four)

All four labels MUST appear on **pod template labels** AND **Service labels**.

| Label | Expected Value | Verified? |
|-------|---------------|-----------|
| `embernet.ai/store-app` | `"true"` | ☐ |
| `embernet.ai/gui-type` | `"web"` | ☐ |
| `embernet.ai/app-name` | `"codesys-pod"` | ☐ |
| `embernet.ai/gui-port` | `"8080"` (or `"8081"` with sidecar) | ☐ |

**Verification command:**
```bash
helm template test-release charts/codesys-pod | grep -c "embernet.ai/"
# Expected: 8 (4 labels × 2 resources: service + pod template)
# Note: installerUrl also contains "embernet.ai" — count actual label lines
```

- [ ] Labels present on pod template (deployment.yaml via `codesys-pod.storeLabels` helper)
- [ ] Labels present on Service (service.yaml via `codesys-pod.storeLabels` helper)
- [ ] `gui-port` switches to sidecar port when `sidecarProxy.enabled: true`
- [ ] Labels generated via `codesys-pod.storeLabels` helper (NOT hardcoded)

### 3. Network Configuration

- [ ] `network.hostNetwork: true` is the **default** in `values.yaml`
- [ ] Deployment renders `hostNetwork: true` + `dnsPolicy: ClusterFirstWithHostNet` by default
- [ ] Deployment renders `dnsPolicy: ClusterFirst` when `hostNetwork: false`
- [ ] `hostPort` is set on all three ports (1217, 4840, 8080) when `hostNetwork: true`
- [ ] `hostPort` is absent when `hostNetwork: false`

**Verification:**
```bash
# Default (hostNetwork: true)
helm template test-release charts/codesys-pod | grep -E "hostNetwork|dnsPolicy|hostPort"

# Override (hostNetwork: false)
helm template test-release charts/codesys-pod --set network.hostNetwork=false | grep -E "hostNetwork|dnsPolicy|hostPort"
```

### 4. Service Configuration

- [ ] Service type is `ClusterIP` (default)
- [ ] Service name uses `{{ include "codesys-pod.fullname" . }}` helper
- [ ] Service selector uses `{{ include "codesys-pod.selectorLabels" . }}`
- [ ] `nodeSelector: {}` exists in values.yaml and is wired into Deployment
- [ ] Service exposes all three ports: gateway (1217), opcua (4840), webvisu (8080)

### 5. Sidecar Proxy Decision

CODESYS WebVisu is a **server-rendered HTML5 HMI** — NOT a complex SPA.

| Criterion | Assessment |
|-----------|------------|
| Has web UI? | ✅ Yes — WebVisu on port 8080 |
| Is an SPA? | ❌ No — server-rendered HTML5 |
| Absolute asset paths? | ⚠️ Evaluate — `/webvisu.htm` likely uses relative |
| Has root_url config? | ❌ No — no configurable base path |
| **Verdict** | **NO sidecar by default** — enable if WebVisu breaks through Dashboard proxy |

- [ ] Confirmed: `sidecarProxy.enabled: false` is default
- [ ] Confirmed: `configmap-sidecar-proxy.yaml` template only renders when enabled
- [ ] Confirmed: When sidecar enabled, `gui-port` switches to sidecar `listenPort` (8081)
- [ ] Confirmed: `gui.type` defaults to `"web"`
- [ ] Sidecar container is the **last** container in the pod spec
- [ ] When enabled: sidecar health check responds at `/sidecar-health`

### 6. Chart Linting & Templating

- [ ] `helm lint charts/codesys-pod` passes clean (0 errors)
- [ ] `helm template test-release charts/codesys-pod` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set network.hostNetwork=false` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set sidecarProxy.enabled=true` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set persistence.enabled=false` renders without errors

---

## CI/CD Pipeline Validation

### 7. GitHub Actions Workflow

- [ ] `.github/workflows/helm-publish.yml` exists
- [ ] Triggers on push to `main` with path filter `charts/**`
- [ ] Includes `workflow_dispatch:` for manual triggers
- [ ] Uses `azure/setup-helm@v4`
- [ ] Uses `peaceiris/actions-gh-pages@v4`
- [ ] Packages chart from `charts/codesys-pod` directory
- [ ] Indexes with correct URL: `https://embernet-ai.github.io/Codesys-AMD-64-x86/`
- [ ] Has lint job that runs before publish job
- [ ] Publishes to `.deploy` directory (avoids root pollution)

### 8. Helm Repository Verification

After the workflow runs:

- [ ] `gh-pages` branch updated with new `.tgz` package
- [ ] `index.yaml` on `gh-pages` contains the new version entry
- [ ] URLs in `index.yaml` are **absolute** (not relative)
- [ ] Repository is fetchable:
  ```bash
  helm repo add codesys-amd64-test https://embernet-ai.github.io/Codesys-AMD-64-x86/
  helm repo update
  helm search repo codesys-amd64-test
  ```
- [ ] Chart version in index matches `Chart.yaml` version

---

## Industrial Dashboard Integration

### 9. Dashboard Discovery

- [ ] Dashboard can discover the deployed pod via `embernet.ai/store-app: "true"` label
- [ ] Dashboard shows "CODESYS Control SL (AMD64)" from `gui.displayName` value
- [ ] Dashboard proxy routes to the correct port (`gui-port` label value)
- [ ] WebVisu loads correctly through the Dashboard iframe/proxy
- [ ] WebVisu at `http://<NODE-IP>:8080/webvisu.htm` is accessible (hostNetwork mode)

### 10. Sidecar Proxy Integration (When Enabled)

- [ ] Dashboard reads `gui-port: "8081"` → routes to sidecar
- [ ] Sidecar rewrites absolute asset paths to relative
- [ ] WebVisu loads correctly through Dashboard proxy (not blank screen)
- [ ] WebVisu HMI controls are interactive through the proxy
- [ ] No 404 errors in browser DevTools for WebVisu assets
- [ ] WebSocket connections for real-time visualization updates work

---

## Post-Release Verification

### 11. Deployment Smoke Test

```bash
# Install the chart
helm install codesys charts/codesys-pod -n industrial --create-namespace

# Verify pod is running
kubectl get pods -n industrial -l app.kubernetes.io/name=codesys-pod

# Check all containers are ready (1/1 or 2/2 with sidecar)
kubectl get pods -n industrial -l embernet.ai/store-app=true

# Verify services
kubectl get svc -n industrial -l embernet.ai/store-app=true

# Verify labels on pod
kubectl get pods -n industrial -l embernet.ai/store-app=true -o jsonpath='{.items[0].metadata.labels}' | jq .

# Test WebVisu
curl -s http://<NODE-IP>:8080/webvisu.htm | head -10

# Test Gateway port
nc -zv <NODE-IP> 1217

# Test OPC UA port
nc -zv <NODE-IP> 4840
```

- [ ] Pod starts successfully (init container downloads and installs CODESYS)
- [ ] Main container healthy (CODESYS runtime running)
- [ ] PVCs are bound (persistence enabled by default)
- [ ] Event log shows no warnings or errors

### 12. CODESYS-Specific Functional Verification

- [ ] CODESYS IDE can connect via Gateway port 1217
- [ ] PLC project can be downloaded to runtime
- [ ] WebVisu displays runtime HMI correctly
- [ ] OPC UA Server responds to client connections on port 4840
- [ ] Runtime data persists across pod restarts (via PVC)
- [ ] Resource usage is within expected limits (1Gi RAM, 1 CPU)

---

## Rancher Catalog Annotations Verification

- [ ] `catalog.cattle.io/display-name` is `"CODESYS Control SL (AMD64)"`
- [ ] `catalog.cattle.io/release-name` is `"codesys-pod"`
- [ ] `catalog.cattle.io/certified` is `"partner"`
- [ ] `catalog.cattle.io/namespace` is `"industrial"`
- [ ] `catalog.cattle.io/os` is `"linux"`
- [ ] `catalog.cattle.io/arch` is `"amd64"` (NOT `arm64,amd64` — this is the x86-only variant)
- [ ] `catalog.cattle.io/kube-version` is `">=1.19.0-0"`
- [ ] `catalog.cattle.io/rancher-version` is `">=2.5.0-0"`
- [ ] `catalog.cattle.io/upstream-version` matches `appVersion`

---

## Architecture Differentiation from codesys_arm_64

This chart is the **AMD64/x86 variant**. Key differences from the ARM32 sibling:

| Field | AMD64 (this repo) | ARM32 (codesys_arm_64) |
|-------|-------------------|----------------------|
| Repository | `Codesys-AMD-64-x86` | `codesys_arm_64` |
| `catalog.cattle.io/arch` | `amd64` | `arm64,amd64` |
| `catalog.cattle.io/display-name` | `CODESYS Control SL (AMD64)` | `CODESYS Control ARM32` |
| `gui.displayName` | `CODESYS Control SL (AMD64)` | `CODESYS Control ARM32` |
| `installerUrl` | `...Linux.SL.<ver>.package` | `...Linux.ARM.32.bit.SL.<ver>.package` |

Ensure these remain distinct to avoid cross-architecture confusion in the Dashboard or Rancher catalog.

---

## Rollback Protocol

If the release introduces regressions:

1. **Revert the commit** on `main` branch
2. **CI/CD will republish** the previous chart version to GitHub Pages
3. **On-cluster rollback:**
   ```bash
   helm rollback codesys -n industrial
   ```
4. **Document the issue** in a GitHub Issue with:
   - Chart version that failed
   - Error logs and symptoms
   - Steps to reproduce

---

## Sign-Off

| Field | Value |
|-------|-------|
| Chart Version | `1.2.0` |
| App Version | `4.20.0.0` |
| Base Image | `debian:bullseye` |
| Sidecar Image | `nginxinc/nginx-unprivileged:1.27-alpine` |
| Deployment Strategy | `Recreate` |
| Released By | _______________ |
| Release Date | _______________ |
| Dashboard Verified | ☐ Yes / ☐ No |
| Sidecar Needed | ☐ No (server-rendered WebVisu — evaluate if breaks through proxy) |

---

**🔥 Fireball Industries** — *Ignite Your Factory Efficiency*
