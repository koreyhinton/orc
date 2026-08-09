#!/bin/bash

cat << EOF

export type RegexParam = {
    keys: string[] | false;
    pattern: RegExp;
}

EOF
