#!/bin/bash

: "${S3_FILE_NS:=com.koreyhinton.s3.classes}"
: "${S3_FILE_CLASS:=S3File}"
cat << EOF

    package ${S3_FILE_NS}

    data class ${S3_FILE_CLASS} (
        var bucket: String,
        var name: String
    )

EOF
