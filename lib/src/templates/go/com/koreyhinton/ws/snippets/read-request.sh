#!/bin/bash

# ws read-request
#
#   command arg:  |ns_|
#   input:        |ns_|Conn    net.Conn
#   output:       |ns_|Reader  *bufio.Reader (declared)
#                 |ns_|Req     *http.Request (declared, nil if the read failed)
#   settings:     WS_HANDSHAKE_TIMEOUT  default 5 * time.Second
#   imports:      bufio, net/http, time

: "${WS_HANDSHAKE_TIMEOUT:=5 * time.Second}"
v=${1}
# maps
. ${NSMAP}/bind ${v} Conn Reader Req

cat << EOF
	// Read the HTTP request, which may ask to open a websocket. The connection
	// gets a deadline to send it and read the reply, so a silent one can't hold
	// things up. Keep the buffered reader: if the connection becomes a
	// websocket, its frames must be read through it, since it may already
	// hold the first ones.
	${!conn}.SetDeadline(time.Now().Add(${WS_HANDSHAKE_TIMEOUT}))
	${!reader} := bufio.NewReader(${!conn})
	${!req}, _ := http.ReadRequest(${!reader})
EOF
