#!/bin/bash

: "${S3_SIGNED_FILE_CLASS_NS:=com.koreyhinton.s3.classes.S3SignedFile}"
: "${S3_REG:=software.amazon.awssdk.regions.Region}"
: "${S3_CRED:=software.amazon.awssdk.auth.credentials.AwsBasicCredentials}"
: "${S3_CRED_PROV:=software.amazon.awssdk.auth.credentials.StaticCredentialsProvider}"
: "${S3_GOR:=software.amazon.awssdk.services.s3.model.GetObjectRequest}"
: "${S3_PSIGNER:=software.amazon.awssdk.services.s3.presigner.S3Presigner}"
: "${S3_URI:=java.net.URI}"
: "${S3_DURA:=java.time.Duration}"
: "${S3_GOPR:=software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest}"
: "${S3_ERR_LOG:=println}"
: "${S3_SECRET_ENV_VAR:=System.getProperty}"
v=${1}
# maps
s3_file=${v}S3File
s3_signed_file=${v}S3SignedFile

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 presign-url                                                  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|S3File (S3File, indirect)                          *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|S3SignedFile (S3SignedFile, indirect)              *
     *                                                                    *
     *        tested with:                                                *
     *            implementation(                                         *
     *                platform("software.amazon.awssdk:bom:2.25.0"))      *
     *            implementation("software.amazon.awssdk:s3")             *
     *            implementation("software.amazon.awssdk:apache-client")  *
     *                                                                    *
     **********************************************************************/

    var ${!s3_signed_file} = ${S3_SIGNED_FILE_CLASS_NS} (
        bucket = ${!s3_file}.bucket,
        name = ${!s3_file}.name,
        url = ""
    )
    try {
        val ${v}PSigner = ${S3_PSIGNER}.builder()
            .region(${S3_REG}.of(${S3_SECRET_ENV_VAR}("AWS_REGION")))
            .credentialsProvider(
                ${S3_CRED_PROV}.create(
                    ${S3_CRED}.create(
                        ${S3_SECRET_ENV_VAR}("AWS_ACCESS_KEY_ID"),
                        ${S3_SECRET_ENV_VAR}("AWS_SECRET_ACCESS_KEY")
                    )
                )
            )
            .endpointOverride(${S3_URI}.create(${S3_SECRET_ENV_VAR}("AWS_URL")))
            .build()

        val ${v}Request = ${S3_GOR}.builder()
            .bucket(${!s3_file}.bucket)
            .key(${!s3_file}.name)
            .build()
        val ${v}PresignedRequest: ${S3_GOPR} =
            ${S3_GOPR}.builder()
            .signatureDuration(${S3_DURA}.ofSeconds(1000))
            .getObjectRequest(${v}Request)
            .build()
        ${!s3_signed_file}.url = ${v}PSigner.presignGetObject(${v}PresignedRequest).url().toString()
    } catch(${v}Exception: Exception) {
        ${S3_ERR_LOG}("Warning: " + ${v}Exception.javaClass.simpleName  +
            " exception. Attempted to retrieve s3 file " + ${!s3_file}.name +
            " and failed with exception: " + ${v}Exception.message)
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 presign-url                                               *
     *                                                                    *
     **********************************************************************/

EOF
