#!/bin/bash

: "${DCIM_DVC_CLASS_NS:=com.koreyhinton.dcim.classes.DcimDevice}"
: "${DCIM_AUTO_DETECT_PARSER:=org.apache.tika.parser.AutoDetectParser}"
: "${DCIM_BODY_CONTENT_HANDLER:=org.apache.tika.sax.BodyContentHandler}"
: "${DCIM_PARSE_CONTEXT:=org.apache.tika.parser.ParseContext}"
: "${DCIM_METADATA:=org.apache.tika.metadata.Metadata}"
: "${DCIM_EXIF_TOOL_COMMAND:=exiftool}"
: "${DCIM_EXIF_TOOL_WAIT_SECS:=20}"
: "${DCIM_JIOF:=java.io.File}"
: "${DCIM_JIOFIS:=java.io.FileInputStream}"
: "${DCIM_TU:=java.util.concurrent.TimeUnit}"
: "${DCIM_VERBOSE:=true}"
: "${DCIM_VERBOSE_LOG:=println}"
: "${DCIM_ERR_LOG:=println}"

v=${1}
# maps
dcim_file=${v}DcimFile
dcim_device=${v}DcimDevice

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    dcim crt-dvc: DIGITAL CAMERA IMAGE CREATE DEVICE                *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|DcimFile (DcimFile, indirect)                      *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|DcimDevice (DcimDevice, indirect)                  *
     *                                                                    *
     *        tested with:                                                *
     *            implementation("org.apache.tika:tika-core:3.3.1")       *
     *            implementation(                                         *
     *              "org.apache.tika:tika-parsers-standard-package:3.3.1")*
     *            exiftool 12.40                                          *
     *                                                                    *
     **********************************************************************/
    val ${v}Parser = ${DCIM_AUTO_DETECT_PARSER}()
    val ${v}Metadata = ${DCIM_METADATA}()
    val ${v}Handler = ${DCIM_BODY_CONTENT_HANDLER}(-1) // -1 for unlimited content sz
    val ${v}Context = ${DCIM_PARSE_CONTEXT}()

    ${DCIM_JIOFIS}(${DCIM_JIOF}(${!dcim_file}.name)).use { ${v}Stream ->
        ${v}Parser.parse(${v}Stream, ${v}Handler, ${v}Metadata, ${v}Context)
    }

    val ${v}HandledList = listOf(
        "Exif IFD0:Make",
        "tiff:Make",
        "Make",
        "Exif IFD0:Model",
        "tiff:Model",
        "Canon Model ID",
        "Model"
    )
    val ${v}IgnoredList = listOf(
        "Exif SubIFD:Lens Model",
        "Exif SubIFD:Lens Make"
    )

    ${v}Metadata.names().forEach {
        val ${v}HasMakeOrModelTag = it.contains("model", ignoreCase = true) ||
            it.contains("make", ignoreCase = true) ||
            it.contains("camera", ignoreCase = true)
        val ${v}IsKnownTag = ${v}HandledList.contains(it) ||
            ${v}IgnoredList.contains(it)
        val ${v}NewTagFound = !${v}IsKnownTag
        if (${v}HasMakeOrModelTag && ${v}NewTagFound) {
            if (${DCIM_VERBOSE}) {
                ${DCIM_VERBOSE_LOG}("tika detected dvc " + it + 
                    ": " + ${v}Metadata.get(it))
            }
        }

        if (${DCIM_VERBOSE}) {
            ${DCIM_VERBOSE_LOG}("tika " + it + ": " + ${v}Metadata.get(it))
        }
    }

    var ${v}Make = ${v}Metadata.get("Exif IFD0:Make") ?:
        ${v}Metadata.get("tiff:Make") ?: ${v}Metadata.get("Make") ?: "Unknown"
    var ${v}Model = ${v}Metadata.get("Exif IFD0:Model") ?:
        ${v}Metadata.get("tiff:Model") ?: ${v}Metadata.get("Model") ?:
        ${v}Metadata.get("Camera Model Name") ?:
        ${v}Metadata.get("Canon Model ID") ?: "Unknown"

    val ${v}UnknownMake = ${v}Make == "Unknown"
    val ${v}UnknownModel = ${v}Model == "Unknown"
    if (${v}UnknownMake || ${v}UnknownModel) {
        // only spawn exiftool process if tika failed to find them
        val ${v}ExifArgs = mutableListOf<String>()
        ${v}ExifArgs.add("${DCIM_EXIF_TOOL_COMMAND}")
        if (${v}UnknownMake)
            ${v}ExifArgs.add("-Make")
        if (${v}UnknownModel) {
            ${v}ExifArgs.add("-Model")
        }
        ${v}ExifArgs.addAll(listOf("-s", "-s", ${!dcim_file}.name))

        try {
            val ${v}Process = ProcessBuilder(${v}ExifArgs)
                .redirectErrorStream(true)
                .start()
            val ${v}Finished = ${v}Process.waitFor(
                ${DCIM_EXIF_TOOL_WAIT_SECS},
                ${DCIM_TU}.SECONDS
            )
            if (${v}Finished) {
                val ${v}StdOutput =
                    ${v}Process.inputStream.bufferedReader().readText().trim()
                val ${v}Lines = ${v}StdOutput.split("\n").filter {
                    it.isNotBlank()
                }
                var ${v}I = 0
                if (${v}UnknownMake) {
                    ${v}Make = ${v}Lines.getOrNull(${v}I)?.substringAfter(": ")
                        ?.trim()?.takeIf {
                            it.isNotBlank()
                        } ?: "Unknown"
                    ${v}I++
                }
                if (${v}UnknownModel) {
                    ${v}Model = ${v}Lines.getOrNull(${v}I)?.substringAfter(": ")
                        ?.trim()?.takeIf {
                            it.isNotBlank()
                        } ?: "Unknown"
                }
            } else {
                ${v}Process.destroyForcibly()
                ${DCIM_ERR_LOG}(
                    "exif tool timed out while attempting to read file:" +
                    ${!dcim_file}.name
                )
            }
        } catch(${v}Exception: Exception) {
            ${DCIM_ERR_LOG}("exif tool failed with exception:" +
                ${v}Exception.message)
        }
    }

    val ${!dcim_device} = ${DCIM_DVC_CLASS_NS} (
        make = ${v}Make,
        model = ${v}Model
    )

    /**********************************************************************
     *                                                                    *
     * :END: dcim crt-dvc: DIGITAL CAMERA IMAGE CREATE DEVICE             *
     *                                                                    *
     **********************************************************************/

EOF
