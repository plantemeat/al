#!/usr/bin/env bash
# al installer
#   curl -fsSL https://raw.githubusercontent.com/<owner>/al/main/install.sh | bash
#   ./install.sh                 # from a local clone (offline)
#   ./install.sh --uninstall     # remove (keeps your aliases.tsv unless --purge)
#
# Env:
#   AL_REPO      owner/repo on GitHub          (default below)
#   AL_REF       branch / tag                  (default: main)
#   AL_RAW_BASE  full raw base URL, overrides the two above
#                e.g. https://ghproxy.net/https://raw.githubusercontent.com/<owner>/al/main
#   AL_HOME      install dir                   (default: ~/.al)
set -euo pipefail

AL_REPO="${AL_REPO:-YOUR_GITHUB_USER/al}"
AL_REF="${AL_REF:-main}"
AL_RAW_BASE="${AL_RAW_BASE:-https://raw.githubusercontent.com/$AL_REPO/$AL_REF}"
AL_HOME="${AL_HOME:-$HOME/.al}"
MARK="# >>> al >>>"
MARK_END="# <<< al <<<"

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

rc_files() {
  local f out=""
  for f in "$HOME/.bashrc" "$HOME/.zshrc"; do [ -f "$f" ] && out="$out $f"; done
  # nothing exists yet: create rc for the login shell
  if [ -z "$out" ]; then
    case "${SHELL:-}" in *zsh) out="$HOME/.zshrc";; *) out="$HOME/.bashrc";; esac
    touch "$out"
  fi
  echo $out
}

strip_block() {  # remove our block from an rc file
  local f=$1 tmp
  grep -qF "$MARK" "$f" 2>/dev/null || return 0
  tmp=$(mktemp)
  awk -v s="$MARK" -v e="$MARK_END" '$0==s{skip=1;next} $0==e{skip=0;next} !skip' "$f" > "$tmp"
  cat "$tmp" > "$f"; rm -f "$tmp"
}

uninstall() {
  local f
  for f in "$HOME/.bashrc" "$HOME/.zshrc"; do [ -f "$f" ] && strip_block "$f"; done
  rm -rf "$AL_HOME/bin" "$AL_HOME/shell" "$AL_HOME/.source" "$AL_HOME/.last_clean"
  if [ "${1:-}" = "--purge" ]; then rm -rf "$AL_HOME"; say "purged $AL_HOME"
  else say "uninstalled (aliases kept in $AL_HOME/aliases.tsv; use --purge to delete)"; fi
  say "open a new shell to finish"
}

fetch() {  # fetch <relpath> <dest>
  local url="$AL_RAW_BASE/$1"
  if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 2 --connect-timeout 10 "$url" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -q -T 10 "$url" -O "$2"
  else die "need curl or wget"; fi || die "download failed: $url  (behind GFW? set AL_RAW_BASE to a mirror)"
}

case "${1:-}" in
  --uninstall) uninstall "${2:-}"; exit 0;;
  --purge)     uninstall --purge; exit 0;;
  -h|--help)   sed -n '2,15p' "$0" 2>/dev/null || true; exit 0;;
esac

for c in awk sort mktemp date; do command -v "$c" >/dev/null 2>&1 || die "missing dependency: $c"; done

mkdir -p "$AL_HOME/bin" "$AL_HOME/shell"

# local clone? (script file sits next to bin/al)
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -f "$d/bin/al" ] && [ -f "$d/shell/al.sh" ] && SRC_DIR=$d
fi

if [ -n "$SRC_DIR" ]; then
  say "installing from local dir $SRC_DIR"
  cp "$SRC_DIR/bin/al" "$AL_HOME/bin/al.tmp"
  cp "$SRC_DIR/shell/al.sh" "$AL_HOME/shell/al.sh.tmp"
else
  say "downloading from $AL_RAW_BASE"
  fetch bin/al "$AL_HOME/bin/al.tmp"
  fetch shell/al.sh "$AL_HOME/shell/al.sh.tmp"
fi
head -1 "$AL_HOME/bin/al.tmp" | grep -q '^#!' || die "downloaded file looks wrong (not a script)"
mv "$AL_HOME/bin/al.tmp" "$AL_HOME/bin/al"
mv "$AL_HOME/shell/al.sh.tmp" "$AL_HOME/shell/al.sh"
chmod +x "$AL_HOME/bin/al"
[ -f "$AL_HOME/aliases.tsv" ] || : > "$AL_HOME/aliases.tsv"

# remember where we came from, for `al update`
printf 'AL_REPO=%q\nAL_REF=%q\nAL_RAW_BASE=%q\n' "$AL_REPO" "$AL_REF" "$AL_RAW_BASE" > "$AL_HOME/.source"

for f in $(rc_files); do
  strip_block "$f"
  printf '\n%s\n[ -f "%s/shell/al.sh" ] && . "%s/shell/al.sh"\n%s\n' \
    "$MARK" "$AL_HOME" "$AL_HOME" "$MARK_END" >> "$f"
  say "hooked into $f"
done

say "installed: $("$AL_HOME/bin/al" version)  ->  $AL_HOME"
echo
echo "  Activate now:   exec \$SHELL"
echo "  Try:            al set sh12 ssh server12 && sh12"
echo "  Help:           al help"
