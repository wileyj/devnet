set -e
trap "exit" INT TERM
trap "kill 0" EXIT

DEFAULT_TIMEOUT=$(($(date +%s) + 30))
DEFINED_ADDRESSES=$(compgen -A variable | grep "STACKS.*.BTC_ADDR") # retrieve env vars matching STACKS*BTC_ADDRESS
DEFINED_WALLETS=$(compgen -A variable | grep "STACKS.*.BTC_WALLET") # retrieve env vars matching STACKS*BTC_ADDRESS
mapfile -t ADDRESSES < <(printf '%s\n' "$DEFINED_ADDRESSES" | tr ' ' '\n') # convert the compgen output to an array
mapfile -t WALLETS < <(printf '%s\n' "$DEFINED_WALLETS" | tr ' ' '\n') # convert the compgen output to an array

function get_height(){
    ## returns the current block height
    echo $(bitcoin-cli -rpcconnect=bitcoin getblockcount) 2>/dev/null || echo "Error retrieving height"
    true
}

function get_mining_info(){
    ## returns if mining_info has returned
    echo "*** Get mining info"
    bitcoin-cli -rpcconnect=bitcoin -rpcwait getmininginfo 2>/dev/null
    true
}

function mine_blocks(){
    echo "in mine_blocks"
    local wallet=${1}
    local address=${2}
    local blocks=${3}
    echo "Mining ${blocks} blocks to address ${address} in wallet ${wallet}"
    bitcoin-cli -rpcwallet=${wallet} -rpcconnect=bitcoin generatetoaddress ${blocks} ${address}
    true
}

function create_wallet(){
    echo "in create_wallet"
    local wallet=${1}
    local descriptors=${2:-false}
    local load_on_startup=${3:-true}
    echo "*** Creating named wallet ${wallet} (desciptors: ${descriptors}, load_on_startup=${load_on_startup})"
    bitcoin-cli -rpcconnect=bitcoin -named createwallet wallet_name=${wallet} descriptors=${descriptors} load_on_startup=${load_on_startup}
    true
}

function import_address(){
    echo "in import_address"
    local wallet=${1}
    local address=${2}
    local label=${3:-\"\"}
    local rescan=${4:-false}
    echo "***Importing address ${btc_address} with label ${label} to wallet ${btc_wallet} (rescan: ${rescan})"
    bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin importaddress ${btc_address} ${label} ${rescan}
    true
}

function init(){
    # init_blocks should take into account the height of 2.05 and the amount of miners we have

    ## miners 1,2 will have full balance available. miner-3 will only have a few blocks of matured rewards by the time stacks network starts at height 203
    # wait until getmininginfo returns data before continuing (this is our canary)
    while ! get_mining_info; do
        echo "Waiting for a return from bitcoin-cli getmininginfo"
        sleep 1
    done
    local mined_counter=0 # keep track of initial mined blocks
    local address_count=0 # keep track of how many addresses have an initial balance
    for i in $(seq 0 $((${#ADDRESSES[@]} - 1)));do
        local btc_address=${!ADDRESSES[$i]}
        local btc_wallet=${!WALLETS[$i]}
        create_wallet ${btc_wallet} ## create the named wallet
        import_address ${btc_wallet} ${btc_address} ## import the defined address
        mine_blocks ${btc_wallet} ${btc_address} ${INIT_BLOCKS} ## mined the initial balance used for mining
        mined_counter=$((mined_counter + INIT_BLOCKS))  ## keep track of how many blocks were mined in this stage
        echo ""
    done
    echo "mined ${mined_counter} btc to (${#ADDRESSES[@]}) stacks-miner wallets ( ${INIT_BLOCKS} per wallet)"
    echo "Mined counter: $mined_counter"
    echo "STACKS_2_05_HEIGHT: $STACKS_2_05_HEIGHT"
    echo "STACKS_2_05_HEIGHT-1:  $((STACKS_2_05_HEIGHT - 1))"
    echo "math: $(((STACKS_2_05_HEIGHT - 1) - mined_counter))"
    depositor_blocks=$(((STACKS_2_05_HEIGHT - 1) - mined_counter)) ## math to determine how many additional blocks we need to get to 202
    echo "depositor_blocks: $depositor_blocks"
    create_wallet depositor
    local depositor_addr=$(bitcoin-cli -rpcwallet=depositor -rpcconnect=bitcoin getnewaddress label="" bech32)
    mine_blocks "depositor" ${depositor_addr} ${depositor_blocks}
    true
}

function mining_loop(){
    while true; do
        local conf_counter=0
        local random_wallet=""
        local confs=""
        local random="" # for tracking which array element we're using
        local sleep_duration=${MINE_INTERVAL}
        local block_height=$(get_height) # get the block height used in the loop
        ## loop through addresses and see if there are any mining txs in the list
        for i in $(seq 0 $((${#ADDRESSES[@]} - 1)));do
            local btc_address=${!ADDRESSES[$i]}
            local btc_wallet=${!WALLETS[$i]}
            conf_counter=$(( conf_counter + confs ))
            echo="bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin listtransactions '*' 1 0 true | grep -oP '"confirmations": \K\d+' | awk '{print \$1}'"
            confs=$(bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin listtransactions '*' 1 0 true | grep -oP '"confirmations": \K\d+' | awk '{print $1}' || 2>/dev/null || echo "")
        done
        echo "  conf_counter; $conf_counter"
        echo "  date: $(date +%s)"
        echo "  DEFAULT_TIMEOUT: $DEFAULT_TIMEOUT"
        if [ "${conf_counter}" = "0" ] || [ $(date +%s) -gt $DEFAULT_TIMEOUT ]; then
            if [ $(date +%s) -gt $DEFAULT_TIMEOUT ]; then
                echo "Timed out waiting for a mempool tx, mining a btc block..."
            else
                echo "Detected Stacks mining mempool tx, mining btc block..."
            fi
            # need a static random num here. shuf won't work
            # random_wallet=$(printf "%s\n" "${WALLETS[@]}" | shuf -n 1)
            random=$((0 + $RANDOM % ${#ADDRESSES[@]} ))
            # random_wallet="${WALLETS[$random_int]}"
            echo "Mining block to ${WALLETS[$random]} with address ${ADDRESSES[$random]}"
            bitcoin-cli -rpcwallet=${WALLETS[$random]} -rpcconnect=bitcoin generatetoaddress 1 "${ADDRESSES[$random]}"
            DEFAULT_TIMEOUT=$(($(date +%s) + 30))
        else
            echo "No Stacks mining tx detected"
        fi

        if [ "${block_height}" -eq "${PAUSE_HEIGHT}" ]; then
            echo "At boundary ( ${PAUSE_HEIGHT} ) -  sleeping for ${PAUSE_TIMER}"
            sleep ${PAUSE_TIMER}
        # if we use the default snapshot, mine the next block quickly
        elif ! [[ "${CHAINSTATE_DIR}" =~ "genesis" ]] && [[ "${block_height}" -ge "242" && "${block_height}" -lt "243" ]]; then
            echo "Network resumed. sleeping for 5s for next 2 blocks (235-236)"
            sleep_duration=5
        elif [ "${block_height}" -gt $(( ${STACKS_30_HEIGHT} + 1 )) ]; then
            echo "In Epoch3, sleeping for ${MINE_INTERVAL_EPOCH3} ..."
            sleep_duration=${MINE_INTERVAL_EPOCH3}
        elif [ "${block_height}" -gt $(( ${STACKS_25_HEIGHT} + 1 )) ]; then
            echo "In Epoch2.5, sleeping for ${MINE_INTERVAL_EPOCH25} ..."
            sleep_duration=${MINE_INTERVAL_EPOCH25}
        fi

        sleep_duration=${MINE_INTERVAL}
        echo "sleeping for ${sleep_duration}"
        echo "********************************************************"
        sleep ${sleep_duration} &
        wait || exit 0
    done
    true
}

if [ $(get_height) -eq "0" ]; then
    init
fi
## mine forever
mining_loop
