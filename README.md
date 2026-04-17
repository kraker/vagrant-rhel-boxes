# vagrant-rhel-boxes

RHEL Vagrant boxes built with [Red Hat Image Builder][rhdocs] (the
`image-builder` CLI, a Tech Preview tool that's Red Hat's officially
documented path for RHEL 10).

RHEL only — Rocky / Alma / Fedora / CentOS Stream are well-served
elsewhere (Bento, the distros' own orgs).

## Status

**Phase 0, just started.** Planning is done; first builds in progress.
See [`PLAN.md`](PLAN.md) for the vision, scope, technical decisions,
and phased rollout.

## How distribution works

Two ways to consume this project, your pick:

1. **Use the published box** (when available — Phase 3+).
   ```sh
   vagrant plugin install vagrant-registration   # required for RHSM at boot
   vagrant init kraker/rhel-10
   vagrant up                                    # prompts for RHSM creds
   ```
   Boxes are unregistered; the `vagrant-registration` plugin handles
   RHSM at first boot using your Red Hat developer account.

2. **Build your own from the recipe.** Clone the repo, supply RHSM
   credentials, run the build script. You get a box registered to you,
   no plugin required at up-time. This is what the [Red Hat docs][rhdocs]
   describe.

The repo IS the recipe; the published boxes are a convenience built
from that same recipe.

[rhdocs]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
