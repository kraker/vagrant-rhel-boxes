# vagrant-rhel-boxes

Recipes for building RHEL Vagrant boxes with Red Hat Image Builder
(osbuild). RHEL only — Rocky / Alma / Fedora / CentOS Stream are
well-served elsewhere.

## Status

**Planning phase.** No code yet. See [`PLAN.md`](PLAN.md) for the full
vision, scope, technical decisions, and phased rollout.

## Why recipes, not boxes?

Red Hat's developer subscription is per-account; pre-built RHEL boxes
can't be redistributed. This repo ships the *recipe* — you supply your
own RHSM credentials, run the build locally, and get a box registered
to you. See [Red Hat's Image Builder docs][rhdocs] for the official path
this project implements.

[rhdocs]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
