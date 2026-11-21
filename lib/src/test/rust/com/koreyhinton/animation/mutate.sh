#!/bin/bash

# Mutation tests for the animate-sprite snippet. Each mutant is a copy of the
# animation library with one sed edit to the snippet, a bug the unit tests
# should catch. A mutant is killed (good) when the unit tests fail on it, and
# survives (bad) when they all pass. Exits 1 unless every mutant is killed.
#
# Mutants are built in a temp copy of this crate, so src/lib.rs (from run.sh)
# is left alone. They build without -D warnings, since a mutation can leave a
# variable unused.

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error, script must not be source. Run again without sourcing it" >&2
    return 1;
fi

# run script vars
RN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RN_RT="$(cd "${RN_DIR}/../../../../../../.." && pwd)"
RN_LIB="${RN_RT}/lib/src/templates/rust/com/koreyhinton/animation"
RN_SNIPPET="snippets/macroquad/animate-sprite.sh"
RN_TMP="$(mktemp -d)"
trap 'rm -rf "${RN_TMP}"' EXIT

export NSMAP="${RN_RT}/lib/src/main/bash/com/koreyhinton/nsmap"
# share build artifacts across mutants, apart from run.sh's
export CARGO_TARGET_DIR="${RN_DIR}/target/mutants"

# mutants: a name, and the sed script that applies it to the snippet
MT_NAMES=()
MT_SEDS=()
mutant() { MT_NAMES+=("$1"); MT_SEDS+=("$2"); }

mutant "last_animation_id never updated (stuck on frame 0)" \
    '/last_animation_id =$/,/animation\.id\.clone();/d'
mutant "frame_time not reset after a step" \
    '/IncrementFrame && /,/^    }/{/frame_time = 0\.0;/d}'
mutant "frame not reset on a swap" \
    '/\.frame = 0;$/d'
mutant "first paint doesn't count as a swap" \
    's/AnimationSwapped = .*FirstPaint ||/AnimationSwapped = false ||/'
mutant "a swap doesn't block a step" \
    's/IncrementFrame = !.*AnimationSwapped &&/IncrementFrame = true \&\&/'
mutant "no frames > 0 guard" \
    's/ && [^ ]*\.animation\.frames > 0//'
mutant "paint w and h swapped" \
    's/PaintFrame\.w = \(.*\)\.w;/PaintFrame.w = \1.h;/; s/PaintFrame\.h = \(.*\)\.h;/PaintFrame.h = \1.w;/'

mkdir -p "${RN_TMP}/crate/src"
cp "${RN_DIR}/Cargo.toml" "${RN_TMP}/crate/"

# test_lib <lib dir> <log>: generate the tests against a library and run them
test_lib() {
    ORC_ANIMATION="$1" "${RN_DIR}/unit/animate-sprite.test.sh" \
        > "${RN_TMP}/crate/src/lib.rs" 2> "$2" || return 3
    (cd "${RN_TMP}/crate" && cargo test --no-run -q) >> "$2" 2>&1 || return 2
    (cd "${RN_TMP}/crate" && cargo test -q) >> "$2" 2>&1 || return 1
    return 0
}

# the real library must pass first, or every mutant would look killed
test_lib "${RN_LIB}" "${RN_TMP}/baseline.log"
RN_EC=$?
if [[ ${RN_EC} -ne 0 ]]; then
    cat "${RN_TMP}/baseline.log" >&2
    echo "baseline: the unmutated library fails its tests, fix that first" >&2
    exit 1
fi
echo "baseline: passes"

RN_BAD=0
for i in "${!MT_NAMES[@]}"; do
    name="${MT_NAMES[$i]}"
    log="${RN_TMP}/mutant-${i}.log"
    rm -rf "${RN_TMP}/lib"
    cp -r "${RN_LIB}" "${RN_TMP}/lib"
    sed -i "${MT_SEDS[$i]}" "${RN_TMP}/lib/${RN_SNIPPET}"

    # a sed that no longer matches the snippet would test the real code
    if cmp -s "${RN_LIB}/${RN_SNIPPET}" "${RN_TMP}/lib/${RN_SNIPPET}"; then
        echo "STALE     ${name}: its sed no longer changes the snippet"
        RN_BAD=$((RN_BAD + 1))
        continue
    fi

    test_lib "${RN_TMP}/lib" "${log}"
    case $? in
        1)
            # names of the failing tests, from cargo's failures list
            killers=$(sed -n 's/^    tests::\([a-z0-9_]*\)$/\1/p' "${log}" | sort -u | paste -sd ' ')
            echo "killed    ${name}"
            echo "              by: ${killers}"
            ;;
        0)
            echo "SURVIVED  ${name}: no test caught it"
            RN_BAD=$((RN_BAD + 1))
            ;;
        *)
            echo "BROKEN    ${name}: the mutant doesn't build"
            sed 's/^/              /' "${log}" | head -20
            RN_BAD=$((RN_BAD + 1))
            ;;
    esac
done

echo "${#MT_NAMES[@]} mutants, $((${#MT_NAMES[@]} - RN_BAD)) killed, ${RN_BAD} not"
[[ ${RN_BAD} -eq 0 ]]
