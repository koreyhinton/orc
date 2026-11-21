#!/bin/bash

# ws default-server
#
#   command arg:  |ns_|
#   output:       |ns_|Server  Option<String> (declared here), with no
#                              trailing slash
#
#   Desktop: the URL after --server on the command line, or None.
#   Browser: ?server=URL from the page's address, or else port 8080 on the
#   page's own host.

v=${1}
priv=${RANDOM}_
# maps
. ${NSMAP}/bind ${v} Server

cat << EOF

    let mut ${!server}: Option<String> = None;
    #[cfg(not(target_arch = "wasm32"))]
    {
        let args: Vec<String> = std::env::args().collect();
        let at = args.iter().position(|arg| arg == "--server");
        ${!server} = at.and_then(|i| args.get(i + 1)).map(|url| url.trim_end_matches('/').to_string());
    }
    #[cfg(target_arch = "wasm32")]
    {
        let mut url = String::new();
        unsafe { orc_ws_page_param(sapp_jsutils::JsObject::string("server")) }.to_string(&mut url);
        if url.is_empty() {
            unsafe { orc_ws_default_server() }.to_string(&mut url);
        }
        ${!server} = Some(url.trim_end_matches('/').to_string());
    }

EOF
