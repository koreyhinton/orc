#!/bin/bash

: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_LIST_OBJ_V2_REQ_CLASS_FULL:=software.amazon.awssdk.services.s3.model.ListObjectsV2Request}"
: "${S3_ERR_LOG:=println}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} S3ClientBuild S3Bucket

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 list-files                                                   *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |package.|S3ClientBuild: ../classes/S3ClientBuild.sh    *
     *            |ns_|S3Bucket: String                                   *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3FilesCsv: String                                 *
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

    var ${v}S3FilesCsv = "";
    try {

        val ${v}${priv}Request = ${S3_LIST_OBJ_V2_REQ_CLASS_FULL}
            .builder()
            .bucket(${!s3_bucket})
            .build();

        ${S3_CLIENT_BUILD_CLASS_FULL}.client!!
            .listObjectsV2Paginator(${v}${priv}Request)
            .stream().forEach { ${v}${priv}Response ->
                ${v}${priv}Response.contents()?.forEach { ${v}${priv}Object ->
                    if (${v}S3FilesCsv.isEmpty()) {
                        ${v}S3FilesCsv = ${v}${priv}Object.key()
                    } else {
                        ${v}S3FilesCsv += "," + ${v}${priv}Object.key()
                    }
                }
            }

    } catch(${v}${priv}Exception: Exception) {
        ${S3_ERR_LOG}("Warning: " + ${v}${priv}Exception.javaClass.simpleName  +
            " exception. Attempted to list objects " +
            " and failed with exception: " + ${v}${priv}Exception.message + "\n" +
            ${v}${priv}Exception.stackTraceToString())
    } catch (${v}${priv}E: Throwable) {
        ${S3_ERR_LOG}("s3 client failed to list objects, error: " + ${v}${priv}E.message + "\n" +
            ${v}${priv}E.stackTraceToString())
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 list-files                                                *
     *                                                                    *
     **********************************************************************/

EOF
