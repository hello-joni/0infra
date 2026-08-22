# 0infra/opentofu/

OpenTofu IAAC for my cloud resource usage.

## Commands

```bash
tofu init && tofu plan
tofu apply
```

Commit `.terraform.lock.hcl` after any `tofu init` that changes it.

## Secrets

Credentials are manually stored in the GNOME Keyring:

```bash
secret-tool store --label='Hetzner Object Storage access key' service hetzner-s3-access
secret-tool store --label='Hetzner Object Storage secret key' service hetzner-s3-secret
secret-tool store --label='Hetzner Cloud API token' service hcloud-token
```

## Bootstrap

One-time manual backend setup:

- Created bucket `joni-opentofu` at `hel1.your-objectstorage.com`.
- Generated S3 keys and a Hetzner Cloud API token (Read & Write) in the Console.
