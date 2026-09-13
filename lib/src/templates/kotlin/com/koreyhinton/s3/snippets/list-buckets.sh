#!/bin/bash

: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_ERR_LOG:=println}"
v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} S3ClientBuild

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 list-buckets                                                 *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|S3ClientBuild: S3ClientBuild                       *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3BucketCsv: String                                *
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

    var ${v}S3BucketCsv = "";
    try {
        val ${v}${priv}Response = ${S3_CLIENT_BUILD_CLASS_FULL}.client!!
            .listBuckets();
        ${v}${priv}Response.buckets().forEach { ${v}${priv}Bucket ->
            if (${v}S3BucketCsv.length == 0)
                ${v}S3BucketCsv = ${v}${priv}Bucket.name();
            else
                ${v}S3BucketCsv += "," + ${v}${priv}Bucket.name();
        }
    } catch(${v}${priv}Exception: Exception) {
        ${S3_ERR_LOG}("Warning: " + ${v}${priv}Exception.javaClass.simpleName  +
            " exception. Attempted to list buckets " +
            " and failed with exception: " + ${v}${priv}Exception.message + "\n" +
            ${v}${priv}Exception.stackTraceToString())
    } catch (${v}${priv}E: Throwable) {
        ${S3_ERR_LOG}("s3 client faild to list buckets, error: " + ${v}${priv}E.message + "\n" +
            ${v}${priv}E.stackTraceToString())
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 list-buckets                                              *
     *                                                                    *
     **********************************************************************/

EOF
