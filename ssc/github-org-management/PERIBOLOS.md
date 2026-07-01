# Peribolos org management

This directory manages **GitHub team membership** for the `spiffe` org as code,
using [Peribolos](https://docs.prow.k8s.io/docs/components/cli-tools/peribolos/)
(from Kubernetes' Prow). The desired state lives in [`org.yaml`](./org.yaml);
GitHub is reconciled to match it via GitHub Actions.

## How it works

| When | Workflow | Peribolos run | Effect |
|------|----------|---------------|--------|
| PR touches `org.yaml` | `peribolos-plan` | no `--confirm` | **Dry-run.** Logs the changes it *would* make. Review this in the job log. |
| Merge to `main` | `peribolos-apply` | `--confirm` | **Applies** the config to the org. |

Both runs use `--fix-teams --fix-team-members`. That means this repo manages:

- the **set of teams** in the org (create / delete / rename), and
- each listed team's **membership and roles** (member vs. maintainer).

It does **not** manage: org membership/ownership, org settings, or team→repo
permissions. (Those would need `--fix-org-members` / `--fix-org` /
`--fix-team-repos`, which are deliberately left off.)

The two workflows run as **different GitHub Apps** with different privileges, and
the apply path is build-isolated and human-gated — see [Security model](#security-model).

## ⚠️ Peribolos is authoritative over *all* teams

There is no "manage only these N teams" mode. `--fix-teams` treats **any team in
the org that is not in `org.yaml` as a team to delete**, and `--fix-team-members`
treats every listed team's roster as authoritative (anyone not listed is
removed). `--fix-team-members` cannot be used without `--fix-teams`.

Consequences:

1. **Every existing team must be listed**, or it will be targeted for deletion.
   `org.yaml` currently enumerates all 9 org teams. Three are *actively curated*
   (`ssc`, `spiffe-maintainers`, `spire-maintainers`); the other six are captured
   verbatim as a baseline so they are not deleted. Their rosters mirror GitHub at
   bootstrap, but going forward **any out-of-band change to them is reverted** on
   the next apply.
2. **Adding a team in the GitHub UI is not enough** — it must also be added here,
   or it gets deleted on the next apply.
3. If you genuinely want to manage *only* a subset of teams and leave everything
   else untouched, Peribolos is the wrong tool — the Terraform GitHub provider
   (`github_team` / `github_team_members`) can manage individual resources.

## Safety rails

- **Dry-run by default.** Nothing mutates without `--confirm` (apply-only).
- **`--maximum-removal-delta` (default 0.25).** Aborts if a run would delete more
  than 25% of the org's *teams*. With 9 teams, dropping ≥3 from the config fails
  closed instead of mass-deleting. ⚠️ This guard covers **team deletion only** —
  it does **not** limit team *membership* removals. Membership edits are gated
  solely by PR review, so protect `org.yaml` with branch protection + CODEOWNERS.
- The `--require-self` / `--min-admins` checks only apply to `--fix-org-members`,
  which we don't use, so the App does not need to be an org admin in any list.

## Making a change

1. Edit the relevant team's roster in `org.yaml`.
2. Open a PR. The `peribolos-plan` check runs the dry-run and logs the exact
   diff it *would* apply — confirm it changes only what you expect.
3. Get it approved by a code owner (`@spiffe/ssc` owns this directory; enforced
   by branch protection on `main`) and merge.
4. The `peribolos-apply` workflow starts but **pauses** on the `org-management`
   environment for a required reviewer to approve the deployment. On approval it
   runs `--confirm` and reconciles the org. Newly-added users who aren't yet org
   members receive a team invitation (pending until accepted).

## Security model

The dangerous capability here is **mutating org team membership**. The design
keeps the write credential small, isolated, and hard to reach.

**Two GitHub Apps, not one.**

- **Plan** runs in PR context (`pull_request`). For same-repo branch PRs the
  workflow's secrets are readable by the PR author's own (author-controlled)
  workflow file, so plan uses a **read-only** App (Org Members: *Read*). If that
  key leaks, the worst outcome is reading team rosters — which org members can
  already see.
- **Apply** uses a separate **read/write** App (Org Members: *Read & write*).
  Scoping the minted token alone would not be enough: whoever holds an App's
  *private key* can mint a token with *any* permission that App was granted. One
  shared App would therefore expose write power to PRs. Separate Apps make this a
  real privilege boundary.

**The write key is reachable only from `main`, after human approval.** The apply
App's secrets live in the protected `org-management` environment (restricted to
the `main` branch, with required reviewers). No PR-triggered workflow can read
them, and every apply pauses for a reviewer to approve after seeing the plan.

**The build never touches the write key.** Apply is split into two jobs: `build`
compiles peribolos with no credentials and no repo checkout (the module is
fetched and integrity-checked against `sum.golang.org`), then hands the binary to
the `apply` job as an artifact. The dependency-heavy compile cannot exfiltrate a
credential it never sees.

**Everything is pinned.** Actions are pinned to commit SHAs (with version
comments) and peribolos to a module pseudo-version, so a moved tag or branch
can't silently change what runs next to the token.

**Blast radius.** The apply App can add/remove team members (including granting
the team-maintainer role) and create/delete teams (deletion capped at 25% by
`--maximum-removal-delta`). It **cannot** touch org ownership, org membership,
org settings, or repo permissions. Org ownership stays manual (see
[README](./README.md)). **Never add `--fix-org-members`** to these workflows — it
is the lever that would let a merged config change org owners.

## Setup (one-time)

### 1. Two GitHub Apps

Create both Apps owned by the `spiffe` org, set "Where can this GitHub App be
installed?" to **Only on this account**, install each on the `spiffe` org, and
generate a private key for each.

| App | Org permission | Used by |
|-----|----------------|---------|
| `spiffe-org-plan` | Members: **Read** | `peribolos-plan` (PRs) |
| `spiffe-org-apply` | Members: **Read & write** | `peribolos-apply` (`main`) |

(Add **Repository → Administration: Read & write** to the apply App later only if
you ever enable `--fix-team-repos`.)

### 2. Secrets

| Secret | Where it lives | Value |
|--------|----------------|-------|
| `PLAN_APP_ID` | repo secret | plan App's numeric ID |
| `PLAN_APP_PRIVATE_KEY` | repo secret | plan App's PEM private key |
| `APPLY_APP_ID` | **`org-management` environment** | apply App's numeric ID |
| `APPLY_APP_PRIVATE_KEY` | **`org-management` environment** | apply App's PEM private key |

The apply secrets **must** be environment secrets (next step), not repo secrets —
that is what keeps them off PR-triggered runs.

### 3. Protected environment

Repo → Settings → Environments → create **`org-management`**:

- **Deployment branches and tags**: *Selected* → `main` only.
- **Required reviewers**: the SSC (each apply is then human-approved).
- Add the two `APPLY_APP_*` secrets here.

### 4. Branch protection on `main`

- Require a pull request before merging, with at least one approval.
- **Require review from Code Owners** — `@spiffe/ssc` owns `/ssc/`, so it must
  approve any change to `org.yaml`.
- **Require status checks to pass**: the `Peribolos (plan)` check.
- Dismiss stale approvals on new commits; block force-pushes and deletions.
- **Do not allow administrators to bypass** these rules.

### 5. Actions policy

Repo (or org) → Settings → Actions → General:

- **Fork pull request workflows**: require approval for all outside collaborators.
- Optionally restrict allowed actions to `actions/*` (the only ones used here);
  the SHA pins are the primary integrity control regardless.

### Re-generating the baseline (recommended before first apply)

`org.yaml` was hand-assembled from the org's current state. To guarantee it is a
faithful, no-op baseline, regenerate it with peribolos' dump mode using a token
with `admin:org` scope and diff against this file:

```sh
go install sigs.k8s.io/prow/cmd/peribolos@latest
peribolos --github-token-path <token-file> --dump spiffe --dump-full > /tmp/spiffe-dump.yaml
```

Then run the `peribolos-plan` workflow (or peribolos locally without `--confirm`)
and confirm the dry-run reports **no changes** before enabling the apply job.
