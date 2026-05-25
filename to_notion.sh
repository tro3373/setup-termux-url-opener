#!/data/data/com.termux/files/usr/bin/bash
# POST the current OGP result to Notion as a database page.
# Reads $1 (defaults to $script_dir/ogp.result.json).

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly script_dir

validate_input() {
  if [[ ! -f ${json_file} ]]; then
    echo "==> Error: ogp result not found: ${json_file}" >&2
    return 1
  fi
}

load_env() {
  if [[ -f ${script_dir}/.env ]]; then
    # shellcheck disable=SC1091
    . "${script_dir}/.env"
  fi

  if [[ -z ${NOTION_API_KEY:-} || -z ${NOTION_DATABASE_ID:-} ]]; then
    echo "==> Error: NOTION_API_KEY or NOTION_DATABASE_ID is not set" >&2
    return 1
  fi
}

build_payload() {
  # Build payload directly from ogp.result.json via jq so quoting is safe.
  jq \
    --arg db "${NOTION_DATABASE_ID}" \
    '{
      parent: { database_id: $db },
      properties: ({
        "名前": { title: [ { text: { content: (.title // "") } } ] },
        "URL":  { url: (.url // "") },
        "既読": { checkbox: false },
        "Stock": { checkbox: false }
      } + (if (.image // "") == "" then {} else { "画像URL": { url: .image } } end)),
      children: [
        {
          object: "block",
          type: "paragraph",
          paragraph: {
            rich_text: [ { text: { content: (.description // "") } } ]
          }
        }
      ]
    }' <"${json_file}" >"${payload_file}"
}

post_to_notion() {
  curl -L -sS -X POST 'https://api.notion.com/v1/pages' \
    -H "Authorization: Bearer ${NOTION_API_KEY}" \
    -H "Content-Type: application/json" \
    -H "Notion-Version: 2022-06-28" \
    -d @"${payload_file}" \
    -w '\nHTTP %{http_code}\n'
}

main() {
  set -euo pipefail

  local json_file="${1:-${script_dir}/ogp.result.json}"
  local payload_file="${script_dir}/to_notion.json"

  validate_input
  load_env
  build_payload
  post_to_notion
}
main "$@"
