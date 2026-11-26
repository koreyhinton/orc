#!/bin/bash
# orc init: build.sh

# Checks the architecture (orc check), then runs each pipeline: its main.sh
# prints a program, an optional formatter tidies it, and the result replaces
# the output file. Never edit an output: edit the .sh files and run ./build.sh.

cd "$(dirname "$0")" || exit 1

. ./orc-env.sh || exit 1

set -o pipefail

# snippets are leaves: only a main.sh may call them
"${ORC}/lib/src/main/bash/com/koreyhinton/cli/orc-check" . || exit 1

# The pipelines, one per main.sh: "<main.sh>|<output>|<formatter, or empty>".
# orc init adds a line here for each main.sh it sets up.
orc_pipelines=(
@ORC_PIPELINES@
)

for orc_pipeline in "${orc_pipelines[@]}"; do
    IFS='|' read -r orc_main orc_out orc_format <<< "${orc_pipeline}"
    mkdir -p "$(dirname "${orc_out}")"
    # main.sh runs from its own folder, where its snippets are. Write to a
    # temp file, so a failed build keeps the last good output.
    if [[ -n "${orc_format}" ]]; then
        (cd "$(dirname "${orc_main}")" && "./$(basename "${orc_main}")") \
            | ${orc_format} > "${orc_out}.tmp"
    else
        (cd "$(dirname "${orc_main}")" && "./$(basename "${orc_main}")") \
            > "${orc_out}.tmp"
    fi
    if [[ $? -ne 0 ]]; then
        rm -f "${orc_out}.tmp"
        echo "build.sh: ${orc_main} failed; ${orc_out} is unchanged" >&2
        exit 1
    fi
    mv "${orc_out}.tmp" "${orc_out}"
done
