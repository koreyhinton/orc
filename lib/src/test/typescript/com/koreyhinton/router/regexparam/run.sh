#!/bin/bash

: "${GITHUB_WORKSPACE:=/k/repos/kh/orc}"

export ORC_ROUTER="${GITHUB_WORKSPACE}/lib/src/templates/typescript/com/koreyhinton/router"
export NSMAP="${GITHUB_WORKSPACE}/lib/src/main/bash/com/koreyhinton/nsmap"

cd "${GITHUB_WORKSPACE}/lib/src/test/typescript/com/koreyhinton/router/regexparam" || exit 1

./fixtures/models/regex-param.sh > ./fixtures/models/regex-param.ts
./fixtures/models/keyed-route.sh > ./fixtures/models/keyed-route.ts
./unit/tests.sh > ./unit/tests.ts
npx tsx unit/tests.ts
