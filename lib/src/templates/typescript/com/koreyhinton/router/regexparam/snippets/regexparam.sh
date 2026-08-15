#!/bin/bash

: "${REG_PAR_CLASS:=RegexParam}"
: "${REG_PAR_RES_CLASS:=RegexParamResult}"

v=${1}
# maps
. ${NSMAP}/bind ${v} RegexParamManifest

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
     *            |ns_|RegexParamManifest: RegexParamManifest             *
     *                                                                    *
     *        output:                                                     *
     *            |ns_|RegexParamResult: RegexParamResult                 *
     *                                                                    *
     *        required model type imports:                                *
     *            RegexParam                                              *
     *            RegexParamManifest                                      *
     *            RegexParamResult                                        *
     *                                                                    *
     **********************************************************************/

    const ${v}RegexParamResult = {
        regexParams: ([] as ${REG_PAR_CLASS}[])
    } as ${REG_PAR_RES_CLASS};

    for (const ${v}KeyedPath of ${!regex_param_manifest}.keyedPaths) {

        if (${v}KeyedPath instanceof RegExp) {
            ${v}RegexParamResult.regexParams.push({
                keys: false,
                pattern: ${v}KeyedPath,
                keyedPath: ${v}KeyedPath
            } as ${REG_PAR_CLASS});
            continue;
        }

	let ${v}C: string, ${v}O: number, ${v}Tmp: string | undefined,
            ${v}Ext: number, ${v}Keys=[], ${v}Pattern='',
            ${v}Arr: (string|undefined)[] = ${v}KeyedPath.split('/');
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

        ${v}RegexParamResult.regexParams.push({
            keys: ${v}Keys,
            pattern: new RegExp('^' + ${v}Pattern + '\/?$', 'i'),
            keyedPath: ${v}KeyedPath
	} as ${REG_PAR_CLASS});

    }

    /**********************************************************************
     *                                                                    *
     * :END: router regexparam: REGEX PARAMETERS                          *
     *                                                                    *
     **********************************************************************/

EOF
