function __fish_expand_userdir -d 'Expand user directory reference. Surely there is a better way to do this.'
  set argv (string replace -r '^~/' "$HOME/" $argv)
  set argv (string replace -r '^~$' "$HOME" $argv)
  set final
  for a in $argv
    set len (string length $a)
    for v in (string match -arn '^~[^~();$/]+(?=/|$)' $a)
      set v (string split ' ' $v)
      set start $v[1]
      set l $v[2]
      set parts
      if test $start -gt 1
        set parts $parts (string sub -l (math start-1) $a)
      end
      # eval hackery. But reasonably safe since we disallow () $ ;
      eval 'set parts $parts '(string sub -s $start -l $l $a)
      if test (math start+l) -le $len
        set parts $parts (string sub -s (math start+l) $a)
      end
      set a (string join '' $parts)
      set len (string length $a)
    end
    set final $final $a
  end
  printf '%s\n' $final
end
