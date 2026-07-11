#!/bin/bash

: "${DCIM_DVC_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_DVC_CLASS:=DcimDevice}"
cat << EOF

    package ${DCIM_DVC_NS}

    data class ${DCIM_DVC_CLASS} (
        var make: String,
        var model: String
    )

EOF
