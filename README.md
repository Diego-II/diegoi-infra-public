# diegoi-infra

> **Public, sanitized mirror** of a private repo, published one-way.
> Account IDs, emails, domains and project/app names are placeholders
> (`111111111111`, `owner@example.com`, `example.com`, `project-a`, `app1`, ...).

Infrastructure-as-code for the **my-org** AWS Organization. This is the
*central* repo: it manages the management ("root") account, the org structure,
guardrails, SSO, and **vends** member accounts. Each big project (e.g.
`project-a`) gets its own account here, then lives in its own repo and deploys
into that account via GitHub OIDC — no stored AWS keys.

## Model: factory vs. tenant

```
  THIS repo (factory)                          project repo (tenant)
  ───────────────────                          ─────────────────────
  • Organizations / OUs / SCPs                 • app resources (S3, Lambda…)
  • creates accounts + baseline:               • its own TF state (in its
      - GitHub OIDC deploy role                  own account's bucket)
      - per-account state bucket               • assumes deploy role via OIDC
      - your SSO access                        • never touches Organizations
```

Organizations APIs only work from the management account, so account creation
lives **only** here. That keeps the most dangerous credentials in one place.

## Layout

| Path | Account | What it manages | State key |
|---|---|---|---|
| `bootstrap/` | management | the TF state bucket (local state, run once) | local |
| `live/org/` | management | org import, OUs, SCP guardrails, account vending | `org/` |
| `live/identity-center/` | management | SSO permission sets + your user + assignments | `identity-center/` |
| `live/management-baseline/` | management | cost budget, CI OIDC role, optional org CloudTrail | `management-baseline/` |
| `live/accounts/project-a/` | project-a | OIDC deploy role + state bucket inside the account | `accounts/project-a/` |
| `live/accounts/homelab/` | homelab | app secrets in SSM + the `winbox` IAM user | `accounts/homelab/` |
| `live/accounts/project-b/` | project-b | OIDC deploy role + state bucket inside the account | `accounts/project-b/` |
| `live/cloudflare/` | Cloudflare + management (registrar) | `example.com` zone, Tunnel into winbox, Google-login Access per app (`apps.yaml`) | `cloudflare/` |
| `modules/account/` | — | reusable: vend an account into an OU | — |
| `modules/account-baseline/` | — | reusable: OIDC + deploy role + state bucket | — |

State: one S3 bucket `diegoi-tfstate-111111111111`, one key per stack, native
S3 lockfiles (`use_lockfile`) — no DynamoDB.

## Bootstrap order

Run from the management account (currently your IAM user; switch to SSO after
`identity-center` is applied). **Always read the plan before applying.**

```bash
# 0. Create the state bucket (local state, one time)
cd bootstrap
terraform init && terraform apply

# 1. Org: imports your existing org, adds OUs, vends project-a, enables SCPs.
#    Review the plan: it must show the org IMPORTED with no destructive
#    changes — only SERVICE_CONTROL_POLICY being enabled + new OUs/account.
cd ../live/org
terraform init && terraform plan      # <-- inspect carefully
terraform apply

# 2. SSO: permission sets + your Identity Center user + account assignments.
cd ../identity-center
terraform init && terraform apply
#    Then finish SSO login setup in the console / `aws configure sso`,
#    and stop using the long-lived IAM access keys.

# 3. Management baseline: cost budget + CI OIDC role.
cd ../management-baseline
terraform init && terraform apply

# 4. project-a baseline: keyless deploy role + state bucket inside the account.
cd ../accounts/project-a
terraform init && terraform apply
terraform output deploy_role_arn      # <-- paste into the project-a repo CI
```

## Wiring the project-a project repo

1. Create `Diego-II/project-a` on GitHub.
2. Copy `examples/project-a-ci.yml` into it as `.github/workflows/deploy.yml`.
3. Set `role-to-assume` to the `deploy_role_arn` output from step 4.
4. Its Terraform state goes in `project-a-tfstate-<project-a-account-id>` (that
   account's own bucket). The repo never needs management-account access.

## Known sharp edges (see inline comments)

- **Org import** (`live/org/imports.tf`): the first plan adopts the existing
  org. Read it — there must be no destructive change beyond enabling SCPs.
- **Legacy account** (`222222222222`): left unmanaged for now; may have been
  invited (no `OrganizationAccountAccessRole`). Instructions inline.
- **Identity Center users**: managed in the default AWS identity store. If you
  attach an external IdP later, manage users there instead.
- **CI roles** use `AdministratorAccess` for now — scope down once the needed
  permission surface is known.

## Adding the next project account

Copy the `module "project_a"` block in `live/org/main.tf` and the
`live/accounts/project-a/` directory, rename, give it a unique `+alias` email,
and apply. That's the whole vending flow.

## Cloudflare: apps on winbox at `<app>.example.com`

`live/cloudflare/` points the `example.com` nameservers (still registered at
Amazon) to Cloudflare. It also runs a Tunnel named `winbox` whose connector
runs on the box (`Diego-II/home-agent` → `scripts/setup-tunnel.sh`), and puts
every app behind Google login.

- **Add an app or change who can see it:** edit `live/cloudflare/apps.yaml`
  (port + `allowed_emails`), then apply. Any `*.example.com` host not listed
  there falls back to an owner-only rule.
- **Apply:** `CLOUDFLARE_API_TOKEN` (from `.env`) + management AWS creds.
  CI does not plan this stack (it has no Cloudflare token).
- **No secrets in state:** the tunnel secret is generated by Cloudflare, and
  the Google login method is configured by hand in the Zero Trust dashboard.
  Re-fetch the connector token with the curl line in `setup-tunnel.sh`.
- Names are flat (`app1.example.com`, not `app1.home-agent.example.com`): free
  Universal SSL only covers one level below the zone.
- **Mesh (SSH into winbox):** the Mesh node is named `winbox-mesh` (WSL, Mesh IP
  `100.96.0.2`), joined by home-agent `scripts/setup-mesh.sh`. Two device profiles
  send **only `100.96.0.0/12`** through Cloudflare: one for Mesh nodes, so the
  scrapers keep leaving from the home IP, and one for the owner's devices
  (traffic only, no DNS), so Tailscale keeps working on the same Mac.

## Public mirror

`scripts/publish-public.py` publishes a sanitized copy of `main` to the public
`Diego-II/diegoi-infra-public` repo, as a fresh commit with no shared history.
It swaps account IDs, emails, domains and project/app names for placeholders,
and refuses to publish if any real value or secret-looking string survives.

```bash
git fetch && scripts/publish-public.py --out ../diegoi-infra-public
git -C ../diegoi-infra-public push
```
