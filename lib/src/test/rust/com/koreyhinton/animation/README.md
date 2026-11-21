# animation tests

Unit, type-name and mutation tests for the rust animation library's `animate-sprite`
snippet (`lib/src/templates/rust/com/koreyhinton/animation`).

## Run

From anywhere in the repo, one command runs all the tests:

```bash
lib/src/test/rust/com/koreyhinton/animation/run.sh
```

Requires bash and a Rust toolchain (`cargo`). There are no crate dependencies.

`run.sh` sets `ORC_ANIMATION` and `NSMAP` from its own location, runs
`unit/models-version.check.sh` (which checks that `models.sh` refuses any
version but the one in `version.sh`, so an app asking for the wrong orc
version fails to generate), and generates the Rust tests:

- `src/lib.rs` from `unit/animate-sprite.test.sh`: the unit tests.
- `tests/type_names.rs` from `unit/type-names.test.sh`: plays an app that
  already has its own `Animation`, `AnimatedSprite` and `PaintFrame` types,
  and renames the library's with the `ANIMATION_*_FULLY_QUALIFIED` settings.
  It's its own crate, because a name clash fails its whole compile (E0428).

It runs both with `RUSTFLAGS="-D warnings"`, so a warning in the generated
code fails the run. If the unit tests pass, it then runs the mutation tests
(`mutate.sh`). A failed version check or type-name test doesn't stop the
other tests from running, but the run exits 0 only if everything passes.

To run one test, run `run.sh` once to generate `src/lib.rs`, then call cargo
from this folder with a test name filter. This skips the mutation tests:

```bash
cd lib/src/test/rust/com/koreyhinton/animation
cargo test --lib swap
cargo test --test type_names
```

## Mutation tests

`run.sh` runs these after the unit tests pass. To run only them:

```bash
lib/src/test/rust/com/koreyhinton/animation/mutate.sh
```

`mutate.sh` checks that the tests catch bugs. Each mutant is a copy of the
animation library with one `sed` edit to one of its files that adds a bug:
in the snippet (such as never updating `last_animation_id`), or in the
version check (such as `models.sh` skipping it, or `version.sh` not exiting
on a mismatch). For each mutant the version check or a unit test should
fail, which means it's killed. It prints one line per mutant:

| Result | Meaning |
| --- | --- |
| `killed` | a test failed on the mutant (good), followed by the tests that failed |
| `SURVIVED` | every test passed: the tests miss that bug, so add or strengthen one |
| `STALE` | the `sed` no longer changes its file, so update it to match the file's current text |
| `BROKEN` | the mutant doesn't build, so the edit proves nothing; change it so it builds |

It first checks that the unmutated library passes. It exits 0 only if every
mutant is killed. It builds in a temp copy of the crate (sharing
`target/mutants`), so it doesn't touch `src/lib.rs`, and without
`-D warnings`, since a mutation can leave a variable unused.

To add a mutant, add a `mutant "<name>" <file> '<sed script>'` line in
`mutate.sh`, where `<file>` is relative to the library folder (such as
`models.sh`, or `"${MT_SNIPPET}"` for the snippet). Pick bugs the tests can
actually catch: for example, `>` to `>=` on the frame interval would always
survive, since frame time is never exactly 0.1s in the tests. Changing the
version in `version.sh` would survive too, on purpose: the version check
reads the version from there, so a bump doesn't break it.

## Layout

| Path | What it is |
| --- | --- |
| `run.sh` | generates the tests and runs them, then `mutate.sh` |
| `mutate.sh` | runs the tests against mutated copies of the snippet |
| `unit/animate-sprite.test.sh` | prints the tests as one Rust file, with `models.sh` and the snippet inlined |
| `unit/type-names.test.sh` | prints the type-name test, an app whose own types share the library's default names |
| `unit/models-version.check.sh` | checks `models.sh` against `version.sh` (bash, prints no Rust) |
| `Cargo.toml` | the test crate |
| `src/`, `tests/`, `target/`, `Cargo.lock` | generated, gitignored |

Don't edit `src/lib.rs` or `tests/type_names.rs`: they're overwritten on
every run. Edit the `unit/*.test.sh` that prints them instead.

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
