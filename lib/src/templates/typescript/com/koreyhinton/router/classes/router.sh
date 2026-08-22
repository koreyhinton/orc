#!/bin/bash

cat << EOF

    /*
        RegexParamManifest = {
            keyedPaths: (string|RegExp)[];
        };
    */

    export type Router = RegexParamManifest & {
        activeRoute: ActiveRoute | null;
        regexParams: RegexParam[];
        eventStore: EventStore;
    }

EOF
