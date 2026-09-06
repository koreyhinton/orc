#!/bin/bash

v=${1:-test_}

cat << EOF

    ` ${ORC_ROUTER}/snippets/import.sh ../fixtures/models `
    import { registerRoutes } from '../sut/register-routes';
    import { registerRoutesInj } from '../sut/register-routes-inj';
    import { pollRoute } from '../sut/poll-route';
    import { expect, test } from 'vitest';
    import { navigation } from '../fixtures/web'

    export const assert = function(b: boolean) {
        expect(b).toBe(true);
    };

    test('intercepts', () => {

        let expect1 = '/'; // route-on-load path
        let expect2 = '/navChangePath';

        global.location = { pathname: expect1 };
        let rc: RouterConfig = {routes:[expect1,expect2]};
        let router = registerRoutes(rc);
        pollRoute(router); // first poll
        navigation.cb({
            canIntercept: true,
            intercept: ()=>{},
            // cross-origin request to example.org works for
            // testing mocked intercept/poll-route directly, but in reality it
            // short-circuits (because canIntercept == false)
            destination: {url: 'http://example.org'+expect2 }
        });

        assert(router.activeRoute.hot &&
            router.activeRoute.realPath == expect1);
        pollRoute(router);
        assert(router.activeRoute.hot &&
            router.activeRoute.realPath == expect2);
    });


    test('keyed R-O-L and parses multiple keyed routes', () => {

        global.location = { pathname: '/user/2' };

        let ${v}rol_Spec = {
            expect: '/user/2'
        };

        let ${v}rol_RouterConfig: RouterConfig = {
            routes: [
                '/page/:name',
                '/contact/:contactId',
                '*'
            ]
        };

        // R-O-L
        ` ./route-on-load.sh ${v}rol_ `

        assert(${v}rol_Router != null);

        for (let params of ${v}rol_Router.regexParams) {
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

    test('R-O-L without a match falls back to provided first route', () => {

        global.location = { pathname: '/not/the/path' };

        let ${v}rol_Spec = { expect: '/first' };
        let ${v}rol_RouterConfig: RouterConfig = {
            routes: [
                ${v}rol_Spec.expect,
                '/second'
            ]
        };

        ` ./route-on-load.sh ${v}rol_ `

    });

    test('R-O-L without a match falls back to hardcoded root route', () => {

        global.location = { pathname: '/not/the/path' };

        let ${v}rol_Spec = { expect: '/' };
        let ${v}rol_RouterConfig: RouterConfig = {
            routes: [
            ]
        };

        ` ./route-on-load.sh ${v}rol_ `

    });

    test('pollRoute no active route, navigate event, w/ key paths', () => {

        global.location = { pathname: '/not/the/path' };
        let ${v}Router: Router = {
            activeRoute: null,
            regexParams: [{
                keyedPath: "/user/:userId",
                keys: ['userId'],
                pattern: /^foo\$/
            }],
            eventStore: {
                pollSubjects: [{
                    key: 'RouteNavigationEvent',
                    polled: true, // mock event listener (router-registration)
                    event: {
                        destination: {
                            url: 'http://example.org/nomatch'
                        }
                    } as NavigateEvent,
                    eventType: 'NavigateEvent'
                }]
            },
            keyedPaths: ["/user/:userId"]
        };

        pollRoute(${v}Router);

    });


    test('pollRoute active route match', () => {

        global.location = {};
        let ${v}Router: Router = {
            activeRoute: {
                hot: true,
                realPath: '/',
                keyedPath: '/',
                params: []
            },
            regexParams: [{
                keyedPath: "/user/:userId",
                keys: ['userId'],
                pattern: /^.*\$/
            }],
            eventStore: {
                pollSubjects: [{
                    key: 'FooClick',
                    polled: true, // mock event listener (router-registration)
                    event: null,
                    eventType: 'click'
                }]
            },
            keyedPaths: []
        };

        pollRoute(${v}Router);

    });

    test('pollRoute active route not matched', () => {

        let ${v}Router: Router = {
            activeRoute: {
                hot: true,
                realPath: '/',
                keyedPath: '/',
                params: []
            },
            regexParams: [{
                keyedPath: "/user/:userId",
                keys: ['userId'],
                pattern: /^foo\$/
            }],
            eventStore: {
                pollSubjects: [{
                    key: 'RouteNavigationEvent',
                    polled: true, // mock event listener (router-registration)
                    event: {
                        destination: {
                            // cross-origin request to example.org works for
                            // testing poll-route directly, but in reality it
                            // short-circuits (because canIntercept == false)
                            url: 'http://example.org/nomatch'
                        }
                    } as NavigateEvent,
                    eventType: 'NavigationEvent'
                }]
            },
            keyedPaths: []
        };

        pollRoute(${v}Router);

        assert(${v}Router.activeRoute.hot && ${v}Router.activeRoute.realPath == '/');
    });

    test('pollRoute active route matched with param results', () => {

        global.location = { pathname: '/' };
        let ${v}Router: Router = {
            activeRoute: {
                hot: true,
                realPath: '/',
                keyedPath: '/',
                params: []
            },
            regexParams: [{
                keyedPath: "/user/:userId",
                keys: ['userId'],
                pattern: /^.*\$/
            }],
            eventStore: {
                pollSubjects: [{
                    key: 'RouteNavigationEvent',
                    polled: true, // mock event listener (router-registration)
                    event: {
                        destination: {
                            url: 'http://example.org/user/30'
                        }
                    } as NavigateEvent,
                    eventType: 'NavigationEvent'
                }]
            },
            keyedPaths: []
        };

        pollRoute(${v}Router);

    });

    test('pollRoute active route not matched with param results with router keyedPaths', () => {

        global.location = { pathname: '/' };
        let ${v}Router: Router = {
            activeRoute: {
                hot: true,
                realPath: '/',
                keyedPath: '/',
                params: []
            },
            regexParams: [{
                keyedPath: "/user/:userId",
                keys: ['userId'],
                pattern: /^.foo$/
            }],
            eventStore: {
                pollSubjects: [{
                    key: 'RouteNavigationEvent',
                    polled: true, // mock event listener (router-registration)
                    event: {
                        destination: {
                            url: 'http://example.org/user/30'
                        }
                    } as NavigateEvent,
                    eventType: 'NavigationEvent'
                }]
            },
            keyedPaths: ["/user/:userId"]
        };

        pollRoute(${v}Router);

    });


EOF
