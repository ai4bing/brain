#!/usr/bin/zsh

cwd=$0:A:h
source "$cwd/find.sh"
source "$cwd/conf.sh"

_grepLangGrep () {
  grep --color=auto -h "$1" <(grep -niH "$@" | sed 's/.*\/z\//~\/z\//')
}
_grepLangInit () {
  _grepLangSearchPATH=( "$@" )
}
_grepFindFilesToGrep () {
  local findargs=(
    -type f
    -not -wholename '*/.stversions/*'
    -not -wholename '*/docker-data/*'
    -not -wholename '*/node_modules/*'
  )
  # TODO: reuse find.sh functions
  local langfiles=($(find $_grepLangSearchPATH \( -regex ".*/$__brain_suffix""[^/]*[^~]$" -or -regex ".*$__brain_suffix$" -or -regex ".*$__brain_suffix\.[^/]*$" \) $findargs))
  # local todos=($(find $_grepLangSearchPATH -name "todo" -type f))
  # for t in $todos; do langfiles+=$t; done
  #echo "XXX $langfiles" >&2
  echo "${langfiles[@]}"
}
_grepLangAndTodoFiles () {
  _grepLangGrep "$@" $(_grepFindFilesToGrep)
}
# alias grepstu=grepz
grepbsess () {
  _grepLangInit $__brain_session_dir
  _grepLangAndTodoFiles "$@"
}
__brain_grep () {
  _grepLangInit $__brain_roots
  _grepLangAndTodoFiles "$@"
}
