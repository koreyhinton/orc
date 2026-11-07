# orc

orc generates imperative code from bash. A library here is a set of snippets: bash scripts that print code in a target language. An app inlines the snippets into its own generated program, so the result reads from top to bottom with no jumps into library functions.

## Layout

- Snippets: `lib/src/templates/{lang}/com/koreyhinton/{lib}/snippets/{snippet}.sh`, with a `README.md` in `{lib}/`.
- Library root: `{lib}/version.sh` (the version and its check), `{lib}/models.sh` (the library's types, if it has any), and `{lib}/snippets/import.sh` (its imports).
- Namespace binding: `lib/src/main/bash/com/koreyhinton/nsmap/` (`bind`, `nsmap`, `nsremap`, `symbolize`). Apps set `NSMAP` to this folder.
- Tests: `lib/src/test/{lang}/com/koreyhinton/{lib}/`.
- Each library gets an environment variable pointing at its folder, named `ORC_{LIB}` (`ORC_WS`, `ORC_ROUTER`). Apps call snippets through it: `` ` ${ORC_WS}/snippets/read-frame.sh ${v}pl_ ` ``.

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

- It checks the version like `import.sh` does.
- It prints a whole file in the target language, with its own package or module line and its own imports, so the types' imports never mix with the app's. The app writes it to its own generated file (`ws_models.go`).
- Type names are package-level, so they can't use `${v}${priv}`. Give each type a fixed name that's clearly the library's (`WsConn`), and make it a setting so an app can rename it on a clash: `: "${WS_CONN_TYPE:=WsConn}"`. Every snippet that uses the type sets the same default. The package name is a setting too (`WS_PACKAGE`).
- A type shows up in snippet headers as the type of an input or output (`|ns_|Ws  *WsConn (from upgrade)`). Prefer passing one value of a library type over binding several related values separately.
- If the library grows many types, `models.sh` can be split into smaller scripts inside the library later; apps still make the one call.

## Version and imports

Each library keeps its version in `{lib}/version.sh` (see `lib/src/templates/go/com/koreyhinton/ws/version.sh`). `models.sh` and `snippets/import.sh` both source it with the version the app asks for, so there's one place to bump:

- It holds the library's version, `ORC_{LIB}_V="0.1.0"`.
- It takes the version the app asks for as `$1`. If they differ (compare as strings, with `!=`, not `-ne`), it prints an error to stderr and exits 1, which exits the script that sourced it.

`snippets/import.sh <version>`:

- After the version check, it prints a comment with the library and version, then every import or dependency the library's snippets need, each with a comment naming which snippets need it (`"time" // orc dependency (read-request, upgrade, write-json)`). Use the target language's comment and import syntax.
- Keep it in sync with the `imports:` line in every snippet's header. The app must not list these imports itself: the library provides them.

Apps call `import.sh` between heredocs, not in backticks, so a mismatch stops the app's script, and the build with `pipefail`. Keep the version the app asks for in one place in the app (sharecmd exports `ORC_WS_VERSION` from `build.sh`):

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

Don't bump the version while a library is unpublished: changes before its first release ship as that first version. After it's published, bump it (semver) whenever a snippet, `models.sh` or `import.sh` changes:

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
- how to use `import.sh`
- a full example

Check the example by generating code from it and compiling that code. For Go, run `gofmt` and `go vet`.

## Testing

Before finishing a change to a snippet, generate code that uses it and compile it. Run the library's tests under `lib/src/test/` if it has any, and the generated program's own tests if you're changing a snippet an app depends on.
