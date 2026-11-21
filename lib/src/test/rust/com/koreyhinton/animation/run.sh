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

# models.sh must refuse the wrong version. Keep going on a failure, so the
# run still reports the Rust tests, but fail the run at the end.
./unit/models-version.check.sh
RN_CHECK_EC=$?

mkdir -p src tests
set -o pipefail
./unit/animate-sprite.test.sh > ./src/lib.rs || exit 1
./unit/type-names.test.sh > ./tests/type_names.rs || exit 1

# warnings in the generated code fail the run
export RUSTFLAGS="-D warnings"

# The type-name test is its own crate, and a name clash fails its whole
# compile, so run it apart from the unit tests and fail the run at the end.
cargo test --test type_names
RN_NAMES_EC=$?

cargo test --lib || exit $?

# then check the tests catch bugs (mutate.sh repeats the unit tests as its
# baseline, so only run it once they pass)
unset RUSTFLAGS
./mutate.sh || exit $?

[[ ${RN_CHECK_EC} -eq 0 && ${RN_NAMES_EC} -eq 0 ]]
