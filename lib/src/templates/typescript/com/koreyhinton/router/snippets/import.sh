#!/bin/bash

loc="$1"

cat << EOF

    import type { Router, RouterConfig,
        RegexParam, RegexParamResult, RegexParamManifest,
        EventStoreConfig, EventStore, EventPoll,
        EventPollReport
     } from '${loc}';

EOF
