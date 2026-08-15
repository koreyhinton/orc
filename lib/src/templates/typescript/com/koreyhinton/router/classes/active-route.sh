#!/bin/bash

: "${REG_PAR_MAN_KEY_PATH_TYPES:=string|RegExp}"

cat << EOF

export type ActiveRoute = {
    hot: boolean;
    realPath: string;
    keyedPath: ${REG_PAR_MAN_KEY_PATH_TYPES};
    params: Record<string, string | null>;
}

EOF
