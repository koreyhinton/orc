#!/bin/bash

: "${DCIM_STREAM_CLASS_NS:=com.koreyhinton.dcim.classes.DcimStream}"
: "${DCIM_SOURCE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimSource}"
: "${DCIM_WWW_FILE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimWwwFile}"
: "${DCIM_FILE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimFile}"
: "${DCIM_FFPROBE:=com.github.kokorin.jaffree.ffprobe.FFprobe}"

v=${1}
# maps
. ${NSMAP}/bind ${v} DcimSource DcimStreams

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    dcim list-streams: DIGITAL CAMERA IMAGE MEDIA LIST STREAMS      *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|DcimSource (DcimSource)                            *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|DcimStreams (List<DcimStream>)                     *
     *                                                                    *
     *        tested with:                                                *
     *            implementation(                                         *
     *                "com.github.kokorin.jaffree:jaffree:2024.08.29")    *
     *                                                                    *
     **********************************************************************/
    val ${!dcim_streams} = mutableListOf<${DCIM_STREAM_CLASS_NS}>()

    val ${v}Probe = ${DCIM_FFPROBE}.atPath().setShowStreams(true)

    if (${!dcim_source} is ${DCIM_FILE_CLASS_NS}) {
        ${v}Probe.setInput(${!dcim_source}.name)
    } else if (${!dcim_source} is ${DCIM_WWW_FILE_CLASS_NS}) {
        ${v}Probe.setInput(${!dcim_source}.url)
    }

    val ${v}Result = ${v}Probe.execute()
    ${v}Result.streams.forEach { ${v}Stream ->
        ${!dcim_streams}.add(
            ${DCIM_STREAM_CLASS_NS} (
                index = ${v}Stream.index,
                encodingLc = ${v}Stream.codecName?.lowercase() ?: "unknown",
                typeLc = ${v}Stream.codecType?.name?.lowercase()?.firstOrNull() ?: 'u'
            )
        )
    }

    /**********************************************************************
     *                                                                    *
     * :END: dcim list-streams: DIGITAL CAMERA IMAGE MEDIA LIST STREAMS   *
     *                                                                    *
     **********************************************************************/

EOF
