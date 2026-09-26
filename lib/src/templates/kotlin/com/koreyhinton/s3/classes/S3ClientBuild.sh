#!/bin/bash

: "${S3_CLIENT_CLASS_FULL:=software.amazon.awssdk.services.s3.S3Client}"
: "${S3_CLIENT_BUILD_NS:=com.koreyhinton.s3.classes}"
: "${S3_CLIENT_BUILD_CLASS:=S3ClientBuild}"
cat << EOF

    package ${S3_CLIENT_BUILD_NS}

    data class ${S3_CLIENT_BUILD_CLASS} (
        // listed in low to high null ordering (highest gets nulled out first):
        var awsRegion: String?, // immediately set to null on client init
        var awsUrl: String?, // immediately set to null on client init
        var awsAccessKeyId: String?, // immediately set to null on client init
        var awsSecretAccessKey: String? // immediately null on client init
    ) {
        companion object {
            var client: ${S3_CLIENT_CLASS_FULL}? = null/*
                initialized by ./../snippets/build-client.sh
            */
        }
    }

EOF
