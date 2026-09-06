#!/bin/bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error, script must not be source. Run again without sourcing it" >&2
    return 1;
fi

# run script vars
RN_RT="${GITHUB_WORKSPACE:-/k/repos/kh/orc}"
RN_NVM_SH="${NVM_DIR:-;}/nvm.sh"
RN_ND_VRSN=22
RN_EC=0

# orc lib vars (required to assemble typescript files)
export ORC_EVENT="${RN_RT}/lib/src/templates/typescript/com/koreyhinton/event"
export ORC_ROUTER="${RN_RT}/lib/src/templates/typescript/com/koreyhinton/router"
export NSMAP="${RN_RT}/lib/src/main/bash/com/koreyhinton/nsmap"

if [[ -z "$GITHUB_ACTIONS" && -f "$RN_NVM_SH" ]]; then
    # source it, since nvm isn't available to this non-sourced/subshell script
    . "$RN_NVM_SH"
    nvm use 22 1>/dev/null
fi

if [[ "$(node --version | cut -d '.' -f1)" != "v${RN_ND_VRSN}" ]]; then
    echo "requires node version ${RN_ND_VRSN}.x" >&2
    exit 2
fi

cd "${RN_RT}/lib/src/test/typescript/com/koreyhinton/router" || exit 1

./fixtures/models.sh > ./fixtures/models.ts
./sut/poll-route.sh > ./sut/poll-route.ts
./sut/register-routes.sh > ./sut/register-routes.ts
./sut/register-routes-inj.sh > ./sut/register-routes-inj.ts
./fixtures/web.sh > ./fixtures/web.ts

cd integration
for f in `ls ./*.test.sh 2>/dev/null`
do
    fname=$(basename "$f")
    ts_fname="${fname%.*}.ts"
    "./${f}" > "./${ts_fname}"
done
cd ..

if command -v vitest &>/dev/null; then
    vitest --run 2>&1 1>/dev/null
    RN_EC=$?
    vitest run --coverage
else
    npx vitest --run 2>&1 1>/dev/null
    RN_EC=$?
    npx vitest run --coverage
fi

echo "ec=${RN_EC}"
exit $RN_EC
