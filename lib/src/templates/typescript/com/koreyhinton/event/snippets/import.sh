#!/bin/bash

loc="$1"

cat << EOF

    import type { EventStoreConfig, EventStore,
        EventPollSubject, EventRegistration, EventPollReport
     } from '${loc}';

EOF
