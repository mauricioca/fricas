# Spool output has lines with and without "-- ".
# There are special lines that come from ioHook that look like
## -- \begin{TeXOutput}
## .. \end{TeXOutput}
## -- \begin{MessageOutput}
## .. \end{MessageOutput}
## -- \begin{SysCmdOutput}
## .. \end{SysCmdOutput}
# Lines inside these environments are treated in a special way.
# These environments appear inside lines that start with
## -- \xtc{
# and end with
## -- }
# All lines outside the xtc stuff that have no "-- " in front of it
# will not make it into the output.
# The line
## -- \xtc{
# will become
## \xtcLong{
# and the final
## -- }
# will become
## }
# The "-- \begin" and "-- \end"  line will be removed.
# If inside the TeXOutput we see "\leqno(n)" then the respective number n
# is taken as the step number and will be printed as the fourth argument
# of \xtcLong.
# TeXOutput can be missing. MessageOutput can appear before and after
# TeXOutput.
# The SysCmdOutput is treated like MessageOutput where the lines
## -- \begin{MessageOutput}
# and
## --\end{MessageOutput}
# will be removed.

# If the first word of a MessageOutput is "Type:" then that environment
# describes the type of the output and will go into the fifth argument of
# \xtcLong.

# The global variable xtcarg will be used to remember in which argument of
# \xtcLong we are currently writing. This is mainly to distinguish between
# the third (math output) and the fifth (result type), because in both of
# these places we might have notification messages.

BEGIN {
    xtcarg=0
    print "% !! DO NOT MODIFY THIS FILE BY HAND !! Created by spool2tex.awk."
}

# Discard \begin{inputonly} ... \end{inputonly}.
/^-- \\begin{inputonly}/,/^-- \\end{inputonly}/ {next}

# start of xtc
/^-- \\xtc{/ {
    sub(/^-- \\xtc{/, "\\xtcLong{", $0)
    print $0
    xtcarg=1
    stepnumber="" # reset
    next
}

# everything outside \xtc...
xtcarg==0 {
    if (substr($0,1,3) == "-- ") {
        printf("%s\n",substr($0,4))
    }
    next
}

# For everything below xtcarg>0.

# end of xtc
/^-- }$/ {
    # If there was no TeXOutput, we are still at xtcarg==3.
    if (xtcarg==3) {
        print "\\vbox{\\hbox{\\quad}}%"
        print "}{}{%"
    }
    print "}"
    xtcarg=0
    next
}

# Print the first xtc argument (comment text)
xtcarg==1 {
    printf("%s\n",substr($0,4))
    if (match($0,/^-- }{/)) {xtcarg=2}
    next
}

# Print the second argument (input lines, \spadcommand, \begin{spadsrc})
xtcarg==2 {
    if (match($0,/^-- \\begin{[a-zA-Z]*Output}/)) {
        print "}{%"
        xtcarg=3
    } else if (match($0, /^-- /)) {
        printf("%s\n",substr($0,4))
        next
    }
}

# The third argument can be MessageOutput, SysCmdOutput, and TeXOutput.
# It definitely stops at "-- \end{TeXOutput}".
# We use the variable inVerbatim to signal whether we have opened a
# verbatim part that we must close.
# Interestingly the fifth argument is treated exactly the same.

(xtcarg==3 || xtcarg==5) && /^-- \\begin{SysCmdOutput}/ {
    inSysCmdOutput=1
    inVerbatim=0
    inMessageOutput=1
    next
}

(xtcarg==3 || xtcarg==5) && /^-- \\begin{MessageOutput}/ {
    if (inSysCmdOutput) {next}
    inVerbatim=0
    inMessageOutput=1
    next
}

(xtcarg==3 || xtcarg==5) && (/^-- \\end{MessageOutput}/ || /^-- \\end{SysCmdOutput}/) {
    if (inVerbatim==1) {
        print "}% end of \\vbox"
        inVerbatim=0
    }
    inMessageOutput=0
    next
}

(xtcarg==3 || xtcarg==5) && inMessageOutput==1 {
    if ($1 == "Type:") {
        handleType()
        next
    }
    if (inVerbatim==0) {
        print "\\vbox{\\Isize{}%"
        inVerbatim=1
    }
    if (substr($0,1,3)=="   ") {$0=substr($0,4)}
    escapeSpecials()
    printf("\\vbox{\\outputMsg{} %s\\hfill}\n", $0)
    next
}

xtcarg==3 && /^-- \\begin{TeXOutput}/ {
    print "\\["
    inTeXOutput=1
    next
}

xtcarg==3 && /^-- \\end{TeXOutput}/ {
    print "\\]}{" stepnumber "}{"
    stepnumber=""
    inTeXOutput=0
    xtcarg=5
    next
}

# Ignore the $$, because we already take care of it.
inTeXOutput==1 && /^\$\$$/ {next}

# Ignore empty line
inTeXOutput==1 && $1=="" {next}

# Record the step number.
inTeXOutput==1 && /^\\leqno/ {
    sub(/^\\leqno\(/, "", $0)
    sub(/\) *$/, "", $0)
    stepnumber=$0
    next
}

# Treat math lines.
inTeXOutput==1 {
    gsub(/_/,"\\_")
    gsub(/#/,"\\#")
    if ((NF == 1) && ($1 == "true"))
        print "{\\rm true}"
    else if ((NF == 1) && ($1 == "false"))
        print "{\\rm false}"
    else
        print $0
}


# Treat a line whose first non-space characters are "Type:".
function handleType() {
    if (xtcarg==3) {
        print "\\vbox{\\hbox{\\quad}}%"
        print "}{}{%"
        xtcarg=5
    }
    $1 = ""
    if ($2 == "Void") {
        print "\\vbox{\\hbox{\\quad}}%"
        return
    }
    gsub(/%/,"\\%")
    gsub(/,/,", ")
    gsub(/"/,"\\\"")
    gsub(/->/,"$\\rightarrow$")
    print $0
}

function escapeSpecials() {
         gsub(/ /,"\\ ")
         gsub(/_/,"\\_")
         gsub(/%/,"\\%")
         gsub(/\$/,"\\$")
         gsub(/#/,"\\#")
         gsub(/{/,"\\{")
         gsub(/}/,"\\}")
         gsub(/&/,"\\\\&")
}
