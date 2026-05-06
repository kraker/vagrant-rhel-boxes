# HCP Vagrant Box Registry — setup runbook

One-time setup needed before the `publish` job in `.github/workflows/build.yml` can push boxes to a `kraker/<family>` namespace. Skip whichever sections are already done.

## Prerequisites

- An HCP account at <https://portal.cloud.hashicorp.com>.
- An HCP project (the default one created with the account is fine for a single-project use case like this).
- Vagrant 2.4.3+ locally if you want to verify auth before wiring CI (Vagrant 2.4.9 is what this project tests against).

## 1. Create the box namespace

Repeat this once per box family the repo publishes — currently `rhel-10` and `rhel-9`. Skip any that already return metadata via `vagrant cloud box show kraker/<family>`.

In the HCP portal:

1. Navigate to **Vagrant** → **Registries**.
2. **Create box**: organization `kraker` (or whatever org you've set up), name `rhel-10` (or `rhel-9`, etc.). Public visibility recommended (matches the existing boxes' setting).

That's the only box-level setup. Versions and providers are created on demand by the publish workflow — no need to pre-create.

## 2. Create a service principal for CI

The publish workflow authenticates as a service principal (SP), not a human. SPs don't expire, can be scoped narrowly, and can be rotated independently of any human's account.

1. HCP portal → **Access Control (IAM)** → **Service Principals** → **Create service principal**.
2. Scope: **Project-level**, scoped to the project containing your Vagrant registry. (Organization-level works but grants more than the publish workflow needs.)
3. Role: **Contributor**. Viewer is read-only and won't allow uploads. Admin is broader than necessary. Contributor is the minimum that supports creating box versions and uploading provider artifacts.
4. After the SP exists, generate a **service principal key**. **The Client Secret is shown exactly once** — copy it before closing the dialog.

## 3. Stash credentials in GitHub repo secrets

In <https://github.com/kraker/vagrant-rhel-boxes/settings/secrets/actions>:

1. **New repository secret** → name `HCP_CLIENT_ID`, value the Client ID from step 2.
2. **New repository secret** → name `HCP_CLIENT_SECRET`, value the Client Secret from step 2.

The `publish` job in `build.yml` reads them as env vars; Vagrant 2.4.3+ uses `HCP_CLIENT_ID` and `HCP_CLIENT_SECRET` natively to mint short-lived access tokens on demand — no `vagrant cloud auth login` step needed.

## 4. Verify locally (optional but recommended)

```bash
export HCP_CLIENT_ID=...
export HCP_CLIENT_SECRET=...
vagrant cloud box show kraker/rhel-10   # or any namespace you've created
```

Box metadata back = auth works. Auth error = double-check the SP role is Contributor and the project scope includes the registry.

## Rotation

SP keys don't expire by default. Rotate the key (don't delete the SP itself) when:

- Someone leaves who had access to the secret.
- A secret may have been logged or exposed.
- On a schedule, if your org has one.

To rotate:

1. HCP portal → SP → generate a new key.
2. Update both repo secrets with the new values.
3. Delete the old key.
4. Re-run the publish workflow once to confirm.

## Why not Terraform / IaC for this?

Considered and explicitly skipped. The HCP-side resources (one project, one SP, one box namespace) change roughly once a year. The state-management overhead of Terraform — backend, locking, drift detection, plan/apply CI — exceeds the things being managed. Revisit if multiple projects, multiple environments, or audit/compliance requirements emerge.
