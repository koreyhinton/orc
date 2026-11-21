#!/bin/bash

# Checks that models.sh refuses a version other than the library's, so an
# app asking for the wrong orc version fails to generate instead of getting
# types it wasn't written against. The library's version is read from
# version.sh, so a version bump doesn't need a change here.
#
# Prints one line per check and exits 1 if any fail. Not a generator: unlike
# *.test.sh, it prints no Rust.

: "${ORC_ANIMATION:?set ORC_ANIMATION (see run.sh)}"

CK_FAILED=0
CK_OUT="$(mktemp)"
CK_ERR="$(mktemp)"
trap 'rm -f "${CK_OUT}" "${CK_ERR}"' EXIT

pass() { echo "ok      $1"; }
fail() { echo "FAILED  $1: $2"; CK_FAILED=1; }

# models <version...>: run models.sh, keeping its exit code, stdout and stderr
models() {
    "${ORC_ANIMATION}/models.sh" "$@" > "${CK_OUT}" 2> "${CK_ERR}"
}

CK_V=""
if [[ -f "${ORC_ANIMATION}/version.sh" ]]; then
    CK_V=$(sed -n 's/^ORC_ANIMATION_V="\(.*\)"$/\1/p' "${ORC_ANIMATION}/version.sh")
fi
if [[ -n "${CK_V}" ]]; then
    pass "version.sh sets ORC_ANIMATION_V (${CK_V})"
else
    fail "version.sh sets ORC_ANIMATION_V" "no ORC_ANIMATION_V=\"x.y.z\" line in ${ORC_ANIMATION}/version.sh"
fi

# the wrong version, and no version at all, must fail without printing types
for CK_ASK in "0.0.0-wrong" ""; do
    CK_NAME="models.sh '${CK_ASK}' fails"
    models "${CK_ASK}"
    CK_EC=$?
    if [[ ${CK_EC} -eq 0 ]]; then
        fail "${CK_NAME}" "exited 0"
    elif [[ -s "${CK_OUT}" ]]; then
        fail "${CK_NAME}" "exited ${CK_EC} but still printed code"
    elif ! grep -qi 'version' "${CK_ERR}"; then
        fail "${CK_NAME}" "exited ${CK_EC} without a version error on stderr"
    else
        pass "${CK_NAME} ($(head -1 "${CK_ERR}"))"
    fi
done

# the library's own version must generate the types
if [[ -n "${CK_V}" ]]; then
    CK_NAME="models.sh ${CK_V} generates the types"
    models "${CK_V}"
    CK_EC=$?
    if [[ ${CK_EC} -ne 0 ]]; then
        fail "${CK_NAME}" "exited ${CK_EC}: $(head -1 "${CK_ERR}")"
    elif ! grep -q 'struct AnimatedSprite' "${CK_OUT}"; then
        fail "${CK_NAME}" "no AnimatedSprite in the output"
    else
        pass "${CK_NAME}"
    fi
fi

exit ${CK_FAILED}
