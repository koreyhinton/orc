#!/bin/bash

v=${1:-sut_}
cat << EOF

    import { navigation } from '../fixtures/web';
    import { registerRoutesInj } from './register-routes-inj';

    ` ${ORC_ROUTER}/snippets/import.sh ../fixtures/models `

    export function registerRoutes(
        ${v}router_RouterConfig: RouterConfig
    ): Router {
        return registerRoutesInj(${v}router_RouterConfig, false)
    };

EOF
