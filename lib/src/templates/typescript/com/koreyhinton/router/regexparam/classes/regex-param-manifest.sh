#!/bin/bash

: "${REG_PAR_MAN_KEY_PATH_TYPES:=string|RegExp}"

cat << EOF
    export type RegexParamManifest = {
        keyedPaths: (${REG_PAR_MAN_KEY_PATH_TYPES})[];
    };

EOF
