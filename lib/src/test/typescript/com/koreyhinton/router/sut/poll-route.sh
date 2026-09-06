#!/bin/bash

v=${1:-sut_}
cat << EOF

    import { navigation } from '../fixtures/web';
    import { registerRoutesInj } from './register-routes-inj';

    ` ${ORC_ROUTER}/snippets/import.sh ../fixtures/models `

    export function pollRoute(
        ${v}router_Router: Router
    ): Router {

        ` ${ORC_ROUTER}/snippets/poll-route.sh ${v}router_ `

        return ${v}router_Router;
    };

EOF
