#!/usr/bin/env bash
# worktree-task 测试。隔离 sandbox(临时目录 + 一次性 git repo),每个用例独立。
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WT="$SCRIPT_DIR/../worktree-task"
PASS=0
FAIL=0

assert_eq() { # 期望 实际 描述
  if [[ "$1" == "$2" ]]; then
    PASS=$((PASS + 1)); echo "  ✓ $3"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $3"; echo "    期望: [$1]"; echo "    实际: [$2]"
  fi
}
assert_dir() { # 路径 描述
  if [[ -d "$1" ]]; then PASS=$((PASS + 1)); echo "  ✓ $2"
  else FAIL=$((FAIL + 1)); echo "  ✗ $2 (目录不存在: $1)"; fi
}
assert_file() { # 路径 描述
  if [[ -f "$1" ]]; then PASS=$((PASS + 1)); echo "  ✓ $2"
  else FAIL=$((FAIL + 1)); echo "  ✗ $2 (文件不存在: $1)"; fi
}
assert_grep() { # 文件 模式 描述
  if grep -q "$2" "$1" 2>/dev/null; then PASS=$((PASS + 1)); echo "  ✓ $3"
  else FAIL=$((FAIL + 1)); echo "  ✗ $3 (未匹配 [$2]: $1)"; fi
}
assert_contains() { # 字符串 子串 描述
  if [[ "$1" == *"$2"* ]]; then PASS=$((PASS + 1)); echo "  ✓ $3"
  else FAIL=$((FAIL + 1)); echo "  ✗ $3 (输出不含 [$2])"; fi
}
assert_absent() { # 路径 描述
  if [[ ! -e "$1" ]]; then PASS=$((PASS + 1)); echo "  ✓ $2"
  else FAIL=$((FAIL + 1)); echo "  ✗ $2 (路径仍存在: $1)"; fi
}

make_sandbox() {
  local sb; sb="$(mktemp -d)"
  mkdir -p "$sb/repos" "$sb/wt"
  echo "$sb"
}
make_repo() { # sandbox 名字 [基线分支=dev]
  local r="$1/repos/$2" base="${3:-dev}"
  local up="$1/upstream-$2"
  git init -q --bare "$up"
  git init -q -b "$base" "$r"
  git -C "$r" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$r" remote add origin "$up"
  git -C "$r" push -q -u origin "$base"
}
make_cloned_repo() { # sandbox 名字  -> repos/<名字> 是 clone:本地只有 main,基线 dev 仅在 origin
  local up="$1/upstream-$2"
  git init -q -b main "$up"
  git -C "$up" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$up" branch dev
  git clone -q "$up" "$1/repos/$2"
}
make_stale_cloned_repo() { # sandbox 名字 [remote=origin] -> local dev 落后 remote/dev
  local sb="$1" name="$2" remote="${3:-origin}"
  local up="$sb/upstream-$name" seed="$sb/seed-$name" repo="$sb/repos/$name"
  git init -q --bare "$up"
  git clone -q "$up" "$seed"
  git -C "$seed" switch -q -c dev
  git -C "$seed" -c user.name=t -c user.email=t@t commit -q --allow-empty -m old
  git -C "$seed" push -q origin dev
  git clone -q "$up" "$repo"
  git -C "$repo" switch -q dev
  git -C "$seed" -c user.name=t -c user.email=t@t commit -q --allow-empty -m new
  git -C "$seed" push -q origin dev
  if [[ "$remote" != "origin" ]]; then
    git -C "$repo" remote rename origin "$remote"
  fi
}
write_config() { # sandbox [repo:base[:remote] ...]  默认 myrepo:dev  -> 打印配置文件路径
  local sb="$1"; shift
  [[ $# -gt 0 ]] || set -- myrepo:dev
  local cfg="$sb/dev-project.json" entries="" spec name base remote remote_json
  for spec in "$@"; do
    IFS=':' read -r name base remote <<< "$spec"
    remote_json=""
    [[ -n "${remote:-}" ]] && remote_json=",\"remote\":\"$remote\""
    entries+="\"$name\":{\"base\":\"$base\"$remote_json},"
  done
  cat > "$cfg" <<EOF
{
  "project": "test",
  "repos_root": "$sb/repos",
  "worktree_root": "$sb/wt",
  "repos": { ${entries%,} }
}
EOF
  echo "$cfg"
}

# ── 用例 1:create 为单 repo 建出 task 分支 worktree ──────────────
echo "[1] create 为单 repo 建出 task 分支 worktree"
SB="$(make_sandbox)"
make_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t1 --repos myrepo > /dev/null 2>&1
assert_dir "$SB/wt/t1/myrepo" "worktree 目录已建"
assert_eq "feat/t1" "$(git -C "$SB/wt/t1/myrepo" branch --show-current 2>/dev/null)" "分支是 feat/t1"
rm -rf "$SB"

# ── 用例 2:create 在任务根写 TASK.md 骨架 ──────────────────────
echo "[2] create 在任务根写 TASK.md 骨架"
SB="$(make_sandbox)"
make_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t2 --repos myrepo > /dev/null 2>&1
assert_file "$SB/wt/t2/TASK.md" "TASK.md 已建"
assert_grep "$SB/wt/t2/TASK.md" "t2" "TASK.md 含任务 id"
assert_grep "$SB/wt/t2/TASK.md" "Issue: <待创建/待关联>" "TASK.md 含 Issue 占位"
assert_grep "$SB/wt/t2/TASK.md" "交付模式: MR 审查" "TASK.md 含默认交付模式"
rm -rf "$SB"

# ── 用例 3:list 列出已建任务工作区 ─────────────────────────────
echo "[3] list 列出已建任务工作区"
SB="$(make_sandbox)"
make_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t1 --repos myrepo > /dev/null 2>&1
out="$("$WT" list --config "$CFG" 2>/dev/null)"
assert_contains "$out" "t1" "list 输出含 t1"
rm -rf "$SB"

# ── 用例 4:remove 删除任务工作区(含 git worktree 记录)─────────
echo "[4] remove 删除任务工作区"
SB="$(make_sandbox)"
make_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t1 --repos myrepo > /dev/null 2>&1
"$WT" remove --config "$CFG" --task t1 > /dev/null 2>&1
assert_absent "$SB/wt/t1" "任务目录已删除"
assert_eq "1" "$(git -C "$SB/repos/myrepo" worktree list | wc -l | tr -d ' ')" "源仓只剩主 worktree"
rm -rf "$SB"

# ── 用例 5:create 多 repo 全部建出,同名 task 分支 ──────────────
echo "[5] create 多 repo 全部建出"
SB="$(make_sandbox)"
make_repo "$SB" a
make_repo "$SB" b
CFG="$(write_config "$SB" a:dev b:dev)"
"$WT" create --config "$CFG" --task t5 --repos a,b > /dev/null 2>&1
assert_dir "$SB/wt/t5/a" "repo a 的 worktree 已建"
assert_dir "$SB/wt/t5/b" "repo b 的 worktree 已建"
assert_eq "feat/t5" "$(git -C "$SB/wt/t5/a" branch --show-current 2>/dev/null)" "a 分支 feat/t5"
assert_eq "feat/t5" "$(git -C "$SB/wt/t5/b" branch --show-current 2>/dev/null)" "b 分支 feat/t5"
rm -rf "$SB"

# ── 用例 6:create 任务已存在时报错退出 ─────────────────────────
echo "[6] create 任务已存在时报错退出"
SB="$(make_sandbox)"
make_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t1 --repos myrepo > /dev/null 2>&1
rc=0; "$WT" create --config "$CFG" --task t1 --repos myrepo > /dev/null 2>&1 || rc=$?
assert_eq "1" "$rc" "重复 create 以退出码 1 报错"
rm -rf "$SB"

# ── 用例 7:config 文件不存在时报错退出 ─────────────────────────
echo "[7] config 不存在时报错退出"
SB="$(make_sandbox)"
rc=0; "$WT" create --config "$SB/nonexist.json" --task t1 --repos myrepo > /dev/null 2>&1 || rc=$?
assert_eq "1" "$rc" "缺 config 以退出码 1 报错"
rm -rf "$SB"

# ── 用例 8:未知命令打印用法并非零退出 ─────────────────────────
echo "[8] 未知命令打印用法并非零退出"
rc=0; out="$("$WT" bogus 2>&1)" || rc=$?
assert_eq "1" "$rc" "未知命令退出码 1"
assert_contains "$out" "用法" "打印了用法说明"

# ── 用例 9:基线分支只在远程(clone 来的仓)时仍切到 task 分支 ────
echo "[9] create:基线分支只在远程时仍切到 task 分支"
SB="$(make_sandbox)"
make_cloned_repo "$SB" myrepo
CFG="$(write_config "$SB")"
"$WT" create --config "$CFG" --task t9 --repos myrepo > /dev/null 2>&1
assert_eq "feat/t9" "$(git -C "$SB/wt/t9/myrepo" branch --show-current 2>/dev/null)" "分支是 feat/t9(非 dev)"
assert_absent "$SB/wt/t9/dev" "无多余 dev 目录"
rm -rf "$SB"

# ── 用例 10:本地 base 落后远端时使用远端最新 commit ─────────────
echo "[10] create:本地 base 落后远端时使用远端最新 commit"
SB="$(make_sandbox)"
make_stale_cloned_repo "$SB" myrepo
CFG="$(write_config "$SB")"
remote_hash="$(git -C "$SB/repos/myrepo" ls-remote origin refs/heads/dev | awk '{print $1}')"
"$WT" create --config "$CFG" --task t10 --repos myrepo > /dev/null 2>&1
wt_hash="$(git -C "$SB/wt/t10/myrepo" rev-parse HEAD)"
assert_eq "$remote_hash" "$wt_hash" "worktree HEAD 使用 origin/dev 最新 commit"
assert_grep "$SB/wt/t10/TASK.md" "$remote_hash" "TASK.md 记录 baseline commit"
rm -rf "$SB"

# ── 用例 11:配置 remote 非 origin 时使用对应远端 ────────────────
echo "[11] create:配置 remote 非 origin 时使用对应远端"
SB="$(make_sandbox)"
make_stale_cloned_repo "$SB" myrepo gitlab
CFG="$(write_config "$SB" myrepo:dev:gitlab)"
remote_hash="$(git -C "$SB/repos/myrepo" ls-remote gitlab refs/heads/dev | awk '{print $1}')"
"$WT" create --config "$CFG" --task t11 --repos myrepo > /dev/null 2>&1
wt_hash="$(git -C "$SB/wt/t11/myrepo" rev-parse HEAD)"
assert_eq "$remote_hash" "$wt_hash" "worktree HEAD 使用 gitlab/dev 最新 commit"
assert_grep "$SB/wt/t11/TASK.md" "gitlab/dev" "TASK.md 记录非 origin baseline ref"
rm -rf "$SB"

echo
echo "PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
