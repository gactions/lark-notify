# Lark Notify

GitHub Action to send a text notification to a Lark/Feishu custom bot via webhook.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `webhook` | yes | — | Lark/Feishu custom bot webhook URL |
| `content` | yes | — | Text message content to send |
| `secret` | no | `''` | Signing secret from the bot's signature verification setting |

## Usage

```yaml
- uses: gactions/lark-notify@main
  with:
    webhook: ${{ secrets.LARK_WEBHOOK }}
    content: 'Build ${{ job.status }} for ${{ github.repository }}@${{ github.ref_name }}'
    secret: ${{ secrets.LARK_SECRET }}
```

Enable signature verification on the custom bot to get a `secret`; omit it if the
bot doesn't have signature verification enabled.
