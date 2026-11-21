#!/bin/bash

# orc animation version, shared by models.sh.
#
#   Source it with the version the app asks for:
#       . "$(dirname "${BASH_SOURCE[0]}")/version.sh" "${1}"
#   It exits the sourcing script with 1 if the versions differ.

ORC_ANIMATION_V="0.1.0"

if [[ "${1}" != "${ORC_ANIMATION_V}" ]]; then
    echo "Error: invalid orc animation version specified. Requested: ${1}, provided: ${ORC_ANIMATION_V}" 1>&2
    exit 1
fi
