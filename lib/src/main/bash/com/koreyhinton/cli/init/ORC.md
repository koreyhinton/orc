# orc

This app's code is generated: bash scripts print the program, assembled with [orc](https://github.com/koreyhinton/orc). `orc init` wrote this file; it can update it when orc's rules change, so keep the app's own notes in `CLAUDE.md`.

## Build

```bash
./build.sh   # runs orc check, then every pipeline
```

- Each pipeline is a `main.sh` and the file it generates, listed in `build.sh` as `"<main.sh>|<output>|<formatter>"`. An app can have several, such as a backend and a frontend.
- Outputs are generated and gitignored. Never edit one; edit the `.sh` files and run `./build.sh`.
- `build.sh` writes each output to a temp file first, so a failed build keeps the last good output. A formatter, if listed, tidies the output; `orc init` adds `rustfmt` for Rust and `gofmt` for Go.
- `orc-env.sh` finds orc: `$ORC` if set, else `orc root` (orc's `cli` folder on `PATH`), else `../orc`. It warns when it falls back or `orc` isn't on `PATH`, and carries on. It checks the orc core version the project is pinned to (stopping the build on another one), exports `NSMAP`, and each orc library the app uses gets its path and version there too.
- `orc init` sets up a pipeline for each new `main.sh` (or entry file such as `src/main.rs`) it finds, and never changes one that's already listed. Run it again after adding one. It never runs the language's own tool (`cargo init`, `go mod init`, ...); it warns when that tool's project file is missing.
- CI (`.github/workflows/orc.yml`) checks out orc at the pinned core version's tag (`core/v<version>`) and runs `./build.sh`. Bump the version in `orc-env.sh` and the workflow together. Add the language's build and test steps after it.

## One pipeline: main.sh calls every snippet

- A `main.sh` is the program. It prints the code inside a heredoc and inlines each snippet where it belongs with a backtick call: `` ` ./my-snippet.sh ${v}my_ ` ``.
- Snippets (every other `.sh` a `main.sh` calls) are leaves. A snippet never runs another `.sh`: no backtick calls, `$(...)`, `source`, `.` or `./x.sh` of another script. Data passes from one snippet to the next through `main.sh`'s maps, so `main.sh` is the single place the program's flow reads top to bottom, one level deep.
- `orc check` enforces this, and `build.sh` runs it first, so a violation fails the build locally before it reaches CI.
- Snippets print straight-line code that works anywhere it's inlined: inside a loop, an `if`, or a function's top. No functions, callbacks, early `return`, `break`, `continue` or `throw`; drive loops with a flag. No `if` whose whole body is another `if`. Follow the snippet rules in orc's `CLAUDE.md`.
- A snippet does its one job. `main.sh` decides whether it runs, by wrapping the call in an `if`.

## Names

- `v` is the bash namespace variable. `main.sh` sets `v=${1:-mn_}`, and each snippet takes its namespace as `v=$1`.
- Map a snippet's inputs and outputs to names in `main.sh` with exports (`export ${v}my_Input=input`). Inside the snippet, bind them with `. ${NSMAP}/bind ${v} Input Output` and use them as `${!input}`, `${!output}`. Outputs left unmapped get the namespaced name (`mn_my_Output`).
- A snippet's own variables are prefixed `${v}` (`${v}count`), so two snippets inlined in one scope never clash.
- `bind` turns each name into a lowercase shell variable (`Vel` becomes `vel`). Don't bind a name that lowercases to `v`, or to anything else the snippet uses in bash (`priv`, `bind_*`), and don't name a generated variable `v`.

## Languages

orc assembles compiled languages, where leading whitespace doesn't change what code means: Rust, Go, Java, Kotlin, C#, C, C++ and TypeScript. Code inside a heredoc is indented to read clearly in the bash, and that indentation passes through to the output (a formatter, where there is one, tidies it). A language where indentation is meaning, such as Python, isn't a fit.

## Types

If the app has its own types, and the language allows many types in one file, print them all from one `models.sh` that `main.sh` (and any tests) call between heredocs, so everything compiles against the same definitions. In a language that wants one type per file (Java), print one file per type instead.

## Bash details

- The printed code is an unquoted heredoc, so escape `$`, backticks and backslashes that belong to the target language (`\$`, `` \` ``, `\\`).
- Text that's awkward inside a heredoc, such as a long multi-line string, can be built in bash and exported to where it's needed.
- Each snippet runs as its own bash process. Nothing it exports reaches `main.sh` or other snippets, and `exit` in it doesn't stop `main.sh`.
