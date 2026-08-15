#!/bin/bash

: "${EVT_POL_TYPES:=string}"  # ie: |HomeButtonClickEvent

cat << EOF

    export type EventPollSubject = EventPoll & {
        key: ${EVT_POL_TYPES};
        polled: boolean;
    };

EOF
