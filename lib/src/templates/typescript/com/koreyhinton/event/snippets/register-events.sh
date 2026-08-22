#!/bin/bash

: "${REG_EVT_WARN:=console.warn}"

v=${1}
# maps
. ${NSMAP}/bind ${v} EventStoreConfig EventStore

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
     *        input/output:                                               *
     *            |ns_|EventStore: EventStore                             *
     *                                                                    *
     *        required model type imports:                                *
     *            NavigateEvent                                           *
     *                                                                    *
     **********************************************************************/

    for (const ${v}EventRegistration of ${!event_store_config}.events) {

        if (${v}EventRegistration.listener == null) {
            ${REG_EVT_WARN}("null listener, please pass in window, navigation, or element")
        } else {
            ${v}EventRegistration.listener.addEventListener(
                ${v}EventRegistration.eventType,
                ${v}FiredEvt => {
                    for (let ${v}Si=0;/*subject index*/
                            ${v}Si<${!event_store}.pollSubjects.length;
                            ${v}Si++) {
                        let ${v}TestSubject = 
                            ${!event_store}.pollSubjects[${v}Si];
                        if (${v}TestSubject.key === ${v}EventRegistration.key) {
                            if (${v}EventRegistration.eventType == 'navigate' &&
                                    ${v}EventRegistration.intercept &&
                                    (${v}FiredEvt as NavigateEvent).canIntercept) {
                                let ${v}NavEvent =
                                    (${v}FiredEvt as NavigateEvent);
                                if (${v}NavEvent.navigationType != 'reload') {
                                    ${v}NavEvent.intercept({});
                                }
                            }
                            ${v}TestSubject.polled = true;
                            ${v}TestSubject.event = ${v}FiredEvt;
                            break;
                        }
                    }
                }
            );
            ${!event_store}.pollSubjects.push({
                event: null,
                eventType: ${v}EventRegistration.eventType,
                key: ${v}EventRegistration.key,
                polled: false
            });
        }
    }

    /**********************************************************************
     *                                                                    *
     * :END: event register-events                                        *
     *                                                                    *
     **********************************************************************/

EOF
