# Lark Notify

GitHub Action to send a status card or text notification to a Lark/Feishu custom bot
via webhook. Cards keep the message body prominent, with a colored status header,
GitHub context, and links to logs and the commit.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `webhook` | yes | — | Lark/Feishu custom bot webhook URL |
| `content` | yes | — | Message body; supports Lark Markdown in card format |
| `format` | no | `card` | Message format: `card` or `text` |
| `title` | no | Workflow name | Card title |
| `status` | no | `${{ job.status }}` | Card status: `success`, `failure`, `cancelled` or `skipped` |
| `secret` | no | `''` | Signing secret from the bot's signature verification setting |

## Usage

```yaml
- uses: gactions/lark-notify@main
  if: always()
  with:
    webhook: ${{ secrets.LARK_WEBHOOK }}
    title: 'Build'
    content: |
      **Result**  ${{ job.status }}
      Ready for review in the workflow logs.
    secret: ${{ secrets.LARK_SECRET }}
```

Enable signature verification on the custom bot to get a `secret`; omit it if the
bot doesn't have signature verification enabled.

Existing callers receive cards by default. Set `format: text` to keep the original
plain-text message. The card uses the current job status; when notifying from a
separate job, pass the upstream result through `status`, such as
`${{ needs.build.result }}`. Input definitions live in [action.yml](action.yml);
card layout and webhook delivery live in [entrypoint.sh](entrypoint.sh).

## Personal notifications

A group can have just one member, so notifying a single person needs no app bot:
create a group with only yourself, add a custom bot to it (group settings → Group
Bots → Add Bot → Custom Bot), and use its webhook as above. See Feishu's
[custom bot guide](https://open.feishu.cn/document/client-docs/bot-v3/add-custom-bot)
(checked 2026-10-23).
