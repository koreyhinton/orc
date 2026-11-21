#!/bin/bash

# ws read
#
#   command arg:  |ns_|
#   input/output: |ns_|Ws    WsClient (from connect)
#   output:       |ns_|Text  Option<String> (declared here): one text message,
#                            or None when none is waiting
#
#   Reads at most one message and never waits for one. Call it in a loop
#   driven by a flag until Text is None to drain everything that arrived.
#   Also sends any data send.sh couldn't write yet. When the connection
#   closes, Ws's state becomes 2 and close_reason says why; messages that
#   arrived before the close are still delivered first.

v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Ws Text

cat << EOF

    let mut ${!text}: Option<String> = None;
    #[cfg(not(target_arch = "wasm32"))]
    {
        let mut closed: Option<String> = None;
        if let Some(socket) = ${!ws}.socket.as_mut() {
            // send what an earlier send couldn't write without blocking
            match socket.flush() {
                Err(tungstenite::Error::Io(e)) if e.kind() == std::io::ErrorKind::WouldBlock => {}
                Err(e) => closed = Some(format!("send failed: {e}")),
                Ok(()) => {}
            }
            match socket.read() {
                Ok(tungstenite::Message::Text(t)) => ${!text} = Some(t.to_string()),
                Ok(tungstenite::Message::Close(frame)) => {
                    let reason = frame.map(|f| f.reason.to_string()).unwrap_or_default();
                    closed = Some(if reason.is_empty() {
                        "server closed the connection".to_string()
                    } else {
                        reason
                    });
                }
                Ok(_) => {} // binary, ping and pong (tungstenite answers pings)
                Err(tungstenite::Error::Io(e))
                    if matches!(e.kind(), std::io::ErrorKind::WouldBlock | std::io::ErrorKind::TimedOut) => {}
                Err(e) => {
                    if closed.is_none() {
                        closed = Some(format!("connection lost: {e}"));
                    }
                }
            }
        }
        if let Some(reason) = closed {
            ${!ws}.socket = None;
            ${!ws}.state = 2;
            ${!ws}.close_reason = reason;
        }
    }
    #[cfg(target_arch = "wasm32")]
    {
        let state = unsafe { orc_ws_state() };
        let msg = unsafe { orc_ws_try_recv() };
        let has_msg = !msg.is_nil() && !msg.is_undefined();
        if has_msg {
            let mut text = String::new();
            msg.to_string(&mut text);
            ${!text} = Some(text);
        }
        if ${!ws}.state != 2 && state == 1 {
            ${!ws}.state = 1;
        }
        // report the close only once every message before it is delivered
        if ${!ws}.state != 2 && state == 2 && !has_msg {
            let mut reason = String::new();
            unsafe { orc_ws_close_reason() }.to_string(&mut reason);
            ${!ws}.state = 2;
            ${!ws}.close_reason = reason;
        }
    }

EOF
