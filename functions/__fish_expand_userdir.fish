
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
