# orc

code generation for imperative flow/orchestration

## code templates

imperative snippets:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/snippets/{snippet}.sh

library types, printed as one whole file:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/models.sh <version>

library version, checked by models.sh and snippets/import.sh:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/version.sh

(older libraries print their types from one `classes/{Class}.sh` per type)

## variable namespace mapping tools

    ./lib/src/main/bash/com/koreyhinton/nsmap/nsmap

    ./lib/src/main/bash/com/koreyhinton/nsmap/nsremap

## versions

each part of orc is versioned and tagged on its own:

    core/v{x.y.z}     lib/src/main (nsmap, the orc command)
    {lib}/v{x.y.z}    a template library, e.g. ws/v0.1.0

the core version is in:

    ./lib/src/main/bash/com/koreyhinton/version.sh

`orc init` pins a project to the core version it ran with: its `orc-env.sh` checks it on every build (a different orc stops the build), and its CI checks out the matching tag (`ref: core/v0.1.0`). to move a project to a newer orc, bump the version in both places.

## the orc command

put the cli folder on PATH:

    export PATH="<orc>/lib/src/main/bash/com/koreyhinton/cli:${PATH}"

set orc up around a project's layout (make the layout with the language's own tool first, e.g. `cargo init`); it shows its plan and writes nothing until you accept:

    orc init

check that only a main.sh calls snippets (build.sh runs this first):

    orc check

### example: a macroquad game

with `ORC` set to orc's root and the cli folder on PATH (above), cargo makes the project and orc takes over its `src/main.rs`:

    cargo init
    cargo add macroquad
    orc init
    ./build.sh
    cargo run

`orc init` sees cargo's untouched hello world and the macroquad dependency, and asks:

    Let build.sh own src/main.rs? [Y/n]
    ... Start src/main.sh from a macroquad skeleton instead? [Y/n]
    Proceed? [y/N] y

`src/main.sh` now prints the program from its heredoc, and `./build.sh` checks the architecture, then writes it (through `rustfmt`) to `src/main.rs`:

```rust
use macroquad::prelude::*;

#[macroquad::main("mygame")]
async fn main() {
    loop {
        clear_background(WHITE);
        // snippets go here
        next_frame().await
    }
}
```

`cargo run` opens the window. From here, edit `src/main.sh` (never `src/main.rs`): write snippets next to it, call them from its heredoc, and run `./build.sh` again.

tests:

    ./lib/src/test/bash/com/koreyhinton/cli/run.sh

## documentation

[s3 model](docs/models/s3.svg)
