# Starter kit: the project repo for the `project-b` account

Scaffolding for the **project** repo that deploys into the `project-b` account
(`333333333333`). Copy it into that repo — it does not belong in this one.

The repo name does not matter. Infra is applied from a laptop, so nothing
depends on a GitHub identity.

```
<your-repo>/
└── infra/
    ├── backend.tf     state in project-b-tfstate-333333333333
    ├── versions.tf
    ├── providers.tf   no creds; allowed_account_ids guard
    ├── variables.tf
    ├── main.tf        DNS zone lookup + starter data bucket
    └── outputs.tf
```

## Setup

Add a `project-b` profile to `~/.aws/config` — same shape as the existing `homelab`
one, assuming into the account from `my-org`:

```ini
[profile project-b]
role_arn       = arn:aws:iam::333333333333:role/OrganizationAccountAccessRole
source_profile = my-org
region         = us-east-1
```

Then:

```bash
cp -r <diegoi-infra>/examples/project-b-project/infra ./infra
AWS_PROFILE=project-b terraform -chdir=infra init
AWS_PROFILE=project-b terraform -chdir=infra plan
AWS_PROFILE=project-b terraform -chdir=infra apply
```

Once the Identity Center password is set, `aws configure sso` is the better
path — the SSO user already has AdministratorAccess assigned to this account.

## What lives where

| Thing | Owner | Why |
|---|---|---|
| Account, OU, SCPs | `diegoi-infra` | Organizations API is management-only |
| State bucket `project-b-tfstate-333333333333` | `diegoi-infra` | Can't store state in a bucket it creates |
| Zone `project-b.example.net` + parent NS record | `diegoi-infra` | Delegation spans two accounts |
| **Records inside the zone** | **this repo** | Look the zone up by name |
| Everything else in the account | this repo | |

## No CI for infra — the tradeoff

Deliberate: no GitHub Actions means no standing credential to this account
sitting on the internet, and it sidesteps the PR-can-assume-admin problem
entirely. What you give up:

- **No plan on PRs.** Run `terraform plan` before you push, not after.
- **Drift is invisible.** Nothing re-plans on a schedule. Run a plan
  periodically; `-detailed-exitcode` returns 2 when drift exists.
- **State locking still applies** (`use_lockfile`), so a second laptop can't
  corrupt state — but nothing stops two people applying different code in turn.

The account still has an unused `github-actions-deploy` role with
`AdministratorAccess`, created by the baseline module. It trusts
`repo:Diego-II/project-b:*` — a repo you're not creating. It is harmless but it is
dead weight; ask to have it removed from the baseline for this account.

## Sharp edges

- **`project-b` sits in the Sandbox OU**, which the `baseline-guardrails` SCP does
  not cover. Nothing stops this account leaving the org or stopping CloudTrail.
- **Budget.** The management account's ceiling is $50 with alerts at $15/$20;
  spend here counts toward it. A hosted zone is $0.50/month. The starter
  bucket expires `raw/` after 90 days.
