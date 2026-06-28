# dev-bootstrap shell integration
#
# Single entry point: sources the shared aliases/functions and links the
# scripts directory into PATH and the zsh completion fpath.
#
# Install: add ONE line to your ~/.zshrc (before `compinit`):
#   [ -f "$HOME/scripts/dev-bootstrap/scripts/source.sh" ] && source "$HOME/scripts/dev-bootstrap/scripts/source.sh"

_dbs="${HOME}/scripts/dev-bootstrap/scripts"

# Shared aliases and helper functions
[ -f "$_dbs/aliases.sh" ] && source "$_dbs/aliases.sh"
[ -f "$_dbs/wrap_functions.sh" ] && source "$_dbs/wrap_functions.sh"
[ -f "$_dbs/func_cdr.sh" ] && source "$_dbs/func_cdr.sh"
[ -f "$_dbs/yt-download/functions.sh" ] && source "$_dbs/yt-download/functions.sh"
[ -f "$_dbs/claude-lmstudio.sh" ] && source "$_dbs/claude-lmstudio.sh"
[ -f "$_dbs/pi-lmstudio.sh" ] && source "$_dbs/pi-lmstudio.sh"

# Link the scripts directory into PATH (idempotent)
case ":$PATH:" in
  *":$_dbs:"*) ;;
  *) export PATH="$_dbs:$PATH" ;;
esac

# Add zsh completions to fpath (run `compinit` afterwards in your ~/.zshrc)
fpath=("$_dbs/completions" $fpath)

unset _dbs
