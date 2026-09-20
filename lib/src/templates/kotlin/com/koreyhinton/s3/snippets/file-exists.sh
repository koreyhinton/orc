#!/bin/bash

: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_CONFIRMED_FILE_CLASS_NS:=com.koreyhinton.s3.classes.S3ConfirmedFile}"
: "${S3_HOR:=software.amazon.awssdk.services.s3.model.HeadObjectRequest}"
: "${S3_ERR_LOG:=println}"
v=${1}
# maps
. ${NSMAP}/bind ${v} S3ClientBuild S3File S3ConfirmedFile

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 file-exists                                                  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |package.|S3ClientBuild: ../classes/S3ClientBuild.sh    *
     *            |ns_|S3File: ../classes/S3File.sh                       *
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
     *        todo: need to re-test with:                                 *
     *            (or go back to commit 9f717d99 to avoid breaking change)*
     *            implementation(                                         *
     *                platform("software.amazon.awssdk:bom:2.25.0"))      *
     *            implementation("software.amazon.awssdk:s3")             *
     *            implementation("software.amazon.awssdk:apache-client")  *
     *                                                                    *
     **********************************************************************/

    var ${!s3_confirmed_file} = ${S3_CONFIRMED_FILE_CLASS_NS}(
        bucket = ${!s3_file}.bucket,
        name = ${!s3_file}.name,
        exists = false,
        bytes = 0
    )
    try {
        val ${v}Request = ${S3_HOR}.builder()
            .bucket(${!s3_file}.bucket)
            .key(${!s3_file}.name)
            .build()
        var ${v}Response = ${S3_CLIENT_BUILD_CLASS_FULL}.client!!.headObject(${v}Request)
        ${!s3_confirmed_file}.exists = true
        ${!s3_confirmed_file}.bytes = ${v}Response.contentLength()
    } catch(${v}Exception: Exception) {
        ${S3_ERR_LOG}("Warning: " + ${v}Exception.javaClass.simpleName  +
            " exception. Attempted to retrieve s3 file info " + ${!s3_file}.name +
            " and failed with exception: " + ${v}Exception.message)
    } catch (${v}${priv}E: Throwable) {
        ${S3_ERR_LOG}("s3 client failed to retrieve s3 file info, error: " + ${v}${priv}E + "\n" +
            ${v}${priv}E.stackTraceToString())
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 file-exists                                               *
     *                                                                    *
     **********************************************************************/

EOF
