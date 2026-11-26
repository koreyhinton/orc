#!/bin/bash
# orc init: orc-env.sh

# orc's paths, shared by build.sh and any test scripts. Source it:
#     . ./orc-env.sh || exit 1
#
# ORC is orc's root folder (the one holding lib/): $ORC if it's set, else
# the orc on PATH (orc root), else orc cloned next to this repo (../orc).
# Using either fallback, or orc missing from PATH, prints a warning but
# carries on: an orc next to the repo, or a full path to its cli, is fine.

orc_env_cli="lib/src/main/bash/com/koreyhinton/cli"
if [[ -z "${ORC}" ]]; then
    if ORC=$(orc root 2> /dev/null) && [[ -n "${ORC}" ]]; then
        echo "orc-env.sh: warning: ORC isn't set; using the orc on PATH (${ORC})" >&2
    else
        ORC=$(realpath -m "$(dirname "${BASH_SOURCE[0]}")/../orc")
        echo "orc-env.sh: warning: ORC isn't set and orc isn't on PATH; using the orc next to this repo (${ORC})" >&2
    fi
fi
if [[ ! -d "${ORC}/lib/src/main/bash/com/koreyhinton" ]]; then
    echo "orc not found at ${ORC}: clone it there, put its cli folder on PATH, or set ORC" >&2
    unset orc_env_cli
    return 1 2>/dev/null || exit 1
fi
if ! command -v orc > /dev/null 2>&1; then
    echo "orc-env.sh: warning: orc isn't on PATH; add ${ORC}/${orc_env_cli} to PATH to run orc init and orc check by name" >&2
fi
unset orc_env_cli
export ORC
export NSMAP="${ORC}/lib/src/main/bash/com/koreyhinton/nsmap"

# Each orc library the app uses gets its path and version here, e.g.:
#     export ORC_WS="${ORC}/lib/src/templates/rust/com/koreyhinton/ws"
#     export ORC_WS_VERSION="0.1.0"
