# AGENTS.md — django-helm

Standalone Helm chart for the Django app (`docker.io/vaymen/django-app:<commit-id>`) with PostgreSQL via CloudNativePG (`database.mode=cnpg`) or an external DB (`database.mode=external`). App code: `django-app-Exam`; VM variant: `django-ansible-Exam`.

## Layout
- `Chart.yaml`, `values.yaml` (defaults), `values-local.yaml` (kind/minikube), `values-production.yaml`, `values-example.yaml`.
- `templates/` — deployment (with `migrate` init container), service, configmap, secret, serviceaccount, pdb, hpa, ingress, cnpg-cluster, `_helpers.tpl`.

## Commands
```bash
helm lint . --set django.allowedHosts=x.example.com
helm template t . -f values-local.yaml           # must render without errors
helm template t . -f values-production.yaml
helm upgrade --install django-app . -n django --create-namespace -f values-local.yaml --wait --timeout 10m
```
`helm lint` only prints INFO for `required` values; `helm template` is the real check that `django.allowedHosts` is enforced.

## Rules
- No hard-coded environment config in templates; expose it through `values.yaml`.
- `django.allowedHosts` is required and `*` is rejected. Keep that.
- Secrets are never committed. DB credentials come from the operator-generated Secret (or `database.credentialsSecret`); the Django key is generated with `lookup` or comes from `secret.existingSecret`.
- Keep the pod hardened: `runAsNonRoot`, read-only root FS, drop all capabilities, seccomp `RuntimeDefault`, no ServiceAccount token.
- Probes: liveness `/healthz` (no DB), readiness `/readyz` (DB), plus a startup probe.
- `image.tag` is a git commit id; keep `Chart.yaml` `appVersion` in sync. Never default to `latest`.
- CloudNativePG's own chart needs Kubernetes ≥ 1.29 (document older-version workaround in the README, do not vendor it).
- Test every change on a real cluster (kind) before claiming it works. README stays in English.
