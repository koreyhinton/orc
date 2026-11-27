# Pathfinding

Grid pathfinding for Rust, generated from bash with orc. The `find-path`
snippet runs A* over a grid of walkable and blocked cells, and gives the
cells to walk from a start cell to a goal cell. It's deterministic: the same
grid and cells always give the same path, on any machine, so it's safe in a
lockstep game where every player runs the same simulation.

It doesn't know about pixels, units or drawing. The app decides how big a
cell is, which cells are blocked (walls, trees, buildings), and what to do
with the path, such as walking a unit through the cells' centers.

## Snippets

| Snippet | What it does |
| --- | --- |
| `snippets/find-path.sh` | finds the cheapest path between two cells of a `PathGrid` |

```sh
` ${ORC_PATHFINDING}/snippets/find-path.sh ${v}path_ `
```

| Binding | Type | |
| --- | --- | --- |
| `\|ns_\|Grid` | `PathGrid` | input: the cells to search |
| `\|ns_\|Start` | `(usize, usize)` | input: the `(x, y)` cell to start from |
| `\|ns_\|Goal` | `(usize, usize)` | input: the `(x, y)` cell to reach |
| `\|ns_\|Path` | `Vec<(usize, usize)>` | output, declared by the snippet: the cells after `Start`, ending at `Goal` |
| `\|ns_\|Found` | `bool` | output, declared by the snippet: `true` if `Path` ends at `Goal` |

How it searches:

- Steps go to any of the 8 neighbors. A straight step costs 10 and a
  diagonal one 14 (about 10 × √2), so costs stay whole numbers and add up
  the same everywhere.
- A diagonal step needs both cells beside it open, so a path never squeezes
  between two blocked cells that touch at a corner, or clips the corner of
  one.
- If `Goal` can't be reached (it's blocked, or walled off), `Path` ends at
  the reachable cell nearest `Goal` instead, and `Found` is `false`. That's
  usually what a game wants: a unit ordered into a wall walks up to it.
- `Start` may be blocked, and a path still leads out of it. `Start` and
  `Goal` outside the grid are moved to its nearest edge.
- `Path` is empty when `Start` is already the goal (or the nearest cell to
  it), and when the grid is empty or its `blocked` doesn't hold `w * h`
  cells.
- Ties between equally cheap cells break by their index, never by
  allocation or hash order.

## Types and models.sh

`models.sh <version>` prints the type the snippet uses. For Rust it prints
just the type definition, with no module line or imports: your app inlines
it in its own generated file. Call it between heredocs, not in backticks, so
a version mismatch stops your build (see the example's `main.sh`):

```rust
// a grid of cells, each walkable or blocked
struct PathGrid {
    w: usize,           // columns
    h: usize,           // rows
    blocked: Vec<bool>, // w * h, row by row: cell (x, y) is blocked[y * w + x]
}
```

## Settings

| Setting | Default | Used by |
| --- | --- | --- |
| `PATHFINDING_GRID_FULLY_QUALIFIED` | `PathGrid` | `models.sh` |

Rename the type when your app already has one by that name. Export the
setting before calling `models.sh`:

```sh
export PATHFINDING_GRID_FULLY_QUALIFIED=OrcPathGrid
```

## Imports

None. The snippet writes out the std paths it uses
(`std::collections::BinaryHeap`, `std::cmp::Reverse`).

## Version

The library's version is in `version.sh` (`0.1.0`). `models.sh` takes the
version your app asks for, and fails your build if it doesn't match:

```
Error: invalid orc pathfinding version specified. Requested: 0.0.1, provided: 0.1.0
```

## What it doesn't handle yet

- Cells are either walkable or blocked: there are no costs per cell (such
  as slow ground or roads).
- It only moves in 8 directions; a 4-direction mode would be a setting.
- The path goes cell to cell. Straightening it (cutting across open ground
  instead of zig-zagging through cell centers) is up to the app.
- It searches the whole grid each time. On a large grid with a goal that
  can't be reached, it visits every reachable cell before giving up.

## Example

A command line app, `maze-path`, that finds a path through a small maze and
prints it, marking the path with `*`.

You must change this path variable inside `./build.sh`:

* orc

Source files:

- ./Cargo.toml
- ./build.sh
- ./src/main.sh

Generated files:

- ./src/main.rs

./Cargo.toml

```toml
[package]
name = "maze-path"
version = "0.1.0"
edition = "2021"

[dependencies]
```

./build.sh

```sh
#!/bin/bash

orc=/path/to/orc  # path to root of this repo
export NSMAP=${orc}/lib/src/main/bash/com/koreyhinton/nsmap
export ORC_PATHFINDING=${orc}/lib/src/templates/rust/com/koreyhinton/pathfinding
export ORC_PATHFINDING_VERSION=0.1.0

set -o pipefail

cd "$(dirname "$0")/src" || exit 1
# write to a temp file, so a failed generate keeps the last good main.rs
./main.sh > ./main.rs.tmp && mv ./main.rs.tmp ./main.rs || exit 1
```

./src/main.sh

```sh
#!/bin/bash

v=${1:-mn_}
# maps
export ${v}path_Grid=grid
export ${v}path_Start=start
export ${v}path_Goal=goal
export ${v}path_Path=path
export ${v}path_Found=found

cat << EOF
#![allow(non_snake_case)]
EOF

# between heredocs, not in backticks, so a version mismatch stops the build
${ORC_PATHFINDING}/models.sh "${ORC_PATHFINDING_VERSION}" || exit 1

cat << EOF

fn main() {
    let maze = [
        "S....#....",
        ".###.#.##.",
        "...#...#..",
        "##.#####.#",
        "...#....G.",
    ];
    let mut start = (0usize, 0usize);
    let mut goal = (0usize, 0usize);
    let mut blocked = vec![];
    for (y, row) in maze.iter().enumerate() {
        for (x, c) in row.chars().enumerate() {
            if c == 'S' {
                start = (x, y);
            }
            if c == 'G' {
                goal = (x, y);
            }
            blocked.push(c == '#');
        }
    }
    let grid = PathGrid { w: maze[0].len(), h: maze.len(), blocked };

    ` ${ORC_PATHFINDING}/snippets/find-path.sh ${v}path_ `

    println!("found: {found}, {} steps", path.len());
    for (y, row) in maze.iter().enumerate() {
        let line: String = row
            .chars()
            .enumerate()
            .map(|(x, c)| if c == '.' && path.contains(&(x, y)) { '*' } else { c })
            .collect();
        println!("{line}");
    }
}
EOF
```

command line run

```sh
chmod +x build.sh
chmod +x src/main.sh
./build.sh && cargo run
```

Output:

```
found: true, 18 steps
S****#****
.###*#*##*
...#***#**
##.#####*#
...#....G.
```
