# tmsu completion. Requires functions/__fish_expand_userdir.fish and __fish_tmsu_database.fish
#

set -u log /tmp/.fishtmsu.log

complete -c tmsu -n '__fish_tmsu_needs_command' -f -s v -l verbose --description 'show verbose messages.'
complete -c tmsu -n '__fish_tmsu_needs_command' -f -s h -l help --description 'show help and exit.'
complete -c tmsu -n '__fish_tmsu_needs_command' -f -s V -l version --description 'show version inforamtion and exit.'
complete -c tmsu -n '__fish_tmsu_needs_command' -r -s D -l database --description 'use the specified database.'
complete -c tmsu -n 'set -l c (__fish_tmsu_needs_command); or test $c = help' -f -a 'config copy cp delete del rm dupes files query help imply info init merge mount rename mv repair fix status tag tags unmount umount untag untagged values'

# XXX works with --color=foo but not --color foo
complete -c tmsu -n '__fish_tmsu_needs_command' -f -r -l color -a 'auto always never' --description "use color: auto/always/never."

function __fish_print_tmsu_tags_old
  set -l db
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_database $argv)
    set arg --database $db
  end
  set -l tok (commandline -t)
  set -l isquoted 0
  if contains (string sub -s 1 -l 1 "$tok") '"' "'"
    set isquoted 1
  end
  #
  printf "fptt head: -%s-\n" (string sub -s 1 -l 1 "$tok") >> $log
  printf "fptt tok: -%s- / isquoted $isquoted\n" $tok >> $log
  if test $isquoted = 1; and test (string sub -s -1 -l 1 "$tok") = " "
    printf "fptt tok!: -%s-\n" $tok >> $log
    set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
    printf "fptt pre!: -%s-\n" $prefix >> $log
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
  set -l values_for_tag
  echo "fptt: argv = $argv" >> $log
  if test "$argv[1]" = "--ops"
    set argv $argv[2..-1]
    set showops 1
  end
  if test "$argv[1]" = "--tag"
    echo "values_for_tag set to $argv[2]" >> $log
    set values_for_tag $argv[2]
    set argv $argv[3..-1]
  end

  if test -n "$argv[1]"
    set db (__fish_tmsu_database $argv)
    if test -z "$db"
      # DB doesn't exist
      return
    end
    set arg --database $db
  end
  # XXX use __fish_commandline_is_singlequoted instead of this hack.
  set -l tok (commandline -t)
  set -l isquoted 0
  if contains (string sub -s 1 -l 1 "$tok") '"' "'"
    set isquoted 1
  end
  printf "fptt head: -%s-\n" (string sub -s 1 -l 1 "$tok") >> $log
  printf "fptt tok: -%s- / isquoted $isquoted\n" $tok >> $log
  if test $isquoted = 1; and test (string sub -s -1 -l 1 "$tok") = " "
    printf "fptt tok!: -%s-\n" $tok >> $log
    set -l prefix (string match -r '.+ ' (string sub -s 2 "$tok"))
    set prefix (string trim -rc \"\' $prefix)
    printf "fptt pre!: -%s-\n" $prefix >> $log
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
      begin
        if test -n "$values_for_tag"; and not contains $values_for_tag '>' '<' '!'
          echo "q:values_for_tag set to '$values_for_tag'" >> $log
          tmsu $arg values $values_for_tag | while read v
            printf '%s=%s\n' $values_for_tag $v
          end
        else
          tmsu $arg tags
        end
      end | while read t
          echo "$prefix$t"; echo "$t "; end
      if test $showops = 1
        for op in $ops; echo "$prefix$op";end
      end
    else
      if test -n "$values_for_tag"; and not contains $values_for_tag '>' '<' '!'
        echo "uq:values_for_tag set to '$values_for_tag'" >> $log
        tmsu $arg values $values_for_tag | while read v
          printf '%s=%s\n' $values_for_tag $v
        end
      else
        tmsu $arg tags
      end
      if test $showops = 1
        printf '%s\n' $ops
      end
    end
  end
end

function __fish_print_tmsu_values
  set -l db
  set -l arg
  set -l tag
  if test "$argv[1]" = "--tag"
    echo "fptv: tag set to $argv[2]" >> $log
    set tag $argv[2]
    set argv $argv[3..-1]
  end
  if test -n "$argv[1]"
    set db (__fish_tmsu_database $argv)
    if test -z "$db"
      # DB doesn't exist
      return
    end
    set arg --database $db
  end
  if test -n "$tag"
    tmsu $arg values $tag
  else
    tmsu $arg values
  end
end

function __fish_print_tmsu_values_for_tag
  set -l db
  set -l tag $argv[1]
  set argv $argv[2..-1]
  set -l arg
  if test -n "$argv[1]"
    set db (__fish_tmsu_database $argv)
    if test -z "$db"
      # DB doesn't exist
      return
    end
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
    set db (__fish_tmsu_database $argv)
    if test -z "$db"
      # DB doesn't exist
      return
    end
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
    echo "bailout on" $cmd >> $log
    return 1;
  end

  set subcmd $cmd[$subcmd..-1]
  if test (count $subcmd) -eq 1
    return 1
  end
  echo "subcmd" $subcmd >> $log
  set -l skip_next 1
  switch $subcmd[1]
    case tag
    echo "tag on - " $subcmd >> $log
    for v in $subcmd[2..-1]
      test $skip_next -eq 0
      and set skip_next 1
      and continue
      switch $v
        case '-c' '--create' '-w' '-w*' '--where' '--where='
          return 0
	case '-f' '--from' '-f*' '--from=*' '-t' '--tags'\
             '-t*' '--tags=*'
	  return 1
        case '-*'
          continue
        case '*'
          echo "FILED" $v >> $log
          return 0
      end
    end
    case untag
    for v in $subcmd[2..-1]
      test $skip_next -eq 0
      and set skip_next 1
      and continue
      switch $v
        case '-t' '--tags'
          return 1
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

function __fish_tmsu_complete_query
  echo "cq: " $argv >> $log
  set -l curtoken (commandline -ct)
  set -l prevtoken $argv[-1]

  if contains -- $prevtoken -w
    set prevtoken
  end

#  if test (count $argv) -ge 2
#    set prevtoken "$argv[-2]"
#  end

# * AND/OR must follow a TAG, TAG=VALUE, VALUE, or ) token
# * NOT may follow anything except a comparison operator.
# * comparison operators must follow a TAG (not a TAG=VALUE!)
# * values must be suggested when last token is CMP
# * 'tag=' versions of plain tags must be suggested (at least
#   when last token is TAG with no =). When completing them,
#   the values should be fetched (ie. tmsu values $tag)
#   to create tag=value candidates.
# * ( must not follow a comparison operator.
#
  set -l list_tags 1
  set -l list_values
  set -l values_for_tag
  set -l logical_ops 'and' 'or' 'not' '(' ')'
  set -l cmp_ops
  switch "$prevtoken"
    case '' 'and' 'or' 'not'
      for v in 'and' 'or' 'not'
        set -e logical_ops[(contains -i $v $logical_ops)]
      end
    case '('
      for v in 'and' 'or' ')'
        set -e logical_ops[(contains -i $v $logical_ops)]
      end
    case ')'
      set -e logical_ops[(contains -i '(' $logical_ops)]
    case l{t,e} g{t,e} eq ne "<"{,=} {!,=}= ">"{,=}
      set logical_ops
      set list_tags
      if test -n "$argv[-2]"
        set list_values "$argv[-2]"
      else
        set list_values ''
      end
    case '*'
      # not an operator. Tag or tag=value
      if not set -l eqindex (string match -arn '(?<!\\\)=' -- $prevtoken)
        set cmp_ops l{t,e} g{t,e} eq ne "<"{,=} {!,=}= ">"{,=}
      end
  end
  switch $curtoken
    case '*=*'
      set eqindex (string match -rn '(?<!\\\)=' $curtoken)
      if test (count $eqindex) -gt 0
        set eqindex (string split ' ' $eqindex[1])[1]
        set values_for_tag (string sub -l (math eqindex-1) $curtoken)
        set values_for_tag (string unescape $values_for_tag)
	echo "tval found, eqindex='$eqindex' values_for_tag='$values_for_tag'" >> $log
        echo "eqindex count " (count $eqindex) >> $log
      end
  end
  if test (count $cmp_ops) -gt 0
    printf '%s\n' $cmp_ops
  end
  begin
    if test (count $logical_ops) -gt 0
      printf '%s\n' $logical_ops
    end
    if test -n "$list_tags"
      __fish_print_tmsu_tags $argv
    end
    if test (count $list_values) -gt 0
      if test -n $list_values[1]
        __fish_print_tmsu_values --tag $list_values $argv
      else
        __fish_print_tmsu_values $argv
      end
    end
    if test -n "$values_for_tag"
     echo "tval2 values_for_tag='$values_for_tag'" >> $log
      __fish_print_tmsu_tags --tag $values_for_tag $argv
    end
  end
# | while read v; string escape --no-quoted "$v";end
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

# note: copy + rename offer tagnames unconditionally
#       (including in positions where you don't want an existing tagname)
#       This is intentional, so that you can use tab-completion to tell
#	whether the new name will collide with anything.

# CONFIG completed
set -l conf {autoCreate{Tags,Values},reportDuplicates}{,={yes,no}} directoryFingerprintAlgorithm{,={none,}}
set conf $conf fileFingerprintAlgorithm{,=none,={dynamic:,}{SHA{1,256},MD5}} symlinkFingerprintAlgorithm{,={none,follow,targetName{,NoExt}}}
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = config;' -f -a "$conf"
set -e conf


# COPY/CP completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and contains $c copy cp;' -f -a '(__fish_print_tmsu_tags)'

# DELETE/DEL/RM completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and contains $c delete del rm'
complete -c tmsu -n "$co" -f -l value --description 'delete a value'
complete -c tmsu -n "$co; and __fish_contains_opt value" -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co; and not __fish_contains_opt value" -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'

# DUPES completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = dupes' -s r -l recursive --description 'recursively check directory contents'

# files/query
set -l co 'not set -l c (__fish_tmsu_needs_command); and contains $c files query'
complete -c tmsu -n $co -f -a '(__fish_tmsu_complete_query (commandline -cpo)[2..-1])'
complete -c tmsu -n $co -f -s d -l directory --description 'list only items that are directories'
complete -c tmsu -n $co -f -s f -l file --description 'list only items that are files'
complete -c tmsu -n $co -f -s 0 -l print0 --description 'delimit files with a NUL character rather than newline'
complete -c tmsu -n $co -f -s c -l count --description 'list the number of files rather than their names'
complete -c tmsu -n $co -r -f -s p -l path --description 'list only items under PATH' -a '(__fish_complete_directories (commandline -ct))'
complete -c tmsu -n $co -f -s e -l explicit --description 'list only explicitly tagged files'
complete -c tmsu -n $co -r -f -s s -l sort --description 'sort output by:' -a 'id none name size time'
complete -c tmsu -n $co -f -s i -l ignore-case --description 'ignore the case of tag and value names'
# XXX main query completer

# HELP completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = help' -f -s l -l list --description 'list commands'

# imply
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = imply'
complete -c tmsu -n "$co" -f -s d -l delete --description 'deletes the tag implication'
complete -c tmsu -n "$co" -f -a '(__fish_print_tmsu_tags_or_tvalues (commandline -cpo)[2..-1])'

# INIT completed
complete -c tmsu -n 'not set -l c (__fish_tmsu_needs_command); and test $c = init' -f -a '(__fish_complete_directories (commandline -ct))'

# MERGE completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = merge'
complete -c tmsu -n "$co" -f -l value --description 'merge values'
complete -c tmsu -n "$co; and __fish_contains_opt value" -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co; and not __fish_contains_opt value" -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'

# mount
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = mount'
complete -c tmsu -n "$co" -f -r -s o -l options --description 'mount options (passed to fusermount)'
# XXX detect specification of FILE and then only offer directory completion.

# RENAME/MV completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and contains $c rename mv'
complete -c tmsu -n "$co" -f -l value --description 'rename a value'
complete -c tmsu -n "$co; and __fish_contains_opt value" -f -a '(__fish_print_tmsu_values (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co; and not __fish_contains_opt value" -f -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'

# repair/fix
set -l co 'not set -l c (__fish_tmsu_needs_command); and contains $c repair fix'
complete -c tmsu -n "$co" -f -r -s p -l path --description 'limit repair to files in database under PATH'
complete -c tmsu -n "$co" -f -s P -l pretend --description 'do not make any changes'
complete -c tmsu -n "$co" -f -s R -l remove --description 'remove missing files from the database'
complete -c tmsu -n "$co" -f -s m -l manual --description 'manually relocate files'
complete -c tmsu -n "$co" -f -s u -l unmodified --description 'recalculate fingerprints for unmodified files'
complete -c tmsu -n "$co" -f -l rationalize --description 'remove explicit taggings where an implicit tagging exists'
# XXX count # of arguments to `repair --manual`, offer no completions after second path argument

# STATUS completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = status'
complete -c tmsu -n $co -f -s d -l directory --description 'do not examine directory contents (non-recursive)'
complete -c tmsu -n $co -f -s P -l no-dereference --description 'do not dereference symbolic links'

# tag
# XXX allow multiple tags to be completed,
# as in `tmsu tag -t '2002 bana<TAB>`. Partly done but fragile
# XXX similar for query
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = tag'
complete -c tmsu -n $co -f -r -s t -l tags --description 'the set of tags to apply' -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co;and __fish_tmsu_has_file" -f -r -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# XXX this needs to be a custom function, with the following rules
#

complete -c tmsu -n $co -f -r -s w -l where --description 'tags files matching QUERY' -a '(__fish_tmsu_complete_query (commandline -cpo)[2..-1])'
complete -c tmsu -n $co -f -s r -l recursive --description 'recursively apply tags to directory contents'
complete -c tmsu -n $co -r -s f -l from --description 'copy tags from the SOURCE file'
complete -c tmsu -n $co -f -s c -l create --description 'create tags or values without tagging any files'
complete -c tmsu -n $co -f -s e -l explicit --description 'explicitly apply tags even if they are already implied'
complete -c tmsu -n $co -f -s F -l force --description 'apply tags to non-existent or non-permissioned paths'
complete -c tmsu -n $co -f -s P -l no-dereference --description 'do not follow symbolic links (tag the link itself)'


# tags

# unmount/umount
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = umount'
complete -c tmsu -n "$co" -f -s a -l all --description 'unmounts all mounted TMSU file-systems'
# XXX identify only TMSU (FUSEFS?) mountpoints
complete -c tmsu -n "$co" -a '(__fish_print_mounted)'

# untag
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = untag'
complete -c tmsu -n $co -f -r -s t -l tags --description 'the set of tags to remove' -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
# XXX could be folded into tag
complete -c tmsu -n "$co;and __fish_tmsu_has_file" -f -r -a '(__fish_print_tmsu_tags (commandline -cpo)[2..-1])'
complete -c tmsu -n "$co" -f -s a -l all --description 'strip each file of all tags'
complete -c tmsu -n $co -f -s r -l recursive --description 'recursively remove tags from directory contents'
complete -c tmsu -n $co -f -s P -l no-dereference --description 'do not follow symbolic links (untag the link itself)'

# UNTAGGED completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = untagged'
complete -c tmsu -n $co -f -s c -l count --description 'list the number of files rather than their names'
complete -c tmsu -n $co -f -s d -l directory --description 'do not examine directory contents (non-recursive)'
complete -c tmsu -n $co -f -s P -l no-dereference --description 'do not dereference symbolic links'
complete -c tmsu -n $co -f -a '(__fish_complete_directories (commandline -ct))'

# VALUES completed
set -l co 'not set -l c (__fish_tmsu_needs_command); and test $c = values'
complete -c tmsu -n $co -f -s c -l count --description 'list # of values rather than their names'
complete -c tmsu -n $co -f -s 1 --description 'list one value per line'
complete -c tmsu -n $co -a '(__fish_print_tmsu_tags)'

#complete -c tmsu -n 'set -l c (__fish_tmsu_needs_command) or test $c = values' -f -a '(__fish_print_tmsu_tags (commandline -cpo))'
#
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
