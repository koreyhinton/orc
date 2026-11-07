#!/bin/bash

# ws write-json
#
#   command arg:  |ns_|
#   input:        |ns_|Ws        *WsConn (from upgrade)
#                 |ns_|Msg       any value encoding/json can marshal
#   output:       |ns_|WriteErr  error (declared by the caller, set here)
#   settings:     WS_WRITE_TIMEOUT  default 5 * time.Second
#   imports:      encoding/binary, encoding/json, time

: "${WS_WRITE_TIMEOUT:=5 * time.Second}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Ws Msg WriteErr

cat << EOF
	// Write msg as JSON in one websocket text frame. Frames from a server
	// aren't masked.
	${v}${priv}Payload, _ := json.Marshal(${!msg})
	${v}${priv}Frame := []byte{0x81} // FIN bit and the text opcode
	${v}${priv}N := len(${v}${priv}Payload)
	${v}${priv}Small := ${v}${priv}N < 126
	${v}${priv}Medium := ${v}${priv}N >= 126 && ${v}${priv}N <= 0xffff
	${v}${priv}Large := ${v}${priv}N > 0xffff
	if ${v}${priv}Small {
		${v}${priv}Frame = append(${v}${priv}Frame, byte(${v}${priv}N))
	}
	if ${v}${priv}Medium {
		${v}${priv}Frame = append(${v}${priv}Frame, 126)
		${v}${priv}Frame = binary.BigEndian.AppendUint16(${v}${priv}Frame, uint16(${v}${priv}N))
	}
	if ${v}${priv}Large {
		${v}${priv}Frame = append(${v}${priv}Frame, 127)
		${v}${priv}Frame = binary.BigEndian.AppendUint64(${v}${priv}Frame, uint64(${v}${priv}N))
	}
	${v}${priv}Frame = append(${v}${priv}Frame, ${v}${priv}Payload...)
	${!ws}.Conn.SetWriteDeadline(time.Now().Add(${WS_WRITE_TIMEOUT}))
	_, ${!write_err} = ${!ws}.Conn.Write(${v}${priv}Frame)
EOF
