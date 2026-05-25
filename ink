#!/data/data/com.termux/files/usr/bin/bash

_ink() {
  local stdin=
  if [[ ! -t 0 ]]; then
    stdin="$(cat <&0)"
  fi
  if [[ $# -eq 0 && -z $stdin ]]; then
    return
  fi

  local open="\033["
  local close="${open}0m"
  export black="0;30m"
  export red="1;31m"
  export green="1;32m"
  export yellow="1;33m"
  export blue="1;34m"
  export purple="1;35m"
  export cyan="1;36m"
  export gray="0;37m"
  export white="$close"

  local text="$stdin$*"
  local color="$close"

  case $1 in
    black | red | green | yellow | blue | purple | cyan | gray | white)
      eval color="\$$1"
      text="$stdin${*:2}"
      ;;
  esac

  # %b: ${open}="\033[" などバックスラッシュエスケープを printf に解釈させる（%s だと ANSI コードが文字列として出力される）
  printf "%b%b%b%b\n" "${open}" "${color}" "${text}" "${close}" 1>&2
}

main() {
  if [[ $# -eq 0 ]]; then
    for col in black red green yellow blue purple cyan gray white; do
      echo $col | _ink $col
    done
    return
  fi
  _ink "$@"
}
main "$@"
