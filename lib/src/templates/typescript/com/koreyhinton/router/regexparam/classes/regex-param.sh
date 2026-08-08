#!/bin/bash

cat << EOF

export class RegexParam {
    constructor(
        public keys: Array<string>,
        public pattern: RegExp
    ) {}
}

EOF
