#!/bin/bash

v=${1}
priv="${RANDOM}_"
# maps
. ${NSMAP}/bind ${v} RouterConfig
export ${v}regpar_RegexParamManifest=${v}Router

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    router register-routes                                          *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|RouterConfig: RouterConfig                         *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|Router: Router                                     *
     *                                                                    *
     *        required model type imports:                                *
     *            RegexParam                                              *
     *            RegexParamManifest                                      *
     *            RegexParamResult                                        *
     *            EventStore                                              *
     *            EventStoreConfig                                        *
     *            EventPollSubject                                        *
     *            Router                                                  *
     *                                                                    *
     **********************************************************************/

    const ${v}${priv}regpar_RegexParamManifest: RegexParamManifest = {
        keyedPaths: []
    };
    let ${v}${priv}RegexParams: RegexParam[] = [];

    for (const ${v}Route of ${v}RouterConfig.routes) {
        const ${v}NormRoute = ${v}Route.startsWith('/')
            ? ${v}Route
            : '/' + ${v}Route;
        ${v}${priv}regpar_RegexParamManifest.keyedPaths.push(${v}NormRoute);
    }

    if (${v}${priv}regpar_RegexParamManifest.keyedPaths.length > 0) {
        ` ${ORC_ROUTER}/regexparam/snippets/regexparam.sh ${v}${priv}regpar_ `
        ${v}${priv}RegexParams = ${v}${priv}regpar_RegexParamResult.regexParams;
    }

    const ${v}${priv}EventStore: EventStore = {
        pollSubjects: []
    };
    const ${v}${priv}EventStoreConfig: EventStoreConfig = {
        events: [
            {
                key: 'RouteNavigationEvent',
                eventType: 'navigate',
                listener: navigation,
                intercept: true
            }
        ]
    };

    ` ${ORC_EVENT}/snippets/register-events.sh ${v}${priv} `

    let ${v}Router: Router = {
        activeRoute: null, // gets assigned in poll
        keyedPaths: ${v}${priv}regpar_RegexParamManifest.keyedPaths,
        regexParams: ${v}${priv}RegexParams,
        eventStore: ${v}${priv}EventStore
    }; // => RegexParamManifest


    /**********************************************************************
     *                                                                    *
     * :END: router register-routes                                       *
     *                                                                    *
     **********************************************************************/

EOF
