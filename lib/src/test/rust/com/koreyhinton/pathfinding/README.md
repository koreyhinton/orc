# pathfinding tests

Unit, type-name and mutation tests for the rust pathfinding library's
`find-path` snippet (`lib/src/templates/rust/com/koreyhinton/pathfinding`).
They follow the animation library's tests (`../animation/README.md`), which
explain the mutation results and controls in more detail.

## Run

From anywhere in the repo, one command runs all the tests:

```bash
lib/src/test/rust/com/koreyhinton/pathfinding/run.sh
```

Requires bash and a Rust toolchain (`cargo`). There are no crate dependencies.

`run.sh` sets `ORC_PATHFINDING` and `NSMAP` from its own location, runs
`unit/models-version.check.sh` (which checks that `models.sh` refuses any
version but the one in `version.sh`), and generates the Rust tests:

- `src/lib.rs` from `unit/find-path.test.sh`: the unit tests.
- `tests/type_names.rs` from `unit/type-names.test.sh`: plays an app that
  already has its own `PathGrid`, and renames the library's with
  `PATHFINDING_GRID_FULLY_QUALIFIED`. It's its own crate, because a name
  clash fails its whole compile (E0428).

It runs both with `RUSTFLAGS="-D warnings"`, then the mutation tests
(`mutate.sh`) if the unit tests pass. The run exits 0 only if everything
passes.

To run one test, run `run.sh` once to generate `src/lib.rs`, then call cargo
from this folder with a test name filter:

```bash
cd lib/src/test/rust/com/koreyhinton/pathfinding
cargo test --lib random
```

## What the unit tests check

Small hand-drawn grids (rows of text, `#` for blocked) pin down each rule:
straight and diagonal paths, going around a wall, no cutting a blocked
corner, a blocked or walled-off goal ending at the nearest reachable cell, a
blocked start, cells off the grid, and empty or mismatched grids.

`paths_on_random_grids_are_the_cheapest_there_are` then runs 200 random
grids against `reference_costs`, a plain Dijkstra search over the same
moves. Every path must be walkable step by step and cost exactly the
cheapest cost there is; when the goal can't be reached, the path must end
at the reachable cell nearest it, the cheapest way. The grids come from a
fixed-seed generator, so every run tests the same ones.

## Mutation tests

`mutate.sh` runs the tests against copies of the library with one bug each
(such as an estimate that overshoots, diagonal steps that cut corners, or
`models.sh` skipping its version check), and every mutant must make a test
fail. It prints `killed`, `SURVIVED`, `STALE` or `BROKEN` per mutant, as
the animation tests do, then checks its control: the type-name test without
its setting must fail with E0428.

To add a mutant, add a `mutant "<name>" <file> '<sed script>'` line, where
`<file>` is relative to the library folder.

## Layout

| Path | What it is |
| --- | --- |
| `run.sh` | generates the tests and runs them, then `mutate.sh` |
| `mutate.sh` | runs the tests against mutated copies of the library |
| `unit/find-path.test.sh` | prints the unit tests as one Rust file, with `models.sh` and the snippet inlined |
| `unit/type-names.test.sh` | prints the type-name test |
| `unit/models-version.check.sh` | checks `models.sh` against `version.sh` (bash, prints no Rust) |
| `Cargo.toml` | the test crate |
| `src/`, `tests/`, `target/`, `Cargo.lock` | generated, gitignored |

## CI

`.github/workflows/rust.yml` runs `run.sh` on pushes and pull requests to
`main`.
