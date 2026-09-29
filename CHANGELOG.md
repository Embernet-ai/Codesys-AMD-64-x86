# Changelog — codesys-pod (AMD64/x86)

All notable changes to the CODESYS Control SL (AMD64/x86) Helm chart.

---

## [2.2.0] (2026-09-29), chart `codesys-control-for-linux-sl`

### Fixed

- **The runtime no longer squats port 1217.** This chart declared a `gateway`
  port on 1217 that the runtime has never bound, because the Control SL package
  ships no gateway. That was written off as harmless compatibility. It was not.
  Under `hostNetwork` a declared port becomes a `hostPort`, and the scheduler
  reserves a hostPort whether or not a process ever listens on it, so the node's
  1217 was held by a socket that did not exist and a real
  `codesys-edge-gateway-for-linux` could never be placed beside the runtime.
  Found on `crane-cp-01`, where `ss -ltn` showed nothing on 1217 while the
  Deployment reserved it and the gateway the CODESYS IDE connects to had nowhere
  to go. 1217 is now rendered nowhere: not as a containerPort, not as a
  hostPort, and not on the Service, which had been advertising a port that
  refused every connection. Same call the Edge Gateway chart made in 2.2.0 when
  it dropped WebVisu and OPC UA from its own Service.

  2.1.0 shipped `network.hostPorts.gateway` to move the phantom out of the way.
  That worked, but it made every operator learn a workaround for a port that
  should never have been declared, so it is fixed at the source instead.

  `service.ports.gateway` and `network.hostPorts.gateway` both stay as keys and
  are inert. An existing values file that sets either still parses and still
  means what it always did, which is nothing. Nothing else moves: 11740, 4840
  and 8080 render exactly as they did in 2.1.0, and with the gateway key out of
  the host-port helper a pod that sets no other port knob goes back to running
  the image ENTRYPOINT verbatim instead of the config wrapper.

## [2.1.0] (2026-09-27), chart `codesys-control-for-linux-sl`

### Added

- **Every host port can move, and the runtime moves with it.** With
  `network.hostNetwork: true` the pod shares the node's network, so a second
  CODESYS runtime on the node (Virtual Control binds the same 11740 and 4840),
  an Edge Gateway (1217), or Telegraf (8080) cannot schedule next to it.
  `network.hostPorts.runtime`, `.opcua`, and `.gateway` move the
  containerPort and hostPort together (Kubernetes rejects a hostNetwork pod
  where they differ), and the start script writes the matching key into
  `CODESYSControl_User.cfg`: `[CmpBlkDrvTcp] ListenPort` and
  `[CmpOPCUAServer] NetworkPort`. `network.udpPortIndex` (0 to 3) sets
  `[CmpBlkDrvUdp] DefaultPortIndex`, which picks UDP 1740 to 1743; the runtime
  binds that port without declaring it, so the scheduler could never see that
  clash. Each key was proven on `codesys-control-sl:4.22.0.0` by setting it and
  watching `ss`. The Service keeps its ports. Empty (the default) renders
  exactly what 2.0.4 did, in every toggle combination tried; all of them are
  ignored when hostNetwork is off. There is no knob for WebVisu's 8080: its
  web server only starts with a WebVisu application running, so its port key
  could not be proven.

### Fixed

- **`catalog.cattle.io/upstream-version` says 4.22.0.0.** It was left at
  4.20.0.0 when 1.5.0 moved the runtime to 4.22.0.0 and rode along through
  every release since, so Rancher and the store showed a runtime version the
  chart has not shipped in a month. The release checklist requires the
  annotation to match `appVersion`. This was held as 2.0.5 and never shipped on
  its own, so it goes out here. It is Chart.yaml metadata only; no render moves
  because of it.

## [2.0.4] (2026-09-27), chart `codesys-control-for-linux-sl`

### Fixed

- **2.0.3 stopped the boot application from loading.** It appended its own
  `[CmpApp]` and `[CmpUserMgr]` sections, but the 4.22 image already ships
  both, and the runtime only reads the first copy of a section. The first
  station moved to 2.0.3 came up "CODESYS Control ready" with its
  `Application.app` on disk and no application running. Each setting now goes
  into the existing section (right under its first header, where the 1.x chart
  put it and where it worked) and a new section is written only when the file
  has none. Verified on `codesys-control-sl:4.22.0.0`: one section each, the
  line inside it, and a re-run changes nothing.

## [2.0.3] (2026-09-27), chart `codesys-control-for-linux-sl`

### Fixed

- **The runtime config bootstrap skipped the image's entrypoint.** With
  `runtimeConfig.registerBootApplication` or `disableUserMgmtEnforce` on, the
  chart replaced the container command and exec'd `codesyscontrol.bin`
  itself, so `pre_start.sh` never ran and the runtime started without
  `LD_LIBRARY_PATH=/opt/codesys/lib` or `PRODUCT`, the launch contract the 4.22
  image's `entrypoint.sh` reproduces from the vendor's systemd unit. It hands
  off to `/usr/local/bin/entrypoint.sh` now.
- **Both edits could silently do nothing.** They used
  `sed '/^\[CmpApp\]/a ...'`, which adds nothing when the section is not
  already in the file. Each edit appends its own section now, still guarded by
  grep so restarts do not stack duplicates.
- **The boot application is only registered when it exists.** Registering
  `Application` with no `Application.app` on disk points the runtime at nothing.

Verified against `ghcr.io/embernet-ai/codesys-control-sl:4.22.0.0` with the
entrypoint overridden the way a pod `command` does it: both lines land in
`CODESYSControl_User.cfg`, `pre_start.sh` reports OK, PID 1 is
`codesyscontrol.bin` with the library path and product set, and a second pass
adds nothing. Same logic a live rootless Podman station was already running.

## [2.0.2] (2026-09-27), chart `codesys-control-for-linux-sl`

### Changed

- Comments in the published chart no longer name a customer, a site, or a
  station. The chart is served from a public Pages site, and nine comment lines
  in `values.yaml`, `deployment.yaml`, and `service.yaml` carried them. The
  technical content of each note is unchanged, and the rendered manifests are
  identical to 2.0.1 apart from the version label.

## [2.0.1] (2026-09-27), chart `codesys-control-for-linux-sl`

### Fixed
- **Icon is the CODESYS logo.** `Chart.yaml` `icon` was the avatar of the
  CODESYS-examples GitHub org. It now points at
  `https://embernet-ai.github.io/Codesys-AMD-64-x86/icon.png`, this repo's
  `icon.png`, which `helm-publish.yml` now copies next to `index.yaml`.
  github.io sends CORS, so the store card renders it.
- **Deployed tile icon.** The pod and the Service carry
  `embernet.ai/app-icon` from the chart icon. Neither had one.
- **Sidecar rewrites are header gated** (sidecar is still off by default).
  Every replacement goes through `$embernet_root`, mapped from
  `X-Embernet-Proxy-Prefix`: no header, the page and its CSS pass through
  byte identical apart from the existing `<base href>`; with the header,
  every path carries the dashboard's prefix. The old `./` rewrite broke
  nested pages at root and `url()` inside stylesheets.

### Unchanged on purpose
- `codesys-app` stays in the index through `charts/LEGACY-RETAINED.txt`. Its
  retained 1.6.0 tarball still carries the old icon, because it is the
  already-published file.

---

## [1.5.0] — 2026-08-27

### Changed
- **Default runtime 4.20.0.0 → 4.22.0.0**, and the default image moves from
  `ghcr.io/embernet-ai/codesys-sl` to
  **`ghcr.io/embernet-ai/codesys-control-sl`**.
- The image is now built by **`Embernet-ai/codesys-packages`**, not by this
  repo's `build-image.yml`. That workflow fetches the `.package` with an
  unauthenticated `curl`, which only works against a *public* release; the
  4.22.0.0 assets live on `codesys-packages`, which is private, so it 404s.
  Its default URL also still points at `codesys-linux-x86`, a repo that no
  longer exists. A workflow running *inside* `codesys-packages` reads its own
  private release with the built-in `GITHUB_TOKEN`, needing no PAT and no
  repository visibility change.
- `image.tag` is now pinned explicitly instead of falling back to
  `Chart.appVersion`, so a chart-only version bump cannot silently move the
  PLC runtime.

### Notes
- 4.22 is **not** a drop-in rebuild of 4.20. Its `.deb` adds
  `Depends: systemd (>= 240)` and ships
  `/etc/systemd/system/codesyscontrol.service` in place of
  `/etc/init.d/codesyscontrol`. `ExecStart` is unchanged, but the unit adds an
  `ExecStartPre` hook, `User=codesyscontrol`, and an `LD_LIBRARY_PATH`. See
  `codesys-packages`' Dockerfile and `entrypoint.sh`.
- Verified running on `ut3-cp-em-0001` (tenant `tranetech-ut3`) before release.

## [1.2.0] — 2026-04-16

### Changed
- **Sidecar proxy image**: `nginx:1.25-alpine` → `nginxinc/nginx-unprivileged:1.27-alpine`
  - Standard nginx crashes with `readOnlyRootFilesystem: true` (cannot write to `/var/cache/nginx`, `/var/run`)
  - `nginx-unprivileged` is designed for rootless/read-only operation
- **Sidecar securityContext**: `runAsUser/runAsGroup: 101` → `65534` (nobody)
  - Aligns with `nginx-unprivileged` default user

### Added
- **Deployment strategy**: `strategy.type: Recreate`
  - Prevents RWO PVC scheduling deadlock when using `hostNetwork: true`
  - RollingUpdate causes new pod to fail scheduling because old pod holds host ports on the only eligible node
- **Sidecar writable volumes**: `/var/cache/nginx` (emptyDir 64Mi), `/var/run` (emptyDir 1Mi)
  - nginx-unprivileged requires these writable directories even with read-only root
- **CHANGELOG.md**: Created for audit trail (this file)

### Fixed
- `.gitignore`: Cleaned up to exclude stale Helm build artifacts (`*.tgz`, `index.yaml`) from main branch

---

## [1.1.0] — 2026-04-15

### Added
- Full EmberNET template alignment
- EmberNET store labels (Big Four) on pod template and Service
- Sidecar proxy scaffolding (disabled by default)
- `configmap-sidecar-proxy.yaml` with CODESYS WebVisu-specific rewrite rules
- `RELEASE_CHECKLIST.md` — full release protocol
- `hostNetwork: true` default with conditional `dnsPolicy`
- `hostPort` bindings for all three CODESYS ports (1217, 4840, 8080)
- Multi-port Service (gateway, opcua, webvisu)
- CI/CD workflow with lint job + publish job + merge-based index

### Changed
- Chart restructured to `charts/codesys-pod/` directory layout
- CI/CD workflow uses `.deploy/` staging directory (avoids root pollution)

---

## [1.0.x] — Pre-alignment

- Initial chart versions (archived in `_archive/`)
- Basic deployment with installer pattern
- No EmberNET store labels
- No sidecar proxy support
- CI/CD without lint stage

---

**🔥 Fireball Industries** — *Ignite Your Factory Efficiency*
