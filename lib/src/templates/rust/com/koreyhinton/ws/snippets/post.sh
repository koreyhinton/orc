#!/bin/bash

# ws post
#
#   command arg:  |ns_|
#   input:        |ns_|Url   String or &str, http:// (desktop: http only)
#   output:       |ns_|Post  WsPost (declared here). Poll it with post-poll.sh
#                            until done; body is the reply's body, or an error
#                            for a failure or a status other than 200.
#   settings:     WS_POST_TYPE     default WsPost
#                 WS_POST_TIMEOUT  default std::time::Duration::from_secs(5)
#
#   An HTTP/1.1 POST with an empty body (such as a lockstep server's
#   /match). Desktop sends it and reads the reply before going on, up to the
#   timeout, so post once (when joining), not every frame. The browser sends
#   it in the background.

: "${WS_POST_TYPE:=WsPost}"
: "${WS_POST_TIMEOUT:=std::time::Duration::from_secs(5)}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Url Post

cat << EOF

    let mut ${!post} = ${WS_POST_TYPE} {
        id: -1,
        done: false,
        body: Err(String::new()),
    };
    #[cfg(not(target_arch = "wasm32"))]
    {
        let url: &str = ${!url}.as_ref();
        let rest = url.strip_prefix("http://").unwrap_or("");
        let (host, path) = match rest.find('/') {
            Some(i) => (&rest[..i], &rest[i..]),
            None => (rest, "/"),
        };
        let addr = std::net::ToSocketAddrs::to_socket_addrs(host)
            .ok()
            .and_then(|mut addrs| addrs.next());
        let reply: Result<String, String> = match addr {
            None => Err(format!("can't post to {url}: only http:// with host:port is supported")),
            Some(addr) => match std::net::TcpStream::connect_timeout(&addr, ${WS_POST_TIMEOUT}) {
                Err(e) => Err(format!("connect to {host}: {e}")),
                Ok(mut stream) => {
                    let _ = stream.set_read_timeout(Some(${WS_POST_TIMEOUT}));
                    let _ = stream.set_write_timeout(Some(${WS_POST_TIMEOUT}));
                    let request = format!(
                        "POST {path} HTTP/1.1\r\nHost: {host}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                    );
                    let mut response = String::new();
                    match std::io::Write::write_all(&mut stream, request.as_bytes())
                        .and_then(|_| std::io::Read::read_to_string(&mut stream, &mut response))
                    {
                        Err(e) => Err(format!("post to {url}: {e}")),
                        Ok(_) => match response.split_once("\r\n\r\n") {
                            None => Err(format!("post to {url}: bad HTTP response")),
                            Some((head, body)) => {
                                let status = head.lines().next().unwrap_or("");
                                if status.split(' ').nth(1) == Some("200") {
                                    Ok(body.to_string())
                                } else {
                                    Err(format!("server replied {status}"))
                                }
                            }
                        },
                    }
                }
            },
        };
        ${!post}.body = reply;
        ${!post}.done = true;
    }
    #[cfg(target_arch = "wasm32")]
    {
        let url: &str = ${!url}.as_ref();
        ${!post}.id = unsafe { orc_ws_http_post(sapp_jsutils::JsObject::string(url)) };
    }

EOF
