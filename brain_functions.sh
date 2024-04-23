#!/usr/bin/zsh

cwd=$0:A:h
source "$cwd/conf.sh"
source "$cwd/grep.sh"
source "$cwd/find.sh"

# LANGUAGE
__brain_root_edit () {
    if [[ $# -eq 0 ]]; then
        echo "brain: no search term provided"
        return 1
    fi
    local f=$(__brain_find_file "$@")
    local multiple=0
    [[ "$f" =~ '.*:.*' ]] && multiple=1
    if [[ "$f" == "" ]]; then
        echo "brain: no information available about '$@'"
        return 1
    fi
    if [[ $multiple == 1 ]]; then
        local first=$(echo $f|sed "s,:,\n,g"|head -n1)
        local all=$(echo $f|sed "s,:,\n,g")
        echo -e "brain: ambiguous query result {\n$all\n}, choosing '$first'"
        f="$first"
    fi
    local ff=${f##*/}
    local sess="$__brain_session_dir/${ff%%.*}_${ff##*.}.vim"
    if [[ -f "$sess" ]]; then
        $EDITOR $f -S "$sess" -c "autocmd VimLeave * mksession! $sess"
    else
        $EDITOR $f -c "autocmd VimLeave * mksession! $sess"
    fi
}
__brain_new () {
    if [[ -f "${__brain_roots[2]}/$1.brain${2:+.$2}" ]]; then
        echo "file already exists"
    else
        touch -a "${__brain_roots[2]}/$1.brain${2:+.$2}"
    fi
}
__brain_pw_edit () {
    local __brain_roots=$__brain_pw_roots __brain_suffix=$__brain_pw_suffix
    __brain_root_edit "$@"
}
__brain_session () {
    local sess="$__brain_session_dir/$1.vim"
    [[ -f "$sess" ]] || return 1
    $EDITOR -S $sess
}
__brain_human_files () {
    for f in $(find $__brain_human_root -type f -not \( -name '*~' -or -name '*.vcf' \) ); do
        echo "${f#$__brain_human_root/}"
    done
}
__brain_human_edit () {
    local file="$HOME/z/priv/misc/contact/$1"
    $EDITOR $file
}
__brain_human () {
    __brain_human_edit "$@"
}
brain () {
    if [[ $# -eq 0 ]]; then
        echo "brain"
        echo "  e  | edit <file>     search brain for lan.<file>/<file.lang an open it"
        echo "  n  | new  <file>     new file at ~/z/brainfiles/"
        echo "  g  | grep <string>   grep things from files in roots"
        echo "  f  | find <file>     find file"
        echo "  ls | list            list all brain files"
        echo ""
        echo "  ------------ NOT USED FOR ME ------------"
        echo "  c|contact <name>     search brain for humans"
        echo "  pw <file>            search brain for <file>.pw"
        return 0
    fi
    local arg1="$1"
    shift
    if [[ "$arg1" =~ '^(e|edit)$' ]]; then
        __brain_root_edit "$@"
    elif [[ "$arg1" =~ '^(g|grep)$' ]]; then
        greplang "$@"
    elif [[ "$arg1" =~ '^(pw)$' ]]; then
        __brain_pw_edit "$@"
    elif [[ "$arg1" =~ '^(session)$' ]]; then
        __brain_session "$@"
    elif [[ "$arg1" =~ '^(n|new)$' ]]; then
        __brain_new "$@"
    elif [[ "$arg1" =~ '^(f|find)$' ]]; then
        __brain_list | grep "$@"
    elif [[ "$arg1" =~ '^(ls|list)$' ]]; then
        __brain_list
    elif [[ "$arg1" =~ '^(c|contact)$' ]]; then
        __brain_human "$@"
    fi
}

# completion!
__brain_echo_line () {
    echo "ctx=$context state=$state statedescr=$state_descr line=$line"
}
_brain_2nd () {
    if [[ "$line" =~ '.*(pw).*' ]]; then
        _values 'pw files' $(ls $__brain_pw_roots/*.pw\
                |sed -e "s,$__brain_pw_roots/,,g"\
            |sed -e "s,\(.*\).pw,\1,g")
    elif [[ "$line" =~ '.*(session).*' ]]; then
        _values 'sessions' $(ls $__brain_session_dir/*.vim\
                |sed -e "s,$__brain_session_dir/,,g"\
            |sed -e "s,\(.*\).vim,\1,g")
    elif [[ "$line" =~ '.*(contact).*' ]]; then
        _values 'contact humans' $(__brain_human_files)
    else
        #__brain_echo_line
    fi
}
_brain () {
    local context state state_descr line
    typeset -A opt_args
    _arguments ":operation:(edit new grep find list session pw contact)" ":subject:_brain_2nd"
}
