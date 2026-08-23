#!/bin/bash

v=${1:-test_}

cat << EOF

    ` ${ORC_ROUTER}/snippets/import.sh ../fixtures/models `
    import { registerRoutes } from '../sut/register-routes';
    import { registerRoutesInj } from '../sut/register-routes-inj';
    import { expect, test } from 'vitest';
    import { navigation } from '../fixtures/web'

    export const assert = function(b: boolean) {
        expect(b).toBe(true);
    };

    test('registerRoutes w/ nav event parsed multiple keyed routes', () => {

        let ${v}router_RouterConfig: RouterConfig = {
            routes: [
                '/page/:name',
                '/contact/:contactId',
                '*'
            ]
        };
        let ${v}router_Router = registerRoutes(${v}router_RouterConfig);
        navigation.cb({canIntercept: true, intercept: ()=>{} });

        assert(${v}router_Router != null);

        for (let params of ${v}router_Router.regexParams) {
            assert(params.keys !== false && params.keys.length > 0);
        }

    });

    test('registerRoutes w/ nav event parsed multiple non-keyed routes', () => {

        let ${v}router_RouterConfig: RouterConfig = {
            routes: [
                '/',
                /\\/[a-c]\\/[d-f]/,
                'abc/def'
            ]
        };
        let ${v}router_Router = registerRoutes(${v}router_RouterConfig);
        navigation.cb({canIntercept: true, intercept: ()=>{} });

        assert(${v}router_Router != null);

        for (let params of ${v}router_Router.regexParams) {
            assert(params.keys === false || params.keys.length === 0);
        }
    });

    test('registerRoutes warns failing events but still parses route', () => {

        let warned = false;

        let ${v}router_RouterConfig: RouterConfig = {
            routes: [
                '/'
            ]
        };

        let ${v}Router = registerRoutesInj(
            ${v}router_RouterConfig,
            true,
            () => { warned = true; }
        );
        assert(
            warned &&
            ${v}Router != null &&
            ${v}Router.regexParams.length === 1 &&
            ${v}Router.regexParams[0].pattern != null
        );
    });

EOF
