# Requires functions/__fish_expand_userdir.fish
#

set -l log /tmp/.fishtmsu.log

function __fish_tmsu_database -d 'Return active tmsu DB, given commandline args'
  set -l nextarg
  for a in $argv
    switch $a
      case config copy delete dupes files help imply info init merge\
           mount rename repair status tag tags unmount untag untagged\
           values
        # No -D/--database before subcommand == no database specified on CLI
        break
      case '-D=*' '--database=*'
        __fish_expand_userdir (string split -m 1 = -- $a)[2]
        return
      case '-D' '--database'
        set nextarg y
      case '*'
	echo "db:nextarg=~$nextarg~ a=$a" >> $log
	if test -n "$nextarg"
          __fish_expand_userdir $a
          return
	end
        continue
    end
  end
  if set -q TMSU_DB
    __fish_expand_userdir "$TMSU_DB"
    return
  end
  tmsu info 2>/dev/null | fgrep Database: | cut -d ' ' -f 2-
end
