#!/bin/bash

: "${DCIM_STREAM_CLASS_NS:=com.koreyhinton.dcim.classes.DcimStream}"
: "${DCIM_SOURCE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimSource}"
: "${DCIM_WWW_FILE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimWwwFile}"
: "${DCIM_FILE_CLASS_NS:=com.koreyhinton.dcim.classes.DcimFile}"
: "${DCIM_FFMPEG:=com.github.kokorin.jaffree.ffmpeg.FFmpeg}"
: "${DCIM_URL_INP:=com.github.kokorin.jaffree.ffmpeg.UrlInput}"
: "${DCIM_JNIOF_PATHS:=java.nio.file.Paths}"
: "${DCIM_PI:=com.github.kokorin.jaffree.ffmpeg.PipeInput}"
: "${DCIM_URL:=java.net.URL}"

v=${1}
# maps
. ${NSMAP}/bind ${v} DcimSource DcimStreams DcimFFmpeg

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    dcim compat-convert-streams: DIGITAL CAMERA IMAGE CONV STREAMS  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|DcimStreams (List<DcimSource>)                     *
     *            |ns_|DcimSource (DcimSource)                            *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|DcimFFmpeg (FFmpeg)
     *                                                                    *
     *        tested with:                                                *
     *            implementation(                                         *
     *                "com.github.kokorin.jaffree:jaffree:2024.08.29")    *
     *                                                                    *
     **********************************************************************/

    val ${v}DcimFFmpeg = ${DCIM_FFMPEG}.atPath()

    if (${!dcim_source} is ${DCIM_FILE_CLASS_NS}) {
        ${v}DcimFFmpeg.addInput(${DCIM_URL_INP}.fromPath(
            ${DCIM_JNIOF_PATHS}.get(
                ${!dcim_source}.name)
            )
        )
    } else if (${!dcim_source} is ${DCIM_WWW_FILE_CLASS_NS}) {
        val ${v}Url = ${DCIM_URL}(${!dcim_source}.url)
        val ${v}Connection = ${v}Url.openConnection()
        ${v}Connection.setRequestProperty("Range", "bytes=0-")
        ${v}DcimFFmpeg.addInput(
            //${DCIM_PI}.pumpFrom(${v}Connection.inputStream)
            ${DCIM_URL_INP}.fromUrl(${!dcim_source}.url) //.setFormat("mp4")
        ) //.addArguments("-movflags", "faststart")
    }

    var ${v}ConvertVideo = false
    var ${v}ConvertAudio = false
    val ${v}SafeAudCodecs = listOf("aac", "mp3", "mp4a", "ac-3", "eac3")

    ${!dcim_streams}.forEach { ${v}Stream ->

        if (${v}Stream.typeLc == 'v' && ${v}Stream.encodingLc == "hevc") {
            ${v}ConvertVideo = true
        }

        if (${v}Stream.typeLc == 'a' && !${v}SafeAudCodecs.contains(${v}Stream.encodingLc)) {
            ${v}ConvertAudio = true
        }

        if (${v}Stream.typeLc == 'a' || ${v}Stream.typeLc == 'v') {
            // data or unknown types don't get mapped

            ${v}DcimFFmpeg.addArguments(
                "-map",
                "0:"+${v}Stream.index.toString() //"0:" + ${v}Stream.typeLc + ":" + ${v}Stream.index
            )

        }
    }

    ${v}DcimFFmpeg.addArguments("-movflags", "frag_keyframe+empty_moov") //+faststart")

    // force stream
    // ${v}DcimFFmpeg.addArguments("-seekable", "0")
    /*
        ${v}DcimFFmpeg.addArguments("-analyzeduration", "0")
        ${v}DcimFFmpeg.addArguments("-probesize", "32")
        ${v}DcimFFmpeg.addArguments("-fflags", "nobuffer+genpts")
        ${v}DcimFFmpeg.addArguments("-flags", "low_delay")

        ${v}DcimFFmpeg.addArguments("-reconnect", "1")
        ${v}DcimFFmpeg.addArguments("-reconnect_streamed", "1")
        ${v}DcimFFmpeg.addArguments("-reconnect_delay_max", "5")

    */



    if (${v}ConvertAudio) {
        ${v}DcimFFmpeg.addArguments("-c:a", "aac")
        ${v}DcimFFmpeg.addArguments("-b:a", "128k")
    } else {
        ${v}DcimFFmpeg.addArguments("-c:a", "copy")
    }

    if (${v}ConvertVideo) {
        ${v}DcimFFmpeg.addArguments("-c:v", "libx264")
        ${v}DcimFFmpeg.addArguments("-pix_fmt", "yuv420p")
        // which if not all of these need to be added?:
        ${v}DcimFFmpeg.addArguments("-crf", "23")
        ${v}DcimFFmpeg.addArguments("-preset", "medium")
        ${v}DcimFFmpeg.addArguments("-profile:v", "high")
        ${v}DcimFFmpeg.addArguments("-level", "4.0")
    } else {
        ${v}DcimFFmpeg.addArguments("-c:v", "copy")
    }


    /**********************************************************************
     *                                                                    *
     * :END: dcim compat-convert-streams DIGITAL CAMERA IMAGE CONV STREAMS*
     *                                                                    *
     **********************************************************************/

EOF
