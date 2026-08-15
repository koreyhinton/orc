#!/bin/bash

cat << EOF

    export type EventStoreConfig = {
        events: EventRegistration[];
    };

EOF
