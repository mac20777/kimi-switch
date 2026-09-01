#!/usr/bin/env bash
set -euo pipefail

test_root="$(mktemp -d "${TMPDIR:-/tmp}/kimi-switch-test.XXXXXX")"
cleanup() {
    [[ -n "$test_root" && -d "$test_root" ]] || return
    rm -rf "$test_root"
}
trap cleanup EXIT

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kimi_home="$test_root/kimi-home"
mock_bin="$test_root/bin"
mkdir -p "$kimi_home/credentials" "$kimi_home/accounts" "$mock_bin"

printf '{"account":"A"}\n' > "$kimi_home/credentials/kimi-code.json"
printf '{"account":"A"}\n' > "$kimi_home/accounts/A.credentials.json"
printf '{"account":"B"}\n' > "$kimi_home/accounts/B.credentials.json"
printf 'key-a\n' > "$kimi_home/accounts/A.apikey"
printf 'key-b\n' > "$kimi_home/accounts/B.apikey"
printf 'A' > "$kimi_home/accounts/.current"
: > "$kimi_home/session_index.jsonl"
cat > "$kimi_home/config.toml" <<'EOF'
api_key = "key-a"

[thinking]
effort = "max"
EOF

cat > "$mock_bin/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "-c" ]]; then
    exit 0
fi
shift
cmd="${1:-}"
case "$cmd" in
    best-other)
        if [[ "${MOCK_NO_ALTERNATE:-0}" != "1" ]]; then
            echo B
        fi
        ;;
    synclive|freshen|statusline) ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$mock_bin/python3"

PATH="$mock_bin:$PATH" KIMI_CODE_HOME="$kimi_home" "$repo_root/kimi-switch" help | \
    grep -q '5 小时额度用尽时'
PATH="$mock_bin:$PATH" KIMI_CODE_HOME="$kimi_home" "$repo_root/kimi-switch" help | \
    grep -q '返回退出码 3'

PATH="$mock_bin:$PATH" KIMI_CODE_HOME="$kimi_home" "$repo_root/kimi-switch" rotate >/dev/null
cmp -s "$kimi_home/credentials/kimi-code.json" "$kimi_home/accounts/B.credentials.json"
[[ "$(<"$kimi_home/accounts/.current")" == "B" ]]
grep -q '^api_key = "key-b"$' "$kimi_home/config.toml"

if PATH="$mock_bin:$PATH" KIMI_CODE_HOME="$kimi_home" MOCK_NO_ALTERNATE=1 \
    "$repo_root/kimi-switch" rotate >/dev/null 2>&1; then
    echo "Expected rotate without an alternate account to fail" >&2
    exit 1
fi

echo "kimi-switch-test: PASS"
