#!/bin/bash

: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_GOR:=software.amazon.awssdk.services.s3.model.GetObjectRequest}"
: "${S3_ERR_LOG:=println}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} S3ClientBuild S3File

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 file-text                                                    *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |package.|S3ClientBuild: ../classes/S3ClientBuild.sh    *
     *            |ns_|S3File: ../classes/S3File.sh                       *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3FileText: String?                                *
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

    var ${v}S3FileText: String? = null;
    try { 
        val ${v}${priv}Request = ${S3_GOR}.builder()
            .bucket(${!s3_file}.bucket)
            .key(${!s3_file}.name)
            .build()
        ${v}S3FileText = ${S3_CLIENT_BUILD_CLASS_FULL}.client!!
            .getObjectAsBytes(${v}${priv}Request).asUtf8String()
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
     * :END: s3 file-text                                                 *
     *                                                                    *
     **********************************************************************/

EOF
