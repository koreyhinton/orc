#!/bin/bash

# Mutation tests for the pathfinding library. Each mutant is a copy of the
# library with one sed edit to one of its files, a bug the tests should catch.
# The tests are the version check (unit/models-version.check.sh), the
# type-name test (unit/type-names.test.sh) and the Rust unit tests. A mutant
# is killed (good) when a test fails on it, and survives (bad) when they all
# pass.
#
# Then each control is a copy of a test with one sed edit, run against the
# real library, that must fail with a given error. It shows the test can
# fail for the reason it exists: the type-name test without its setting
# must hit the name clash (E0428). Exits 1 unless every mutant is killed and
# every control fails as expected.
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
RN_LIB="${RN_RT}/lib/src/templates/rust/com/koreyhinton/pathfinding"
RN_TMP="$(mktemp -d)"
trap 'rm -rf "${RN_TMP}"' EXIT

export NSMAP="${RN_RT}/lib/src/main/bash/com/koreyhinton/nsmap"
# use the default type names, unless a test sets its own
unset PATHFINDING_GRID_FULLY_QUALIFIED
# share build artifacts across mutants, apart from run.sh's
export CARGO_TARGET_DIR="${RN_DIR}/target/mutants"

# mutants: a name, the library file to edit, and the sed script to apply
MT_NAMES=()
MT_FILES=()
MT_SEDS=()
mutant() { MT_NAMES+=("$1"); MT_FILES+=("$2"); MT_SEDS+=("$3"); }

MT_SNIPPET="snippets/find-path.sh"

mutant "the estimate overshoots, so paths aren't the cheapest" "${MT_SNIPPET}" \
    's/let \${v}\${priv}left_n = 10 \*/let ${v}${priv}left_n = 30 */'
mutant "a diagonal step costs the same as a straight one" "${MT_SNIPPET}" \
    's/(\(-\{0,1\}1\), \(-\{0,1\}1\), 14)/(\1, \2, 10)/'
mutant "diagonal steps cut blocked corners" "${MT_SNIPPET}" \
    's/\${v}\${priv}cost == 10$/${v}${priv}cost >= 10/'
mutant "blocked cells are walkable" "${MT_SNIPPET}" \
    's/let \${v}\${priv}open_step = !\${!grid}\.blocked\[\${v}\${priv}n\]/let ${v}${priv}open_step = true/'
mutant "an unreachable goal gives no path toward it" "${MT_SNIPPET}" \
    '/\${v}\${priv}nearest = \${v}\${priv}near;/d'
mutant "the nearest cell ignores how close it is" "${MT_SNIPPET}" \
    's/let \${v}\${priv}near = (\${v}\${priv}left, /let ${v}${priv}near = (0, /'
mutant "Found is never set" "${MT_SNIPPET}" \
    '/\${!found} = true;/d'
mutant "the path is backwards" "${MT_SNIPPET}" \
    '/\${!path}\.reverse();/d'
mutant "Start isn't moved onto the grid" "${MT_SNIPPET}" \
    's/\${!start}\.0\.min(\${v}\${priv}w - 1)/${!start}.0/'
mutant "Goal isn't moved onto the grid" "${MT_SNIPPET}" \
    's/let \${v}\${priv}goal_y = \${!goal}\.1\.min(\${v}\${priv}h - 1);/let ${v}${priv}goal_y = ${!goal}.1;/'
mutant "a grid whose cells don't match its size is searched" "${MT_SNIPPET}" \
    's/ && \${!grid}\.blocked\.len() == \${v}\${priv}w \* \${v}\${priv}h//'
mutant "an empty grid is searched" "${MT_SNIPPET}" \
    's/if \${v}\${priv}w > 0 && \${v}\${priv}h > 0 && /if /'

# the version check: models.sh must refuse a version other than version.sh's
mutant "models.sh skips the version check" models.sh \
    '/^\. .*version\.sh/d'
mutant "models.sh runs version.sh instead of sourcing it" models.sh \
    's/^\. \(.*version\.sh\)/bash \1/'
mutant "version.sh doesn't exit on a mismatch" version.sh \
    '/^    exit 1$/d'
mutant "version.sh compares with -ne, not !=" version.sh \
    's/ != / -ne /'

# the type-name setting: the name must come from its setting
mutant "models.sh ignores the PathGrid name setting" models.sh \
    's/struct \${PATHFINDING_GRID_FULLY_QUALIFIED} {/struct PathGrid {/'

# controls: a name, the test generator to edit, the sed script to apply, the
# cargo test target it generates, and the error it must then fail with
CT_NAMES=()
CT_FILES=()
CT_SEDS=()
CT_TARGETS=()
CT_ERRORS=()
control() { CT_NAMES+=("$1"); CT_FILES+=("$2"); CT_SEDS+=("$3"); CT_TARGETS+=("$4"); CT_ERRORS+=("$5"); }

control "type-name test without its setting clashes" unit/type-names.test.sh \
    '/^export PATHFINDING_.*_FULLY_QUALIFIED=/d' type_names 'E0428'

mkdir -p "${RN_TMP}/crate/src" "${RN_TMP}/crate/tests"
cp "${RN_DIR}/Cargo.toml" "${RN_TMP}/crate/"

# test_lib <lib dir> <log>: run the version check against a library, then
# generate the Rust tests against it and run them. The type-name test's
# compile failing is a kill (a name clash), but the unit tests' is a broken
# mutant.
test_lib() {
    ORC_PATHFINDING="$1" "${RN_DIR}/unit/models-version.check.sh" > "$2" 2>&1 || return 1
    ORC_PATHFINDING="$1" "${RN_DIR}/unit/find-path.test.sh" \
        > "${RN_TMP}/crate/src/lib.rs" 2>> "$2" || return 3
    ORC_PATHFINDING="$1" "${RN_DIR}/unit/type-names.test.sh" \
        > "${RN_TMP}/crate/tests/type_names.rs" 2>> "$2" || return 3
    (cd "${RN_TMP}/crate" && cargo test --lib --no-run -q) >> "$2" 2>&1 || return 2
    (cd "${RN_TMP}/crate" && cargo test --test type_names -q) >> "$2" 2>&1 || return 1
    (cd "${RN_TMP}/crate" && cargo test --lib -q) >> "$2" 2>&1 || return 1
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
    file="${MT_FILES[$i]}"
    sed -i "${MT_SEDS[$i]}" "${RN_TMP}/lib/${file}"

    # a sed that no longer matches its file would test the real code
    if cmp -s "${RN_LIB}/${file}" "${RN_TMP}/lib/${file}"; then
        echo "STALE     ${name}: its sed no longer changes ${file}"
        RN_BAD=$((RN_BAD + 1))
        continue
    fi

    test_lib "${RN_TMP}/lib" "${log}"
    case $? in
        1)
            # the failed version checks, the type-name test with its error
            # codes, or cargo's list of failing unit tests
            killers=$( {
                sed -n 's/^FAILED  \([^:]*\):.*/\1/p' "${log}"
                if grep -q '^error.*type_names' "${log}"; then
                    codes=$(grep -o 'E0[0-9]\{3\}' "${log}" | sort -u | paste -sd ' ')
                    echo "type_names${codes:+ (${codes})}"
                fi
                sed -n 's/^    tests::\([a-z0-9_]*\)$/\1/p' "${log}"
            } | sort -u | paste -sd ',' | sed 's/,/, /g')
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

# controls: run the edited test against the real library
RN_CT_BAD=0
for i in "${!CT_NAMES[@]}"; do
    name="${CT_NAMES[$i]}"
    file="${CT_FILES[$i]}"
    target="${CT_TARGETS[$i]}"
    want="${CT_ERRORS[$i]}"
    log="${RN_TMP}/control-${i}.log"
    gen="${RN_TMP}/control-${i}.sh"
    sed "${CT_SEDS[$i]}" "${RN_DIR}/${file}" > "${gen}"

    if cmp -s "${RN_DIR}/${file}" "${gen}"; then
        echo "STALE     ${name}: its sed no longer changes ${file}"
        RN_CT_BAD=$((RN_CT_BAD + 1))
        continue
    fi

    # an empty generated file would compile and pass, so check it ran
    if ! ORC_PATHFINDING="${RN_LIB}" bash "${gen}" > "${RN_TMP}/crate/tests/${target}.rs" 2> "${log}"; then
        echo "BROKEN    ${name}: the edited ${file} doesn't generate"
        sed 's/^/              /' "${log}" | head -20
        RN_CT_BAD=$((RN_CT_BAD + 1))
        continue
    fi

    if (cd "${RN_TMP}/crate" && cargo test --test "${target}" -q) >> "${log}" 2>&1; then
        echo "PASSED    ${name}: the edited test passes, so it can't catch this"
        RN_CT_BAD=$((RN_CT_BAD + 1))
    elif grep -q "${want}" "${log}"; then
        echo "failed    ${name}"
        echo "              with: ${want}"
    else
        echo "WRONG     ${name}: it failed, but without ${want}"
        sed 's/^/              /' "${log}" | head -20
        RN_CT_BAD=$((RN_CT_BAD + 1))
    fi
done

echo "${#CT_NAMES[@]} controls, $((${#CT_NAMES[@]} - RN_CT_BAD)) failed as expected, ${RN_CT_BAD} not"
[[ ${RN_BAD} -eq 0 && ${RN_CT_BAD} -eq 0 ]]
