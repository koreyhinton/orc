#!/bin/bash

cat << EOF

    export type EventPoll = {
        event: Event | null,
        eventType: string
    };

EOF
