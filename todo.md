* Make quoted completion better - `tag -t` and `tag -w`, maybe also `files`
* Reduce debug spam a lot
* Remove COMPLETED markers
* Eliminate any error messages from tmsu that disrupt the completion display
* Handle tmsu-special characters [<>()= ] in tag names
  * <>()! must be escaped in queries, but not in `tmsu tag|untag`
    (can this be considered a bug in tmsu? for example
     creating a tag '!=' is done like `tmsu tag myfile '\!\='`,
     but `tmsu tags myfile` reports `myfile: !\=`;
     you cannot then ask: `tmsu files '!\='`, you must use `'\!\='`)
  * = is comparitively easy; `tmsu tags [$filename]` returns escaped =, `tmsu values $tagname` returns escaped
    =. This appears correct for 'tmsu files' usage, but `tmsu tag` balks at the unescaped = between `fo\=o` and
    `ba\=r`. 