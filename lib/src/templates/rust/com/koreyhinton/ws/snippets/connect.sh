#!/bin/bash

# ws connect
#
#   command arg:  |ns_|
#   input:        |ns_|Url  String or &str, http:// or ws:// (becomes ws://)
#   output:       |ns_|Ws   WsClient (declared here). state 1 once open, 2
#                           if it failed (close_reason says why)
#   settings:     WS_CLIENT_TYPE      default WsClient
#                 WS_CONNECT_TIMEOUT  default std::time::Duration::from_secs(5)
#
#   Desktop connects and does the websocket handshake before going on (up to
#   the timeout), then makes the socket non-blocking so read.sh never waits.
#   The browser opens the socket in the background: state stays 0 until the
#   first read.sh after it opens. Plain ws:// only on desktop (no TLS).

: "${WS_CLIENT_TYPE:=WsClient}"
: "${WS_CONNECT_TIMEOUT:=std::time::Duration::from_secs(5)}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Url Ws

cat << EOF

    // websocket URL: http://host -> ws://host, https:// -> wss://
    let ${v}${priv}Url: String = {
        let url: &str = ${!url}.as_ref();
        if let Some(rest) = url.strip_prefix("https://") {
            format!("wss://{rest}")
        } else if let Some(rest) = url.strip_prefix("http://") {
            format!("ws://{rest}")
        } else {
            url.to_string()
        }
    };
    let mut ${!ws} = ${WS_CLIENT_TYPE} {
        #[cfg(not(target_arch = "wasm32"))]
        socket: None,
        state: 0,
        close_reason: String::new(),
    };
    #[cfg(not(target_arch = "wasm32"))]
    {
        // ws://host:port/path -> host:port, to open the TCP connection
        let host = ${v}${priv}Url
            .strip_prefix("ws://")
            .unwrap_or("")
            .split('/')
            .next()
            .unwrap_or("")
            .to_string();
        let addr = std::net::ToSocketAddrs::to_socket_addrs(host.as_str())
            .ok()
            .and_then(|mut addrs| addrs.next());
        match addr {
            None => {
                ${!ws}.state = 2;
                ${!ws}.close_reason = format!("can't connect to {}: only ws:// with host:port is supported", ${v}${priv}Url);
            }
            Some(addr) => match std::net::TcpStream::connect_timeout(&addr, ${WS_CONNECT_TIMEOUT}) {
                Err(e) => {
                    ${!ws}.state = 2;
                    ${!ws}.close_reason = format!("connect to {host}: {e}");
                }
                Ok(stream) => {
                    let _ = stream.set_read_timeout(Some(${WS_CONNECT_TIMEOUT}));
                    let _ = stream.set_nodelay(true);
                    match tungstenite::client(${v}${priv}Url.as_str(), stream) {
                        Err(e) => {
                            ${!ws}.state = 2;
                            ${!ws}.close_reason = format!("websocket handshake failed: {e}");
                        }
                        Ok((socket, _)) => {
                            // from here on, reads and writes never block the game loop
                            let _ = socket.get_ref().set_nonblocking(true);
                            ${!ws}.socket = Some(socket);
                            ${!ws}.state = 1;
                        }
                    }
                }
            },
        }
    }
    #[cfg(target_arch = "wasm32")]
    unsafe {
        orc_ws_connect(sapp_jsutils::JsObject::string(${v}${priv}Url.as_str()));
    }

EOF
