#!/bin/bash

# pathfinding models
#
#   command arg:  <version>, the orc pathfinding version the app expects
#   prints:       the types the pathfinding snippets use
#   settings:     PATHFINDING_GRID_FULLY_QUALIFIED  default PathGrid
#
#   Call it between heredocs, not in backticks, so a version mismatch stops
#   the app's script:
#       ${ORC_PATHFINDING}/models.sh 0.1.0 || exit 1
#
#   Rename the type when the app already has one by that name.

: "${PATHFINDING_GRID_FULLY_QUALIFIED:=PathGrid}"
. "$(dirname "${BASH_SOURCE[0]}")/version.sh" "${1}"

cat << EOF

    // a grid of cells, each walkable or blocked
    struct ${PATHFINDING_GRID_FULLY_QUALIFIED} {
        w: usize,           // columns
        h: usize,           // rows
        blocked: Vec<bool>, // w * h, row by row: cell (x, y) is blocked[y * w + x]
    }

EOF
