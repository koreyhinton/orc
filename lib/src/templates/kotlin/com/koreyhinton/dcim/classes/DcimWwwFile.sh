#!/bin/bash

: "${DCIM_WWW_FILE_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_SRC_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_WWW_FILE_CLASS:=DcimWwwFile}"
: "${DCIM_SRC_IFACE:=DcimSource}"

cat << EOF

    package ${DCIM_WWW_FILE_NS}

    data class ${DCIM_WWW_FILE_CLASS} (
        var url: String
    ): ${DCIM_SRC_NS}.${DCIM_SRC_IFACE}

EOF
