#!/bin/bash

cat << EOF
    export type RegexParamManifest = {
        keyedPaths: (string|RegExp)[];
    };

EOF
