#!/usr/bin/zsh

# brain file extention (search via edit)
__brain_suffix="brain"
__brain_suffix2="br"
# brain file directories (all of them will be search on every edit call)
__brain_roots=($HOME/bsess $HOME/z/testbrain)
# brain session storage directory
__brain_session_dir=$__brain_roots[1]
# brain pw directories searched for '.$__brain_pw_suffix' files
# (encryption is on you sir..)
__brain_pw_roots=($HOME/z/priv/misc/intl)
__brain_pw_suffix=pw
# brain contact root directory
__brain_human_root=$HOME/z/priv/misc/contact
