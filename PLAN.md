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

## 3. The Distribution Model: Recipes, Not Binaries

This is the central architectural decision and the most important
thing to understand about the project.

### Why recipes only

Red Hat's developer subscription is per-account. A RHEL box that's been
registered to RHSM during build cannot be redistributed without
violating the subscription terms. This is why:

- Bento publishes Rocky 10 and Alma 10 but **never** RHEL.
- Roboxes' `generic/rhel*` boxes were always unregistered and required
  the user to register at `vagrant up` time via `vagrant-registration`
  — a tolerated gray area Red Hat could revisit at any time.

There are two paths the project could have taken:

1. **Recipes only (chosen).** Ship the osbuild blueprint, a build
   script, docs. Users supply their own RHSM credentials, run the
   build locally, get a RHEL box that's registered to *them*. Zero
   redistribution issues. Zero gray area. Aligned with [Red Hat's own
   documented path](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder).
2. **Unregistered binaries** (Roboxes model). Ship a pre-built but
   unregistered box; require `vagrant-registration` at up-time.
   Tolerated historically, not formally blessed.

We pick (1) on principle: it's the Red Hat-official path, it's
unambiguous about the licensing, and the build experience is part of
the consulting-brand value proposition (you learn the toolchain by
running it).

### What that implies for the repo

- **No `.box` files in releases.** Nothing to upload to HCP Vagrant
  Registry. Probably nothing on GitHub Releases either.
- **The repo IS the distribution.** `git clone`, `make build`. Docs
  are the user interface.
- **CI's job is recipe validation, not binary publishing.** A
  self-hosted runner builds the recipe end-to-end on every change
  with secrets-injected RHSM creds, throws away the result, reports
  pass/fail. Catches blueprint drift.

---

## 4. Build Toolchain: Red Hat Image Builder (osbuild)

### Decision

Image Builder is the toolchain. Packer was considered and rejected.

### Why Image Builder over Packer

1. **Brand alignment.** Demonstrating mastery of Red Hat's *official*
   tooling is the entire point of this project as a consulting-brand
   artifact. Picking Packer would put this project alongside ten
   others; Image Builder puts it nearly alone.
2. **Content opportunity.** "Packer Vagrant box tutorial" returns
   hundreds of articles. "osbuild Vagrant box" returns Red Hat's docs
   and almost nothing else. Every planned article occupies nearly
   virgin search territory.
3. **Faster builds, simpler recipes.** Image Builder composes from
   packages; builds are minutes, not tens of minutes. TOML blueprints
   are dramatically smaller and more declarative than HCL templates +
   kickstart files.
4. **First-class Vagrant box output.** RHEL 10.1+ ships
   `vagrant-libvirt` and `vagrant-virtualbox` as native osbuild image
   types — no manual box wrapping.
5. **No HashiCorp licensing concerns.** osbuild is Apache 2.0 / GPL.
   Packer is BUSL since 2023.

### Trade-offs to manage

- **Build host constraint**: every CI runner that does an actual build
  must be RHEL/Fedora/Rocky/Alma. GitHub-hosted Ubuntu runners can't
  run `osbuild-composer`. Mitigation: self-hosted runner on the
  homelab build node.
- **Single provider per build**: producing both libvirt and VirtualBox
  boxes for one RHEL version means two osbuild invocations, not one.
  CI handles this with a build matrix.
- **Less of a community safety net**: when something breaks in
  osbuild, the references are Red Hat docs and osbuild GitHub issues.
  Plan for more independent debugging — also the content opportunity.

---

## 5. Repository Structure

Single GitHub repo, RHEL-only, deliberately small.

```
rhel-vagrant-boxes/                 # repo root (working name)
├── README.md                       # quickstart: clone, source creds, make build
├── LICENSE                         # Apache 2.0 (matches osbuild upstream)
├── blueprints/
│   ├── rhel-10.toml                # current focus
│   └── rhel-9.toml                 # later
├── scripts/
│   ├── build.sh                    # wraps composer-cli for one (version, provider) build
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

- Repo: TBD final name; working name `rhel-vagrant-boxes`. Should match
  the consulting brand handle.
- Blueprint files: `rhel-<major>-<minor>.toml` if minor matters, else
  `rhel-<major>.toml`.

---

## 6. Build Infrastructure

### Build hardware: homelab

- Dedicated build node in the homelab (existing hardware).
- **Must run a RHEL-family OS** (Rocky 10 or RHEL 10) so
  `osbuild-composer` and `composer-cli` are available.
- Required: nested virt for VirtualBox compose, ≥32 GB RAM, ≥500 GB
  SSD, 8+ cores comfortable.
- KVM/libvirt enabled (default on RHEL family).

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

### Phase 0 — Hello, World (one weekend)

- Repo created on GitHub. Final name picked.
- Provision the homelab build node with Rocky 10 (or RHEL 10) +
  osbuild-composer.
- One blueprint: `blueprints/rhel-10.toml`, output type
  `vagrant-libvirt`.
- One script: `scripts/build.sh` that calls `composer-cli compose
  start rhel-10 vagrant-libvirt` and waits for completion.
- README documents how to run locally (set RHSM env vars, run
  script).

**Done when**: someone with RHSM credentials can clone the repo, set
two env vars, run one command, and get a RHEL 10 libvirt Vagrant box
they can `vagrant up`.

### Phase 1 — VirtualBox provider

- Add `vagrant-virtualbox` output to the same blueprint.
- Update `build.sh` to handle both providers (`build.sh rhel-10
  libvirt`, `build.sh rhel-10 virtualbox`).

### Phase 2 — CI smoke-test

- Self-hosted runner registered against the GitHub repo.
- Workflow: build both providers on PR / cron, fail the run if either
  build or boot smoke-test fails.

### Phase 3 — Docs site + first article

- Docs split into proper sections (`docs/`).
- First article written and published on personal blog (or Dev.to /
  Medium first for SEO).
- Repo README links the article; article links the repo.

### Phase 4 — RHEL 9 blueprint

- Add `blueprints/rhel-9.toml`.
- CI matrix expanded to cover both RHEL versions × both providers.

### Phase 5 — Iterate based on usage

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
2. **"The Red Hat-official way to build a RHEL 10 Vagrant box."**
   The Phase 0 walkthrough. Blueprint, build script, RHSM, the works.
3. **"Image Builder vs Packer for Vagrant boxes: when the official
   tool is the right choice."**
   Honest comparison. Argues for Image Builder on first principles
   without dismissing Packer. The flagship piece.
4. **"Why I ship recipes, not binaries: the RHEL EULA and you."**
   The recipes-only architectural decision, made teachable.
5. **"Self-hosted GitHub Actions runners on a Rocky / RHEL build
   host."**
   The CI infrastructure piece. Phase 2 material.
6. **"Customizing RHEL Vagrant boxes with osbuild blueprints."**
   Deep dive on the TOML blueprint format. Recurring reference piece.
7. **"What I learned maintaining the RHEL Vagrant box recipe for one
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
- [ ] Confirm homelab build node OS (Rocky 10 vs RHEL 10). RHEL gives
      authentic experience and exercises the same RHSM dance the user
      would do; Rocky removes the build-host registration step.
- [ ] Whether to publish a "metadata-only" entry on HCP Vagrant
      Registry pointing users at the repo. Probably no — would just
      confuse the recipes-only model.
- [ ] Whether to support both RHEL 10 and RHEL 9 from the start, or
      RHEL 10 only and add RHEL 9 if users ask.
- [ ] Personal blog platform: own domain from day one, or start on
      Dev.to / Medium for SEO?
- [ ] Should the consulting brand site link to the repo, or should
      they evolve in parallel and converge later?

---

## Appendix A — References

- [osbuild project](https://osbuild.org/) — the tool.
- [Image Builder: vagrant-virtualbox image type (RHEL 10.1)](https://osbuild.org/docs/user-guide/image-descriptions/rhel-10.1/vagrant-virtualbox/)
- [Image Builder: vagrant-libvirt image type](https://osbuild.org/docs/user-guide/image-descriptions/rhel-10.1/vagrant-libvirt/)
- [Red Hat docs: Creating Vagrant boxes with RHEL image builder (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder)
- [chef/bento](https://github.com/chef/bento) — model for repo
  structure (uses Packer, builds Rocky/Alma not RHEL).
- [lavabit/robox](https://github.com/lavabit/robox) — the cautionary
  tale; the project this work effectively replaces for RHEL.
- [HashiCorp BSL adoption](https://www.hashicorp.com/en/blog/hashicorp-adopts-business-source-license)
