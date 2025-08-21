#!/bin/sh
set -u

ports="20443 21443 22443"

while sleep 3
do
    echo "stacks-node:"
    for p in $ports
    do
        resp=$(curl -s -w "\n%{http_code}" 127.0.0.1:"$p"/v2/info)
        body=$(printf "%s" "$resp" | sed '$d')
        code=$(printf "%s" "$resp" | tail -n1)
        stats=$(printf "%s" "$body" |
            jq -r '[.stacks_tip_height, .burn_block_height, .server_version] | @tsv' |
            tr '\t' ' ')
        echo "  $p($stats) [status: $code]"
    done
    echo
done
