# ws (Rust client)

Client-side websocket and HTTP POST steps for Rust games, generated from
bash. They work on desktop and in the browser (wasm32), and never block a
game loop that calls them once a frame. Each snippet is a straight run of
Rust statements, with no functions, threads or callbacks, so it can be
inlined into an imperative program and read from top to bottom.

orc's Go `ws` library is the server side. Its app,
[sharecmd](https://github.com/koreyhinton/sharecmd), is a lockstep relay
these snippets can talk to. They're adapted from its Rust demo client
(`demo/src/net.rs` and `demo/web/lockstep_net.js`), which used a background
thread. Here a non-blocking socket is polled instead.

| Snippet | What it does |
|---|---|
| `snippets/default-server.sh` | The server URL: `--server URL` on desktop, `?server=` or port 8080 on the page's host in the browser |
| `snippets/post.sh` | Starts an HTTP POST with an empty body and gives back a `WsPost` |
| `snippets/post-poll.sh` | Sets the `WsPost`'s `done` and `body` once the reply is in |
| `snippets/connect.sh` | Opens a websocket (`http://` becomes `ws://`) and gives back a `WsClient` |
| `snippets/read.sh` | Reads at most one text message, without waiting, and notices a close |
| `snippets/send.sh` | Sends one text message, without waiting |

| File | What it does |
|---|---|
| `models.sh <version>` | Prints `WsClient`, `WsPost` and the browser plugin's `extern "C"` block |
| `js/orc_ws.js` | The browser plugin. Serve it with your wasm and load it after `gl.js` (or `mq_js_bundle.js`) and `sapp_jsutils.js` |

`models.sh` checks the version you ask for against `version.sh` and exits 1
if it differs.

Crates: `tungstenite` on desktop and `sapp-jsutils` on wasm32:

```toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
tungstenite = "0.30"

[target.'cfg(target_arch = "wasm32")'.dependencies]
sapp-jsutils = "0.1"
```

## Waiting

- Desktop `connect.sh` and `post.sh` finish their work before going on, up to
  `WS_CONNECT_TIMEOUT` and `WS_POST_TIMEOUT` (5 seconds). Call them once,
  when joining, not every frame. After the handshake the socket is
  non-blocking.
- In the browser both run in the background. Poll the `WsPost` with
  `post-poll.sh`. The `WsClient`'s `state` goes from 0 to 1 on the first
  `read.sh` after it opens.
- `read.sh` and `send.sh` never wait. Drain messages with a loop driven by a
  flag, until `Text` is `None`:

```sh
    let mut reading = true;
    while reading {
        ` ${ORC_WS}/snippets/read.sh ${v}net_ `
        reading = ${v}net_Text.is_some();
        ...
    }
```

`state` 2 means closed, and `close_reason` says why: a failed connect, the
server's close reason, or a lost connection. Messages that arrived before a
close are delivered first.

## Calling a snippet

As in orc's other libraries, each snippet takes a namespace (`|ns_|`) and
binds its inputs and outputs with `nsmap/bind`. The header comment at the top
of each snippet lists them. Export a name to map it to one of your variables.

```sh
export ${v}net_Url=ws_url
export ${v}net_Ws=ws
...
    ` ${ORC_WS}/snippets/connect.sh ${v}net_ `
```

Settings:

| Variable | Default | Used by |
|---|---|---|
| `WS_CLIENT_TYPE` | `WsClient` | `models.sh`, `connect.sh` |
| `WS_POST_TYPE` | `WsPost` | `models.sh`, `post.sh` |
| `WS_CONNECT_TIMEOUT` | `std::time::Duration::from_secs(5)` | `connect.sh` |
| `WS_POST_TIMEOUT` | `std::time::Duration::from_secs(5)` | `post.sh` |

## Not handled yet

TLS (`wss://` and `https://`) on desktop, binary messages, proxies, and more
than one websocket at a time in the browser.
