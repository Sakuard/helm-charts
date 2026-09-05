# Helm Charts

Reusable Helm charts published from this repository.

## Add the repository

```sh
helm repo add sakuard https://sakuard.github.io/helm-charts
helm repo update
```

## Install `common`

```sh
helm upgrade --install jarvis sakuard/common \
  --version 0.1.0 \
  --namespace jarvis \
  --create-namespace
```

Pass application-specific settings with one or more `--values` files, as in the
existing `cosparks/infra/helmfile/cosparks/jarvis` deployment.

## Release flow

- Every push to `main` triggers `.github/workflows/release.yaml`.
- If `common/` changes and `common/Chart.yaml`'s `version` also changes, the
  workflow automatically lints, packages, and publishes the chart.
- If `common/` changes but the chart version does not, the workflow displays:
  `chart 有異動，但 helm-chart 版本為更新確定要發佈嗎？`
- Configure the `helm-chart-release` environment with yourself as a required
  reviewer in **Settings → Environments**. The pending job then shows
  **Review deployments → Approve and deploy** as the confirmation button.
- After confirmation, the workflow increments the patch version, commits it to
  `main`, and publishes the chart.
- GitHub Pages must serve the `gh-pages` branch from its repository root. Set
  this once in **Settings → Pages → Deploy from a branch**.

The published repository URL is:

`https://sakuard.github.io/helm-charts`
