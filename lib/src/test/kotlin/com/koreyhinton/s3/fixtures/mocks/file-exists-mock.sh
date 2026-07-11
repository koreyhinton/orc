#!/bin/bash

export S3_CONFIRMED_FILE_CLASS_NS=com.koreyhinton.s3.fixtures.models.S3ConfirmedFile
export S3_HOR:=com.koreyhinton.s3.integration.S3_HOR

if [[ -z "$S3_CLIENT" ]]; then
    export S3_CLIENT=com.koreyhinton.s3.integration.S3_CLIENT
    cat << EOF
        class S3_CLIENT private constructor() {
            fun builder() {
                return S3_CLIENT()
            }
            fun region() {
                return S3_CLIENT()
            }
            fun credentialsProvider() {
                return S3_CLIENT()
            }
            fun endpointOverride(s3uri: S3_URI) {
                return S3_CLIENT()
            }
        }
EOF
fi

if [[ -z "$S3_REG" ]]; then
    export S3_REG=com.koreyhinton.s3.integration.S3_REG
    cat << EOF
        class S3_REG private constructor() {
            fun of(s1: String) {
                return S3_REG()
            }
        }
EOF
fi

if [[ -z "$S3_CRED" ]]; then
    export S3_CRED=com.koreyhinton.s3.integration.S3_CRED
    cat << EOF
        class S3_CRED private constructor() {
            fun create(s1: String, s2: String) {
                return S3_CRED()
            }
        }
EOF
fi

if [[ -z "$S3_CRED_PROV" ]]; then
    export S3_CRED_PROV=com.koreyhinton.s3.integration.S3_CRED_PROV
    cat << EOF
        class S3_CRED_PROV private constructor() {
            fun create(cred: S3_CRED) {
                return S3_CRED_PROV()
            }
        }
EOF
fi
