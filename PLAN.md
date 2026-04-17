# RHEL Vagrant Boxes — Project Plan

> Working title only. The eventual GitHub repo name is TBD.
> Captured 2026-04-16. Revised same day after two strategic narrowings:
> (1) Image Builder picked over Packer; (2) scope narrowed to RHEL only,
> dropping Rocky/Alma/Fedora/CentOS Stream from the original RHEL family
> charter.

A community-maintained collection of **RHEL Vagrant box recipes** — built
with Red Hat's own Image Builder (osbuild), shipped as blueprints and
build scripts (not binaries), produced for the dev/lab community gap
that no one currently fills.

This document captures the project's vision, scope, technical decisions,
phased plan, and open questions. It lives outside the eventual repo so
the planning history is traceable separately from the codebase.

---

## 1. Vision & Goals

**What we're building**: a single Git repo that contains osbuild
blueprints and build scripts for producing RHEL Vagrant boxes. Users
clone the repo, supply their own Red Hat developer credentials, and
run a build. The repo is the recipe; the user produces the binary.

**Strategic context — Red Hat consulting pivot (2026)**: this is one
prong of a broader pivot into Red Hat consulting. The choice of Image
Builder over Packer is deliberate: Image Builder is Red Hat's official
path, is barely covered in blog content, and producing demonstrated
expertise with it directly supports the consulting brand. The
RHEL-only scope sharpens the identity further — this is "the Red Hat
way to RHEL Vagrant boxes," nothing else.

**Audience**: primarily learners and DevOps practitioners — RHCSA / RHCE
candidates, sysadmins moving up the stack, homelab people graduating
into real ops work, and the consulting customers those people become.
Not in tension with the consulting-brand framing: that audience *is*
the consulting target audience, just earlier in their journey. The tone
of docs and articles should be approachable, not academic. Geerling's
voice is the closest reference point: serious technical depth, low
ceremony.

**Why RHEL only**:
- **Rocky, Alma, Fedora, and CentOS Stream are already well-served.**
  Bento publishes Rocky 10 and Alma 10. AlmaLinux and Rocky orgs
  publish their own. Fedora has osbuild itself + community boxes.
  Adding more there is duplicative.
- **RHEL is the actual gap.** `generic/rhel*` has stalled (see
  [Roboxes notes](https://github.com/lavabit/robox/issues/306)). Bento
  deliberately doesn't publish RHEL because of EULA constraints. The
  Roboxes pattern (unregistered binary + `vagrant-registration`) is in
  decline.
- **Focus is the brand.** "I publish a bunch of Vagrant boxes" is
  forgettable. "I built the modern, official-Red-Hat-tooling path for
  RHEL Vagrant boxes" is memorable.
- **Tie to the book.** "The RHCSA Field Manual" needs a RHEL 10 dev
  environment for its executable `{bash}` snippets. This project
  produces what that book's reader needs — and the book's reader is
  exactly the consulting brand's target audience.

**Inspiration / prior art**:
- [osbuild project](https://osbuild.org/) — the upstream tool.
- [Red Hat docs: Creating Vagrant boxes with RHEL image builder (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder)
- [chef/bento](https://github.com/chef/bento) — model for repo
  structure (uses Packer, builds Rocky/Alma not RHEL).
- [lavabit/robox](https://github.com/lavabit/robox) — the cautionary
  tale; the project this work effectively replaces for RHEL.

---

## 2. Scope

### In scope

| Distro | Versions | Publishing model |
|---|---|---|
| RHEL | 10 (priority), 9 (later) | Recipes only — blueprint + build script |

That's the entire matrix.

### Providers

| Provider | Phase | Notes |
|---|---|---|
| libvirt | Phase 0 | First-class osbuild output type; KVM is native to a Linux build host |
| VirtualBox | Phase 1 | First-class osbuild output type in RHEL 10.1+ |
| VMware Fusion / Workstation | Maybe later | Not a first-class osbuild output |
| Parallels | Out of scope | Not a first-class osbuild output |
| Hyper-V | Out of scope | Same |

### Architectures

- amd64 / x86_64 (primary)
- aarch64 / arm64 (secondary, blocked on ARM build hardware)

### Out of scope

- **Rocky Linux, AlmaLinux, CentOS Stream, Fedora.** All already served
  by other projects. Producing more would duplicate.
- **Debian / Ubuntu / Arch / BSD.** Image Builder doesn't speak them;
  also off-brand for a Red Hat-focused project.
- **Cloud images** (AMI, GCE, Azure). osbuild can produce them but
  they're a different audience.
- **Containers.** Different project.

---

## 3. The Distribution Model: Hybrid (Recipe Source + Unregistered Binaries)

This is the central architectural decision and the most important
thing to understand about the project.

### The RHEL EULA constraint

Red Hat's developer subscription is per-account. A RHEL box that's
been *registered to RHSM during build* cannot be redistributed
without violating the subscription terms. This is why:

- Bento publishes Rocky 10 and Alma 10 but **never** RHEL.
- Roboxes' `generic/rhel*` boxes were always **unregistered** and
  required the user to register at `vagrant up` time via the
  `vagrant-registration` plugin — a tolerated gray area Red Hat
  could revisit at any time.

### The hybrid model (chosen)

The repo serves two audiences in one design:

1. **The recipe.** Anyone can `git clone` the repo and build their
   own box from the blueprint, registered to their own RHSM account.
   Zero redistribution concerns. This is how RHEL itself documents
   the [Image Builder Vagrant path](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder).
2. **Pre-built, unregistered boxes.** CI builds the recipe and
   publishes the resulting boxes to HCP Vagrant Registry (primary)
   and GitHub Releases (backup). Users can `vagrant init kraker/rhel-10`
   and `vagrant up`; the `vagrant-registration` plugin handles RHSM
   at boot time. This is the Roboxes model — gray area but tolerated
   for years.

The recipe is the substantive contribution; the binaries are a
convenience that gets the project into the same ergonomic territory
as `bento/rockylinux-10`.

### What that implies for the repo

- **`.box` files DO get published**, to HCP Vagrant Registry +
  GitHub Releases. Boxes are unregistered; `vagrant-registration`
  plugin is a documented prerequisite.
- **The repo also stands alone as a recipe.** `git clone`, set RHSM
  env vars, `./scripts/build.sh` produces a box locally without
  needing the published artifact.
- **CI does both jobs**: validate the recipe (PR smoke-test) AND
  publish releases (on tag push).
- **No paid hosting.** HCP Vagrant Registry's free tier and GitHub
  Releases are the entire distribution surface. If/when traffic
  outgrows free tiers, that's a happy problem to solve later.

---

## 4. Build Toolchain: RHEL Image Builder (`image-builder` CLI)

### Decision

RHEL Image Builder is the toolchain. Within the Image Builder family
there are two CLI options; we pick the newer `image-builder` CLI over
the older `composer-cli`. Packer was considered and rejected.

### The two Image Builder CLIs

Red Hat ships two command-line interfaces to the same underlying
osbuild engine:

| | `composer-cli` | `image-builder` |
|---|---|---|
| Status | GA | **Technology Preview** (RHEL 10.0+) |
| Architecture | Client/server with `osbuild-composer.service` daemon | Daemonless |
| Workflow | Push blueprint → start compose → poll → fetch | Single `image-builder build` command |
| Container-friendly | No | Yes (designed for ephemeral pipelines) |
| State | Persistent (daemon holds blueprints/composes) | Stateless |
| Surface in RHEL 10 docs | Legacy reference path | The path the doc leads with |

Both CLIs consume the same TOML blueprints and produce the same image
types — so the choice between them is operational, not architectural.
A switch later is a script change, not a re-architecture.

### Why `image-builder` over `composer-cli`

1. **Simplicity is real.** The full Vagrant build is one command:
   `sudo image-builder build --distro rhel-10.0 vagrant-libvirt`. With
   composer-cli you manage a daemon, push the blueprint, kick off a
   compose, poll for status, and fetch the artifact — five commands
   and stateful daemon management.
2. **Daemonless = better for CI.** The self-hosted GitHub Actions
   runner has no service to register, manage, or recover. Each build
   is a clean process tree that exits when done.
3. **Container-friendly.** `image-builder` is designed for use inside
   containers. Doors stay open for ephemeral CI builds even if we
   don't use them initially.
4. **Red Hat is leading with it.** The entire RHEL 10 documentation
   for image building is written around `image-builder`, not
   composer-cli — even chapters covering KVM, cloud uploads, Vagrant,
   and OpenSCAP integration. The Tech Preview label is procedural;
   the editorial decision is "this is the way."
5. **Brand and content alignment.** Being early on a Tech Preview
   tool that's clearly the future is exactly the kind of leading-edge
   positioning the consulting brand benefits from. "Here's how to use
   the new official RHEL build tool" is more interesting than
   "here's how to use the old one."

### Why Image Builder over Packer

1. **Brand alignment.** Demonstrating mastery of Red Hat's *official*
   tooling is the entire point of this project as a consulting-brand
   artifact. Picking Packer would put this project alongside ten
   others; Image Builder puts it nearly alone.
2. **Content opportunity.** "Packer Vagrant box tutorial" returns
   hundreds of articles. "image-builder Vagrant box" returns Red
   Hat's docs and almost nothing else.
3. **Faster builds, simpler recipes.** Image Builder composes from
   packages; builds are minutes, not tens of minutes. TOML blueprints
   are dramatically smaller and more declarative than HCL templates +
   kickstart files.
4. **First-class Vagrant box output.** RHEL 10.0+ ships
   `vagrant-libvirt` and `vagrant-virtualbox` as native image types
   — no manual box wrapping.
5. **No HashiCorp licensing concerns.** osbuild is Apache 2.0 / GPL.
   Packer is BUSL since 2023.

### Trade-offs to manage

- **Tech Preview status.** `image-builder` could change incompatibly
  before GA. Mitigation: pin to a known-good version on the build
  host; the blueprints themselves are stable across CLIs (composer-cli
  consumes the same TOML). Worst case we swap the build script.
- **Build host constraint**: every runner that does an actual build
  must be RHEL/Fedora/Rocky/Alma. GitHub-hosted Ubuntu runners can't
  run image-builder. Mitigation: self-hosted runner on the homelab
  build node.
- **Single provider per build**: producing both libvirt and VirtualBox
  boxes for one RHEL version means two `image-builder build`
  invocations, not one. CI handles this with a build matrix.
- **Less of a community safety net**: when something breaks, the
  references are Red Hat docs and the osbuild GitHub issues. Plan for
  more independent debugging — also the content opportunity.

---

## 5. Repository Structure

Single GitHub repo, RHEL-only, deliberately small.

```
vagrant-rhel-boxes/                 # repo root
├── README.md                       # quickstart: clone, source creds, make build
├── LICENSE                         # Apache-2.0 (matches osbuild upstream)
├── blueprints/
│   ├── rhel-10.toml                # current focus
│   └── rhel-9.toml                 # later
├── scripts/
│   ├── build.sh                    # wraps `image-builder build` for one (version, provider) build
│   ├── lib/                        # shared bash helpers
│   └── ci/                         # CI smoke-test entry points
├── customizations/                 # post-compose tweaks (vagrant user, sudoers)
│   ├── vagrant-user.sh
│   └── common.sh
├── .github/workflows/
│   └── smoke-test.yml              # validates the recipe builds end-to-end
├── docs/
│   ├── quickstart.md               # short — points back at README
│   ├── architecture.md
│   ├── why-image-builder.md        # the toolchain decision article, in-tree
│   ├── why-recipes-only.md         # the EULA reasoning, in-tree
│   └── rhsm-credentials.md         # how to get + manage RHSM creds
└── PLAN.md                         # this doc, copied in once repo exists
```

### Naming conventions

- Blueprint files: `rhel-<major>-<minor>.toml` if minor matters, else
  `rhel-<major>.toml`.

---

## 6. Build Infrastructure

### Build hardware: homelab

- **Phase 0 / prototyping (now)**: local Fedora workstation. `image-builder`
  runs natively on Fedora. The wrinkle is that building RHEL images
  from a Fedora host needs RHSM credentials plus repo overrides
  pointing at RHEL CDN — the host's own Fedora repos can't satisfy
  RHEL package requests.
- **Phase 2+ (later)**: dedicated build node in the homelab on RHEL 10
  or Rocky 10. Aspirational — moves CI builds off the workstation and
  exercises the same OS the eventual users would be on.
- **Image Builder is daemonless.** No `osbuild-composer.service` to
  manage on either host.
- Required: nested virt for VirtualBox compose, ≥32 GB RAM, ≥500 GB
  SSD, 8+ cores comfortable. (Workstation likely has all of this.)
- KVM/libvirt enabled (default on Fedora and RHEL family).

### CI: GitHub Actions + self-hosted runner

- **Self-hosted runner on the homelab build node** for the actual
  builds. No GitHub-hosted runners can do this work.
- Job: build the RHEL 10 blueprint end-to-end with secrets-injected
  RHSM creds, verify the resulting box boots under libvirt, throw away
  the artifact, report pass/fail.
- Trigger: PRs touching `blueprints/`, `scripts/`, `customizations/`,
  plus a weekly cron to catch upstream RHEL changes that break the
  recipe.
- Secrets: `RHSM_USERNAME`, `RHSM_PASSWORD` as repo secrets;
  short-lived, rotatable.

### Build cadence

- Recipe is event-driven (PR-validated, weekly cron sanity check).
- No release cadence — there are no binaries to release. The release
  artifact is a Git tag pointing at a known-good recipe state.

---

## 7. Phased Plan

**Status as of 2026-04-16**: Phases 0, 1, and 2 complete in a single
session. `kraker/rhel-10` v20260416.0 is published on HCP Vagrant
Registry with both `virtualbox` and `libvirt` providers as an alpha
(libvirt provider not yet smoke-tested locally — no libvirt setup on
the Fedora workstation). Phase 3 (CI) deferred to the homelab build
host.

### Phase 0 — Hello, World on the local Fedora workstation ✅ DONE

- Repo created on GitHub: `kraker/vagrant-rhel-boxes`.
- `image-builder` v58 installed from the HashiCorp Fedora repo plus
  `osbuild` + `osbuild-tools` from Fedora's own repos.
- Blueprint `blueprints/rhel-10.toml` written (intentionally minimal
  — image-builder's `vagrant-libvirt` and `vagrant-virtualbox` types
  ship the vagrant user, sudo config, and insecure SSH key by default).
- Build host registered to RHSM via `subscription-manager` so
  image-builder can pull RHEL 10 packages from the CDN. No `--force-repo`
  override needed — the RHEL 10 SCA entitlement was sufficient.
- `scripts/build.sh` wraps `sudo image-builder build` with arg parsing
  for version and provider.

**Outcome**: `./scripts/build.sh rhel-10.0 vagrant-libvirt` produced a
940 MB box in ~15 minutes.

### Phase 1 — VirtualBox provider ✅ DONE

- Same blueprint, built with `./scripts/build.sh rhel-10.0
  vagrant-virtualbox`. 914 MB box.
- Smoke-tested: `vagrant box add` + `vagrant up` succeeded; the box
  booted and `cat /etc/os-release` returned authentic
  `Red Hat Enterprise Linux 10.0 (Coughlan)`, kernel
  `6.12.0-55.43.1.el10_0.x86_64`.

### Phase 2 — First HCP publish ✅ DONE (as alpha)

- `hcp` CLI installed from the HashiCorp Fedora repo.
- Auth via `hcp auth login` (browser) → `hcp auth print-access-token`
  → `VAGRANT_CLOUD_TOKEN`. This works around the broken
  `vagrant cloud auth login` (see Lessons appendix).
- Both providers published to `kraker/rhel-10` v20260416.0 with
  `--direct-upload --no-release`, then `vagrant cloud version release
  --force` to publish.
- Marked alpha because the libvirt provider was published without
  a local smoke test.

### Phase 3 — CI smoke-test (TODO — homelab)

- Self-hosted runner on the homelab build node.
- Workflow: build both providers on PR / cron, fail the run if either
  build or boot smoke-test fails.

### Phase 4 — Docs site + first article (TODO)

- Docs split into proper sections (`docs/`).
- First article written and published on personal blog (or Dev.to /
  Medium first for SEO).
- Repo README links the article; article links the repo.

### Phase 5 — RHEL 9 blueprint (TODO)

- Add `blueprints/rhel-9.toml`.
- CI matrix expanded to cover both RHEL versions × both providers.

### Phase 6 — Iterate based on usage

- React to issues / PRs from early users.
- Refine docs based on actual confusion points.
- Continue article series.

---

## 8. Content Strategy

The brand is **"the modern, official-Red-Hat-tooling path for RHEL
Vagrant boxes."** Every article is positioned as authoritative on a
narrow but valuable topic.

### Article series (rough order)

1. **"Why there's no `generic/rhel10` and what to do about it."**
   The opening salvo. Mostly drafted in the conversation that produced
   this plan. Sets up the project.
2. **"Building a RHEL 10 Vagrant box with `image-builder`, the new
   Tech Preview CLI."**
   The Phase 0 walkthrough using the daemonless CLI. Covers the
   blueprint, the build script, and RHSM setup end to end.
3. **"`image-builder` vs `composer-cli`: which RHEL Image Builder
   CLI should you use?"**
   Comparison piece on the two CLIs in the same family. Concrete
   recommendation, honest about Tech Preview risk.
4. **"Image Builder vs Packer for Vagrant boxes: when the official
   tool is the right choice."**
   Cross-tool comparison. Argues for Image Builder on first principles
   without dismissing Packer. The flagship piece.
5. **"Why I ship recipes, not binaries: the RHEL EULA and you."**
   The recipes-only architectural decision, made teachable.
6. **"Self-hosted GitHub Actions runners on a Rocky / RHEL build
   host."**
   The CI infrastructure piece. Phase 2 material.
7. **"Customizing RHEL Vagrant boxes with Image Builder blueprints."**
   Deep dive on the TOML blueprint format. Recurring reference piece.
8. **"What I learned maintaining the RHEL Vagrant box recipe for one
   year."**
   12-month retrospective. Confirms the project still ships.

### Distribution

- Personal blog (own domain ideally; Dev.to / Medium acceptable for
  early SEO).
- Cross-post to r/redhat, r/linuxadmin, lobste.rs.
- Submit to Red Hat Developer blog if quality holds.
- Each article links the repo and vice versa.

### Video

- 10-min "build your first RHEL 10 Vagrant box from this repo."
- Longer-form "homelab RHEL build server setup" if there's appetite.

### Differentiator

This is now sharp: "the Red Hat-official way to do RHEL Vagrant
boxes." It's a small enough niche that one person can credibly own
it and a real enough need that the audience exists.

---

## 9. Open Questions / Decisions Pending

- [x] **Final repo name: `vagrant-rhel-boxes`** (decided 2026-04-16).
- [x] **License: Apache-2.0** (decided 2026-04-16). Matches osbuild
      upstream and Bento. Revisitable — MIT is the obvious alternative
      if Apache-2.0 starts to feel too institutional for the
      learners-and-DevOps audience.
- [x] **CLI: `image-builder` (Tech Preview)** over `composer-cli`
      (decided 2026-04-16). Daemonless, simpler, container-friendly,
      and the path Red Hat's RHEL 10 docs lead with. Tech Preview risk
      is bounded: blueprints are CLI-agnostic, so a fallback to
      composer-cli is a script change.
- [x] **Build host (Phase 0): local Fedora workstation** (decided
      2026-04-16). Homelab RHEL/Rocky build node deferred to Phase 2+.
- [x] **Distribution model: hybrid** (decided 2026-04-16). Recipe in
      the repo; unregistered binaries published to HCP Vagrant Registry
      + GitHub Releases. No paid hosting. Reopens the EULA gray area
      (Roboxes-style); accepted as a deliberate trade for adoption.
- [ ] Pin a known-good `image-builder` version on the build host to
      insulate against Tech Preview API churn.
- [ ] Whether to support both RHEL 10 and RHEL 9 from the start, or
      RHEL 10 only and add RHEL 9 if users ask.
- [ ] Personal blog platform: own domain from day one, or start on
      Dev.to / Medium for SEO?
- [ ] Should the consulting brand site link to the repo, or should
      they evolve in parallel and converge later?
- [ ] **Better RHSM credential handling than `export` in shell.** The
      examples and README currently document
      `export RHSM_USERNAME=... RHSM_PASSWORD=...` for the
      `vagrant-registration` plugin to pick up, which leaves the
      password in shell history and visible in `/proc/<pid>/environ`.
      Acceptable for now (these are dev creds, low blast radius) but
      worth a follow-up. Candidates to evaluate: a sourced
      `.rhel-credentials` file documented as never-committed (the
      pattern the rhcsa-field-manual repo used), keyring/secret-tool
      integration, or whether `vagrant-registration` itself supports
      a credentials file path.
- [ ] **Add VirtualBox Guest Additions to the box.** The first
      consumer (rhcsa-field-manual dogfood, 2026-04-17) hit
      "unknown filesystem type 'vboxsf'" because image-builder doesn't
      install Guest Additions by default. Workaround there is
      `synced_folder type: "rsync"` but that's host→VM only and
      surprises anyone expecting Bento-style vboxsf mounts. Options:
      (a) bake guest additions into the blueprint via the VirtualBox
      installer ISO post-compose step, (b) install
      `virtualbox-guest-additions` from RPMFusion or similar in
      provisioning, (c) document the rsync workaround as the official
      pattern. The libvirt provider has the same class of issue with
      9p — needs `kernel-modules-extra` or virtfs setup verified.
- [ ] **Document `config.registration.auto_attach = false` requirement
      for RHEL 10.** Same dogfood hit `subscription-manager: error: no
      such option: --auto-attach` because RHEL 10 dropped the flag
      (Simple Content Access is now the default model) but
      vagrant-registration v1.3.4 still passes it. Override in the
      consumer Vagrantfile is the workaround; documenting it on the
      box's HCP description and in `examples/*/Vagrantfile` would save
      every new user the same debug session.

---

## Appendix A — References

- [osbuild project](https://osbuild.org/) — the underlying engine
  both `image-builder` and `composer-cli` drive.
- [Image Builder: vagrant-virtualbox image type (RHEL 10.1)](https://osbuild.org/docs/user-guide/image-descriptions/rhel-10.1/vagrant-virtualbox/)
- [Image Builder: vagrant-libvirt image type](https://osbuild.org/docs/user-guide/image-descriptions/rhel-10.1/vagrant-libvirt/)
- [Red Hat docs: Composing a customized RHEL system image (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/) — full doc; Chapter 12 covers Vagrant. A copy is bundled at `references/Red_Hat_Enterprise_Linux-10-Composing_a_customized_RHEL_system_image-en-US.pdf` (CC-BY-SA 3.0).
- [chef/bento](https://github.com/chef/bento) — model for repo
  structure (uses Packer, builds Rocky/Alma not RHEL).
- [lavabit/robox](https://github.com/lavabit/robox) — the cautionary
  tale; the project this work effectively replaces for RHEL.
- [HashiCorp BSL adoption](https://www.hashicorp.com/en/blog/hashicorp-adopts-business-source-license)

---

## Appendix B — Lessons from Phase 0–2

Captured from the first end-to-end build + publish on 2026-04-16. These
are the gotchas that cost time and would have been worth knowing in
advance — record them now so future-self doesn't relearn.

### Auth: `vagrant cloud auth login` is broken post-HCP

The interactive `vagrant cloud auth login` command still hits the legacy
Vagrant Cloud auth endpoint, which returns `Method Not Allowed` against
the post-migration HCP backend. Username/password isn't accepted either,
because GitHub-OAuth'd HCP accounts have no password.

**Working path**: install `hcp` (HashiCorp Fedora repo: `dnf install hcp`),
then:

```sh
hcp auth login                            # browser flow, one-time per machine
export VAGRANT_CLOUD_TOKEN=$(hcp auth print-access-token)
vagrant cloud auth whoami                 # confirms the token works
```

The JWT from `print-access-token` is user-scoped and lasts ~1 hour. Fresh
exec each time you need it for `vagrant cloud` commands. CI will use
service principal credentials instead — see below.

### Service principals work for CI, not interactive use

Org-level **Contributor** role on a Service Principal is sufficient for
publishing. The flow is OAuth2 client_credentials against
`https://auth.idp.hashicorp.com/oauth2/token` — exchange Client ID +
Secret for a JWT, then use the JWT as `VAGRANT_CLOUD_TOKEN`. Documented
in §4 above; will become CI's auth path in Phase 3.

The HCP UI for SP key generation is buried — at time of writing (HCP UI
revs every few months), it wasn't visible from the SP detail page. Save
the steps when figured out.

### Vagrant Cloud field limits

- `--short-description`: 120 character maximum. Validation only fires at
  submit time; the CLI doesn't pre-check.

### Publishing flags worth remembering

- `--direct-upload` for boxes >100 MB. Sends the file directly to backend
  storage instead of through the Vagrant Cloud API.
- `--no-release` to publish as a draft for verification. Default
  behavior is "do not release" but explicit is clearer.
- `vagrant cloud version release` requires `--force` in non-interactive
  contexts (otherwise it prompts for a TTY confirmation).

### image-builder noise to ignore

- `grub2-probe: error: failed to get canonical path of /dev/mapper/luks-...`
  fires during the build pipeline when image-builder probes the host's
  block devices. Non-fatal — the image's grub config is set from the
  blueprint defaults, not the host's layout. Pure noise.

### Box file ownership

`image-builder build` runs under sudo, so the resulting `.box` file is
root-owned. `chown` to the user before `vagrant box add` or
`vagrant cloud publish`. Worth folding into `scripts/build.sh` later.
