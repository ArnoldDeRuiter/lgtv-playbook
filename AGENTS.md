# AGENTS.md

TV config/customization repo — pushed to GitHub as `lgtv-playbook` (local
dir is still named `lgtv`; that's intentional, not stale). Read
`~/git/personal/slopbro/TV-HANDOVER.md` first for the TV's IP/SSH access,
CDP, root exec bridge, and standing rules — this file only covers what's
specific to working in this repo.

## Reapply everything

```sh
ansible-playbook ansible/site.yml
```

Idempotent, safe to rerun any time. Runs from `localhost`, shells out to
`ssh`/`scp` against the `tvtje` alias (the TV has no Python — normal
Ansible remote modules don't apply here).

## Structure

- `ansible/site.yml` — the playbook; its own bottom section lists what it
  deliberately does *not* manage.
- `ansible/files/telnet_bootstrap.py` — SSH-recovery fallback, see
  TV-HANDOVER.md's "Regaining SSH access" section.
- `ansible/vault.yml` (gitignored, local-only) + `vault.yml.example`
  (committed template) + `ansible.cfg` (must stay in `ansible/`, not repo
  root) — login-autofill credentials for F1TV/Family7, ansible-vault
  encrypted, deployed to `/var/lib/webosbrew/tv-credentials.json` on the TV.
- `ansible/files/ssh-wrapper/ssh` — puts this TV's key on `ssh` for
  Glasshouse's `deploy.sh` (it calls plain `ssh root@<ip>`); used by section 5
  of `site.yml`, which deploys Glasshouse from `~/git/personal/glasshouse`.
- `glasshouse/` — ansible-vault-encrypted Glasshouse backup (restored from
  the dashboard's backup page, not by the playbook).
- `homescreen/` — the custom home-screen bind-mount overlay (working copy +
  its own README with manual commands). This is also the source the
  `webos-home-customizer` app repo packages as an installable app.

## Rules

- Never `git push` — Captain pushes himself.
- Never touch `ansible/vault.yml` content or assume it should be committed —
  it's gitignored on purpose, Captain's explicit choice.
- Test any TV-facing change live (SSH/CDP) before committing.
