#!/bin/bash

: "${DCIM_FILE_NS:=com.koreyhinton.dcim.classes}"
: "${DCIM_FILE_CLASS:=DcimFile}"
cat << EOF

    package ${DCIM_FILE_NS}

    data class ${DCIM_FILE_CLASS} (
        var name: String
    )

EOF
