#!/bin/bash

echo package com.koreyhinton.s3.integration

# mocks
. ${ORC_MOCK}/file-exists-mock.sh
. ${ORC_MOCK}/presign-url-mock.sh

# maps
. ${NSMAP}/symbolize ${v} S3File S3ConfirmedFile S3SignedFile

v=${1:-test_}
cat << EOF
    fun main(args: Array<String>) {
        var testName = "S3 Integration Test: File Exists And Presign Url"
        var pass = true

        try {
            var ${v}S3File = S3File(
                bucket = "a",
                name = "b"
            )
            ` ${ORC_S3}/snippets/file-exists.sh ${v} `
            ` ${ORC_S3}/snippets/presign-url.sh ${v} `
            pass = ${v}S3SignedFile.url == "foo://bar"
        }
        catch (e: Exception) {
            pass = false
        }

        if (pass)
            println(testName + "...PASS")
        else
            println(testName + "...FAIL")
    }
EOF
