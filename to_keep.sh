#!/data/data/com.termux/files/usr/bin/bash
# Send the current OGP result to Google Keep via Android intent.
# Reads $1 (defaults to $script_dir/ogp.result.json).
# When the `gemini` CLI is available, generate a Japanese summary first.
#
# chroot wrapping policy:
#   - `am`, `curl`, `jq` run on the Termux host (no chroot needed).
#   - `gemini` runs inside `termux-chroot` because it expects a Linux FS layout.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly script_dir

has() { command -v "$1" >&/dev/null; }

validate_inputs() {
  if [[ ! -f ${json_file} ]]; then
    echo "==> Error: ogp result not found: ${json_file}" >&2
    return 1
  fi

  if ! has am; then
    echo "==> Error: am command not found, cannot open Google Keep." >&2
    return 1
  fi
}

read_ogp() {
  url=$(jq -r '.url // empty' <"${json_file}")
  title=$(jq -r '.title // empty' <"${json_file}")
  description=$(jq -r '.description // empty' <"${json_file}")
  image=$(jq -r '.image // empty' <"${json_file}")
}

cat_for_keep() {
  printf '%s\n\n%s\n' "${description}" "${url}"
}

cat_for_keep_via_gemini() {
  {
    cat "${prompt_path}"
    printf '%s\n' "${url}"
  } >"${prompt_gen_path}"
  termux-chroot bash -c "cat <${prompt_gen_path} | gemini -y -p '' | grep -v 'Loaded cached credentials.'"
}

generate_body() {
  if has gemini; then
    cat_for_keep_via_gemini
    return
  fi
  cat_for_keep
}

prepare_stream() {
  if [[ -z ${image} ]]; then
    return
  fi
  curl -fSsL -o "${image_file}" "${image}"
  stream_opt=(--esa android.intent.extra.STREAM "file:///sdcard/Download/termux-url-opener.img")
}

send_to_keep() {
  am start -a android.intent.action.SEND_MULTIPLE \
    -t "image/*" \
    -p com.google.android.keep \
    --es android.intent.extra.SUBJECT "${title}" \
    --es android.intent.extra.TEXT "${body}" \
    "${stream_opt[@]}"
}

main() {
  set -euo pipefail

  local json_file="${1:-${script_dir}/ogp.result.json}"
  local image_file="${script_dir}/termux-url-opener.img"
  local prompt_path="${script_dir}/prompt.md"
  local prompt_gen_path="${script_dir}/prompt-gen.md"
  local url title description image
  local stream_opt=()
  local body

  validate_inputs
  read_ogp
  prepare_stream
  body=$(generate_body)
  send_to_keep
}
main "$@"
