#!/bin/bash

: "${ROUT_CFG_ROUT_TYPES:=string}"

cat << EOF

    export type RouterConfig = {
        routes: (${ROUT_CFG_ROUT_TYPES})[];
    }

EOF
