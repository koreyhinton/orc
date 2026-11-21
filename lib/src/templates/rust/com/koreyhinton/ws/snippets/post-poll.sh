#!/bin/bash

# ws post-poll
#
#   command arg:  |ns_|
#   input/output: |ns_|Post  WsPost (from post): sets done, and body once done
#
#   Never waits. Desktop posts are already done, so this does nothing there.

v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Post

cat << EOF

    #[cfg(target_arch = "wasm32")]
    if !${!post}.done {
        let status = unsafe { orc_ws_http_status(${!post}.id) };
        if status != 0 {
            let mut body = String::new();
            unsafe { orc_ws_http_body(${!post}.id) }.to_string(&mut body);
            ${!post}.body = if status == 1 { Ok(body) } else { Err(body) };
            ${!post}.done = true;
        }
    }

EOF
