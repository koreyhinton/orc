#!/bin/bash

: "${REG_PAR_KEY_TYPES:=string}"
: "${REG_PAR_MAN_KEY_PATH_TYPES:=string|RegExp}"

cat << EOF

export type RegexParam = {
    keyedPath: ${REG_PAR_MAN_KEY_PATH_TYPES};
    keys: (${REG_PAR_KEY_TYPES})[] | false;
    pattern: RegExp;
}

EOF
