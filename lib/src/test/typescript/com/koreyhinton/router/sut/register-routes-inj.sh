#!/bin/bash

export REG_EVT_INJ="regEvtInj || "
export REG_EVT_WARN="warnfn"

v=${1:-sut_}
cat << EOF

    import { navigation } from '../fixtures/web';
    ` ${ORC_ROUTER}/snippets/import.sh ../fixtures/models `

    export function registerRoutesInj(
        ${v}router_RouterConfig: RouterConfig,
        regEvtInj = true,
        warnfn = console.warn
    ): Router {

        ` ${ORC_ROUTER}/snippets/register-routes.sh ${v}router_ `

        return ${v}router_Router;
    };

EOF
