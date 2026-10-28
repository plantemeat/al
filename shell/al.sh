# al shell integration (bash / zsh). Sourced from ~/.bashrc or ~/.zshrc.
# Turns entries in ~/.al/aliases.tsv into shell functions and keeps them in sync.

AL_HOME="${AL_HOME:-$HOME/.al}"
_AL_BIN="$AL_HOME/bin/al"
_AL_NAMES=""

_al_touch() { command "$_AL_BIN" _touch "$1" 2>/dev/null; }

_al_reload() {
  # eval forces word splitting in both bash and zsh
  [ -n "$_AL_NAMES" ] && eval "unset -f $_AL_NAMES" 2>/dev/null
  _AL_NAMES=""
  eval "$(command "$_AL_BIN" _defs)"
}

# wrapper so that set/unset/clean take effect in the current shell immediately
al() {
  command "$_AL_BIN" "$@"
  local rc=$?
  case "${1:-}" in
    set|add|unset|rm|del|clean|import|update|upgrade) _al_reload ;;
  esac
  return $rc
}

if [ -x "$_AL_BIN" ]; then
  # auto clean expired aliases at most once a day, silently
  _al_stamp="$AL_HOME/.last_clean"
  if [ ! -f "$_al_stamp" ] || [ -n "$(find "$_al_stamp" -mtime +0 2>/dev/null)" ]; then
    command "$_AL_BIN" clean -q >/dev/null 2>&1; : > "$_al_stamp"
  fi
  unset _al_stamp
  _al_reload
fi
