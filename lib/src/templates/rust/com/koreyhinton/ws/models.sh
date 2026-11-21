#!/bin/bash

# ws models
#
#   command arg:  <version>, the orc ws version the app expects
#   prints:       the types the ws snippets use, and the browser plugin's
#                 functions (js/orc_ws.js) for wasm32 builds
#   settings:     WS_CLIENT_TYPE  default WsClient
#                 WS_POST_TYPE    default WsPost
#
#   Call it between heredocs, not in backticks, so a version mismatch stops
#   the app's script:
#       ${ORC_WS}/models.sh 0.1.0 || exit 1
#
#   Rename a type when the app already has one by that name. Set the same
#   settings for the snippets, which use the names too.
#
#   Crates: tungstenite (desktop), sapp-jsutils (wasm32).

: "${WS_CLIENT_TYPE:=WsClient}"
: "${WS_POST_TYPE:=WsPost}"
. "$(dirname "${BASH_SOURCE[0]}")/version.sh" "${1}"

cat << EOF

    // A websocket client, polled once a frame (see orc ws snippets).
    // state: 0 connecting, 1 open, 2 closed (close_reason says why)
    struct ${WS_CLIENT_TYPE} {
        #[cfg(not(target_arch = "wasm32"))]
        socket: Option<tungstenite::WebSocket<std::net::TcpStream>>,
        state: u8,
        close_reason: String,
    }

    // An HTTP POST with an empty body. body is set once done is true.
    struct ${WS_POST_TYPE} {
        #[cfg_attr(not(target_arch = "wasm32"), allow(dead_code))] // the browser request id
        id: i32,
        done: bool,
        body: Result<String, String>,
    }

    // Implemented by the browser plugin, js/orc_ws.js.
    #[cfg(target_arch = "wasm32")]
    unsafe extern "C" {
        fn orc_ws_connect(url: sapp_jsutils::JsObject);
        fn orc_ws_send(text: sapp_jsutils::JsObject);
        fn orc_ws_try_recv() -> sapp_jsutils::JsObject;
        fn orc_ws_state() -> i32; // 0 connecting, 1 open, 2 closed
        fn orc_ws_close_reason() -> sapp_jsutils::JsObject;
        fn orc_ws_http_post(url: sapp_jsutils::JsObject) -> i32;
        fn orc_ws_http_status(id: i32) -> i32; // 0 pending, 1 ok, 2 failed
        fn orc_ws_http_body(id: i32) -> sapp_jsutils::JsObject;
        fn orc_ws_page_param(name: sapp_jsutils::JsObject) -> sapp_jsutils::JsObject;
        fn orc_ws_default_server() -> sapp_jsutils::JsObject;
    }

EOF
