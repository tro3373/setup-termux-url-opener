#!/usr/bin/env bash
# Test for to_gtasks.sh title/notes generation logic.
# Mocks `gog` so we can capture and assert its CLI args.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly script_dir

main() {
  set -euo pipefail

  local test_dir
  test_dir=$(mktemp -d)
  # shellcheck disable=SC2064 # local変数のためtrap定義時に展開が必要
  trap "rm -rf '${test_dir}'" EXIT

  setup_locale
  setup_mock_gog

  export PATH="${test_dir}:${PATH}"
  export GOG_TASKS_LIST_ID="test-list"
  export GOG_KEYRING_PASSWORD="dummy"

  local fail=0
  local pass=0

  run_all_cases

  printf '\n---\nresult: %d passed, %d failed\n' "${pass}" "${fail}"
  [[ ${fail} -eq 0 ]]
}

setup_locale() {
  # bash ${var:0:n} counts characters under UTF-8 locale but bytes under C locale.
  # Pin to a UTF-8 locale so the multi-byte truncation test stays deterministic.
  local loc
  for loc in en_US.UTF-8 C.UTF-8 ja_JP.UTF-8; do
    if locale -a 2>/dev/null | grep -qix "${loc}"; then
      export LC_ALL="${loc}"
      return
    fi
  done
}

setup_mock_gog() {
  # Mock gog: dump argv one per line so the harness can parse it.
  cat >"${test_dir}/gog" <<'GOG_EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  printf '%s\n' "$arg"
done
GOG_EOF
  chmod +x "${test_dir}/gog"
}

assert_eq() {
  local name=$1 expected=$2 actual=$3
  if [[ ${expected} == "${actual}" ]]; then
    pass=$((pass + 1))
    printf '  ok  %s\n' "${name}"
    return 0
  fi
  fail=$((fail + 1))
  printf '  NG  %s\n' "${name}"
  printf '    expected: %q\n' "${expected}"
  printf '    actual:   %q\n' "${actual}"
}

# Mock gog prints one arg per line; expected layout: tasks add <list> --title <title> --notes <notes>
extract_title() {
  local out=$1
  awk '
    BEGIN { hit=0 }
    {
      if (hit==1) { print; hit=0 }
      if ($0=="--title") { hit=1 }
    }
  ' <<<"${out}"
}

extract_notes() {
  local out=$1
  awk '
    BEGIN { hit=0 }
    {
      if (hit==1) { print }
      if ($0=="--notes") { hit=1 }
    }
  ' <<<"${out}"
}

run_case() {
  local name=$1 json=$2 expected_title=$3 expected_notes=$4
  printf '\n[%s]\n' "${name}"
  local json_path="${test_dir}/ogp.result.json"
  printf '%s' "${json}" >"${json_path}"
  local out
  out=$(bash "${script_dir}/to_gtasks.sh" "${json_path}")
  local actual_title actual_notes
  actual_title=$(extract_title "${out}")
  actual_notes=$(extract_notes "${out}")
  assert_eq "title" "${expected_title}" "${actual_title}"
  assert_eq "notes" "${expected_notes}" "${actual_notes}"
}

run_all_cases() {
  # --- Case 1: GitHub ---
  run_case "github" '{
  "url": "https://github.com/Zackriya-Solutions/meetily",
  "title": "GitHub - Zackriya-Solutions/meetily: Privacy first AI...",
  "description": "Privacy first, AI meeting assistant...",
  "image": "https://example.com/img.png"
}' \
    '[Zackriya-Solutions/meetily](https://github.com/Zackriya-Solutions/meetily)' \
    'Privacy first, AI meeting assistant...'

  # --- Case 2: x.com (description longer than 50 chars) ---
  local x_url="https://x.com/i/status/2058416339136733492"
  local x_title="@とろ港区 on X"
  local x_desc="クレアチンは全ビジネスパーソンが知るべき「脳のハック術」です。「寝不足で頭が回らない」その正体は、脳のエネルギー（ATP）切れ。"
  local expected_x_link="${x_desc:0:50}…"

  run_case "x.com" "$(jq -n \
    --arg u "${x_url}" --arg t "${x_title}" --arg d "${x_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${expected_x_link}](${x_url})" \
    "${x_desc}

${x_title}"

  # --- Case 3: note.com (general site) ---
  local note_url="https://note.com/info/n/nbfac66311b8a"
  local note_title="今月のおすすめnote10選！"
  local note_desc="note編集部がピックアップした、今月のおすすめnoteをご紹介します。"

  run_case "note.com" "$(jq -n \
    --arg u "${note_url}" --arg t "${note_title}" --arg d "${note_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${note_title}](${note_url})" \
    "${note_desc}"

  # --- Case 4: misclog (general site) ---
  local m_url="https://misclog.jp/about/"
  local m_title="misclog・運営者について"
  local m_desc="misclogはオガワ コウが運営するAppleデバイスや周辺機器をレビューするWebサイトです。"

  run_case "misclog" "$(jq -n \
    --arg u "${m_url}" --arg t "${m_title}" --arg d "${m_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${m_title}](${m_url})" \
    "${m_desc}"

  # --- Case 5: x.com short description (no truncate) ---
  local xs_url="https://x.com/foo/status/1"
  local xs_title="@author on X"
  local xs_desc="短いポスト"
  run_case "x.com short" "$(jq -n \
    --arg u "${xs_url}" --arg t "${xs_title}" --arg d "${xs_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${xs_desc}](${xs_url})" \
    "${xs_desc}

${xs_title}"

  # --- Case 6: x.com with empty description (fallback to title) ---
  local xe_url="https://x.com/foo/status/2"
  local xe_title="@author on X"
  run_case "x.com empty desc" "$(jq -n \
    --arg u "${xe_url}" --arg t "${xe_title}" \
    '{url:$u,title:$t,description:"",image:""}')" \
    "[${xe_title}](${xe_url})" \
    "

${xe_title}"

  # --- Case 7: GitHub owner only (no repo) -> fallback to [title](url) ---
  local go_url="https://github.com/anthropics"
  local go_title="anthropics · GitHub"
  local go_desc="Anthropic builds reliable, interpretable, and steerable AI systems."
  run_case "github owner only" "$(jq -n \
    --arg u "${go_url}" --arg t "${go_title}" --arg d "${go_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${go_title}](${go_url})" \
    "${go_desc}"

  # --- Case 8: GitHub reserved path (/orgs/...) -> fallback ---
  local gr_url="https://github.com/orgs/anthropics/repositories"
  local gr_title="Anthropic repositories"
  local gr_desc="Public org repos"
  run_case "github /orgs/" "$(jq -n \
    --arg u "${gr_url}" --arg t "${gr_title}" --arg d "${gr_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[${gr_title}](${gr_url})" \
    "${gr_desc}"

  # --- Case 9: GitHub URL with trailing path -> canonicalize to owner/repo ---
  local gp_url="https://github.com/Zackriya-Solutions/meetily/tree/main/docs"
  local gp_title="meetily/docs at main"
  local gp_desc="docs directory"
  run_case "github with subpath" "$(jq -n \
    --arg u "${gp_url}" --arg t "${gp_title}" --arg d "${gp_desc}" \
    '{url:$u,title:$t,description:$d,image:""}')" \
    "[Zackriya-Solutions/meetily](https://github.com/Zackriya-Solutions/meetily)" \
    "${gp_desc}"
}

main "$@"
