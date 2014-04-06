BEGIN {
    print ")set message autoload off"
    print ")set break resume"
    print ")lisp (setf |$ioHook| (lambda (x &optional args) (cond ((eq x '|startTeXOutput|) (SAY \"-- \\\\begin{TeXOutput}\")) ((eq x '|endOfTeXOutput|) (SAY \"-- \\\\end{TeXOutput}\")) ((eq x '|startKeyedMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) ((eq x '|endOfKeyedMsg|) (SAY \"-- \\\\end{MessageOutput}\")) ((eq x '|startSysCmd|) (SAY \"-- \\\\begin{SysCmdOutput}\")) ((eq x '|endSysCmd|) (SAY \"-- \\\\end{SysCmdOutput}\")) ((eq x '|startPatternMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) ((eq x '|endPatternMsg|) (SAY \"-- \\\\end{MessageOutput}\")))))"
    print ")set output tex on"
    print ")set output algebra off"
    print ")set output length 62"
    print ")set message time off"
    print ")set streams calculate 7"
    print "-- \\begin{inputonly}"
    print "outputSpacing(0)"
    print "-- \\end{inputonly}"
}

END {
    print ")set quit unprotected"
    print ")quit"
}

# print lines between \begin{inputonly} and \end{inputonly}
/^\\begin{inputonly}/ {
    print "-- " $0
    getline
    while (substr($1,1,15) != "\\end{inputonly}") {
        print $0
        getline
    }
    print "-- " $0
    next
}


{
    print "-- " $0
    if (match($0,/^\\head/)) {
        print "-- \\begin{inputonly}"
        print ")clear all"
        print "-- \\end{inputonly}"
    }
}

/^} *$/ && xtc==2 {xtc=0}

xtc==2 && /^\\spadcommand{/ {
    gsub(/^\\spadcommand{/, "", $0)
    gsub(/}$/, "", $0)
    gsub(/\\\$/, "$", $0)
    gsub(/\\\%/, "%", $0)
    gsub(/\\\#/, "#", $0)
    gsub(/\\\_/, "_", $0)
    gsub(/\\free{.*/, "", $0)
    gsub(/\\bound{.*/, "", $0)
    print $0
}

xtc==2 && /^\\begin{spadsrc}/ {
    n=1
    getline
    while (substr($1,1,13) != "\\end{spadsrc}") {
        print "-- " $0
        arr[n]=$0
        n++
        getline
    }
    print "-- " $0
    for (i = 1; i < n; i++) {print arr[i]}
    next
}

/^\\xtc{/          {xtc=1}
/^\\noOutputXtc{/  {xtc=1}
/^}{/    && xtc==1 {xtc=2}
