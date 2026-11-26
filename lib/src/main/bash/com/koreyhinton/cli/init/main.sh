#!/bin/bash

# The app's @ORC_LANG@ program: build.sh writes what this prints to
# @ORC_OUT_NAME@. Snippets are leaves: only this file calls them, each
# inlined where it belongs with a backtick call:
#
#     ` ./my-snippet.sh ${v}my_ `
#
# so the generated program reads top to bottom. See ORC.md.@ORC_SEEDED@

# the namespace for this file's names in the generated program
v=${1:-mn_}

# maps: name a snippet's inputs and outputs in the generated program, e.g.
#     export ${v}my_Input=input
# (inside the snippet: . ${NSMAP}/bind ${v} Input, then use ${!input})

cat << EOF
@ORC_BODY@
EOF
