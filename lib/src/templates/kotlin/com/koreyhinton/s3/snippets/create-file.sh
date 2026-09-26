#!/bin/bash

: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_POR:=software.amazon.awssdk.services.s3.model.PutObjectRequest}"
: "${S3_REQ_BODY:=software.amazon.awssdk.core.sync.RequestBody}"
: "${S3_ERR_LOG:=println}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} S3ClientBuild S3File Text

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 create-file                                                  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |package.|S3ClientBuild: ../classes/S3ClientBuild.sh    *
     *            |ns_|S3File: ../classes/S3File.sh                       *
     *            |ns_|Text: String                                     *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3ConfirmedFile: ../classes/S3ConfirmedFile.sh     *
     *                                                                    *
     *        tested with:                                                *
     *             implementation(                                        *
     *                  "com.fasterxml.woodstox:woodstox-core:6.6.0")     *
     *            implementation("javax.xml.stream:stax-api:1.0-2")       *
     *            implementation(                                         *
     *                platform("software.amazon.awssdk:bom:2.25.0"))      *
     *            implementation("software.amazon.awssdk:s3")             *
     *            implementation(                                         *
     *                "software.amazon.awssdk:url-connection-client")     *
     *                                                                    *
     **********************************************************************/

    var ${v}S3ConfirmedFile = ${S3_CONFIRMED_FILE_CLASS_NS}(
        bucket = ${!s3_file}.bucket,
        name = ${!s3_file}.name,
        exists = false,
        bytes = 0
    )
    try { 
        val ${v}${priv}Request = ${S3_POR}.builder()
            .bucket(${!s3_file}.bucket)
            .key(${!s3_file}.name)
            .contentType("text/plain")
            .build()
        ${S3_CLIENT_BUILD_CLASS_FULL}.client!!.putObject(
            ${v}${priv}Request,
            ${S3_REQ_BODY}.fromString(${!text})
        )
        ${v}S3ConfirmedFile.exists = true
        ${v}S3ConfirmedFile.bytes = ${!text}
            .toByteArray(Charsets.UTF_8)
            .size
            .toLong()
    } catch(${v}Exception: Exception) {
        ${S3_ERR_LOG}("Warning: " + ${v}Exception.javaClass.simpleName  +
            " exception. Attempted to read s3 file text " + ${!s3_file}.name +
            " and failed with exception: " + ${v}Exception.message)
    } catch (${v}${priv}E: Throwable) {
        ${S3_ERR_LOG}("s3 client failed to read s3 file text, error: " + ${v}${priv}E + "\n" +
            ${v}${priv}E.stackTraceToString())
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 create-file                                               *
     *                                                                    *
     **********************************************************************/

EOF
