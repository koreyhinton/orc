#!/bin/bash

# ws upgrade
#
#   command arg:  |ns_|
#   input:        |ns_|Conn      net.Conn
#                 |ns_|Reader    *bufio.Reader (from read-request)
#                 |ns_|Req       *http.Request (not nil)
#   output:       |ns_|Upgraded  bool (declared by the caller, set here)
#                 |ns_|Ws        *WsConn (declared, nil unless upgraded)
#   settings:     WS_CONN_TYPE  default WsConn (see models.sh)
#   imports:      crypto/sha1, encoding/base64, fmt, strings, time
#
#   Call it only once the app has accepted the request. If it isn't a
#   websocket handshake, Upgraded is false and nothing has been written, so
#   the caller can still send an HTTP error reply.

: "${WS_CONN_TYPE:=WsConn}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Conn Reader Req Upgraded Ws

cat << EOF
	// Finish the websocket handshake (RFC 6455, section 4.2.2): reply
	// 101 Switching Protocols with the accept key, and clear the handshake
	// deadline. From here on the connection carries websocket frames, and Ws
	// pairs it with the reader its frames must be read through.
	${v}${priv}Key := ${!req}.Header.Get("Sec-WebSocket-Key")
	${!upgraded} = strings.EqualFold(${!req}.Header.Get("Upgrade"), "websocket") && ${v}${priv}Key != ""
	var ${!ws} *${WS_CONN_TYPE}
	if ${!upgraded} {
		${v}${priv}Sum := sha1.Sum([]byte(${v}${priv}Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
		${v}${priv}Accept := base64.StdEncoding.EncodeToString(${v}${priv}Sum[:])
		fmt.Fprintf(${!conn}, "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: %s\r\n\r\n", ${v}${priv}Accept)
		${!conn}.SetDeadline(time.Time{})
		${!ws} = &${WS_CONN_TYPE}{Conn: ${!conn}, Reader: ${!reader}}
	}
EOF
