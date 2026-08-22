#!/bin/bash

: "${ROUTER_WARN:=console.warn}"
: "${REG_PAR_MAN_KEY_PATH_TYPES:=string|RegExp}"
v=${1}
priv="${RANDOM}_"
# maps
. ${NSMAP}/bind ${v} Router
export ${v}${priv}EventStore=${!router}.eventStore

REG_PARAM_SNIPPET=$(cat << EOF

        const ${v}Params: Record<string, string | null> = {};
        let ${v}KeyedPath: (${REG_PAR_MAN_KEY_PATH_TYPES}) | null | string | RegExp = null;
        let ${v}Matched = false;
        for (const ${v}Rp of ${!router}.regexParams) {
            const ${v}ResultArr = ${v}Rp.pattern.exec(${v}RealPath);
            if (${v}ResultArr) {
                ${v}KeyedPath = ${v}Rp.keyedPath;
                if (Array.isArray(${v}Rp.keys)) {
                    const ${v}Keys = (${v}Rp.keys as string[]);
                    for (let ${v}I=0; ${v}I<${v}Keys.length; ${v}I++) {
                        // +1 to start at the first capture group (index 0 has complete match)
                        ${v}Params[${v}Keys[${v}I]] = ${v}ResultArr[${v}I+1] || null;
                    }
                }
                ${v}Matched = true;
                break;
            }
        }
        if (!${v}Matched) {
            ${ROUTER_WARN}("unrecognized path pattern: " + ${v}RealPath)
            if (${!router}.keyedPaths.length > 0 && typeof ${!router}.keyedPaths[0] == 'string') {
                ${v}RealPath = ${!router}.keyedPaths[0];
            } else {
                ${v}RealPath = '/';
            }
        }

EOF
)

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    router poll-route                                               *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input/output:                                               *
     *            |ns_|Router: Router                                     *
     *                                                                    *
     *        required model type imports:                                *
     *            EventPoll                                               *
     *            EventPollReport                                         *
     *                                                                    *
     **********************************************************************/

    ` ${ORC_EVENT}/snippets/poll-event.sh ${v}${priv} `

    if (${!router}.activeRoute == null) {

        /* snippet */
        let ${v}RealPath = location.pathname;
        ${REG_PARAM_SNIPPET}
        ${!router}.activeRoute = {
            hot: true,
            realPath: ${v}RealPath,
            params: ${v}Params,
            keyedPath: ${v}KeyedPath as ${REG_PAR_MAN_KEY_PATH_TYPES}
        };
        /* end snippet */

    } else if ('RouteNavigationEvent' in ${v}${priv}EventPollReport.polls) {
        const ${v}Poll: EventPoll =
            ${v}${priv}EventPollReport.polls['RouteNavigationEvent'];
        const ${v}NavEvt = ${v}Poll.event as NavigateEvent;
        const ${v}NavUrl = new URL(${v}NavEvt.destination.url)
        if (${v}NavUrl.pathname != ${!router}.activeRoute.realPath) {
            ${!router}.activeRoute.hot = true;
            ${!router}.activeRoute.realPath = ${v}NavUrl.pathname;

            /* snippet */
            let ${v}RealPath = ${v}NavUrl.pathname;
            ${REG_PARAM_SNIPPET}
            ${!router}.activeRoute.params = ${v}Params;
            ${!router}.activeRoute.realPath = ${v}RealPath;
            ${!router}.activeRoute.keyedPath = ${v}KeyedPath as
                ${REG_PAR_MAN_KEY_PATH_TYPES};
            /* end snippet */

        }
        
    } else {
        ${!router}.activeRoute.hot = false;
    }

    /**********************************************************************
     *                                                                    *
     * :END: router poll route                                            *
     *                                                                    *
     **********************************************************************/

EOF
