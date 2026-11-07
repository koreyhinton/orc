#!/bin/bash

# ws import
#
#   command arg:  <version>, the orc ws version the app expects
#   prints:       every import the ws snippets need, for the app's import block
#
#   Call it between heredocs, not in backticks, so a version mismatch stops
#   the app's script.

. "$(dirname "${BASH_SOURCE[0]}")/../version.sh" "${1}"

cat << EOF
	// Bash-assembled with orc ws version ${ORC_WS_V}
	"bufio"           // orc dependency (read-request)
	"crypto/sha1"     // orc dependency (upgrade)
	"encoding/base64" // orc dependency (upgrade)
	"encoding/binary" // orc dependency (read-frame, write-json)
	"encoding/json"   // orc dependency (write-json)
	"errors"          // orc dependency (read-frame)
	"fmt"             // orc dependency (upgrade)
	"io"              // orc dependency (read-frame)
	"net/http"        // orc dependency (read-request)
	"strings"         // orc dependency (upgrade)
	"time"            // orc dependency (read-request, upgrade, write-json)
EOF
