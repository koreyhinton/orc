#!/bin/bash

: "${GITHUB_WORKSPACE:=/k/repos/kh/orc}"

# nvm use 22 # uncomment and run this on local machine switch to 22

export ORC_EVENT="${GITHUB_WORKSPACE}/lib/src/templates/typescript/com/koreyhinton/event"
export ORC_ROUTER="${GITHUB_WORKSPACE}/lib/src/templates/typescript/com/koreyhinton/router"
export NSMAP="${GITHUB_WORKSPACE}/lib/src/main/bash/com/koreyhinton/nsmap"

cd "${GITHUB_WORKSPACE}/lib/src/test/typescript/com/koreyhinton/router" || exit 1

./fixtures/models.sh > ./fixtures/models.ts
./sut/register-routes.sh > ./sut/register-routes.ts
./sut/register-routes-inj.sh > ./sut/register-routes-inj.ts
./fixtures/web.sh > ./fixtures/web.ts

for f in `ls integration/*.test.sh 2>/dev/null`
do
    fname=$(basename "$f")
    ts_fname="${fname%.*}.ts"
    "./${f}" > "./integration/${ts_fname}"
done

vitest --run
