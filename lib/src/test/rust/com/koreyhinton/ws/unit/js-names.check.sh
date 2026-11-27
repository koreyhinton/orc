#!/bin/bash

# Checks that the browser plugin (js/orc_ws.js) provides exactly the
# functions models.sh declares in its wasm32 extern block. The wasm build
# links them by name, so a function the plugin names differently isn't found
# when the browser loads the game, and the first call to it aborts the game
# (a Rust panic, "RuntimeError: unreachable"). The Rust tests run on desktop
# and never load the plugin, so only this check catches it.
#
# Prints one line per check and exits 1 if any fail. Not a generator: unlike
# *.test.sh, it prints no Rust.

: "${ORC_WS:?set ORC_WS (see run.sh)}"

CK_FAILED=0
pass() { echo "ok      $1"; }
fail() { echo "FAILED  $1: $2"; CK_FAILED=1; }

# the version models.sh wants, so it prints its types
CK_V=$(sed -n 's/^ORC_WS_V="\(.*\)"$/\1/p' "${ORC_WS}/version.sh")
CK_RUST=$("${ORC_WS}/models.sh" "${CK_V}" | sed -n 's/^ *fn \(orc_ws_[a-z_]*\)(.*/\1/p' | sort -u)
CK_JS=$(sed -n 's/^ *importObject\.env\.\([a-z_]*\) *=.*/\1/p' "${ORC_WS}/js/orc_ws.js" | sort -u)

if [[ -z "${CK_RUST}" ]]; then
    fail "models.sh declares the plugin's functions" "no 'fn orc_ws_...' lines in its output"
fi

CK_NAME="js/orc_ws.js provides every function models.sh declares"
CK_MISSING=$(comm -23 <(echo "${CK_RUST}") <(echo "${CK_JS}") | paste -sd ' ')
if [[ -n "${CK_MISSING}" ]]; then
    fail "${CK_NAME}" "missing ${CK_MISSING}"
else
    pass "${CK_NAME} ($(echo "${CK_RUST}" | wc -l) functions)"
fi

CK_NAME="js/orc_ws.js provides nothing models.sh doesn't declare"
CK_EXTRA=$(comm -13 <(echo "${CK_RUST}") <(echo "${CK_JS}") | paste -sd ' ')
if [[ -n "${CK_EXTRA}" ]]; then
    fail "${CK_NAME}" "extra ${CK_EXTRA}"
else
    pass "${CK_NAME}"
fi

exit ${CK_FAILED}
