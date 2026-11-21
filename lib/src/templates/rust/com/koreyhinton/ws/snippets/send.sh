#!/bin/bash

# ws send
#
#   command arg:  |ns_|
#   input/output: |ns_|Ws    WsClient (from connect)
#   input:        |ns_|Text  &str or String, sent as one text message
#
#   Never waits. On desktop, data that can't be written yet is kept and sent
#   by the next send.sh or read.sh. Does nothing unless Ws is open; a failure
#   closes Ws (state 2, close_reason says why).

v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Ws Text

cat << EOF

    #[cfg(not(target_arch = "wasm32"))]
    {
        let mut failed: Option<String> = None;
        if let Some(socket) = ${!ws}.socket.as_mut() {
            let text: &str = ${!text}.as_ref();
            match socket.send(tungstenite::Message::text(text)) {
                // queued: read.sh flushes it
                Err(tungstenite::Error::Io(e)) if e.kind() == std::io::ErrorKind::WouldBlock => {}
                Err(e) => failed = Some(format!("send failed: {e}")),
                Ok(()) => {}
            }
        }
        if let Some(reason) = failed {
            ${!ws}.socket = None;
            ${!ws}.state = 2;
            ${!ws}.close_reason = reason;
        }
    }
    #[cfg(target_arch = "wasm32")]
    if ${!ws}.state == 1 {
        let text: &str = ${!text}.as_ref();
        unsafe { orc_ws_send(sapp_jsutils::JsObject::string(text)) };
    }

EOF
