# Changelog — codesys-pod (AMD64/x86)

All notable changes to the CODESYS Control SL (AMD64/x86) Helm chart.

---

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
