#!/bin/bash


cat << EOF


    type Navigation = {
        addEventListener: (eventType: string, callback: (evt: any)=>void): void,
        cb: (evt: any)=>void
    };


    export const navigation: Navigation = {
        cb: ()=>{},
        addEventListener: function(t, c) {
            navigation.cb = c
        }
    };
EOF

