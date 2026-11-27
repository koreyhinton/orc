// orc ws browser plugin: the wasm32 side of the orc ws snippets (models.sh
// declares these functions). Uses the browser's own WebSocket and
// XMLHttpRequest. Adapted from sharecmd's demo/web/lockstep_net.js.
// Load it after gl.js (or mq_js_bundle.js) and sapp_jsutils.js, which
// provide miniquad_add_plugin, js_object and consume_js_object.
"use strict";

var orc_ws_socket = null;
var orc_ws_state = 0; // 0 connecting, 1 open, 2 closed
var orc_ws_close_reason = "";
var orc_ws_inbox = [];
var orc_ws_requests = {};
var orc_ws_next_id = 0;

function orc_ws_register(importObject) {
    importObject.env.orc_ws_connect = function (url) {
        orc_ws_state = 0;
        orc_ws_close_reason = "";
        orc_ws_inbox = [];
        try {
            orc_ws_socket = new WebSocket(consume_js_object(url));
        } catch (e) {
            orc_ws_state = 2;
            orc_ws_close_reason = "websocket connect failed: " + e;
            return;
        }
        orc_ws_socket.onopen = function () { orc_ws_state = 1; };
        orc_ws_socket.onmessage = function (m) {
            if (typeof m.data === "string") orc_ws_inbox.push(m.data);
        };
        orc_ws_socket.onerror = function () {
            if (!orc_ws_close_reason) orc_ws_close_reason = "connection error";
        };
        orc_ws_socket.onclose = function (e) {
            orc_ws_state = 2;
            if (!orc_ws_close_reason) {
                orc_ws_close_reason = e.reason || ("connection closed (code " + e.code + ")");
            }
        };
    };

    importObject.env.orc_ws_send = function (text) {
        var s = consume_js_object(text);
        if (orc_ws_socket && orc_ws_state === 1) orc_ws_socket.send(s);
    };

    importObject.env.orc_ws_try_recv = function () {
        return orc_ws_inbox.length ? js_object(orc_ws_inbox.shift()) : -1;
    };

    importObject.env.orc_ws_state = function () { return orc_ws_state; };

    importObject.env.orc_ws_close_reason = function () { return js_object(orc_ws_close_reason); };

    importObject.env.orc_ws_http_post = function (url) {
        var id = orc_ws_next_id++;
        var req = { status: 0, body: "" };
        orc_ws_requests[id] = req;
        var xhr = new XMLHttpRequest();
        xhr.open("POST", consume_js_object(url));
        xhr.onload = function () {
            if (xhr.status === 200) {
                req.status = 1;
                req.body = xhr.responseText;
            } else {
                req.status = 2;
                req.body = "server replied HTTP " + xhr.status;
            }
        };
        xhr.onerror = function () {
            req.status = 2;
            req.body = "request failed (is the server running?)";
        };
        xhr.send();
        return id;
    };

    importObject.env.orc_ws_http_status = function (id) {
        return orc_ws_requests[id] ? orc_ws_requests[id].status : 2;
    };

    importObject.env.orc_ws_http_body = function (id) {
        var req = orc_ws_requests[id];
        delete orc_ws_requests[id];
        return js_object(req ? req.body : "");
    };

    importObject.env.orc_ws_page_param = function (name) {
        var v = new URLSearchParams(window.location.search).get(consume_js_object(name));
        return js_object(v || "");
    };

    importObject.env.orc_ws_default_server = function () {
        var scheme = window.location.protocol === "https:" ? "https://" : "http://";
        return js_object(scheme + (window.location.hostname || "localhost") + ":8080");
    };
}

miniquad_add_plugin({ register_plugin: orc_ws_register, name: "orc_ws" });
