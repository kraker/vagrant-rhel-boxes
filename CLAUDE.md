# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Builds RHEL Vagrant boxes (libvirt + virtualbox providers) by driving the daemonless `image-builder` CLI from a small Ansible playbook. The resulting `.box` files land under `build/` for inspection or hand-off to a `vagrant box add` step. Playbooks always target `localhost` — the control node *is* the build host. Long-term goal is automating the same playbook from a GitHub Actions self-hosted runner on this machine, with eventual publication of boxes to Vagrant Cloud.

## Setup

Python deps managed with `uv` (Python 3.12+, see `.python-version`):

```bash
uv sync                # creates .venv with ansible-core + ansible-dev-tools + prek
```

Host-side prerequisites (not handled by the playbook):

- `vagrant` from HashiCorp.
- For libvirt provider: `libvirt-devel` + the `vagrant-libvirt` plugin (see README).
- For VirtualBox provider: VirtualBox installed (Oracle's repo on RHEL — non-trivial; the build will fail without it).
- Passwordless sudo for the invoking user, or run with `--ask-become-pass`. The playbook uses `become: true` at the play level because `image-builder build` requires root.
- Active RHEL subscription with BaseOS + AppStream enabled (image-builder pulls from CDN at compose time).
- ~20 GiB free in `/var/cache/`, 4 GiB RAM minimum (per the RHEL 10 docs' system requirements).

The playbook installs `image-builder` itself via dnf — no manual install needed.

## Common commands

```bash
# Build the libvirt box for the default distro (rhel-10.0)
uv run ansible-playbook build_box.yml

# Build the virtualbox box
uv run ansible-playbook build_box.yml -e provider=virtualbox

# Select a different distro — loads blueprints/<distro-family>.toml.j2
# (e.g., rhel-10.0 and rhel-10.1 both render from blueprints/rhel-10.toml.j2)
uv run ansible-playbook build_box.yml -e distro=rhel-10.1

# Stamp a specific version into the rendered blueprint (default is 0.0.1)
uv run ansible-playbook build_box.yml -e box_version=0.1.0

# Lint everything (mirror of CI)
uv run prek run --all-files

# Bring up the resulting box (after a manual vagrant box add)
vagrant up
```

The playbook builds **one provider per invocation** by design — that maps cleanly onto a GitHub Actions matrix where each provider runs as its own job in parallel on the self-hosted runner.

`vagrant box add` is currently commented out at the bottom of `build_box.yml`. Run it manually after a build, e.g. `vagrant box add --force --name kraker/rhel-10 --provider=libvirt build/rhel-10.0-vagrant-libvirt-x86_64/rhel-10.0-vagrant-libvirt-x86_64.box`. Uncomment the task when the box-add step is ready to be part of the pipeline.

`ansible-navigator.yml` keeps the execution environment disabled because playbooks target localhost — running them inside a container would target the container instead of the host.

## Architecture

The build pipeline is **`image-builder` CLI consuming a local blueprint TOML**, with a thin Ansible wrapper for orchestration:

- `inventory` — single line, `localhost ansible_connection=local`. Everything runs on the box you invoke from.
- `blueprints/<distro-family>.toml.j2` — one Jinja2 template per **major** distro version (`rhel-10.toml.j2` covers any `rhel-10.x`; future `rhel-9.toml.j2` would cover `rhel-9.x`, `rocky-10.toml.j2` would cover `rocky-10.x`). The full distro string (e.g. `rhel-10.0`) is interpolated into the template's top-level `distro = "..."` field; image-builder reads it from there. The `version` field is templated from `box_version` so each build can stamp its own (CI passes it from the git tag). Blueprints are otherwise deliberately minimal: the `vagrant-libvirt` and `vagrant-virtualbox` image types already ship a `vagrant` user with sudo and a generous default package set, so blueprints only add things the image type doesn't already provide.
- `build_box.yml` — single playbook at repo root. Runs with `become: true` at the play level. Vars (all overridable with `-e`): `distro` (default `rhel-10.0`), `provider` (default `libvirt`), `box_version` (default `0.0.1`), `output_dir` (`build/`), and `invoking_user` (captured from `$USER` *before* `become` takes effect — `ansible_user_id` would resolve to `root` once we're escalated, making the chown a no-op). `distro_family` is computed from `distro` (`rhel-10.0` → `rhel-10`) and selects which blueprint template to render. Tasks: dnf-install `image-builder`, render `blueprints/<distro_family>.toml.j2` to `<output_dir>/<distro>.toml`, run `image-builder build vagrant-<provider> --blueprint <rendered-path> --output-dir <dir> --with-manifest`, then chown the entire `output_dir` back to `invoking_user` so non-root tasks (and CI artifact upload) can read the result.
- `--with-manifest` is on by default so every build drops an osbuild manifest next to the `.box` for provenance. `--with-sbom` is available too if SPDX SBOMs become a CI requirement; not currently set.
- The build task lives inside a `block` with the chown in an `always` clause, so the chown still runs even when the build fails — partial root-owned artifacts get reclaimed and stay inspectable without sudo, while the playbook still exits non-zero on a build failure (so downstream CI steps skip as expected).
- Artifact path is **deterministic**, written by image-builder directly into `output_dir` (no per-build subdirectory): `build/{distro}-vagrant-{provider}-{arch}.box` plus a sibling `{distro}-vagrant-{provider}-{arch}.osbuild-manifest.json`. For example: `build/rhel-10.0-vagrant-libvirt-x86_64.box`. The playbook does not construct or validate this path; that's image-builder's contract.
- `Vagrantfile` consumes the registered box (`kraker/rhel-10`) and configures both libvirt and virtualbox providers. Synced folder is intentionally disabled.

When changing what's in the image, edit the relevant `blueprints/<distro-family>.toml.j2` (changes apply to every minor version of that major). When changing how the build runs (extra repos, SBOM, distro pinning), edit the `image-builder build` task in `build_box.yml`. When changing what the resulting VM looks like at boot, that's `Vagrantfile`.

### Why this shape

Earlier iterations tried `infra.osbuild` (broken on RHEL 10, see issue #572) and `myllynen.rhel-image` (forces git-hosted blueprints, no local-file mode). Both are wrappers around `composer-cli`, which is the WeldR-socket client for the legacy `osbuild-composer` daemon. The `image-builder` CLI is upstream osbuild's daemonless replacement — same capabilities, no socket, no group membership, single dnf install. Build artifacts (the `.box` files) include the Vagrant metadata.json + Vagrantfile + image, so no separate box-packaging step is needed.

## CI

Two GitHub Actions workflows under `.github/workflows/`:

**`lint.yml`** runs `prek` on every push/PR. Hooks in `.pre-commit-config.yaml`: trailing-whitespace, end-of-file-fixer, check-added-large-files, `uv-lock` (keeps `uv.lock` synced with `pyproject.toml`), `yamllint`, `ansible-lint`. `prek` is a drop-in `pre-commit` reimplementation — same hook IDs and config schema.

**`build.yml`** runs the playbook on the self-hosted runner — triggered by `workflow_dispatch` or by pushes to `main` that touch `blueprints/**`, `build_box.yml`, or the workflow itself. The `build` job is a `provider × distro` matrix (`[libvirt, virtualbox] × [rhel-10]`) with `fail-fast: false`, so a virtualbox failure doesn't abort the libvirt leg. A `package` job runs after with `actions/upload-artifact/merge` to combine the per-leg artifacts into a single `rhel-10-vagrant-boxes` bundle — the merge dance is required because `actions/upload-artifact@v4+` no longer allows multiple jobs to write to the same artifact name. Workflow-level `concurrency: image-builder-${{ github.ref }}` keeps back-to-back commits from racing the matrix against itself; different branches still build in parallel.
