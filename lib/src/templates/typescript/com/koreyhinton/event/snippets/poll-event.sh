#!/bin/bash

: "${EVT_POL_TYPES:=string}"

v=${1}
# maps

. ${NSMAP}/bind ${v} EventStore

cat << EOF

// https://raw.githubusercontent.com/koreyhinton/orclib/refs/heads/main/orclib-ts/src/EventPoller.ts

    /**********************************************************************
     *                                                                    *
     *    event poll-event                                                *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|EventStore: EventStore                             *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|EventPollReport: EventPollReport                   *
     *                                                                    *
     *        required model type imports:                                *
     *            EventPoll                                               *
     *            EventPollReport                                         *
     *                                                                    *
     **********************************************************************/

    const ${v}EventPollReport = {
        polls: {} as Record<${EVT_POL_TYPES}, EventPoll>
    } as EventPollReport;

    for (var ${v}Si=0;/*subject index*/
            ${v}Si<${!event_store}!.pollSubjects.length; ${v}Si++) {
        var ${v}TestSubject = ${!event_store}!.pollSubjects[${v}Si];
        if (${v}TestSubject.polled) {
            ${v}EventPollReport.polls[${v}TestSubject.key] = {
                event: ${v}TestSubject.event,
                eventType: ${v}TestSubject.eventType
            } as EventPoll;

            ${v}TestSubject.event = null;
            ${v}TestSubject.polled = false;
        }
    }
    /**********************************************************************
     *                                                                    *
     * :END: event poll-event                                             *
     *                                                                    *
     **********************************************************************/

EOF
