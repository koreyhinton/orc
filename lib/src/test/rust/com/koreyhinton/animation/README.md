# animation tests

Unit and mutation tests for the rust animation library's `animate-sprite`
snippet (`lib/src/templates/rust/com/koreyhinton/animation`).

## Run

From anywhere in the repo, one command runs all the tests:

```bash
lib/src/test/rust/com/koreyhinton/animation/run.sh
```

Requires bash and a Rust toolchain (`cargo`). There are no crate dependencies.

`run.sh` sets `ORC_ANIMATION` and `NSMAP` from its own location, generates
`src/lib.rs` from `unit/animate-sprite.test.sh`, then runs `cargo test` with
`RUSTFLAGS="-D warnings"`, so a warning in the generated code fails the run.
If the unit tests pass, it then runs the mutation tests (`mutate.sh`). It
exits 0 only if both pass.

To run one test, run `run.sh` once to generate `src/lib.rs`, then call cargo
from this folder with a test name filter. This skips the mutation tests:

```bash
cd lib/src/test/rust/com/koreyhinton/animation
cargo test swap
```

## Mutation tests

`run.sh` runs these after the unit tests pass. To run only them:

```bash
lib/src/test/rust/com/koreyhinton/animation/mutate.sh
```

`mutate.sh` checks that the unit tests catch bugs. Each mutant is a copy of
the animation library with one `sed` edit to the snippet that adds a bug
(such as never updating `last_animation_id`). For each mutant the unit tests
should fail, which means it's killed. It prints one line per mutant:

| Result | Meaning |
| --- | --- |
| `killed` | a test failed on the mutant (good), followed by the tests that failed |
| `SURVIVED` | every test passed: the tests miss that bug, so add or strengthen one |
| `STALE` | the `sed` no longer changes the snippet, so update it to match the snippet's current text |
| `BROKEN` | the mutant doesn't build, so the edit proves nothing; change it so it builds |

It first checks that the unmutated library passes. It exits 0 only if every
mutant is killed. It builds in a temp copy of the crate (sharing
`target/mutants`), so it doesn't touch `src/lib.rs`, and without
`-D warnings`, since a mutation can leave a variable unused.

To add a mutant, add a `mutant "<name>" '<sed script>'` line in `mutate.sh`.
Pick bugs the tests can actually catch: for example, `>` to `>=` on the
frame interval would always survive, since frame time is never exactly 0.1s
in the tests.

## Layout

| Path | What it is |
| --- | --- |
| `run.sh` | generates the tests and runs them, then `mutate.sh` |
| `mutate.sh` | runs the tests against mutated copies of the snippet |
| `unit/animate-sprite.test.sh` | prints the tests as one Rust file, with `models.sh` and the snippet inlined |
| `Cargo.toml` | the test crate |
| `src/`, `target/`, `Cargo.lock` | generated, gitignored |

Don't edit `src/lib.rs`: it's overwritten on every run. Edit
`unit/animate-sprite.test.sh` instead.

## Adding a test

Add a `#[test]` function to the heredoc in `unit/animate-sprite.test.sh`.
Inline the snippet with `$(update <ns> <sprite>)`, where `<ns>` is the
namespace (such as `mn_t_`) and `<sprite>` is the Rust variable to map
`AnimatedSprite` to. Add frame time to `frame_time` before each update, the
way an app would.

The helpers build sprites with 32 x 48 tiles and 10 fps animations, so
adding 0.03s per update steps on the 4th update (0.12s), not the 3rd (0.09s).

## CI

`.github/workflows/rust.yml` runs `run.sh` (unit and mutation tests) on
pushes and pull requests to `main`.
