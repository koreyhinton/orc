# orc

orc generates imperative code from bash. A library here is a set of snippets: bash scripts that print code in a target language. An app inlines the snippets into its own generated program, so the result reads from top to bottom with no jumps into library functions.

## Layout

- Snippets: `lib/src/templates/{lang}/com/koreyhinton/{lib}/snippets/{snippet}.sh`, with a `README.md` in `{lib}/`.
- Credited snippets: a snippet adapted from another project's code goes one level deeper, in a folder named after that project, with the project's license file copied verbatim next to it: `snippets/{project}/{snippet}.sh` and `snippets/{project}/LICENSE-MIT` (see the rust animation library's `snippets/macroquad/`). Credit the project in the snippet's bash header and in the comment it prints into the generated code, since the generated code is what ships in apps: name the project and the file adapted, then its copyright line and license, and point to the license file. Snippets written from scratch stay in `snippets/`. The router's `regexparam/` folder came before this rule.
- Library root: `{lib}/version.sh` (the version and its check), `{lib}/models.sh` (the library's types, if it has any), and optionally `{lib}/snippets/import.sh` (its imports; see "Version and imports").
- Namespace binding: `lib/src/main/bash/com/koreyhinton/nsmap/` (`bind`, `nsmap`, `nsremap`, `symbolize`). Apps set `NSMAP` to this folder.
- Command line: `lib/src/main/bash/com/koreyhinton/cli/`, the `orc` command (see "The orc command" below), with its tests in `lib/src/test/bash/com/koreyhinton/cli/run.sh`.
- Tests: `lib/src/test/{lang}/com/koreyhinton/{lib}/`.
- Each library gets an environment variable pointing at its folder, named `ORC_{LIB}` (`ORC_WS`, `ORC_ROUTER`). Apps call snippets through it: `` ` ${ORC_WS}/snippets/read-frame.sh ${v}pl_ ` ``.

## The orc command

`lib/src/main/bash/com/koreyhinton/cli/` holds the `orc` command. Apps put that folder on `PATH`. `orc <command>` runs the executable `orc-<command>` next to it, git style, so each command is its own small script; `common.bash` holds what they share (it isn't executable, so it isn't a command). Each script finds orc's files from its own location (through any symlink), never from `PATH` or `ORC`.

- `orc init` sets orc up around the layout already in the folder, so a language's own tool (`cargo init`, `go mod init`, Gradle, Spring Initializr, ...) makes the layout first. It sets up one pipeline per `main.sh`: each `main.sh` not yet in `build.sh`, with the `main.<ext>` next to it as its output (asking the extension, `--ext`, if there's none); else the entry file the tooling made (`src/main.rs`, `main.go`, `*Application.java`, `Program.cs`, ...; `--entry` chooses among several), after asking "Let build.sh own <file>?" (unless it was picked from the list), with a `main.sh` next to it seeded with the file's code so the first build reproduces it; else, after asking, `src/main.sh` with the language's skeleton. Around the pipelines it plans `LICENSE` (AGPL-3.0; another license is only replaced after a yes or `--license agpl`), `.gitignore` (missing lines appended), `ORC.md` (orc's rules, refreshed when they change), `CLAUDE.md` (an `@ORC.md` import added) and `AGENTS.md` (links to `CLAUDE.md` and `ORC.md` added), `orc-env.sh`, `build.sh` and `.github/workflows/orc.yml`.
- `orc init` never runs a language's own tool (`cargo init`, `go mod init`, Gradle, ...): setting up the project is the developer's. When a pipeline's project file (`Cargo.toml`, `go.mod`, `*.csproj`, ...) is missing from the output's folder and those above it, it warns before the plan is accepted, naming the tool, so the developer can stop, run it, and run `orc init` again. It also warns when `ORC` isn't set (naming the orc `build.sh` will find instead, or that it won't find one) and when `orc` isn't on `PATH`. Warnings never stop it.
- `orc init` writes nothing until the plan is shown and accepted (`--yes`, or `--dry-run` to only show it), so stopping at any question, Ctrl-C included, leaves the folder as it was. It never overwrites a `build.sh` or `orc-env.sh` it didn't write (its files carry an `# orc init: <name>` marker on line 2), and never changes a pipeline `build.sh` already lists, so running it again only adds what's new.
- Languages are data: `cli/init/lang/<ext>` sets a language's file name (`Main.java`, since Java wants a public class in a file of its name), formatter (`rustfmt`, `gofmt`), `.gitignore` lines, project files and the tool that makes them (for the warning), and skeleton (indented in the heredoc, no `$` or backticks). orc assembles compiled languages, where indentation doesn't change meaning; an extension with no file there still gets a pipeline, with an empty program. Add a language with one file and a skeleton test in `run.sh`. A framework is a file named `<ext>+<name>` (`rs+macroquad`), sourced after the language's: it names the dependency (`ORC_FRAMEWORK_DEP`, found in `Cargo.toml` or `go.mod`) and overrides the skeleton (`@ORC_APP@` becomes the app folder's name). `orc init` uses it when filling a new `main.sh`, and offers it when the adopted file is still the project tool's untouched default (`ORC_LANG_DEFAULT`, cargo's hello world); a file with real code is always seeded as it is.
- `orc check [<dir>]` enforces the one-level rule: each `main.sh` under `<dir>` is a pipeline, and every local script a `main.sh` calls must run no `.sh` itself. It greps the bash, so it works for any target language: backtick calls, `$(...)`, a script path as a command's first word, and `.`, `source`, `bash`, `sh` or `exec` of a script, outside bash comments. A comment in the printed code that only names a script passes, and library calls through a variable (`${ORC_WS}/...`) are left to their library. In a git work tree, folders `.gitignore` excludes are skipped. `build.sh` runs it before generating anything, and so does CI.
- `orc root` prints orc's root folder. `orc-env.sh` sets `ORC` to `$ORC` if it's set, else `orc root`, else `../orc`, checks orc's core version, and derives `NSMAP` (and any library paths) from it. The core version (`lib/src/main/bash/com/koreyhinton/version.sh`, `ORC_CORE_V`, tagged `core/v<version>`) covers `lib/src/main`; `orc init` fills `@ORC_CORE_V@` in the `orc-env.sh` and `orc.yml` templates with it, so a project stays on the orc it was made with. Unlike a library's `version.sh`, it returns 1 instead of exiting, because `orc-env.sh` is sourced into the caller's shell. Bump it (semver, as for libraries) when anything in `lib/src/main` changes, then tag the commit. It warns on each build when it falls back, or when `orc` isn't on `PATH`, and carries on; the CI template sets `ORC` and puts orc's `cli` on `PATH`, so CI builds are quiet.

Templates in `cli/init/` use placeholders `orc init` fills in (`@ORC_PIPELINES@`, `@ORC_BODY@`, `@ORC_LANG@`, ...). Keep `cli/init/ORC.md` in step with the snippet rules below when they change, and add a test to `run.sh` for any new rule `orc check` enforces.

## Older code

The router, event, s3 and dcim libraries came before these rules. Some of their snippets call other snippets, give private names only some of the time, or have no version check, and they print their types from one `classes/{Class}.sh` per type instead of one `models.sh`. Follow these rules for new libraries and for snippets you change. Don't rewrite older libraries to match unless asked.

## Snippets

A snippet is inlined into the caller's code wherever the caller puts it: inside a loop, an `if`, or the top of a function. Write it so it works anywhere.

- Straight-line code only. No functions, methods, callbacks, threads, goroutines or async work, and nothing that runs later (such as Go's `defer`).
- Execution always reaches the end. No `return`, `break`, `continue`, `goto` or `throw` for control flow. Drive loops with a flag the loop body sets.
- No `if` whose body is only another `if`: write `if a && b`. Prefer named bools tested in flat `if`s with compound conditions.
- Snippets are leaves: a snippet never calls another snippet. The app calls each snippet directly, so the app's own script is the only place nesting happens, and it stays one level deep.
- A snippet does the library's job and nothing the app should decide. The app decides whether a snippet runs, by wrapping the call in an `if`. A snippet doesn't take a "when" bool to switch itself off. For example, the ws `upgrade.sh` snippet sends the 101 reply or does nothing; it doesn't write the app's HTTP error reply.
- Comments in the printed code explain what it does for someone reading the generated program, as in any other code.

### Header

Start each snippet with a bash comment (not printed into the output) that lists its interface:

```bash
# ws read-frame
#
#   command arg:  |ns_|
#   input:        |ns_|Reader   *bufio.Reader (from read-request)
#   input/output: |ns_|Data     []byte, the message so far (declared by the caller)
#   output:       |ns_|Framing  bool, true while the message needs more frames
#   settings:     WS_MAX_MESSAGE  default 1 << 20 (bytes)
#   imports:      encoding/binary, errors, io
```

For each output, say whether the snippet declares it or the caller declares it and the snippet sets it. A value the caller needs after an enclosing block must be declared by the caller before that block.

### Variable names

Generated code from different snippets and the app shares one scope, so a snippet must never clash with a name it doesn't own, wherever it's called.

- **Inputs and outputs are bound.** Bind them with `. ${NSMAP}/bind ${v} Conn Req Upgraded` and use them as `${!conn}`, `${!req}`, `${!upgraded}`. Declare outputs through the bound name too (`${!reader} := ...`), so the snippet works whatever the caller maps them to, or with no mapping at all.
- **Other top-level variables are private.** Give each snippet `priv=${RANDOM}_` and name its own variables `${v}${priv}Name` (`${v}${priv}Payload`). The random part keeps the names apart even when the caller, or another snippet, uses the same namespace in the same scope.
- **Block-scoped variables may stay plain.** A variable declared and used only inside one of the snippet's own blocks (an `if` body, a loop variable) can't clash with the caller's scope. One exception: if a bound name is used later in that block, a plain local could hide a caller variable with the same name. Use the prefix there.
- An empty namespace makes the private names start with a digit, so the generated code fails to compile. That's intended: the error points at the call that's missing its namespace.

### Settings

A setting is an environment variable named after the library, with a default that is a code expression in the target language:

```bash
: "${WS_MAX_MESSAGE:=1 << 20}"
```

List settings in the header and the library README.

### Bash details

- The printed code is an unquoted heredoc, so escape `$` and backticks that belong to the target language.
- A snippet runs as its own bash process (in backticks in the caller's heredoc). Nothing it exports reaches the caller or other snippets, and `exit` in it doesn't stop the caller's script.
- A library script finds its own library's files through its own location, `$(dirname "${BASH_SOURCE[0]}")`, not through `ORC_{LIB}`. That way it works when the app hasn't set the variable, and always uses files from the same checkout. `ORC_{LIB}` is for apps calling into the library. (If a sourced file is missing, bash prints an error and carries on, so a wrong path can silently skip whatever that file does, such as the version check.)

## Models

A library that has its own types (structs, classes, interfaces) prints all of them from one `{lib}/models.sh <version>`, not one script per type. The app makes one call and doesn't need to know the type names, including types only the library creates. See `lib/src/templates/go/com/koreyhinton/ws/models.sh`.

- It checks the version (see "Version and imports").
- It prints a whole file in the target language, with its own package or module line and its own imports, so the types' imports never mix with the app's. The app writes it to its own generated file (`ws_models.go`).
- Rust is the exception: `models.sh` prints just the type definitions, with no module line or imports, and the app inlines them where it wants them, between heredocs in its own generated file (everkeep puts them near the top of `main.rs`). A Rust app is often one generated file, and inlined types need no `mod`, `use` or `pub`. Type names still come from settings, so an app can rename one on a clash (see `lib/src/templates/rust/com/koreyhinton/animation/models.sh`).
- Type names are package-level, so they can't use `${v}${priv}`. Give each type a fixed name that's clearly the library's (`WsConn`), and make it a setting so an app can rename it on a clash: `: "${WS_CONN_TYPE:=WsConn}"`. Every snippet that uses the type sets the same default. The package name is a setting too (`WS_PACKAGE`).
- A type shows up in snippet headers as the type of an input or output (`|ns_|Ws  *WsConn (from upgrade)`). Prefer passing one value of a library type over binding several related values separately.
- If the library grows many types, `models.sh` can be split into smaller scripts inside the library later; apps still make the one call.

## Version and imports

Each library keeps its version in `{lib}/version.sh` (see `lib/src/templates/go/com/koreyhinton/ws/version.sh` or `lib/src/templates/rust/com/koreyhinton/animation/version.sh`). `models.sh`, and `snippets/import.sh` if the library has one, source it with the version the app asks for, so there's one place to bump:

- It holds the library's version, `ORC_{LIB}_V="0.1.0"`.
- It takes the version the app asks for as `$1`. If they differ (compare as strings, with `!=`, not `-ne`), it prints an error to stderr and exits 1, which exits the script that sourced it.

An app has to call `models.sh` before it can use the library's snippets, since they need its types, so `models.sh` alone is enough to check the version. A library with neither types nor an `import.sh` has no version check yet; add one to whichever script apps call first if that's needed.

### Imports

orc libraries don't wrap third-party libraries. A snippet uses a third-party API (such as macroquad's) directly, as the app's own code would, and the app imports what it uses itself. That keeps the generated code readable, and an app can still write its own wrapper snippets where it wants one. So a new library doesn't need `import.sh`: list what each snippet needs in its header's `imports:` line and in the README, and the app adds those imports. The rust animation library has no `import.sh`.

A library may still provide `snippets/import.sh <version>` (ws does):

- After the version check, it prints a comment with the library and version, then every import or dependency the library's snippets need, each with a comment naming which snippets need it (`"time" // orc dependency (read-request, upgrade, write-json)`). Use the target language's comment and import syntax.
- Keep it in sync with the `imports:` line in every snippet's header. The app must not list these imports itself: the library provides them.

### Calling them from an app

Apps call `models.sh` and `import.sh` between heredocs, not in backticks, so a version mismatch stops the app's script, and the build with `pipefail`. In backticks, the error is printed but the script carries on, and the build fails later with confusing errors about missing types. Keep the version the app asks for in one place in the app (sharecmd exports `ORC_WS_VERSION` from `build.sh`, and everkeep exports `ORC_ANIMATE_VERSION` from `orc-env.sh`):

```bash
cat << EOF
import (
EOF

${ORC_WS}/snippets/import.sh "${ORC_WS_VERSION}" || exit 1

cat << EOF
	"log"
)
EOF
```

### Bumping the version

Don't bump the version while a library is unpublished: changes before its first release ship as that first version. After it's published, bump it (semver) whenever a snippet, `models.sh` or `import.sh` (if any) changes:

- **Major:** a change apps have to adapt to. That means a renamed, removed or retyped binding, a removed snippet or setting, or a change to what an output means.
- **Minor:** a new snippet, binding, setting, type or import that existing apps don't have to use.
- **Patch:** a fix inside a snippet with the same interface.

## Library README

Each library's `README.md` covers:

- a table of its snippets and what each does
- its types and `models.sh`, if it has any
- what it doesn't handle yet
- how to call a snippet with a namespace
- its settings
- the imports an app adds for its snippets, or how to use `import.sh` if it has one
- credits for any adapted code, and where their license files are
- a full example

Check the example by generating code from it and compiling that code. For Go, run `gofmt` and `go vet`.

## Testing

Before finishing a change to a snippet, generate code that uses it and compile it. Run the library's tests under `lib/src/test/` if it has any, and the generated program's own tests if you're changing a snippet an app depends on.
