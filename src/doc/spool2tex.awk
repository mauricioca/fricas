# Spool output has lines with and without "-- ".
# There are special lines that come from ioHook that look like
## -- \begin{LaTeXOutput}
## .. \end{LaTeXOutput}
## -- \begin{MessageOutput}
## .. \end{MessageOutput}
## -- \begin{SysCmdOutput}
## .. \end{SysCmdOutput}
# Lines inside these environments are treated in a special way.
# These environments appear inside lines that start with
## -- \begin{xtc}
# and end with
## -- \end{xtc}
# or "noOutputXtc" instead of "xtc".
# All lines outside the xtc stuff that have no "-- " in front of it
# will not make it into the output.
# Output of commands appears inside
## \begin{LaTeXMath}
## \end{LaTeXMath}
# This environment will only be removed, because there will be already
## -- \begin{LaTeXOutput}
## .. \end{LaTeXOutput}
# arount it.

# If the first word of a MessageOutput is "Type:" then that
# environment describes the type of the output and the whole environment
# will be replaced by
## \formatResultType{TYPE}
# where TYPE is the text after "Type: " and is different from "Void".
# If the type is "Void", nothing is output.

BEGIN {
    inxtc=0
    print "% !! DO NOT MODIFY THIS FILE BY HAND !! Created by spool2tex.awk."
}

# Discard \begin{inputonly} ... \end{inputonly}.
/^-- \\begin{inputonly}/,/^-- \\end{inputonly}/ {next}

# start of xtc
/^-- \\begin{xtc}/ || /^-- \begin{noOutputXtc}/ {
    inxtc=1
    sub(/^-- /, "")
    print $0
    next
}

# everything outside xtc environments...
inxtc==0 {
    if (substr($0,1,3) == "-- ") {
        printf("%s\n",substr($0,4))
    }
    next
}

# For everything below xtc>0.

# end of xtc
/^-- \end{xtc}$/ || /^-- \end{noOutputXtc}$/ {
    printf("%s\n",substr($0,4))
    inxtc=0
    next
}

/^-- \\begin{SysCmdOutput}/ {
    print "\\begin{SysCmdOutput}"
    inSysCmdOutput=1
    next
}

/^-- \\begin{MessageOutput}/ {
    if(inSysCmdOutput==1) {next} # skip inside SysCmdOutput
    getline
    if ($1 == "Type:") {
        # Treat a line whose first non-space characters are "Type:".
        if ($2 != "Void") {
            gsub(/%/,"\\%")
            gsub(/,/,", ")
            gsub(/"/,"\\\"")
            gsub(/->/,"$\\rightarrow$")
            $1=""
            gsub(/^ */,"")
            print "\\formatResultType{" $0 "}"
        }
        # read until \\end{MessageOutput} and discard
        while (substr($0,1,22) != "-- \\end{MessageOutput}") {
            getline
        }
        next
    }
    print "\\begin{MessageOutput}"
    print $0
    inMessageOutput=1
    next
}

/^-- \\end{MessageOutput}/ {
    if(inSysCmdOutput==1) {next}
    printf("%s\n",substr($0,4))
    inMessageOutput=0
    next
}

/^-- \\end{SysCmdOutput}/ {
    printf("%s\n",substr($0,4))
    inSysCmdOutput=0
    next
}

(inMessageOutput==1 || inSysCmdOutput==1) {
    print $0
    next
}

/^-- \\begin{LaTeXOutput}/ {
    print "\\begin{LaTeXOutput}"
    inLaTeXOutput=1
    next
}

/^-- \\end{LaTeXOutput}/ {
    print "\\end{LaTeXOutput}"
    inLaTeXOutput=0
    next
}

# Ignore the generated math delimiters \begin{LaTeXMath},
# \end{LaTeXMath}, because we already take care of it.
inLaTeXOutput==1 && (/^\\begin{LaTeXMath}$/ || /^\\end{LaTeXMath}$/) {next}

# Ignore empty line
inLaTeXOutput==1 && $1=="" {next}

# Treat math lines.
inLaTeXOutput==1 {
    gsub(/[^{],/,"&\\linebreak[2]")
    if ((NF == 1) && ($1 == "true"))
        print "\\textrm{true}"
    else if ((NF == 1) && ($1 == "false"))
        print "\\textrm{false}"
    else
        print $0
}

# Print lines inside xtc that start with "-- ".
/^-- / {printf("%s\n",substr($0,4))}
