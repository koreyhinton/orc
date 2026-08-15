#!/bin/bash

v=${1}
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
     *            ActiveRoute                                             *
     *            RegexParam                                              *
     *            RegexParamResult                                        *
     *            EventRegistration                                       *
     *            EventStore                                              *
     *            EventStoreConfig                                        *
     *            EventPollSubject                                        *
     *            Router                                                  *
     *                                                                    *
     **********************************************************************/

    var ${v}Router: Router = {
        activeRoute: null, // gets assigned in poll
        keyedPaths: [] as (string|RegExp)[],// to-be assigned
        regexParams: [] as RegexParam[], // to-be assigned
        eventStore: null // to-be assigned
    } as Router; // => RegexParamManifest

    for (const ${v}Route of ${v}RouterConfig.routes) {
        const ${v}NormRoute = ${v}Route.startsWith('/') ? ${v}Route : '/' + ${v}Route;
        ${v}Router.keyedPaths.push(${v}NormRoute);
    }

    if (${v}Router.keyedPaths.length > 0) {
        ` ${ORC_ROUTER}/regexparam/snippets/regexparam.sh ${v}regpar_ `
        ${v}Router.regexParams = ${v}regpar_RegexParamResult.regexParams;
    }

    const ${v}EventStoreConfig = {
        events: [
            {
                key: 'RouteNavigationEvent',
                eventType: 'navigate',
                listener: navigation,
                intercept: true
            } as EventRegistration
        ]
    } as EventStoreConfig;

    ` ${ORC_EVENT}/snippets/register-events.sh ${v} `

    ${v}Router.eventStore = ${v}EventStore;

    /**********************************************************************
     *                                                                    *
     * :END: router register-routes                                       *
     *                                                                    *
     **********************************************************************/

EOF
