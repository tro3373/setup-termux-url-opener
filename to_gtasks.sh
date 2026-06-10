#!/data/data/com.termux/files/usr/bin/bash
# Add the current OGP result to Google Tasks via `gog`.
# Reads $1 (defaults to $script_dir/ogp.result.json).

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly script_dir

validate_inputs() {
  if [[ ! -f ${json_file} ]]; then
    echo "==> Error: ogp result not found: ${json_file}" >&2
    return 1
  fi

  if ! command -v gog >/dev/null 2>&1; then
    echo "==> Error: gog command not found in PATH" >&2
    return 1
  fi
}

load_env() {
  if [[ -f ${script_dir}/.env ]]; then
    # shellcheck disable=SC1091
    . "${script_dir}/.env"
  fi

  if [[ -z ${GOG_TASKS_LIST_ID:-} ]]; then
    echo "==> Error: GOG_TASKS_LIST_ID is not set" >&2
    return 1
  fi
}

read_ogp() {
  url=$(jq -r '.url // empty' <"${json_file}")
  title=$(jq -r '.title // empty' <"${json_file}")
  description=$(jq -r '.description // empty' <"${json_file}")

  if [[ -z ${url} ]]; then
    echo "==> Error: url is empty in ${json_file}" >&2
    return 1
  fi
}

md_link() { printf '[%s](%s)' "$1" "$2"; }

truncate_chars() {
  local s=$1 n=$2
  if ((${#s} > n)); then
    printf '%s…' "${s:0:n}"
    return
  fi
  printf '%s' "${s}"
}

build_for_github() {
  local owner=$1 repo=$2
  local canon_url="https://github.com/${owner}/${repo}"
  gtask_title=$(md_link "${owner}/${repo}" "${canon_url}")
  gtask_notes="${description}"
}

build_for_x() {
  local link_text
  link_text=$(truncate_chars "${description}" 50)
  [[ -z ${link_text} ]] || link_text="$link_text ${title}"
  # Fallback when description is empty so the title is never "[](url)".
  [[ -z ${link_text} ]] && link_text=${title}
  [[ -z ${link_text} ]] && link_text=${url}
  gtask_title=$(md_link "${link_text}" "${url}")
  # gtask_notes="${description}

  # ${title}"
}

build_default() {
  local link_text=${title}
  [[ -z ${link_text} ]] && link_text=${url}
  gtask_title=$(md_link "${link_text}" "${url}")
  # gtask_notes="${description}"
}

build_args() {
  if [[ ${url} =~ ^https?://github\.com/([^/?#]+)/([^/?#]+) ]]; then
    local owner=${BASH_REMATCH[1]} repo=${BASH_REMATCH[2]}
    # GitHub reserved path segments — fall back to generic title rendering.
    case ${owner} in
      orgs | gist | features | settings | sponsors | enterprise | marketplace | topics | notifications | new | login | join | search)
        build_default
        return
        ;;
    esac
    build_for_github "${owner}" "${repo}"
    return
  fi

  if [[ ${url} =~ ^https?://(x\.com|twitter\.com)/ ]]; then
    build_for_x
    return
  fi

  build_default
}

submit() {
  gog tasks add "${GOG_TASKS_LIST_ID}" --title "${gtask_title}" --notes "${gtask_notes}"
}

main() {
  set -euo pipefail

  local json_file="${1:-${script_dir}/ogp.result.json}"
  local url title description
  local gtask_title gtask_notes

  validate_inputs
  load_env
  read_ogp
  build_args
  submit
}
main "$@"
