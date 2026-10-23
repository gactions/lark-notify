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

## Personal notifications

A group can have just one member, so notifying a single person needs no app bot:
create a group with only yourself, add a custom bot to it (group settings → Group
Bots → Add Bot → Custom Bot), and use its webhook as above. See Feishu's
[custom bot guide](https://open.feishu.cn/document/client-docs/bot-v3/add-custom-bot)
(checked 2026-10-23).
