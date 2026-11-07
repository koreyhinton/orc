#!/bin/bash

# ws read-frame
#
#   command arg:  |ns_|
#   input:        |ns_|Ws       *WsConn (from upgrade)
#   input/output: |ns_|Data     []byte, the message so far (declared by the caller)
#                 |ns_|ReadErr  error (declared by the caller)
#   output:       |ns_|Framing  bool, true while the message needs more frames
#   settings:     WS_MAX_MESSAGE  default 1 << 20 (bytes)
#   imports:      encoding/binary, errors, io
#
#   Call it in a loop to read one message:
#       for framing := true; framing; { read-frame }

: "${WS_MAX_MESSAGE:=1 << 20}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Ws Data ReadErr Framing

cat << EOF
	// Read one websocket frame (RFC 6455, section 5). A message can be split
	// over several frames. Control frames in between are skipped, except a
	// close frame, which counts as a disconnect.
	//
	// Header: the FIN bit and opcode, then the mask bit and a 7-bit length.
	var ${v}${priv}Head [2]byte
	_, ${!read_err} = io.ReadFull(${!ws}.Reader, ${v}${priv}Head[:])
	${v}${priv}Fin := ${v}${priv}Head[0]&0x80 != 0
	${v}${priv}Opcode := ${v}${priv}Head[0] & 0x0f
	${v}${priv}Masked := ${v}${priv}Head[1]&0x80 != 0
	${v}${priv}LenCode := ${v}${priv}Head[1] & 0x7f
	${v}${priv}Size := uint64(${v}${priv}LenCode)

	// A length code of 126 or 127 means the length follows, in 2 or 8 bytes.
	var ${v}${priv}Ext [8]byte
	${v}${priv}Has16 := ${!read_err} == nil && ${v}${priv}LenCode == 126
	if ${v}${priv}Has16 {
		_, ${!read_err} = io.ReadFull(${!ws}.Reader, ${v}${priv}Ext[:2])
		${v}${priv}Size = uint64(binary.BigEndian.Uint16(${v}${priv}Ext[:2]))
	}
	${v}${priv}Has64 := ${!read_err} == nil && ${v}${priv}LenCode == 127
	if ${v}${priv}Has64 {
		_, ${!read_err} = io.ReadFull(${!ws}.Reader, ${v}${priv}Ext[:])
		${v}${priv}Size = binary.BigEndian.Uint64(${v}${priv}Ext[:])
	}

	// Refuse a message over the size limit before allocating for it, so a bad
	// client can't make the server allocate without limit.
	${v}${priv}TooBig := ${!read_err} == nil && ${v}${priv}Size > uint64(${WS_MAX_MESSAGE})-uint64(len(${!data}))
	if ${v}${priv}TooBig {
		${!read_err} = errors.New("message too large")
	}

	// Client frames are masked with a 4-byte key.
	var ${v}${priv}Mask [4]byte
	${v}${priv}HasMask := ${!read_err} == nil && ${v}${priv}Masked
	if ${v}${priv}HasMask {
		_, ${!read_err} = io.ReadFull(${!ws}.Reader, ${v}${priv}Mask[:])
	}
	var ${v}${priv}Payload []byte
	if ${!read_err} == nil {
		${v}${priv}Payload = make([]byte, ${v}${priv}Size)
		_, ${!read_err} = io.ReadFull(${!ws}.Reader, ${v}${priv}Payload)
	}
	for i := 0; ${v}${priv}Masked && i < len(${v}${priv}Payload); i++ {
		${v}${priv}Payload[i] ^= ${v}${priv}Mask[i%4]
	}

	// Opcodes: 0 continues a message, 1 is text, 2 is binary, 8 is close,
	// 9 and 10 are ping and pong.
	${v}${priv}IsClose := ${!read_err} == nil && ${v}${priv}Opcode == 0x8
	if ${v}${priv}IsClose {
		${!read_err} = io.EOF
	}
	${v}${priv}IsData := ${!read_err} == nil && ${v}${priv}Opcode <= 0x2
	if ${v}${priv}IsData {
		${!data} = append(${!data}, ${v}${priv}Payload...)
	}
	${!framing} = ${!read_err} == nil && !(${v}${priv}IsData && ${v}${priv}Fin)
EOF
