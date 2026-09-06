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

# 生成用量 fixture（配合 KS_USAGE_FIXTURES 测试缝，全程不碰网络）
# 参数：<账号名> <h5_used> <h5_limit> <week_used> <week_limit> <h5_多少秒后重置> <week_多少秒后重置>
fixtures="$test_root/fixtures"
mkdir -p "$fixtures"
make_fixture() {
    python3 - "$fixtures/$1.usage.json" "$2" "$3" "$4" "$5" "$6" "$7" <<'FIXEOF'
import json, sys, time
from datetime import datetime, timezone
path, h5u, h5l, wu, wl, h5r, wr = sys.argv[1:8]
def iso(secs):
    return datetime.fromtimestamp(time.time() + int(secs), timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
with open(path, 'w') as f:
    json.dump({
        'usage': {'used': int(wu), 'limit': int(wl), 'resetTime': iso(wr)},
        'limits': [{'window': {'duration': 300, 'timeUnit': 'TIME_UNIT_MINUTE'},
                    'detail': {'used': int(h5u), 'limit': int(h5l), 'resetTime': iso(h5r)}}],
    }, f)
FIXEOF
}

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

# ---- 平衡策略测试（KS_USAGE_FIXTURES + 真实 python3，不走网络）----

# 复位环境：A 为当前账号
cp "$kimi_home/accounts/A.credentials.json" "$kimi_home/credentials/kimi-code.json"
printf 'A' > "$kimi_home/accounts/.current"
cat > "$kimi_home/config.toml" <<'EOF'
api_key = "key-a"

[thinking]
effort = "max"
EOF
rm -f "$kimi_home/accounts/.watch-state.json"

# 场景 1：A 明天重置剩 60%（紧迫），B 6 天后重置剩 20%，5h 都充足 → 必须选 A
make_fixture A 10 100 40 100 18000 86400
make_fixture B 10 100 80 100 18000 518400
pick=$(KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" best)
[[ "$pick" == "A" ]] || { echo "balance case 1: expected A, got $pick" >&2; exit 1; }

# 场景 2：对调（B 明天重置剩 60%）→ 必须选 B（不被"保持当前"迟滞留住）
make_fixture A 10 100 80 100 18000 518400
make_fixture B 10 100 40 100 18000 86400
pick=$(KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" best)
[[ "$pick" == "B" ]] || { echo "balance case 2: expected B, got $pick" >&2; exit 1; }

# 场景 3：A 紧迫但 5h 已打满 → A 被门槛排除，选 B；best -v 末行仍是选中名
make_fixture A 100 100 40 100 18000 86400
make_fixture B 10 100 80 100 18000 518400
verbose_out=$(KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" best -v)
[[ "$(printf '%s\n' "$verbose_out" | tail -1)" == "B" ]] || { echo "balance case 3: expected B" >&2; exit 1; }
printf '%s' "$verbose_out" | grep -q '节奏盈余'
printf '%s' "$verbose_out" | grep -q '门槛'

# 场景 4：watch --once 预判热切——当前 A 的 5h 剩 5%（阈值 10%）→ 切到 B
cp "$kimi_home/accounts/A.credentials.json" "$kimi_home/credentials/kimi-code.json"
printf 'A' > "$kimi_home/accounts/.current"
rm -f "$kimi_home/accounts/.watch-state.json"
make_fixture A 95 100 50 100 18000 345600
make_fixture B 10 100 50 100 18000 345600
KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" watch --once >/dev/null
cmp -s "$kimi_home/credentials/kimi-code.json" "$kimi_home/accounts/B.credentials.json"
[[ "$(<"$kimi_home/accounts/.current")" == "B" ]]
grep -q '^api_key = "key-b"$' "$kimi_home/config.toml"

# 场景 5：watch --once 无人可切——B（当前）和 A 的 5h 都见底 → 保持 B、退出码 3
rm -f "$kimi_home/accounts/.watch-state.json"
make_fixture A 100 100 50 100 18000 345600
make_fixture B 100 100 50 100 18000 345600
rc=0
KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" watch --once >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 3 ]] || { echo "watch wait case: expected exit 3, got $rc" >&2; exit 1; }
cmp -s "$kimi_home/credentials/kimi-code.json" "$kimi_home/accounts/B.credentials.json"
[[ "$(<"$kimi_home/accounts/.current")" == "B" ]]

# 场景 6：watch --once 余量健康 → STAY，退出码 0，不切号
rm -f "$kimi_home/accounts/.watch-state.json"
make_fixture B 10 100 50 100 18000 345600
out=$(KIMI_CODE_HOME="$kimi_home" KS_USAGE_FIXTURES="$fixtures" "$repo_root/kimi-switch" watch --once)
printf '%s' "$out" | grep -q '余量健康'
cmp -s "$kimi_home/credentials/kimi-code.json" "$kimi_home/accounts/B.credentials.json"

echo "kimi-switch-test: PASS"
