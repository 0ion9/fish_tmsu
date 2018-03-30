# tmsu
#
complete -c tmsu -n '__fish_tmsu_needs_command' -f -s v -l verbose --description 'show verbose messages.'
complete -c tmsu -n '__fish_tmsu_needs_command' -f -s h -l help --description 'show help and exit.'
complete -c tmsu -n '__fish_tmsu_needs_command' -f -s V -l version --description 'show version inforamtion and exit.'
complete -c tmsu -n '__fish_tmsu_needs_command' -r -s D -l database --description 'use the specified database.'
complete -c tmsu -n 'set -l c (__fish_tmsu_needs_command); or test $c = help' -f -a 'config copy cp delete del rm dupes files query help imply info init merge mount rename mv repair fix status tag tags unmount umount untag untagged values'

# XXX works with --color=foo but not --color foo
complete -c tmsu -n '__fish_tmsu_needs_command' -f -r -l color -a 'auto always never' --description "use color: auto/always/never."

function __fish_expand_userdir -d 'Expand user directory reference. Surely there is a better way to do this.'
  set argv (string replace -r '^~/' "$HOME/" $argv)
  set argv (string replace -r '^~$' "$HOME" $argv)
  set final
  for a in $argv
    set len (string length $a)
    for v in (string match -rn '^~[^~();$/]+(?=/|$)' $a)
      set start $v[1]
      set l $v[2]
      set parts
      if test $start -gt 1
        set -a parts (string sub -l (math start-1) $a)
      end
      # eval hackery. But reasonably safe since we disallow () $ ;
      set -a parts (eval "echo "(string sub -s $start -l $l $a))
      if test (math start+l) -lt len
        set -a parts (string sub -s (math start+l))
      end
      set a (string join '' parts)
      set len (string length $a)
    end
    set -a final $a
  end
  printf '%s\n' $final
end

function __fish_tmsu_db -d 'Return active tmsu DB, given commandline args'
  # if -D, then use that
  set -l nextarg
  for a in $argv
    switch $a
      case config copy delete dupes files help imply info init merge mount rename repair status tag tags unmount untag untagged values
        # No -D/--database before subcommand == no database specified
        break
      case '-D=*' '--database=*'
        __fish_expand_userdir (string split -m 1 = -- $a)[2]
        return
      case '-D' '--database'
        set nextarg y
      case '*'
	echo "db:nextarg=~$nextarg~ a=$a" >> /tmp/wololo
	if test -n "$nextarg"
          __fish_expand_userdir $a
          return
	end
        continue
    end
  end
  tmsu info | fgrep Database: | cut -d ' ' -f 2-
end

function __fish_print_tmsu_tags_old
  set -l db
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_db $argv)
    set arg --database $db
  end
  set -l tok (commandline -t)
  set -l isquoted 0
  if contains (string sub -s 1 -l 1 "$tok") '"' "'"
    set isquoted 1
  end
  printf "fptt head: -%s-\n" (string sub -s 1 -l 1 "$tok")
  printf "fptt tok: -%s- / isquoted $isquoted\n" $tok >> /tmp/wololo
  if test $isquoted = 1; and test (string sub -s -1 -l 1 "$tok") = " "
    printf "fptt tok!: -%s-\n" $tok >> /tmp/wololo
    set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
    printf "fptt pre!: -%s-\n" $prefix >> /tmp/wololo
    tmsu $arg tags | while read t
      echo "$prefix$t"
    end
  else
    # include versions ending in space, in quoted cases.
    if test $isquoted = 1
      set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
      tmsu $arg tags | while read t; echo "$prefix$t"; echo "$t "; end
    else
      tmsu $arg tags
    end
  end
end

function __fish_print_tmsu_tags
  set -l db
  set -l arg
  set -l showops 0
  set -l ops and or not l{t,e} g{t,e} eq ne "<"{,=} {!,=}= ">"{,=}
  if test "$argv[1]" = "--ops"
    set argv $argv[2..-1]
    set showops 1
  end
  if test -n "$argv[1]"
    set db (__fish_tmsu_db $argv)
    set arg --database $db
  end
  set -l tok (commandline -t)
  set -l isquoted 0
  if contains (string sub -s 1 -l 1 "$tok") '"' "'"
    set isquoted 1
  end
  printf "fptt head: -%s-\n" (string sub -s 1 -l 1 "$tok")
  printf "fptt tok: -%s- / isquoted $isquoted\n" $tok >> /tmp/wololo
  if test $isquoted = 1; and test (string sub -s -1 -l 1 "$tok") = " "
    printf "fptt tok!: -%s-\n" $tok >> /tmp/wololo
    set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
    set prefix (string trim -rc \"\' $prefix)
    printf "fptt pre!: -%s-\n" $prefix >> /tmp/wololo
    tmsu $arg tags | while read t
      echo "$prefix$t"
    end
    if test $showops = 1
      for op in $ops; echo "$prefix$op";end
    end
  else
    # include versions ending in space, in quoted cases.
    if test $isquoted = 1
      set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
      set prefix (string trim -rc \"\' $prefix)
      tmsu $arg tags | while read t; echo "$prefix$t"; echo "$t "; end
      if test $showops = 1
        for op in $ops; echo "$prefix$op";end
      end
    else
      tmsu $arg tags
      if test $showops = 1
        printf '%s\n' $ops
      end
    end
  end
end

function __fish_print_tmsu_values
  set -l db
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_db $argv)
    set arg --database $db
  end
  tmsu $arg values
end

function __fish_print_tmsu_values_for_tag
  set -l db
  set -l tag $argv[1]
  set argv $argv[2..-1]
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_db $argv)
    set arg --database $db
  end
  tmsu $arg values $tag
end

function __fish_print_tmsu_tags_or_tvalues
  set -l db
  set -l tag $argv[1]
  set argv $argv[2..-1]
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_db $argv)
    set arg --database $db
  end
  switch $tag
    # XXX should actually match an unescaped =
    # as is, we sometimes will get f\=oo and look for values
    # when it is a tag only.
    case "*=*"
        set -l t (string match -r '.+?(?=(?<!\\\)=)' $tag)
	and tmsu $arg values $t
    case "*"
        tmsu $arg tags
  end
end


function __fish_tmsu_has_file
  set -l cmd
  if test -n "$argv[1]"
    set cmd $argv
  else
    set cmd (commandline -opc)[2..-1]
  end
  set subcmd (contains -i tag $cmd; or contains -i untag $cmd)
  if not contains tag $cmd;and not contains untag $cmd
    echo "bailout on" $cmd >> /tmp/wololo
    return 1;
  end

  set subcmd $cmd[$subcmd..-1]
  if test (count $subcmd) -eq 1
    return 1
  end
  echo "subcmd" $subcmd >> /tmp/wololo
  set -l skip_next 1
  if test $subcmd[1] = tag;
    echo "tag on - " $subcmd >> /tmp/wololo
    for v in $subcmd[2..-1]
      test $skip_next -eq 0
      and set skip_next 1
      and continue
      switch $v
        case '-c' '--create' '-w' '-w*' '--where' '--where='
          return 0
	case '-f' '--from' '-f*' '--from=*'
	  return 1
        case '-t' '--tags'
          set skip_next 0
          continue
        case '-*'
          continue
        case '*'
          echo "FILED" $v >> /tmp/wololo
          return 0
      end
    end
  else
    for v in $subcmd[2..-1]
      test $skip_next -eq 0
      and set skip_next 1
      and continue
      switch $v
        case '-t' '--tags'
          set skip_next 0
          continue
        case '-*'
          continue
        case '*'
          return 0
      end
    end
  end
  return 1
end

# derived from __fish_git_needs_command
function __fish_tmsu_needs_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 ]
        return 0
    else
        set -l skip_next 1
        # Skip first word because it's "tmsu" or a wrapper
        for c in $cmd[2..-1]
            test $skip_next -eq 0
            and set skip_next 1
            and continue
            switch $c
                # General options that can still take a command
                case "--verbose" "-v" "--database=*" "-D=*" "--color=*"
                    continue
                # General options with an argument we need to skip. The option=value versions
                # have already been handled above
                case '--database' '-D' '--color'
                    set skip_next 0
                    continue
                # General options that cause git to do something and exit - these behave like
                # commands and everything after them is ignored
                case "--version" "-v" "--help" "-h"
                    return 1
                # We assume that any other token that's not an argument to a general option is
                # a command
                case "*"
                    echo $c
                    return 1
            end
        end
        return 0
    end
    return 1
end

function __fish_tmsu_want_file
  if not set -l subc (__fish_tmsu_needs_command);
    switch subc
      case tag
	if __fish_contains_opt -s c -l create
          return 1;
	else 
#          if 
#last_token_is -s t -l tags -s w -l where;
        end
        echo stubbed
	# if last opt was -t/--tags/-w/--where, then no
        # if -c opt, then no.
    end
  else
    return 1
  end
end

# note: copy + rename offer tagnames unconditionally
#       (including in positions where you don't want an existing tagname)
#       This is intentional, so that you can use tab-completion to tell
#	whether the new name will collide with anything.

# config
# COPY/CP completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c copy cp;' -f -a '(__fish_print_tmsu_tags)'
# DELETE/DEL/RM completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c delete del rm' -f -l value --description 'delete a value'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c delete del rm; and __fish_contains_opt value' -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c delete del rm; and not __fish_contains_opt value' -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# DUPES completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = dupes' -s r -l recursive --description 'recursively check directory contents'
# files/query
# HELP completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = help' -f -s l -l list --description 'list commands'

# imply
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = imply' -f -s d -l delete --description 'deletes the tag implication'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = imply' -f -a '(__fish_print_tmsu_tags_or_tvalues (commandline -cpo)[2..-1])'
# init
# MERGE completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = merge' -f -l value --description 'merge values'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = merge; and __fish_contains_opt value' -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = merge; and not __fish_contains_opt value' -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# mount
# RENAME/MV completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c rename mv' -f -l value --description 'rename a value'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c rename mv; and __fish_contains_opt value' -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c rename mv; and not __fish_contains_opt value' -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# repair/fix
# status

# tag
# XXX allow multiple tags to be completed,
# as in `tmsu tag -t '2002 bana<TAB>`. Partly done but fragile
# XXX similar for query
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = tag'
#complete -c tmsu -n "$co;and not __fish_tmsu_has_file"
complete -c tmsu -n $co -f -r -s t -l tags --description 'the set of tags to apply' -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co;and __fish_tmsu_has_file" -f -r -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# XXX this needs to be a custom function, with the following rules
#
# and/or/not must follow a tag, tag=value, value, or ) token
# comparison operators must follow a tag
# values must be suggested when last tokens are TAG CMP
# 'tag=' versions of plain tags must be suggested (at least
# when last token is TAG with no =). When completing them,
# the values should be fetched (ie. tmsu values $tag)
# to create tag=value candidates.
# ( must not follow a comparison operator.
#
complete -c tmsu -n $co -f -r -s w -l where --description 'tags files matching QUERY' -a '(__fish_print_tmsu_tags --ops (commandline -cpo)[2..-1])'
complete -c tmsu -n $co -f -s r -l recursive --description 'Recursively apply tags to directory contents'
complete -c tmsu -n $co -r -s f -l from --description 'copy tags from the SOURCE file'
complete -c tmsu -n $co -f -s c -l create --description 'create tags or values without tagging any files'
complete -c tmsu -n $co -f -s e -l explicit --description 'explicitly apply tags even if they are already implied'
complete -c tmsu -n $co -f -s F -l force --description 'apply tags to non-existent or non-permissioned paths'
complete -c tmsu -n $co -f -s P -l no-dereference --description 'do not follow symbolic links (tag the link itself)'


# tags
# unmount/umount
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = umount' -f -s a -l all --description 'unmounts all mounted TMSU file-systems'
# XXX identify only TMSU (FUSEFS?) mountpoints
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = umount' -a '(__fish_print_mounted)'

# untag
# untagged
# VALUES completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = values'
complete -c tmsu -n $co -f -s c -l count --description 'list # of values rather than their names'
complete -c tmsu -n $co -f -s 1 --description 'list one value per line'
complete -c tmsu -n $co -a '(__fish_print_tmsu_tags)'
#complete -c tmsu -n 'set -l c (__fish_tmsu_needs_command) or test $c = values' -f -a '(__fish_print_tmsu_tags (commandline -cpo))'

# TAG: files should be offered IFF 
#        
#complete -c tmsu - '__fish_tmsu_subcommand tag; and not __fish_contains_opt -s c -l create'

# __fish_commandline_insert_escaped 
# __fish_commandline_is_singlequoted 
# __fish_commandline_test
# __fish_complete_cd __fish_complete_command
# __fish_complete_directories
# __fish_complete_file_url
# __fish_complete_list 
# __fish_complete_path   
# __fish_complete_subcommand 
# __fish_complete_suffix
# __fish_contains_opt
# __fish_describe_command
# __fish_is_first_token
#  __fish_is_token_n
# __fish_make_completion_signals
# __fish_move_last __fish_no_arguments __fish_not_contain_opt
# __fish_number_of_cmd_args_wo_opts __fish_paginate
#  __fish_print_addresses __fish_print_cmd_args
# __fish_print_cmd_args_without_options __fish_print_commands
# __fish_print_encodings
# __fish_pwd
# __fish_reconstruct_path
# __fish_restore_status
# __fish_seen_subcommand_from
# __fish_shared_key_bindings


# toolbox:
#
#  __fish_use_subcommand : has a non-option arg been given?
