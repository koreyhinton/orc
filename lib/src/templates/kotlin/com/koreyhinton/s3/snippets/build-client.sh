#!/bin/bash

: "${S3_CLIENT:=software.amazon.awssdk.services.s3.S3Client}"
: "${S3_CLIENT_BUILD_CLASS_FULL:=com.koreyhinton.s3.S3ClientBuild}"
: "${S3_URL_CONN:=software.amazon.awssdk.http.urlconnection}"
: "${S3_REG:=software.amazon.awssdk.regions.Region}"
: "${S3_CRED:=software.amazon.awssdk.auth.credentials.AwsBasicCredentials}"
: "${S3_CRED_PROV:=software.amazon.awssdk.auth.credentials.StaticCredentialsProvider}"
: "${S3_URI:=java.net.URI}"
: "${S3_ERR_LOG:=println}"

v=${1}
# maps
. ${NSMAP}/bind ${v} S3ClientBuild

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    s3 build-client                                                 *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input/output:                                               *
     *            |ns_|S3ClientBuild: S3ClientBuild                       *
     *                                                                    *
     *        tested with:                                                *
     *            implementation(                                         *
     *                platform("software.amazon.awssdk:bom:2.25.0"))      *
     *            implementation("software.amazon.awssdk:s3")             *
     *            implementation(                                         *
     *                "software.amazon.awssdk:url-connection-client")     *
     *                                                                    *
     **********************************************************************/

    try {
        ${S3_CLIENT_BUILD_CLASS_FULL}.client = ${S3_CLIENT}.builder()
            .region(${S3_REG}.of(${!s3_client_build}.awsRegion))
            .credentialsProvider(
                ${S3_CRED_PROV}.create(
                    ${S3_CRED}.create(
                        ${!s3_client_build}.awsAccessKeyId,
                        ${!s3_client_build}.awsSecretAccessKey
                    )
                )
            )
            .endpointOverride(${S3_URI}.create(${!s3_client_build}.awsUrl))
            .httpClientBuilder(${S3_URL_CONN}.UrlConnectionHttpClient.builder())
            .build()
        ${!s3_client_build}.awsSecretAccessKey = null;
        ${!s3_client_build}.awsAccessKeyId = null;
        ${!s3_client_build}.awsUrl = null;
        ${!s3_client_build}.awsRegion = null;
        // ^listed in high to low null ordering (highest gets nulled out first)
    } catch(${v}${priv}Exception: Exception) {
        ${!s3_client_build}.awsSecretAccessKey = null;
        ${!s3_client_build}.awsAccessKeyId = null;
        ${!s3_client_build}.awsUrl = null;
        ${!s3_client_build}.awsRegion = null;
        // ^listed in high to low null ordering (highest gets nulled out first)

        ${S3_ERR_LOG}("Warning: " + ${v}${priv}Exception.javaClass.simpleName  +
            " exception. Attempted to build s3 client " +
            " and failed with exception: " + ${v}${priv}Exception.message + "\n" +
            ${v}${priv}Exception.stackTraceToString())
    } catch (${v}${priv}E: Throwable) {
        ${S3_ERR_LOG}("s3 client faild to create, error: " + ${v}${priv}E + "\n" +
            ${v}${priv}E.stackTraceToString())
    }

    /**********************************************************************
     *                                                                    *
     * :END: s3 build-client                                              *
     *                                                                    *
     **********************************************************************/

EOF
