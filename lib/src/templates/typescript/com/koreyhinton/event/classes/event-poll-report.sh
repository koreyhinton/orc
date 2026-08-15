#!/bin/bash

: "${EVT_POL_TYPES:=string}"  # ie: |HomeButtonClickEvent

cat << EOF

    export type EventPollReport = {
        polls: Record<${EVT_POL_TYPES}, EventPoll>;
    };

EOF
