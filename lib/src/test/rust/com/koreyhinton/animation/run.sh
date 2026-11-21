#!/bin/bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error, script must not be source. Run again without sourcing it" >&2
    return 1;
fi

# run script vars
RN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RN_RT="$(cd "${RN_DIR}/../../../../../../.." && pwd)"

# orc lib vars (required to assemble rust files)
export ORC_ANIMATION="${RN_RT}/lib/src/templates/rust/com/koreyhinton/animation"
export NSMAP="${RN_RT}/lib/src/main/bash/com/koreyhinton/nsmap"

cd "${RN_DIR}" || exit 1

mkdir -p src
set -o pipefail
./unit/animate-sprite.test.sh > ./src/lib.rs || exit 1

# warnings in the generated code fail the run
RUSTFLAGS="-D warnings" cargo test || exit $?

# then check the tests catch bugs (mutate.sh repeats the unit tests as its
# baseline, so only run it once they pass)
./mutate.sh
