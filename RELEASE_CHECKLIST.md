# 🔥 Release Checklist: codesys-control-for-linux-sl

**EmberNET Helm Chart Release Protocol**
*Fireball Industries, Production Deployment Standard*

---

> **Purpose:** Every chart version that lands on `main` gets published to a public Pages index within a minute, and stations pull it from there. So this list gets walked BEFORE the push, not after. It exists because on 2026-09-27 four versions (2.0.1 through 2.0.4) shipped without anyone opening it, and the `upstream-version` annotation had been lying about the runtime version since August. Every item below has a command. If you did not run the command, the box is not checked.

---

## What This Chart Is Now

`charts/codesys-control-for-linux-sl` deploys CODESYS Control for Linux SL from a **prebuilt image**, `ghcr.io/embernet-ai/codesys-control-sl`. There is no installer, no `installerUrl`, no download and no `dpkg` at pod start. That pattern is dead, and so are the chart names `codesys-pod` and `codesys-app`.

* **The image is built in `Embernet-ai/codesys-packages`**, not here. Its `build-image.yml` builds linux/amd64 and linux/arm64 from `Dockerfile` (base `debian:bookworm-slim`) because that repo can read its own private release assets. This repo's `Dockerfile` and `.github/workflows/build-image.yml` still exist but do not produce the image the chart runs.
* **One chart, two arches.** The image is a manifest index with linux/amd64 and linux/arm64, which is why `catalog.cattle.io/arch` is `amd64,arm64`. The arch annotation may only ever list what the image index actually carries.
* **A seed initContainer** (`seed-workdir`) copies the image's baked `/var/opt/codesys` into the PVC with `cp -an`, once, and never clobbers PLC app or retain data after that. Mounting the PVC straight over that directory would hide the demo license and `bacstac.ini` the image ships.
* **Ports.** 11740/tcp is the runtime port the IDE actually connects to. 4840/tcp is OPC UA. 8080/tcp is the CODESYS web server (WebVisu). 1217/tcp is published for compatibility and never binds, because the runtime package ships no gateway.
* **8080 only listens when there is a WebVisu to serve.** The runtime starts its web server on demand. A fresh pod with no application listens on 4840 and 11740 and nothing on 8080 (measured on `codesys-control-sl:4.22.0.0`, 2026-09-27). So "8080 is dead" on an empty station is not a chart bug; test WebVisu with an application that has a visualization.
* **Privileged, on purpose.** The runtime needs host device nodes for fieldbus, and no capability list grants `/dev`. The waiver comment sits directly above `privileged: true` in `values.yaml`.
* **`hostNetwork` defaults to false** so more than one runtime can live on one node. Turning it on binds the node's real ports and a second instance will not schedule.
* **`runtimeConfig.registerBootApplication` and `runtimeConfig.disableUserMgmtEnforce`** edit `CODESYSControl_User.cfg` at every start and then hand off to the image's `/usr/local/bin/entrypoint.sh`. Both default off. 2.0.3 broke application loading by appending a duplicate `[CmpApp]` section and 2.0.4 fixed it forward the same day; if you touch that script, the test is "a PLC program runs", not "the line got written".
* **Releases created under the old `codesys-app` name** must set `nameOverride: codesys-app` or the PVC gets renamed and the station boots with no application. `charts/LEGACY-RETAINED.txt` keeps `codesys-app-1.6.0.tgz` resolvable in the index for consumers that still pin the old name.

## How the Dashboard Sees It

1. It finds the pod and the Service by `embernet.ai/store-app: "true"`.
2. `embernet.ai/gui-type: "web"` makes it a web app, and `embernet.ai/gui-port` says where: `8080`, or `8081` with the sidecar on.
3. The store card title comes from `catalog.cattle.io/display-name` (`CODESYS Control for Linux SL`) and the card icon from `icon:` in the index entry, loaded with `crossorigin="anonymous"`. That is why the icon lives on this repo's own Pages site, which sends `Access-Control-Allow-Origin: *`.
4. The deployed tile icon comes from the `embernet.ai/app-icon` annotation, pod first, then Service.
5. The Service is named exactly `.Release.Name` and pod and Service both carry `app: <release>`. The launch FQDN is built from the Service name and the node card from the instance label; if those disagree the node card 502s.
6. `tenantLabels` render onto the pod template and the Service. Without `embernet.ai/tenant` on the Service the app is invisible to every tenant scoped view.

Any change to labels, ports, the Service name, or the sidecar touches all of this. Test it through the dashboard, not just a port-forward.

---

## Pre-Release Validation

Run everything from the repo root. `C=charts/codesys-control-for-linux-sl`.

### 1. Version Verification

- [ ] `$C/Chart.yaml` `version` is bumped. Patch for fixes and config tweaks, minor for new non-breaking values, major for breaking changes or a runtime jump that needs station work.
- [ ] `$C/Chart.yaml` `appVersion` is the CODESYS runtime version in the image, e.g. `"4.22.0.0"`.
- [ ] `$C/values.yaml` `image.tag` equals `appVersion`. The tag is pinned on purpose so a chart only bump can never move the runtime; when you move the runtime, move both.
- [ ] `catalog.cattle.io/upstream-version` equals `appVersion`:
  ```bash
  python -c "import yaml;d=yaml.safe_load(open('$C/Chart.yaml'));print(d['appVersion'],d['annotations']['catalog.cattle.io/upstream-version'])"
  # Expected: the same version twice
  ```
- [ ] The image tag exists on GHCR, pulls without credentials, and carries both arches:
  ```bash
  TOK=$(curl -s "https://ghcr.io/token?scope=repository:embernet-ai/codesys-control-sl:pull" | python -c "import sys,json;print(json.load(sys.stdin)['token'])")
  curl -s -H "Authorization: Bearer $TOK" \
    -H "Accept: application/vnd.oci.image.index.v1+json" \
    https://ghcr.io/v2/embernet-ai/codesys-control-sl/manifests/<TAG> \
    | python -c "import sys,json;[print(m['platform']['os'],m['platform']['architecture']) for m in json.load(sys.stdin)['manifests']]"
  # Expected: linux amd64 and linux arm64 (plus unknown unknown attestations)
  # No token or a 401 means the package went private. Clusters pull without
  # credentials, so fix the visibility in the package settings, do not add a pull secret.
  ```
- [ ] `CHANGELOG.md` has an entry for the new version.

### 2. EmberNET Store Labels (The Big Four)

All four labels MUST appear on the **pod template** AND the **Service**, from the `codesys-control-for-linux-sl.storeLabels` helper, never hardcoded.

| Label | Expected Value | Verified? |
|-------|---------------|-----------|
| `embernet.ai/store-app` | `"true"` | ☐ |
| `embernet.ai/gui-type` | `"web"` | ☐ |
| `embernet.ai/app-name` | `"codesys-control-for-linux-sl"` (or the `nameOverride`) | ☐ |
| `embernet.ai/gui-port` | `"8080"`, or `"8081"` with the sidecar | ☐ |

```bash
helm template test-release $C | grep -cE 'embernet.ai/(store-app|gui-type|app-name|gui-port):'
# Expected: 8 (4 labels on the Service, 4 on the pod template)
helm template test-release $C --set sidecarProxy.enabled=true | grep 'gui-port'
# Expected: "8081" twice
helm template test-release $C --set-string 'tenantLabels.embernet\.ai/tenant=acme' | grep -c 'embernet.ai/tenant: acme'
# Expected: 2 (Service and pod template)
helm template test-release $C | grep 'embernet.ai/app-icon'
# Expected: https://embernet-ai.github.io/Codesys-AMD-64-x86/icon.png twice (Service and pod)
```

- [ ] Labels present on pod template and Service
- [ ] `gui-port` switches to the sidecar `listenPort` when `sidecarProxy.enabled: true`
- [ ] `tenantLabels` land on both
- [ ] `embernet.ai/app-icon` on both, and `embernet.ai/display-name` on both when `embernet.displayName` is set

### 3. Network Configuration

- [ ] `network.hostNetwork: false` is the default in `values.yaml`
- [ ] Default render has `dnsPolicy: ClusterFirst`, no `hostNetwork`, no `hostPort`
- [ ] `--set network.hostNetwork=true` renders `hostNetwork: true`, `dnsPolicy: ClusterFirstWithHostNet`, and `hostPort` on 11740, 1217, 4840, and 8080 (plus 8081 with the sidecar)
- [ ] Moved host ports move the runtime too: `--set network.hostNetwork=true --set network.hostPorts.runtime=11750 --set network.hostPorts.opcua=4850 --set network.udpPortIndex=2` renders containerPort equal to hostPort on 11750 and 4850, and the start script writes `ListenPort 11750`, `NetworkPort 4850`, and `DefaultPortIndex 2` into `CODESYSControl_User.cfg`. The Service keeps 11740 and 4840. With hostNetwork off the same flags change nothing.

```bash
helm template test-release $C | grep -E "hostNetwork:|dnsPolicy|hostPort"
helm template test-release $C --set network.hostNetwork=true | grep -E "hostNetwork:|dnsPolicy|hostPort"
```

### 4. Service Configuration

- [ ] Service type is `ClusterIP` by default
- [ ] Service `metadata.name` is `{{ .Release.Name }}`, not the fullname helper (`helm template test-release $C` must show `name: test-release` on the Service)
- [ ] Service selector uses `codesys-control-for-linux-sl.selectorLabels`
- [ ] `nodeSelector: {}` exists in `values.yaml` and reaches the Deployment (`--set 'nodeSelector.kubernetes\.io/hostname=n1'` renders it)
- [ ] Service exposes runtime 11740, gateway 1217, opcua 4840, webvisu 8080, and proxy-http 8081 only with the sidecar
- [ ] Deployment strategy is `Recreate` (RWO PVC plus optional host ports deadlock a RollingUpdate)

### 5. Sidecar Proxy

WebVisu is server rendered, so the sidecar is **off by default**. Turn it on only if WebVisu breaks through the dashboard proxy. When it is on it has to follow the header gated rewrite standard: no `X-Embernet-Proxy-Prefix` header means the page passes through byte identical, the header means every rewritten path carries the dashboard's prefix. Never hardcode `/api/proxy`.

- [ ] `sidecarProxy.enabled: false` is the default and `configmap-sidecar-proxy.yaml` renders nothing without it
- [ ] Both `map $http_x_embernet_proxy_prefix` blocks are in `http {}` and every `sub_filter` replacement uses `$embernet_root`
- [ ] `sub_filter_once off;`, `proxy_set_header Accept-Encoding "";`, and the WebSocket `Upgrade`/`Connection` headers with the `$connection_upgrade` map are present
- [ ] The sidecar is the **last** container and its probes hit `/sidecar-health`
- [ ] `gui.type` is still `"web"`

```bash
helm template test-release $C --set sidecarProxy.enabled=true \
  | grep -nE 'map \$http_x_embernet_proxy_prefix|sub_filter_once|Accept-Encoding|connection_upgrade|sidecar-health|^ +- name:'
```

### 6. Chart Linting and Templating

Every one of these, every release. Paste the output in the PR or the commit body.

- [ ] `helm lint $C` and `helm lint $C --set sidecarProxy.enabled=true` pass with 0 failed
- [ ] `helm template test-release $C` renders
- [ ] `helm template test-release $C --set network.hostNetwork=false` renders
- [ ] `helm template test-release $C --set network.hostNetwork=true` renders
- [ ] `helm template test-release $C --set sidecarProxy.enabled=true` renders
- [ ] `helm template test-release $C --set persistence.enabled=false` renders, with `emptyDir: {}` and no PersistentVolumeClaim
- [ ] `helm template test-release $C --set runtimeConfig.registerBootApplication=true --set runtimeConfig.disableUserMgmtEnforce=true` renders and the command ends in `exec /usr/local/bin/entrypoint.sh`
- [ ] The publish workflow's own gates pass locally: chart directory, `name:`, and `catalog.cattle.io/release-name` all agree, and no chart file has a CR byte (`find charts -type f -exec sh -c 'tr -cd "\r" < "$1" | wc -c' _ {} \;` prints only zeros)
- [ ] App invariants pass the way `.github/workflows/app-invariants.yml` runs them: `python .ci/test-check-app-invariants.py` (32/32), then `python .ci/check-app-invariants.py charts` (0 violations)

---

## CI/CD Pipeline Validation

### 7. GitHub Actions Workflow

- [ ] `.github/workflows/helm-publish.yml` triggers on push to `main` for `charts/**` and `icon.png`, plus `workflow_dispatch:`
- [ ] Uses `azure/setup-helm@v4` and `peaceiris/actions-gh-pages@v4`
- [ ] The lint job (helm lint of every `charts/*`, the name check, the CRLF check) runs before publish
- [ ] Publish packages every `charts/*` into `.deploy`, copies the tarballs listed in `charts/LEGACY-RETAINED.txt` from Pages (a listed file that is missing is a hard error), and builds the index from `.deploy` with `--url https://embernet-ai.github.io/Codesys-AMD-64-x86/`. Never `helm repo index --merge`: merging is what kept resurrecting dead entries whose tarballs 404.
- [ ] `icon.png` is copied next to `index.yaml`, and a missing `icon.png` fails the job

### 8. Helm Repository Verification

After the workflow runs:

- [ ] `index.yaml` on Pages lists the new version with an **absolute** URL, and `codesys-app` 1.6.0 is still there for as long as `LEGACY-RETAINED.txt` lists it
- [ ] Every version that was in the index before the push is still in it. Save `index.yaml` before you push and compare after. The index is rebuilt from the chart directories, so the version you just replaced drops out unless its tarball is on `LEGACY-RETAINED.txt`; add it there in the same release.
- [ ] The published tarball is what `main` holds:
  ```bash
  curl -sO https://embernet-ai.github.io/Codesys-AMD-64-x86/codesys-control-for-linux-sl-<VERSION>.tgz
  mkdir pub && tar -xzf codesys-control-for-linux-sl-<VERSION>.tgz -C pub
  diff -r -x Chart.yaml pub/codesys-control-for-linux-sl $C && echo templates and values identical
  # helm reserializes Chart.yaml; compare it with yaml.safe_load instead of diff
  ```
- [ ] The icon serves with CORS: `curl -sI https://embernet-ai.github.io/Codesys-AMD-64-x86/icon.png` shows `200` and `Access-Control-Allow-Origin: *`
- [ ] The repo resolves:
  ```bash
  helm repo add codesys-amd64-test https://embernet-ai.github.io/Codesys-AMD-64-x86/
  helm repo update
  helm search repo codesys-amd64-test
  # Expected: codesys-control-for-linux-sl at the new version, appVersion equal to Chart.yaml
  ```

---

## On a Cluster

**Never test in a namespace that runs a live station.** Stations run this chart in production, and a test install next to one is a good way to find out what Recreate does to a PLC mid cycle. Use a throwaway namespace (`ember-verify`), install from the published index at the exact version, and delete the release and namespace when done.

### 9. Dashboard Integration

- [ ] The dashboard discovers the release by `embernet.ai/store-app: "true"`
- [ ] The store card says `CODESYS Control for Linux SL` and shows the CODESYS logo, not a blank square
- [ ] The deployed tile shows the logo from `embernet.ai/app-icon`
- [ ] The launch routes to `gui-port` and, with an application that has a WebVisu loaded, WebVisu renders through the dashboard on its own hostname and on the `/api/proxy` fallback
- [ ] A tenant user (not SuperAdmin) sees the app when the store injected `tenantLabels`

### 10. Sidecar Proxy Integration (When Enabled)

- [ ] `gui-port` is `8081` and the dashboard routes to the sidecar
- [ ] With no prefix header the page matches upstream; with the header every `href`, `src`, `action`, quoted `/api/`, `/webvisu`, and `url()` carries the prefix
- [ ] WebVisu controls work and live values update (WebSocket through the sidecar)
- [ ] No 404s for WebVisu assets in browser DevTools

### 11. Deployment Smoke Test

```bash
helm repo add codesys-control-sl https://embernet-ai.github.io/Codesys-AMD-64-x86/ && helm repo update
helm install cds-verify codesys-control-sl/codesys-control-for-linux-sl --version <VERSION> \
  -n ember-verify --create-namespace --wait --timeout 5m

kubectl -n ember-verify get pods -l app.kubernetes.io/instance=cds-verify
kubectl -n ember-verify logs deploy/cds-verify-codesys-control-for-linux-sl -c seed-workdir
kubectl -n ember-verify get pvc,svc -l app.kubernetes.io/instance=cds-verify
kubectl -n ember-verify get svc cds-verify --show-labels
kubectl -n ember-verify get events --field-selector type=Warning

# Which ports the runtime actually opened (hex 2DDC = 11740, 12E8 = 4840, 1F90 = 8080)
kubectl -n ember-verify exec deploy/cds-verify-codesys-control-for-linux-sl -- cat /proc/net/tcp

helm uninstall cds-verify -n ember-verify && kubectl delete ns ember-verify
```

- [ ] Pod is Running and 1/1 (2/2 with the sidecar)
- [ ] `seed-workdir` logged the seeded contents of `/seed`
- [ ] PVC is Bound
- [ ] Service `cds-verify` exists with the store labels
- [ ] 11740 and 4840 are listening; 8080 appears once a WebVisu application is loaded
- [ ] No Warning events

### 12. CODESYS Functional Verification

- [ ] The CODESYS IDE connects on port **11740** (1217 does not bind, that is expected)
- [ ] A PLC project downloads and runs, and after a pod delete it comes back running from the PVC
- [ ] WebVisu displays the HMI
- [ ] An OPC UA client connects on 4840 (anonymous sessions need `runtimeConfig.disableUserMgmtEnforce=true` or rights granted from the IDE)
- [ ] With `runtimeConfig.registerBootApplication=true` and an `Application.app` copied in by file, the application loads after a restart and the cfg has exactly one `[CmpApp]` section
- [ ] Usage stays inside the limits (1 CPU, 1Gi)

---

## Rancher Catalog Annotations

- [ ] `catalog.cattle.io/display-name` is `"CODESYS Control for Linux SL"`
- [ ] `catalog.cattle.io/release-name` is `codesys-control-for-linux-sl` (the lint job enforces this)
- [ ] `catalog.cattle.io/certified` is `partner`
- [ ] `catalog.cattle.io/namespace` is `industrial`
- [ ] `catalog.cattle.io/os` is `linux`
- [ ] `catalog.cattle.io/arch` is `amd64,arm64`, and only while the image index carries both
- [ ] `catalog.cattle.io/kube-version` is `">=1.19.0-0"`
- [ ] `catalog.cattle.io/rancher-version` is `">=2.5.0-0"`
- [ ] `catalog.cattle.io/upstream-version` equals `appVersion`

---

## When a Release Is Bad: Fix Forward

We do not roll back. Not the commit, not the cluster.

* **Do not revert `main`.** The index is rebuilt from `main`, so a revert publishes an older chart as the newest one, the store sees a version go backwards, and every station already on the newer version is now running something the index does not list, because nothing retains a version that was never replaced.
* **Do not `helm rollback`.** It puts the cluster on a revision that neither `main` nor the index describes, and the next upgrade from the store quietly undoes it.
* **Ship the next patch version with the fix.** Same checklist, all of it. 2.0.3 stopped applications from loading; 2.0.4 went out the same afternoon and put the settings back inside the sections the runtime actually reads. Nobody rolled anything back. That is the whole procedure.
* **Write it down** in the new version's CHANGELOG entry: what broke, how it was found, and how the fix was verified.

---

## Sign-Off

| Field | Value |
|-------|-------|
| Chart | `codesys-control-for-linux-sl` |
| Chart Version | `2.1.0` |
| App Version | `4.22.0.0` |
| Image | `ghcr.io/embernet-ai/codesys-control-sl:4.22.0.0` (linux/amd64, linux/arm64) |
| Base Image | `debian:bookworm-slim` (built in `Embernet-ai/codesys-packages`) |
| Sidecar Image | `nginxinc/nginx-unprivileged:1.27-alpine` (off by default) |
| Deployment Strategy | `Recreate` |
| Released By | _______________ |
| Release Date | _______________ |
| Dashboard Verified | ☐ Yes / ☐ No |
| Checked in `ember-verify`, not a live namespace | ☐ Yes |

---

**🔥 Fireball Industries**, *Ignite Your Factory Efficiency*
