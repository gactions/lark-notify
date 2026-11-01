#!/usr/bin/env bash
set -euo pipefail

webhook="${INPUT_WEBHOOK}"
content="${INPUT_CONTENT}"
secret="${INPUT_SECRET:-}"
format="${INPUT_FORMAT:-card}"
title="${INPUT_TITLE:-${GITHUB_WORKFLOW:-GitHub Actions}}"
status="${INPUT_STATUS:-}"

if [[ ! "${webhook}" =~ ^https:// ]]; then
  echo "::error::webhook must be an https URL"
  exit 1
fi

case "${format}" in
  text)
    body=$(jq -n --arg content "${content}" '{msg_type: "text", content: {text: $content}}')
    ;;
  card)
    case "${status}" in
      success) color=green icon='✅' outcome=succeeded button=default ;;
      failure) color=red icon='❌' outcome=failed button=danger ;;
      cancelled) color=grey icon='⚪' outcome=cancelled button=default ;;
      skipped) color=grey icon='⚪' outcome=skipped button=default ;;
      *) color=grey icon='🔔' outcome="${status}" button=default ;;
    esac
    card_title="${icon}${outcome:+ ${outcome}} · ${title}"
    finished="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M') (UTC+8)"
    repository="${GITHUB_REPOSITORY:-}"
    server_url="${GITHUB_SERVER_URL:-https://github.com}"
    run_url=''
    commit_url=''
    if [[ -n "${repository}" ]]; then
      if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
        run_url="${server_url}/${repository}/actions/runs/${GITHUB_RUN_ID}"
      fi
      if [[ -n "${GITHUB_SHA:-}" ]]; then
        commit_url="${server_url}/${repository}/commit/${GITHUB_SHA}"
      fi
    fi
    trigger="${GITHUB_ACTOR:-}"
    if [[ -n "${GITHUB_EVENT_NAME:-}" ]]; then
      trigger="${trigger}${trigger:+ }(${GITHUB_EVENT_NAME})"
    fi
    body=$(jq -n --arg content "${content}" --arg title "${card_title}" \
      --arg color "${color}" --arg button "${button}" \
      --arg repository "${repository}" --arg ref "${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}" \
      --arg trigger "${trigger}" --arg finished "${finished}" \
      --arg run_url "${run_url}" --arg commit_url "${commit_url}" '
      def row($name; $value):
        {
          tag: "column_set", flex_mode: "none", background_style: "default",
          horizontal_spacing: "small",
          columns: [
            {tag: "column", width: "weighted", weight: 1, vertical_align: "top",
             elements: [{tag: "div", text: {tag: "lark_md", content: "**\($name)**"}}]},
            {tag: "column", width: "weighted", weight: 4, vertical_align: "top",
             elements: [{tag: "div", text: {tag: "plain_text", content: $value}}]}
          ]
        };
      def button($text; $type; $url):
        {tag: "button", text: {tag: "plain_text", content: $text}, type: $type, url: $url};
      {
        msg_type: "interactive",
        card: {
          config: {wide_screen_mode: true},
          header: {template: $color, title: {tag: "plain_text", content: $title}},
          elements: (
            [{tag: "div", text: {tag: "lark_md", content: $content}}]
            + (if $repository == "" then [] else [row("📦 Repo"; $repository)] end)
            + (if $ref == "" then [] else [row("🌿 Ref"; $ref)] end)
            + (if $trigger == "" then [] else [row("👤 By"; $trigger)] end)
            + [row("🕒 Time"; $finished)]
            + (if $run_url == "" and $commit_url == "" then [] else [
                {tag: "hr"},
                {tag: "action", actions: (
                  (if $run_url == "" then [] else [button("📋 Logs"; $button; $run_url)] end)
                  + (if $commit_url == "" then [] else [button("🔗 Commit"; "default"; $commit_url)] end)
                )}
              ] end)
          )
        }
      }')
    ;;
  *)
    echo "::error::format must be card or text"
    exit 1
    ;;
esac

# --- optional signature, per Lark/Feishu custom-bot spec: sign over an empty
# --- body using "<timestamp>\n<secret>" as the HMAC-SHA256 key -------------
if [[ -n "${secret}" ]]; then
  timestamp=$(date +%s)
  string_to_sign="${timestamp}
${secret}"
  sign=$(printf '' | openssl dgst -sha256 -hmac "${string_to_sign}" -binary | base64)
  body=$(printf '%s' "${body}" | jq --arg ts "${timestamp}" --arg sign "${sign}" '. + {timestamp: $ts, sign: $sign}')
fi

if ! response=$(curl -sS --connect-timeout 10 --max-time 30 -w '\n%{http_code}' \
  -X POST -H 'Content-Type: application/json' -d "${body}" "${webhook}"); then
  echo "::error::Lark webhook request failed"
  exit 1
fi
http_code=$(printf '%s' "${response}" | tail -n1)
resp_body=$(printf '%s' "${response}" | sed '$d')

echo "Lark response (HTTP ${http_code}): ${resp_body}"

if [[ "${http_code}" != "200" ]]; then
  echo "::error::Lark webhook returned HTTP ${http_code}"
  exit 1
fi

status_code=$(printf '%s' "${resp_body}" | jq -r '.StatusCode // .code // ""')
if [[ -n "${status_code}" && "${status_code}" != "0" ]]; then
  echo "::error::Lark webhook rejected the message: ${resp_body}"
  exit 1
fi
