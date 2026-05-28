#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FT="$SCRIPT_DIR/../finish-task"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }
assert_contains() {
  if [[ "$1" == *"$2"* ]]; then ok "$3"; else bad "$3"; echo "    missing: $2"; fi
}
assert_absent() {
  if [[ ! -e "$1" ]]; then ok "$2"; else bad "$2"; echo "    still exists: $1"; fi
}
assert_rc() {
  if [[ "$1" == "$2" ]]; then ok "$3"; else bad "$3"; echo "    expected rc=$1 actual=$2"; fi
}

make_repo() {
  local path="$1"
  git init -q -b main "$path"
  git -C "$path" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$path" remote add origin "$path"
}

make_sandbox() {
  local sb
  sb="$(mktemp -d)"
  mkdir -p "$sb/repos" "$sb/workspaces"
  make_repo "$sb/repos/root"
  make_repo "$sb/repos/app"
  git -C "$sb/repos/root" worktree add -q "$sb/workspaces/t1" -b feat/t1 main
  git -C "$sb/repos/app" worktree add -q "$sb/workspaces/t1/app" -b feat/t1 main
  git -C "$sb/workspaces/t1" update-ref refs/remotes/origin/main "$(git -C "$sb/repos/root" rev-parse main)"
  git -C "$sb/workspaces/t1/app" update-ref refs/remotes/origin/main "$(git -C "$sb/repos/app" rev-parse main)"
  cat > "$sb/config.json" <<EOF
{
  "repos_root": "$sb/repos",
  "workspace_root": "$sb/workspaces",
  "repos": {
    "root": { "base": "main", "remote": "origin", "path": "root" },
    "app": { "base": "main", "remote": "origin" }
  }
}
EOF
  echo "$sb"
}

make_root_dot_sandbox() {
  local sb
  sb="$(mktemp -d)"
  mkdir -p "$sb/root" "$sb/workspaces"
  make_repo "$sb/root"
  cat > "$sb/config.json" <<EOF
{
  "repos_root": "$sb/root",
  "workspace_root": "$sb/workspaces",
  "repos": {
    "root": { "base": "main", "remote": "origin", "path": "." }
  }
}
EOF
  echo "$sb"
}

echo "[1] status shows workspace state"
SB="$(make_sandbox)"
out="$("$FT" status --config "$SB/config.json" --task t1)"
assert_contains "$out" $'TASK\tt1' "prints task id"
assert_contains "$out" "app" "prints app repo"
assert_contains "$out" "MERGED_IN_BASE" "prints merge column"
rm -rf "$SB"

echo "[2] cleanup refuses dirty workspace"
SB="$(make_sandbox)"
echo x > "$SB/workspaces/t1/app/x.txt"
rc=0; "$FT" cleanup --config "$SB/config.json" --task t1 >/tmp/finish-task-test.out 2>&1 || rc=$?
assert_rc 1 "$rc" "dirty cleanup exits non-zero"
assert_contains "$(cat /tmp/finish-task-test.out)" "BLOCK dirty repo" "reports dirty repo"
rm -rf "$SB" /tmp/finish-task-test.out

echo "[3] cleanup removes merged clean workspace"
SB="$(make_sandbox)"
"$FT" cleanup --config "$SB/config.json" --task t1 >/dev/null 2>&1
assert_absent "$SB/workspaces/t1" "task workspace removed"
rm -rf "$SB"

echo "[4] cleanup removes metadata-only task root"
SB="$(make_root_dot_sandbox)"
mkdir -p "$SB/workspaces/t1"
echo "# task" > "$SB/workspaces/t1/TASK.md"
rc=0; "$FT" cleanup --config "$SB/config.json" --task t1 >/tmp/finish-task-test.out 2>&1 || rc=$?
assert_rc 0 "$rc" "metadata-only cleanup exits zero"
assert_absent "$SB/workspaces/t1" "metadata-only task root removed"
rm -rf "$SB" /tmp/finish-task-test.out

echo
echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
