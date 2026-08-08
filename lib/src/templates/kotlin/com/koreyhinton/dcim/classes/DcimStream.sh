#!/bin/bash

: "${DCIM_STREAM_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_STREAM_CLASS:=DcimStream}"
cat << EOF

    package ${DCIM_STREAM_NS}

    data class ${DCIM_STREAM_CLASS} (
        var index: Int,
        var encodingLc: String, // "hevc", "aac"
        var typeLc: Char, // 'a' (audio), 'v' (video), 'd' (data), 'u' (unknown)
    )

EOF
