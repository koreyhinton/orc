#!/bin/bash

: "${DCIM_FILE_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_SRC_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_FILE_CLASS:=DcimFile}"
: "${DCIM_SRC_IFACE:=DcimSource}"
cat << EOF

    package ${DCIM_FILE_NS}

    data class ${DCIM_FILE_CLASS} (
        var name: String
    ): ${DCIM_SRC_NS}.${DCIM_SRC_IFACE}

EOF
