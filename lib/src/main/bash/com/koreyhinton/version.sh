#!/bin/bash

# orc core version: lib/src/main (nsmap and the orc command), tagged
# core/v<version>. Templates under lib/src/templates have their own.
#
#   A project's orc-env.sh sources it with the version the project asks for:
#       . "${ORC}/lib/src/main/bash/com/koreyhinton/version.sh" 0.1.0
#   It fails with 1 if the versions differ. orc-env.sh is sourced (by
#   build.sh, or by hand into a shell), so it returns rather than exits, and
#   never closes the caller's shell.

ORC_CORE_V="0.1.0"

if [[ "${1}" != "${ORC_CORE_V}" ]]; then
    echo "Error: invalid orc core version specified. Requested: ${1}, provided: ${ORC_CORE_V}" 1>&2
    return 1 2>/dev/null || exit 1
fi
