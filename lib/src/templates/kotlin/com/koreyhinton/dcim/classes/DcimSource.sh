#!/bin/bash

: "${DCIM_SRC_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_SRC_IFACE:=DcimSource}"
cat << EOF

    package ${DCIM_SRC_NS}

    interface ${DCIM_SRC_IFACE}

EOF
