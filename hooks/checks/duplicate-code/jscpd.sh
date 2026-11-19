#!/bin/sh
set -e
. "$(dirname "$0")/../../_env.sh"

import_statement='import[^;]*;'

require_binary "$jscpd_binary" jscpd

package_sources() {
    if [ -d "$1/src" ]; then
        echo "$1/src"
    else
        service_sources "$1"
    fi
}

for package in $services $node_packages; do
    if ! "$jscpd_binary" $(package_sources "$package") \
        --threshold 0 \
        --ignore-pattern "$import_statement" \
        --reporters console \
        --silent; then
        echo "pre-commit: duplicated code in $package - reuse it," >&2
        echo "pre-commit: do not copy it" >&2
        exit 1
    fi
done
