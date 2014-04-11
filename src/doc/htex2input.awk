BEGIN {
    print ")set message autoload off"
    print ")set break resume"
    print ")lisp (setf |$ioHook| (lambda (x &optional args) (cond ((eq x '|startLaTeXOutput|) (SAY \"-- \\\\begin{LaTeXOutput}\")) ((eq x '|endOfLaTeXOutput|) (SAY \"-- \\\\end{LaTeXOutput}\")) ((eq x '|startKeyedMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) ((eq x '|endOfKeyedMsg|) (SAY \"-- \\\\end{MessageOutput}\")) ((eq x '|startSysCmd|) (SAY \"-- \\\\begin{SysCmdOutput}\")) ((eq x '|endSysCmd|) (SAY \"-- \\\\end{SysCmdOutput}\")) ((eq x '|startPatternMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) ((eq x '|endPatternMsg|) (SAY \"-- \\\\end{MessageOutput}\")))))"
    print ")set output latex on"
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

# discard lines between \begin{htonly} and \end{htonly}
/^\\begin{htonly}/,/^\\end{htonly}/ {next}

# delete \begin{texonly} and \end{texonly} lines (leaving what is in between)
/^\\begin{texonly}/ || /^\\end{texonly}/  {next}

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


/^} *$/ && xtc>1 {
    xtc=0
    print "-- \\end{" xtcname "}"
    next
}

xtc==2 && (/^\\spadcommand{/ || /^\\spadgraph{/ || /^\\spadpaste{/) {
    print "-- \\begin{spadsrc}"
    gsub(/^\\spadcommand{/, "")
    gsub(/^\\spadgraph{/, "")
    gsub(/^\\spadpaste{/, "")
    gsub(/}$/, "")
    gsub(/\\\$/, "$")
    gsub(/\\\%/, "%")
    gsub(/\\\#/, "#")
    gsub(/\\\_/, "_")
    gsub(/\\free{.*/, "")
    gsub(/\\bound{.*/, "")
    print "-- " $0
    print "-- \\end{spadsrc}"
    if (xtcname=="xtc" || xtcname=="noOutputXtc") {print $0}
    next
}

xtc==2 && /^\\begin{spadsrc}/ {
    print "-- \\begin{spadsrc}" # This removes optional arguments.
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

/^\\xtc{/ || /^\\noOutputXtc{/ || /^\\nullXtc{/ || /^\\psXtc{/ {
    xtc=1
    sub(/\\/,"")
    sub(/{.*/,"")
    xtcname=$0
    print "-- \\begin{" xtcname "}"
    print "-- \\begin{xtccomment}"
    next
}

/^}{/ && xtc==1 {
    print "-- \\end{xtccomment}"
    xtc=2
    next
}

/^}{/ && xtc==2 {next}

{
    print "-- " $0
    if (match($0,/^\\head/)) {
        print "-- \\begin{inputonly}"
        print ")clear all"
        print "-- \\end{inputonly}"
    }
}
