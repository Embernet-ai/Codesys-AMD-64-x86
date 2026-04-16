# Changelog — codesys-pod (AMD64/x86)

All notable changes to the CODESYS Control SL (AMD64/x86) Helm chart.

---

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
