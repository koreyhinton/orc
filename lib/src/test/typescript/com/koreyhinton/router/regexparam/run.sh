#!/bin/bash

: "${GITHUB_WORKSPACE:=/k/repos/kh/orc}"

# nvm use 22 # uncomment and run this on local machine switch to 22

export ORC_ROUTER="${GITHUB_WORKSPACE}/lib/src/templates/typescript/com/koreyhinton/router"
export NSMAP="${GITHUB_WORKSPACE}/lib/src/main/bash/com/koreyhinton/nsmap"

cd "${GITHUB_WORKSPACE}/lib/src/test/typescript/com/koreyhinton/router/regexparam" || exit 1

./fixtures/models.sh > ./fixtures/models.ts
./unit/tests.sh > ./unit/tests.ts
npx tsc --noEmit unit/tests.ts || exit 1
npx tsx unit/tests.ts
