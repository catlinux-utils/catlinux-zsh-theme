# vim:et sts=2 sw=2 ft=zsh
#
# Catlinux fork of Agnoster from zim
#

_prompt_agnoster_main() {
  # This runs in a subshell
  RETVAL=${?}
  CURRENT_BG=

  _prompt_agnoster_status
  _prompt_agnoster_pwd
  _prompt_agnoster_git
  _prompt_agnoster_end
}

_prompt_agnoster_segment() {
  print -n "%K{${1}}"
  if [[ -n ${CURRENT_BG} ]] print -n "%F{${CURRENT_BG}}"
  print -n ${2}
  CURRENT_BG=${1}
}

_prompt_agnoster_standout_segment() {
  print -n "%S%F{${1}}"
  if [[ -n ${CURRENT_BG} ]] print -n "%K{${CURRENT_BG}}%k"
  print -n "${2}%s"
  CURRENT_BG=${1}
}

_prompt_agnoster_custom_segment() {
  local bg_color=$1
  local fg_color=$2
  local content=$3
  print -n "%K{${bg_color}}"
  if [[ -n ${CURRENT_BG} ]]; then
    print -n "%F{${CURRENT_BG}}"
  fi
  print -n "%F{${fg_color}}"
  print -n " ${content} "
  CURRENT_BG=${bg_color}
}

_prompt_agnoster_end() {
  print -n "%k%F{${CURRENT_BG}}%f "
}

_prompt_agnoster_status() {
  local segment=''
  if (( RETVAL )) segment+=' %F{red}✘'
  if (( EUID == 0 )) segment+=' %F{yellow}⚡'
  if (( ${#jobstates} )) segment+=' %F{cyan}⚙'
  if [[ -n ${VIRTUAL_ENV_PROMPT} ]]; then
    segment+=' %F{cyan}'${VIRTUAL_ENV_PROMPT% }
  elif [[ -n ${VIRTUAL_ENV} ]]; then
    segment+=' %F{cyan}'${VIRTUAL_ENV:t}
  fi
  segment+=' %F{%(!.yellow.default)}%n@%m'
  if [[ -n ${segment} ]]; then
    _prompt_agnoster_segment transparent ${segment}' '
  fi
}
_prompt_agnoster_pwd() {
  local current_dir
  prompt-pwd current_dir
  _prompt_agnoster_custom_segment "black" "#02A5F0" "${current_dir}"
}

_prompt_agnoster_git() {
  if [[ -n ${git_info} ]]; then
    _prompt_agnoster_standout_segment ${git_info[color]} ' '${(e)git_info[prompt]}' '
  fi
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}

zstyle ':zim:prompt-pwd:fish-style' dir-length 0

typeset -gA git_info
if (( ${+functions[git-info]} )); then
  zstyle ':zim:git-info:branch' format ' %b'
  zstyle ':zim:git-info:commit' format '➦ %c'
  zstyle ':zim:git-info:ahead' format ' ↑%A'
  zstyle ':zim:git-info:behind' format ' ↓%B'
  zstyle ':zim:git-info:stashed' format ' ⍟%S'
  zstyle ':zim:git-info:indexed' format ' ✚'
  zstyle ':zim:git-info:unindexed' format ' \uf044'
  zstyle ':zim:git-info:action' format '  %s'
  zstyle ':zim:git-info:clean' format 'green'
  zstyle ':zim:git-info:dirty' format '#77ff00'
  zstyle ':zim:git-info:keys' format \
      'prompt' '%b%c%A%B%S%i%I%s' \
      'color' '%C%D'

  autoload -Uz add-zsh-hook && add-zsh-hook precmd git-info
fi

PS1='$(_prompt_agnoster_main)'
unset RPS1