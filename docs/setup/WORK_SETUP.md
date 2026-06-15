# Work Machine Setup

Supplement to [LAPTOP_SETUP.md](./LAPTOP_SETUP.md)

## 1. SSH keys

See [SSH_KEYS.md](./credentials/SSH_KEYS.md) for more info.

The strategy for SSH keys here is to keep work and personal keys separate.

```bash
# Create a new Proton Pass login: ssh-keys/<hostname>-personal-key
# Generate a password in Proton Pass for the new key
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/$(hostname)-personal-key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/$(hostname)-personal-key
cat ~/.ssh/$(hostname)-personal-key.pub  # store in Proton Pass item; upload to personal GitHub
```

```bash
# Create a new Proton Pass login: ssh-keys/<hostname>-work-key
# Generate a password in Proton Pass for the new key
ssh-keygen -t ed25519 -C "jonathan.hendrickson@bonsairobotics.ai" -f ~/.ssh/$(hostname)-work-key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/$(hostname)-work-key
# store in Proton Pass item; upload to work GitHub
cat ~/.ssh/$(hostname)-work-key.pub
```

Upload `<hostname>-personal-key.pub` to [github.com/settings/keys](https://github.com/settings/keys)
and `<hostname>-work-key.pub` to the company GitHub.

## 2. Clone 0config using the personal SSH alias

The `github-personal` SSH host is configured by `work.nix` to route through
`~/.ssh/$(hostname)-personal-key`.

```bash
git clone git@github-personal:hello-joni/0config.git ~/0config
```

## 3. Jira CLI token

`work.nix` installs a `jira` wrapper that reads the API token from the GNOME
Keyring under `service jira` at each call. The token is the only secret; the
instance URL, email, project, and board live in `~/.config/.jira/.config.yml`,
generated locally by `jira init`.

```bash
# Generate a token at https://id.atlassian.com/manage-profile/security/api-tokens
# Create a new Proton Pass login: api-keys/jira-<hostname>, password = token
secret-tool store --label='Jira API Token' service jira  # paste the token, then Enter
jira init   # select Cloud, then enter instance URL, email, project, and board
jira me     # verify
```

Rotate by clearing the keyring entry, then re-running `secret-tool store`:

```bash
secret-tool clear service jira
```

## 4. Buildkite CLI token

`work.nix` installs the Buildkite CLI (`bk`). It stores a read-only personal API
token in `~/.config/bk.yaml`, written by `bk auth login`. Run it once per machine.

```bash
# Create a token at https://buildkite.com/user/api-access-tokens/new
#   Organization Access: <org-slug>
#   REST scopes (read-only): read_builds, read_build_logs, read_pipelines,
#     read_artifacts, read_organizations, read_user
#   Enable GraphQL API access: yes
# Create a new Proton Pass login: api-keys/buildkite-<hostname>, password = token
bk auth login --org <org-slug> --token <token>
bk auth status   # verify
bk build list -p <a-pipeline-slug> --limit 5   # verify build access
```

Rotate by revoking the old token at https://buildkite.com/user/api-access-tokens,
then re-running `bk auth login` with the replacement.
