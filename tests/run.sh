#!/usr/bin/env bash
# Run: bash tests/run.sh   — installs into a throwaway HOME and exercises bash + zsh
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  \033[31mFAIL\033[0m %s\n     got: %s\n' "$1" "$2"; }
check() { # name expected actual
  case "$3" in *"$2"*) ok "$1";; *) bad "$1" "$3";; esac
}

for SH in bash zsh; do
  command -v $SH >/dev/null || { echo "skip $SH"; continue; }
  echo "== $SH"
  export HOME=$(mktemp -d); touch "$HOME/.bashrc" "$HOME/.zshrc"
  bash "$ROOT/install.sh" >/dev/null || { bad "install" "failed"; continue; }
  RC="$HOME/.${SH}rc"
  run() { $SH -c ". '$RC' 2>/dev/null; $1" 2>&1; }

  check "installed version"    "al 0.1.0"            "$(run 'al version')"
  check "rc block present"     ">>> al >>>"          "$(cat "$RC")"
  check "set with 'as'"        "set: hi -> echo hello" "$(run 'al set hi as echo hello')"
  check "alias runs + args"    "hello world"         "$(run 'hi world')"
  check "same-shell reload"    "bye"                 "$(run 'al set by echo bye >/dev/null; by')"
  run "al set zp 'echo a-b | tr - +'" >/dev/null
  check "pipe in command"      "a+b"                 "$(run 'zp')"
  run "al set qq 'echo \"it'\\''s fine\"'" >/dev/null
  check "single quote in cmd"  "it's fine"           "$(run 'qq')"
  check "show lists"           "hi"                  "$(run 'al show')"
  check "show filter"          "zp"                  "$(run 'al show tr')"
  check "last_used recorded"   "$(date +%Y-%m-%d)"   "$(run 'al show hi')"
  check "reserved name"        "reserved"            "$(run 'al set cd echo x')"
  check "shadow PATH cmd"      "use -f"              "$(run 'al set grep echo x')"
  check "invalid name"         "invalid name"        "$(run 'al set 1a echo x')"
  check "bad ttl"              "bad TTL"             "$(run 'al set -t 3y zz echo x')"
  check "ttl set"              "expires"             "$(run 'al set -t 1s tmp echo tmp')"
  sleep 2
  check "show expired"         "expired"             "$(run 'al show tmp')"
  check "expired not defined"  "not found"           "$(run 'tmp')"
  check "clean dry-run"        "would remove: tmp"   "$(run 'al clean -n')"
  check "clean"                "removed: tmp"        "$(run 'al clean')"
  check "clean --unused"       "nothing to remove"   "$(run 'al clean --unused 1d')"
  check "unset"                "unset: hi"           "$(run 'al unset hi')"
  check "unset removes func"   "not found"           "$(run 'al unset by >/dev/null; by')"
  check "unset missing"        "no such alias"       "$(run 'al unset nope')"
  run 'al export' > "$HOME/exp.tsv"
  run 'al unset zp qq' >/dev/null
  check "import"               "imported 2"          "$(run "al import $HOME/exp.tsv")"
  check "import works"         "a+b"                 "$(run 'zp')"
  bash "$ROOT/install.sh" >/dev/null
  check "reinstall idempotent" "1"                   "$(grep -c '>>> al >>>' "$RC")"
  check "data kept on reinst"  "zp"                  "$(run 'al show')"
  bash "$ROOT/install.sh" --uninstall >/dev/null
  check "uninstall cleans rc"  "0"                   "$(grep -c '>>> al >>>' "$RC")"
  check "uninstall keeps data" "zp"                  "$(cat "$HOME/.al/aliases.tsv")"
  rm -rf "$HOME"
done

echo; echo "passed: $pass  failed: $fail"
[ "$fail" = 0 ]
