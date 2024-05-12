#!/usr/bin/zsh

__brain_directory_ignores=(.stversions docker-data node_modules .brain_files)
# TODO: fuzzy machtes?
__brain_find_file__find () {
  local root="$1" q="$2"
  local opts=($(printf ' -and -not -wholename "*/%s/*" ' "${__brain_directory_ignores[@]}"))
  local f=($(find "$root" \( -wholename "*/$__brain_suffix.$q" -or -wholename "*/$q.$__brain_suffix" \)    $opts ))
  if [[ $#f -eq 0 ]]; then
    f=($(    find "$root" \( -wholename "*/$q*.$__brain_suffix" -or -wholename "*/$__brain_suffix.*$q*" \) $opts ))
  fi
  echo "${(j/:/)f}"
  [[ $#f -eq 1 ]] || return 1
}
__brain_find_file__fd () {
  local root="$1" q="$2" r="$3"
  local opts=($(printf ' -E "%s" ' "${__brain_directory_ignores[@]}"))
  local f=($(fd $opts "^($__brain_suffix\.$q|$q\.$__brain_suffix|$q\.$__brain_suffix\.$r)" "$root"))
  if [[ $#f -eq 0 ]]; then
    if [[ -n "$3" ]]; then
      f=($(fd $opts "^(${__brain_suffix}\.${q}[^/]*\.${r}|${q}[^/]*\.${__brain_suffix}\.${r})" "$root"))
    else
      f=($(fd $opts "^(${__brain_suffix}\.${q}[^/]*|${q}[^/]*\.${__brain_suffix})" "$root"))
    fi
  fi
  echo "${(j/:/)f}"
  [[ $#f -eq 1 ]] || return 1
}
__brain_find_file_in_path () {
  local root="$1" q="$2" r="$3"
  if which fd > /dev/null; then
    __brain_find_file__fd "$root" "$q" "$r"
  else
    __brain_find_file__find "$root" "$q" "$r"
  fi
  return $?
}
__brain_find_all () {
  local all=$(__brain_find_file "")
  for f in $(echo "$all"|sed "s,:,\n,g"); do
    if [[ "$1" == "complete_path" ]]; then
      echo "$f"
    else
      echo $f|sed 's,.*/\(.*\),\1,g'
    fi
  done
}
__brain_list () {
  local all=$(__brain_find_file "")
  for f in $(echo "$all" | sed "s,:,\n,g" | sed 's/.*\/z\//~\/z\//'); do
    echo "$f"
  done
}
__brain_set_roots () {
  __brain_roots=($@)
}
__brain_find_file () {
  local q="$1" r="$2"
  local multiple=0 res=()
  for root in $__brain_roots; do
    res+=($(__brain_find_file_in_path "$root" "$q" "$r"))
    [[ $? -eq 0 ]] || multiple=1
  done
  echo "${(j/:/)res}"
  if [[ $#res -ne 1 ]] || [[ $multiple == 1 ]]; then
    return 1
  fi
  return 0
}
