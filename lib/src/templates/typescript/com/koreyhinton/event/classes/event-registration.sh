#!/bin/bash

: "${EVT_POL_TYPES:=string}"  # ie: |HomeButtonClickEvent

cat << EOF

    export type EventRegistration = {
        listener: HTMLElement | Window | Navigation;
        eventType: string;
        key: ${EVT_POL_TYPES};
        intercept: boolean;
    };

EOF
