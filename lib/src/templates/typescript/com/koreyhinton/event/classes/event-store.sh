#!/bin/bash

cat << EOF

    export type EventStore = {
        pollSubjects: EventPollSubject[];
    };

EOF
