# ws

Server-side websocket steps (RFC 6455) for Go, generated from bash. Each
snippet is a straight run of Go statements with no functions, goroutines or
callbacks, so it can be inlined into an imperative program (such as one big
`main`) and read from top to bottom.

The snippets cover the parts a websocket library usually handles:

| Snippet | What it does |
|---|---|
| `snippets/read-request.sh` | Reads the HTTP request with a deadline and keeps the buffered reader for later frames |
| `snippets/upgrade.sh` | Checks the handshake headers, sends `101 Switching Protocols` with `Sec-WebSocket-Accept`, clears the deadline, and gives back a `*WsConn` |
| `snippets/read-frame.sh` | Reads one frame from a `*WsConn`: header, extended length, size limit, unmasking, fragments, close |
| `snippets/write-json.sh` | Writes a value as JSON in one unmasked text frame to a `*WsConn`, with a write deadline |

Two more scripts sit next to `snippets/`:

| Script | What it does |
|---|---|
| `models.sh <version>` | Prints a whole Go file with the types the snippets use: `WsConn` |
| `snippets/import.sh <version>` | Prints every standard package the snippets need, for your import block |

Both check the version you ask for against `version.sh` and exit 1 if it
differs.

Your app does what's in between: routing, deciding whether to accept a
request before `upgrade.sh` runs, and what to do with each message.

Not handled yet: answering pings, the close handshake (a close frame is
treated as a disconnect, and none is sent back), checking
`Sec-WebSocket-Version` and `Connection`, origin checks, extensions and
subprotocols, and enforcing that client frames are masked.

## Calling a snippet

Each snippet takes a namespace (`|ns_|`) and binds its inputs and outputs with
`nsmap/bind`. The header comment at the top of each snippet lists them.
Export a name to map it to one of your variables. A name you don't export
keeps its namespaced name in the generated code (`main_ws_Ws`).

```sh
export ${v}ws_Conn=conn
...
    ` ${ORC_WS}/snippets/read-request.sh ${v}ws_ `
```

A snippet's own variables are named `${v}${priv}Name`, where `priv` is a
random number for each call, so they can't clash with yours or another
snippet's. Outputs a snippet declares (such as `Ws` in `upgrade.sh`) live in
the block you call it from, so use them in that block.

Settings are environment variables with defaults:

| Variable | Default | Used by |
|---|---|---|
| `WS_HANDSHAKE_TIMEOUT` | `5 * time.Second` | `read-request.sh` |
| `WS_MAX_MESSAGE` | `1 << 20` | `read-frame.sh` |
| `WS_WRITE_TIMEOUT` | `5 * time.Second` | `write-json.sh` |
| `WS_PACKAGE` | `main` | `models.sh` |
| `WS_CONN_TYPE` | `WsConn` | `models.sh`, `upgrade.sh` |

## Models

`models.sh <version>` prints a whole Go file, with its own `package` line and
imports, so the types' imports stay separate from yours. Generate it into its
own file next to your code:

```sh
${ORC_WS}/models.sh 0.1.0 | gofmt > ./ws_models.go || exit 1
```

`WsConn` pairs an upgraded connection with the reader its frames must be read
through (the buffer `read-request.sh` read the handshake with, which may
already hold the first frames). Store the `*WsConn` from `upgrade.sh` and pass
it to `read-frame.sh` and `write-json.sh`. Write to `ws.Conn` only through
`write-json.sh`; close it with `ws.Conn.Close()`.

## Imports

`snippets/import.sh <version>` checks that you asked for the version of these
snippets you have, and prints every standard package they need, each marked
`// orc dependency`. Call it between heredocs, not in backticks, so a version
mismatch stops `main.sh` (and, with `pipefail`, the build). Don't list those
packages yourself; `gofmt` sorts them in with yours. If your app skips a
snippet, Go may report one of its packages as imported and not used.

```sh
cat << EOF
package main

import (
EOF

${ORC_WS}/snippets/import.sh 0.1.0 || exit 1

cat << EOF
	"log"
	"net"
)
EOF
```

## Example

./build.sh

```sh
#!/bin/bash

orc=/path/to/orc  # path to root of this repo
export NSMAP=${orc}/lib/src/main/bash/com/koreyhinton/nsmap
export ORC_WS=${orc}/lib/src/templates/go/com/koreyhinton/ws

set -o pipefail
${ORC_WS}/models.sh 0.1.0 | gofmt > ./ws_models.go || exit 1
./main.sh | gofmt > ./main.go
```

./main.sh (inside a server loop that has accepted `conn`)

```sh
export ${v}ws_Conn=conn
export ${v}ws_Upgraded=upgraded
export ${v}ws_Framing=framing

cat << EOF
	` ${ORC_WS}/snippets/read-request.sh ${v}ws_ `
	upgraded := false
	if ${v}ws_Req != nil && ${v}ws_Req.URL.Path == "/ws" {
		` ${ORC_WS}/snippets/upgrade.sh ${v}ws_ `
		if upgraded {
			var ${v}ws_Data []byte
			var ${v}ws_ReadErr error
			for framing := true; framing; {
				` ${ORC_WS}/snippets/read-frame.sh ${v}ws_ `
			}
			${v}ws_Msg := map[string]string{"echo": string(${v}ws_Data)}
			var ${v}ws_WriteErr error
			` ${ORC_WS}/snippets/write-json.sh ${v}ws_ `
			if ${v}ws_WriteErr != nil {
				log.Println("write:", ${v}ws_WriteErr)
			}
		}
	}
	conn.Close()
EOF
```

[sharecmd](https://github.com/koreyhinton/sharecmd) uses these snippets for a
lockstep game server: see its `main.sh`.
