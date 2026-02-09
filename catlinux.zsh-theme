# Catlinux fork of Agnoster from zim

if [[ -t 1 ]] && [[ -n ${TERM} ]] && [[ ${TERM} != dumb ]] && [[ ${TERM} != linux ]]; then
  colors=$(tput colors 2>/dev/null || echo 0)
  locale_val=${LC_ALL:-${LC_CTYPE:-${LANG:-}}}
  if [[ -n ${locale_val} && ( ${locale_val} == *UTF-8* || ${locale_val} == *utf8* ) ]] && (( colors >= 8 )); then
    CATLINUX_FANCY_PROMPT=1
  fi
fi

_prompt_agnoster_main() {
  RETVAL=${?}
  CURRENT_BG=

  _prompt_agnoster_status
  _prompt_agnoster_pwd
  _prompt_agnoster_git
  _prompt_agnoster_end
}

_prompt_agnoster_segment() {
  if (( CATLINUX_FANCY_PROMPT == 0 )); then
    if [[ -n ${CURRENT_BG} ]]; then
      print -n "%F{white}|%f "
    fi
    print -n "%F{${1}}${2}%f "
    CURRENT_BG=${1}
  else
    print -n "%K{${1}}"
    if [[ -n ${CURRENT_BG} ]] print -n "%F{${CURRENT_BG}}"
    print -n ${2}
    CURRENT_BG=${1}
  fi
}

_prompt_agnoster_standout_segment() {
  if (( CATLINUX_FANCY_PROMPT == 0 )); then
    if [[ -n ${CURRENT_BG} ]]; then
      print -n "%F{white}|%f "
    fi
    print -n "%B%F{${1}}${2}%f%b "
    CURRENT_BG=${1}
  else
    print -n "%S%F{${1}}"
    if [[ -n ${CURRENT_BG} ]] print -n "%K{${CURRENT_BG}}%k"
    print -n "${2}%s"
    CURRENT_BG=${1}
  fi
}

_prompt_agnoster_custom_segment() {
  local bg_color=$1
  local fg_color=$2
  local content=$3
  if (( CATLINUX_FANCY_PROMPT == 0 )); then
    if [[ -n ${CURRENT_BG} ]]; then
      print -n "%F{white}|%f "
    fi
    print -n "%F{${fg_color}} ${content} %f "
    CURRENT_BG=${fg_color}
  else
    print -n "%K{${bg_color}}"
    if [[ -n ${CURRENT_BG} ]]; then
      print -n "%F{${CURRENT_BG}}"
    fi
    print -n "%F{${fg_color}}"
    print -n " ${content} "
    CURRENT_BG=${bg_color}
  fi
}

_prompt_agnoster_end() {
  if (( CATLINUX_FANCY_PROMPT == 0 )); then
    print -n "%f%# "
  else
    print -n "%k%F{${CURRENT_BG}}%f "
  fi
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
    _prompt_agnoster_segment black ${segment}' '
  fi
}

_prompt_agnoster_pwd() {
  _prompt_agnoster_custom_segment "black" "#02A5F0" ' %~ '
}

_prompt_agnoster_git() {
  if [[ -n ${git_info} ]]; then
    _prompt_agnoster_standout_segment ${git_info[color]} $'\u2009'${(e)git_info[prompt]}$'\u2009'
  fi
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}

typeset -gA git_info

_update_git_info() {
  git_info=()

  if ! command -v git >/dev/null 2>&1 || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)

  local ahead=0 behind=0
  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    local cnt
    cnt=$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null) || cnt="0\t0"
    behind=${${(s.\t.)cnt}[1]}
    ahead=${${(s.\t.)cnt}[2]}
  fi

  local porcelain indexed=0 unindexed=0
  porcelain=$(git status --porcelain 2>/dev/null)
  if [[ -n $porcelain ]]; then
    while IFS= read -r line; do
      local x=${line[1]} y=${line[2]}
      if [[ $x != ' ' ]]; then indexed=1; fi
      if [[ $y != ' ' ]]; then unindexed=1; fi
    done <<<"$porcelain"
  fi

  local color="green"
  if (( indexed )); then
    color="#77ff00"
  elif (( unindexed )); then
    color="yellow"
  fi

  local prompt
  if (( CATLINUX_FANCY_PROMPT == 0 )); then
    prompt="${branch}"
    if (( indexed )); then prompt+=" +"; fi
    if (( unindexed )); then prompt+=" ~"; fi
    if (( ahead > 0 )); then prompt+=" ahead:${ahead}"; fi
    if (( behind > 0 )); then prompt+=" behind:${behind}"; fi
  else
    prompt=" ${branch}"
    if (( indexed )); then prompt+=" ✚"; fi
    if (( unindexed )); then prompt+=" \uf044"; fi
    if (( ahead > 0 )); then prompt+=" ↑${ahead}"; fi
    if (( behind > 0 )); then prompt+=" ↓${behind}"; fi
  fi

  git_info=(
    prompt "${prompt}"
    color "$color"
  )
}

autoload -Uz add-zsh-hook && add-zsh-hook precmd _update_git_info

PS1='$(_prompt_agnoster_main)'
unset RPS1