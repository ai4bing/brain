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
    if $brain_with_session; then
      if [[ -f "$sess" ]]; then
          $EDITOR $f -S "$sess" -c "autocmd VimLeave * mksession! $sess"
      else
          $EDITOR $f -c "autocmd VimLeave * mksession! $sess"
      fi
    else
      vim -i NONE --cmd 'set noswapfile' --cmd 'set nobackup' $f
    fi
}
__brain_new () {
    if [[ -f "${__brain_roots[1]}/$1.brain${2:+.$2}" ]]; then
        echo "file already exists"
    else
        touch -a "${__brain_roots[1]}/$1.brain${2:+.$2}"
    fi
}
__brain_pw_edit () {
    local __brain_roots=$__brain_pw_roots __brain_suffix=$__brain_pw_suffix
    local brain_with_session=false
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
        echo "  e  | edit <file>     search brain for brain.<file>/<file>.brain an open it"
        echo "  n  | new  <file>     new file at ~/z/brainfiles DON'T create file with space"
        echo "  g  | grep <string>   grep things from files in __brain_roots"
        echo "  f  | find <file>     find file"
        echo "  t  | todo            find todo"
        echo "  ls | list            list all brain files"
        echo "  pw <file>            search brain for <file>.pw"
        echo "  sync                 rsync to icloud"
        echo ""
        echo "  ------------ NOT USED FOR ME ------------"
        echo "  c  | contact <name>     search brain for humans"
        return 0
    fi
    local arg1="$1"
    shift
    if [[ "$arg1" =~ '^(e|edit|e1|e2|edit1|edit2)$' ]]; then
        __brain_root_edit "$@"
        # rsync target must not contain the final slash when syncing folders, otherwise would be synced into targer folder
        rsync -a --exclude={'priv','sess'} --delete-excluded ~/z/ ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/z
    elif [[ "$arg1" =~ '^(g|grep)$' ]]; then
        __brain_grep "$@"
    elif [[ "$arg1" =~ '^(pw)$' ]]; then
        __brain_pw_edit "$@"
    elif [[ "$arg1" =~ '^(sync)$' ]]; then
        rsync -a --exclude={'priv','sess'} --delete-excluded ~/z/ ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/z
    elif [[ "$arg1" =~ '^(session)$' ]]; then
        # __brain_session "$@"
        echo "use brain edit"
    elif [[ "$arg1" =~ '^(n|new)$' ]]; then
        __brain_new "$@"
    elif [[ "$arg1" =~ '^(f|find)$' ]]; then
        __brain_list | grep -i "$@"
    elif [[ "$arg1" =~ '^(ls|list)$' ]]; then
        __brain_list
    elif [[ "$arg1" =~ '^(c|contact)$' ]]; then
        # __brain_human "$@"
        echo "deprecated"
    elif [[ "$arg1" =~ '^(t|todo)$' ]]; then
        __brain_grep '\(TODO\|NOTE\|FIXME\|XXX\|HELP\|WHY\|WTF\|CONTINUE\)'
    else
        echo "Invalid usage."
    fi
}

# completion!
__brain_echo_line () {
    echo "ctx=$context state=$state statedescr=$state_descr line=$line"
}
_brain_2nd () {
    if [[ "$line" =~ '.*e1.*|.*(edit1).*' ]]; then
        _values 'files' $(ls $__brain_roots[1]/*.brain.*\
                |sed -e "s,$__brain_roots[1]/,,g"\
            |sed -e "s,\(.*\).brain.*,\1,g")
    elif [[ "$line" =~ '.*e2.*|.*(edit2).*' ]]; then
        _values 'files' $(ls $__brain_roots[2]/*.brain.*\
                |sed -e "s,$__brain_roots[2]/,,g"\
            |sed -e "s,\(.*\).brain.*,\1,g")
    elif [[ "$line" =~ '.*e.*|.*(edit).*' ]]; then
        _values 'files' $(ls $__brain_roots[1]/*.brain.* $__brain_roots[2]/*.brain.*\
                |sed -e "s,$__brain_roots[1]/,,g" -e "s,$__brain_roots[2]/,,g"\
            |sed -e "s,\(.*\).brain.*,\1,g")
    elif [[ "$line" =~ '.*(pw).*' ]]; then
        _values 'pw files' $(ls $__brain_pw_roots/*.pw.gpg\
                |sed -e "s,$__brain_pw_roots/,,g"\
            |sed -e "s,\(.*\).pw.gpg,\1,g")
    # elif [[ "$line" =~ '.*(session).*' ]]; then
    #     _values 'sessions' $(ls $__brain_session_dir/*.vim\
    #             |sed -e "s,$__brain_session_dir/,,g"\
    #         |sed -e "s,\(.*\).vim,\1,g")  # WTF not sure why doesn't this show '_txt'
    # elif [[ "$line" =~ '.*(contact).*' ]]; then
        # _values 'contact humans' $(__brain_human_files)
    else
        #__brain_echo_line
    fi
}
_brain () {
    local context state state_descr line
    typeset -A opt_args
    _arguments ":operation:(edit1 edit2 edit new grep find list pw)" ":subject:_brain_2nd"
}
