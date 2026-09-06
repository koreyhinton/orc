#!/bin/bash

# route-on-load does the routing that happens when a site loads,
# ie: event registration + first poll and should route to a match,
# or fallback to first route given, else '/'

# route-on-load is an assertion that it routed on load, so it will
# assert that it worked (the active route is hot)

# usage:
#     1. assign global location
#            global.location = { pathname: '/user/2' };
#     2. assign |ns|Spec var 
#            { expect: '/user/2' }
#     3. assign |ns|RouterConfig var
#     4. invoke route-on-load

v=${1}
priv=${RANDOM}_

# maps
. ${NSMAP}/bind ${v} RouterConfig Spec

cat << EOF
    let ${v}${priv}Router = registerRoutes(${!router_config});
    assert(${v}${priv}Router != null);

    let ${v}Router = pollRoute(${v}${priv}Router);
    assert(${v}Router != null && ${v}${priv}Router === ${v}Router);

    assert(${v}Router.activeRoute.hot &&
        ${v}Router.activeRoute.realPath === ${!spec}.expect);

EOF

