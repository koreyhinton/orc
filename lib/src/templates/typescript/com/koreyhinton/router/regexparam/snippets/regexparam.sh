#!/bin/bash

: "${REGEXPARAM_CLASS:=RegexParam}"

v=${1}
# maps
. ${NSMAP}/bind ${v} KeyedRoutes RegexParams

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    router regexparam: regex parameters                             *
     *        (derived from github.com/lukeed/regexparam, see ./license)  *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input:                                                      *
     *            |ns_|KeyedRoutes: KeyedRoute[]                          *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|RegexParams: (RegexParam[])                        *
     *                                                                    *
     *        required model type imports:                                *
     *            KeyedRoute                                              *
     *            RegexParam                                              *
     *                                                                    *
     **********************************************************************/

    const ${!regex_params}: ${REGEXPARAM_CLASS}[] = [];

    for (const ${v}KeyedRoute of ${!keyed_routes}) {

        if (${v}KeyedRoute.path instanceof RegExp) {
            ${!regex_params}.push(new RegexParam(
                /*keys:*/ false,
                /*pattern:*/ ${v}KeyedRoute.path
            ));
            continue;
        }

	let ${v}C: string, ${v}O: number, ${v}Tmp: string, ${v}Ext: number,
            ${v}Keys=[], ${v}Pattern='',
            ${v}Arr = ${v}KeyedRoute.path.split('/');
	${v}Arr[0] || ${v}Arr.shift();

	while (${v}Tmp = ${v}Arr.shift()) {
		${v}C = ${v}Tmp[0];
		if (${v}C === '*') {
			${v}Keys.push('wild');
			${v}Pattern += '/(.*)';
		} else if (${v}C === ':') {
			${v}O = ${v}Tmp.indexOf('?', 1);
			${v}Ext = ${v}Tmp.indexOf('.', 1);
			${v}Keys.push( ${v}Tmp.substring(1, !!~${v}O ? ${v}O : !!~${v}Ext ? ${v}Ext : ${v}Tmp.length) );
			${v}Pattern += !!~${v}O && !~${v}Ext ? '(?:/([^/]+?))?' : '/([^/]+?)';
			if (!!~${v}Ext) ${v}Pattern += (!!~${v}O ? '?' : '') + '\\\' + ${v}Tmp.substring(${v}Ext);
		} else {
			${v}Pattern += '/' + ${v}Tmp;
		}
	}

        ${!regex_params}.push(new RegexParam(
            /*keys:*/ ${v}Keys,
            /*pattern:*/ new RegExp('^' + ${v}Pattern + '\/?$', 'i')
	));

    }

    /**********************************************************************
     *                                                                    *
     * :END: router regexparam: REGEX PARAMETERS                          *
     *                                                                    *
     **********************************************************************/

EOF
