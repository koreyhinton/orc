#!/bin/bash

# pathfinding find-path
#
#   command arg:  |ns_|
#   input:        |ns_|Grid   PathGrid (models.sh), the cells to search
#   input:        |ns_|Start  (usize, usize), the (x, y) cell to start from
#   input:        |ns_|Goal   (usize, usize), the (x, y) cell to reach
#   output:       |ns_|Path   Vec<(usize, usize)>, declared by the snippet:
#                             the cells to walk, after Start, ending at Goal
#                             (or at the reachable cell nearest it)
#   output:       |ns_|Found  bool, declared by the snippet: true if Path
#                             ends at Goal
#   imports:      none (std paths are written out in full)

v=$1
priv=${RANDOM}_
# maps
. ${NSMAP}/bind $v Grid Start Goal Path Found

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    pathfinding find-path                                           *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|Grid: PathGrid                                     *
     *            |ns_|Start: (usize, usize), the (x, y) start cell       *
     *            |ns_|Goal: (usize, usize), the (x, y) goal cell         *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|Path: Vec<(usize, usize)>, declared here           *
     *                the cells after Start, ending at Goal, or at the    *
     *                reachable cell nearest Goal; empty if Start is it   *
     *            |ns_|Found: bool, declared here                         *
     *                true if Path ends at Goal                           *
     *                                                                    *
     *        required model types (models.sh): PathGrid                  *
     *                                                                    *
     *        A* over 8 directions with whole-number costs: 10 for a      *
     *        straight step, 14 for a diagonal one. A diagonal step       *
     *        can't cut the corner of a blocked cell. Start may be        *
     *        blocked (a path still leads out of it); a blocked Goal is   *
     *        never reached. Start and Goal outside the grid are moved    *
     *        to its nearest edge. Ties break by cell index, so the same  *
     *        grid and cells always give the same path, on any machine.   *
     *                                                                    *
     **********************************************************************/

    let mut ${!path}: Vec<(usize, usize)> = Vec::new();
    let mut ${!found} = false;
    let ${v}${priv}w = ${!grid}.w;
    let ${v}${priv}h = ${!grid}.h;
    if ${v}${priv}w > 0 && ${v}${priv}h > 0 && ${!grid}.blocked.len() == ${v}${priv}w * ${v}${priv}h {
        let ${v}${priv}start = ${!start}.1.min(${v}${priv}h - 1) * ${v}${priv}w + ${!start}.0.min(${v}${priv}w - 1);
        let ${v}${priv}goal_x = ${!goal}.0.min(${v}${priv}w - 1);
        let ${v}${priv}goal_y = ${!goal}.1.min(${v}${priv}h - 1);
        let ${v}${priv}goal = ${v}${priv}goal_y * ${v}${priv}w + ${v}${priv}goal_x;

        // g: the cheapest cost found to each cell; from: the cell it came from
        let mut ${v}${priv}g: Vec<u32> = vec![u32::MAX; ${v}${priv}w * ${v}${priv}h];
        let mut ${v}${priv}from: Vec<usize> = vec![usize::MAX; ${v}${priv}w * ${v}${priv}h];
        let mut ${v}${priv}closed: Vec<bool> = vec![false; ${v}${priv}w * ${v}${priv}h];
        // open cells, cheapest first: (estimated total, estimate left, index)
        let mut ${v}${priv}open: std::collections::BinaryHeap<std::cmp::Reverse<(u32, u32, usize)>> =
            std::collections::BinaryHeap::new();

        // the octile distance to the goal: never more than the real cost
        let ${v}${priv}dx = (${v}${priv}start % ${v}${priv}w).abs_diff(${v}${priv}goal_x) as u32;
        let ${v}${priv}dy = (${v}${priv}start / ${v}${priv}w).abs_diff(${v}${priv}goal_y) as u32;
        let ${v}${priv}h_start = 10 * ${v}${priv}dx.max(${v}${priv}dy) + 4 * ${v}${priv}dx.min(${v}${priv}dy);
        ${v}${priv}g[${v}${priv}start] = 0;
        ${v}${priv}open.push(std::cmp::Reverse((${v}${priv}h_start, ${v}${priv}h_start, ${v}${priv}start)));
        // the closed cell nearest the goal: (estimate left, cost, index)
        let mut ${v}${priv}nearest = (${v}${priv}h_start, 0u32, ${v}${priv}start);

        let mut ${v}${priv}searching = true;
        while ${v}${priv}searching {
            match ${v}${priv}open.pop() {
                None => ${v}${priv}searching = false,
                Some(std::cmp::Reverse((_, ${v}${priv}left, ${v}${priv}i))) => {
                    if !${v}${priv}closed[${v}${priv}i] {
                        ${v}${priv}closed[${v}${priv}i] = true;
                        let ${v}${priv}near = (${v}${priv}left, ${v}${priv}g[${v}${priv}i], ${v}${priv}i);
                        if ${v}${priv}near < ${v}${priv}nearest {
                            ${v}${priv}nearest = ${v}${priv}near;
                        }
                        if ${v}${priv}i == ${v}${priv}goal {
                            ${!found} = true;
                            ${v}${priv}searching = false;
                        }
                        let ${v}${priv}x = (${v}${priv}i % ${v}${priv}w) as i64;
                        let ${v}${priv}y = (${v}${priv}i / ${v}${priv}w) as i64;
                        for (${v}${priv}step_x, ${v}${priv}step_y, ${v}${priv}cost) in [
                            (1i64, 0i64, 10u32),
                            (-1, 0, 10),
                            (0, 1, 10),
                            (0, -1, 10),
                            (1, 1, 14),
                            (1, -1, 14),
                            (-1, 1, 14),
                            (-1, -1, 14),
                        ] {
                            let ${v}${priv}nx = ${v}${priv}x + ${v}${priv}step_x;
                            let ${v}${priv}ny = ${v}${priv}y + ${v}${priv}step_y;
                            let ${v}${priv}in_grid = ${v}${priv}searching
                                && ${v}${priv}nx >= 0
                                && ${v}${priv}ny >= 0
                                && ${v}${priv}nx < ${v}${priv}w as i64
                                && ${v}${priv}ny < ${v}${priv}h as i64;
                            if ${v}${priv}in_grid {
                                let ${v}${priv}n = ${v}${priv}ny as usize * ${v}${priv}w + ${v}${priv}nx as usize;
                                // a diagonal step needs both cells beside it open
                                let ${v}${priv}side_x = ${v}${priv}y as usize * ${v}${priv}w + ${v}${priv}nx as usize;
                                let ${v}${priv}side_y = ${v}${priv}ny as usize * ${v}${priv}w + ${v}${priv}x as usize;
                                let ${v}${priv}open_step = !${!grid}.blocked[${v}${priv}n]
                                    && (${v}${priv}cost == 10
                                        || (!${!grid}.blocked[${v}${priv}side_x] && !${!grid}.blocked[${v}${priv}side_y]));
                                let ${v}${priv}cost_n = ${v}${priv}g[${v}${priv}i] + ${v}${priv}cost;
                                if ${v}${priv}open_step && ${v}${priv}cost_n < ${v}${priv}g[${v}${priv}n] {
                                    ${v}${priv}g[${v}${priv}n] = ${v}${priv}cost_n;
                                    ${v}${priv}from[${v}${priv}n] = ${v}${priv}i;
                                    let ${v}${priv}ndx = (${v}${priv}nx as usize).abs_diff(${v}${priv}goal_x) as u32;
                                    let ${v}${priv}ndy = (${v}${priv}ny as usize).abs_diff(${v}${priv}goal_y) as u32;
                                    let ${v}${priv}left_n = 10 * ${v}${priv}ndx.max(${v}${priv}ndy) + 4 * ${v}${priv}ndx.min(${v}${priv}ndy);
                                    ${v}${priv}open.push(std::cmp::Reverse((${v}${priv}cost_n + ${v}${priv}left_n, ${v}${priv}left_n, ${v}${priv}n)));
                                }
                            }
                        }
                    }
                }
            }
        }

        // walk back from the goal (or the nearest cell) to the start
        let mut ${v}${priv}at = if ${!found} { ${v}${priv}goal } else { ${v}${priv}nearest.2 };
        while ${v}${priv}at != ${v}${priv}start {
            ${!path}.push((${v}${priv}at % ${v}${priv}w, ${v}${priv}at / ${v}${priv}w));
            ${v}${priv}at = ${v}${priv}from[${v}${priv}at];
        }
        ${!path}.reverse();
    }

EOF
