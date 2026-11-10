# vault_password must be mode 600

`vault_password` (git-ignored, in the repo root) is the plaintext ansible-vault password. Anyone who can read it
can decrypt every secret in this repo's vault files.

On 2026-11-10 a security review found it at mode `644` (world-readable) in `VPSje` and `lgtv`; the other
playbook repos already had `600`. All were set to `600`:

```sh
chmod 600 ~/git/personal/*/vault_password
```

This is now enforced by `laptop-claude-playbook` (role `claude_personal`, task "Keep each repo's vault_password
owner-only", repo list in `claude_personal_vault_password_repos`). `make check` there reports a change if a
file drifts.

When cloning a repo on a new machine and recreating `vault_password` by hand, create it with
`install -m 600 /dev/null vault_password` first, then paste the password in. Add any new playbook repo to
`claude_personal_vault_password_repos`.
