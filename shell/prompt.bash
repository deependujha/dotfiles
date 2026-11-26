# shellcheck shell=bash
# Bash prompt. Loaded by init.sh in bash only (zsh keeps its own prompt).
#
#   ~/codes/dotfiles  main*
#   (venv) ❯
#
# Two lines: directory and git branch (with * when dirty), then the Python
# environment and the arrow. user@host appears only over SSH, and the exit
# code only when the last command failed.

PROMPT_DIRTRIM=2
VIRTUAL_ENV_DISABLE_PROMPT=1

__prompt() {
  local ec=$?
  local r='\[\e[0m\]'
  local a='\[\e[38;5;183m\]'   # accent: soft lavender
  local g='\[\e[38;5;244m\]'   # gray

  # git branch (or short sha if detached) + dirty marker
  local git="" branch
  if branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null); then
    local dirty=""
    git diff --quiet --ignore-submodules HEAD 2>/dev/null || dirty="${a}*"
    git="  ${g}${branch}${dirty}${r}"
  fi

  # python env: show project name for generic venv dirs
  local env=""
  if [[ -n ${VIRTUAL_ENV:-} ]]; then
    local vname=${VIRTUAL_ENV##*/}
    case $vname in
      .venv|venv|env|.env) vname=${VIRTUAL_ENV%/*}; vname=${vname##*/} ;;
    esac
    env="(${vname}) "
  elif [[ -n ${CONDA_DEFAULT_ENV:-} ]]; then env="(${CONDA_DEFAULT_ENV}) "
  fi

  # user@host only over SSH
  local host=""
  [[ -n ${SSH_CONNECTION:-} ]] && host="${g}\u@\h${r}  "

  # exit code shown only when the last command failed
  local arrow="${a}❯${r}"
  (( ec != 0 )) && arrow="${g}${ec} ${a}❯${r}"

  PS1="\n${host}${a}\w${r}${git}\n${env}${arrow} "
}

# Must run first so $? is still the last command's exit code. Added only once,
# so `reload` doesn't stack it.
case "${PROMPT_COMMAND:-}" in
  *__prompt*) ;;
  *) PROMPT_COMMAND="__prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
