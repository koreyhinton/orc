#!/bin/bash

: "${S3_CONFIRMED_FILE_CLASS_NS:=com.koreyhinton.s3.classes.S3ConfirmedFile}"
: "${S3_HOR:=software.amazon.awssdk.services.s3.model.HeadObjectRequest}"
: "${S3_CLIENT:=software.amazon.awssdk.services.s3.S3Client}"
: "${S3_REG:=software.amazon.awssdk.regions.Region}"
: "${S3_CRED:=software.amazon.awssdk.auth.credentials.AwsBasicCredentials}"
: "${S3_CRED_PROV:=software.amazon.awssdk.auth.credentials.StaticCredentialsProvider}"
: "${S3_URI:=java.net.URI}"
v=${1}
# maps
s3_file=${v}S3File # input
s3_confirmed_file=${v}S3ConfirmedFile # output

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 file-exists                                                  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|S3File (S3File, indirect)                          *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3ConfirmedFile (S3ConfirmedFile, indirect)        *
     *                                                                    *
     *        tested with:                                                *
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
        val ${v}S3Client = ${S3_CLIENT}.builder()
            .region(${S3_REG}.of(System.getProperty("AWS_REGION")))
            .credentialsProvider(
                ${S3_CRED_PROV}.create(
                    ${S3_CRED}.create(
                        System.getProperty("AWS_ACCESS_KEY_ID"),
                        System.getProperty("AWS_SECRET_ACCESS_KEY")
                    )
                )
            )
            .endpointOverride(${S3_URI}.create(System.getProperty("AWS_URL")))
            .build()
        val ${v}Request = ${S3_HOR}.builder()
            .bucket(${!s3_file}.bucket)
            .key(${!s3_file}.name)
            .build()
        var ${v}Response = ${v}S3Client.headObject(${v}Request)
        ${!s3_confirmed_file}.exists = true
        ${!s3_confirmed_file}.bytes = ${v}Response.contentLength()
    } catch(e: Exception) {
        println("Warning: " + e.javaClass.simpleName  +
            " exception. Attempted to retrieve s3 file " + ${!s3_file}.name +
            " and failed with exception: " + e.message)
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 file-exists                                               *
     *                                                                    *
     **********************************************************************/

EOF
