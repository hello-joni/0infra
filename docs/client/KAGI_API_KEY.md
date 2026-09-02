# Kagi API key

The Kagi MCP server (`kagimcp`, configured in `modules/graphical.nix`) reads a Kagi API key from the
GNOME Keyring at launch. There is one universal Kagi key, stored locally on each machine.

## Generating a key

Open [Kagi API](https://kagi.com/api/) -> API Management -> API Keys and generate a key. API usage
is billed per-request, invoiced monthly.

## Storing a key

Record the key in Proton Pass as `kagi` (see [API_KEYS.md](./API_KEYS.md)), then load it into the
keyring:

```bash
secret-tool store --label='Kagi API Key' service kagi  # paste the key, then Enter
```

## Verifying a key

```bash
secret-tool lookup service kagi  # prints the stored key
```

In Zed, the Agent Panel settings show a green indicator next to `kagi` when the server is active.

## Rotating a key

```bash
secret-tool clear service kagi  # remove the current key
```

Generate a replacement, then re-run `secret-tool store`.
