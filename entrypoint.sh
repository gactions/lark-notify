#!/usr/bin/env bash
set -euo pipefail

webhook="${INPUT_WEBHOOK}"
content="${INPUT_CONTENT}"
secret="${INPUT_SECRET:-}"

if [[ ! "${webhook}" =~ ^https:// ]]; then
  echo "::error::webhook must be an https URL"
  exit 1
fi

body=$(jq -n --arg content "${content}" '{msg_type: "text", content: {text: $content}}')

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
