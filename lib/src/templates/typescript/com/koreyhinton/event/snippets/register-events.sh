#!/bin/bash

: "${REG_EVT_WARN:=console.warn}"

v=${1}
# maps
. ${NSMAP}/bind ${v} EventStoreConfig

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    event register-events                                           *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|EventStoreConfig: EventStoreConfig                 *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|EventStore: EventStore                             *
     *                                                                    *
     *        required model type imports:                                *
     *            EventStore                                              *
     *            EventPollSubject                                        *
     *                                                                    *
     **********************************************************************/

    const ${v}EventStore = {
        pollSubjects: [] as EventPollSubject[]
    } as EventStore;

    for (const ${v}EventRegistration of ${!event_store_config}.events) {

        if (${v}EventRegistration.listener == null) {
            ${REG_EVT_WARN}("null listener, please pass in window, navigation, or element")
        } else {
            ${v}EventRegistration.listener.addEventListener(
                ${v}EventRegistration.eventType,
                ${v}FiredEvt => {
                    for (var ${v}Si=0;/*subject index*/
                            ${v}Si<${v}EventStore.pollSubjects.length;${v}Si++){
                        var ${v}TestSubject=${v}EventStore.pollSubjects[${v}Si];
                        if (${v}TestSubject.key === ${v}EventRegistration.key) {
                            if (${v}EventRegistration.eventType == 'navigate' &&
                                    ${v}EventRegistration.intercept &&
                                    (${v}FiredEvt as NavigateEvent).canIntercept) {
                                (${v}FiredEvt as NavigateEvent).intercept({});
                            }
                            ${v}TestSubject.polled = true;
                            ${v}TestSubject.event = ${v}FiredEvt;
                            break;
                        }
                    }
                }
            );
            ${v}EventStore.pollSubjects.push({
                event: null,
                eventType: ${v}EventRegistration.eventType,
                key: ${v}EventRegistration.key,
                polled: false
            } as EventPollSubject);
        }
    }

    /**********************************************************************
     *                                                                    *
     * :END: event register-events                                        *
     *                                                                    *
     **********************************************************************/

EOF
