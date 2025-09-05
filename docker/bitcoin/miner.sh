set -e
trap "exit" INT TERM
trap "kill 0" EXIT


DEFAULT_TIMEOUT=$(($(date +%s) + 30))
DEFINED_ADDRESSES=$(compgen -A variable | grep "STACKS.*.BTC_ADDR") # retrieve env vars matching STACKS*BTC_ADDRESS
DEFINED_WALLETS=$(compgen -A variable | grep "STACKS.*.BTC_WALLET") # retrieve env vars matching STACKS*BTC_ADDRESS
mapfile -t ADDRESSES < <(printf '%s\n' "$DEFINED_ADDRESSES" | tr ' ' '\n') # convert the compgen output to an array
mapfile -t WALLETS < <(printf '%s\n' "$DEFINED_WALLETS" | tr ' ' '\n') # convert the compgen output to an array
NUM_MINERS=${#ADDRESSES[@]} # use the same value for total miners throughout script
RESERVED_BLOCKS=100 # during initial block mining, reserve 100 blocks to mine at the end so the earlier blocks have received rewards by the epoch 2.0 block


function get_height(){
    ## returns the current block height
    echo $(bitcoin-cli -rpcconnect=bitcoin getblockcount 2>/dev/null || echo "-1")
    true
}

function get_mining_info(){
    ## returns if mining_info has returned
    # echo "[func] Get mining info"
    local mining_info=""
    mining_info=$(bitcoin-cli -rpcconnect=bitcoin -rpcwait getmininginfo 2> /dev/null)
    local ret="$?"
    local chain=$(echo "${mining_info}" | awk '/chain/ { gsub(/[",]/,""); print $2}')
    if [ "$chain" == "regtest" ];then
        return 0
    fi
    return 1
}

function get_wallet_info(){
    ## returns if a wallet exists
    # if wallet db exists, but wallet is not loaded: this will lead to failure of the script since the wallet cannot be created since it is on disk but not loaded in memory
    echo "[func] Get wallet info"
    local wallet=${1}
    echo "    - checking for wallet (${wallet})"
    local getwallet=""
    local ret=""
    getwallet=$(bitcoin-cli -rpcconnect=bitcoin -rpcwait -rpcwallet=${wallet} getwalletinfo 2>&1 > /dev/null) # || return $?
    local ret=$?
    if [ "$ret" -eq "0" ]; then
        echo "    - successfully retrieved named wallet"
        true
    fi
    return $ret
}

function create_wallet(){
    echo "    [func] Create Wallet"
    local wallet=${1}
    local descriptors=${2:-false}
    local load_on_startup=${3:-true}
    echo "        - Creating named wallet ${wallet} (desciptors: ${descriptors}, load_on_startup=${load_on_startup})"
    local createwallet=$(bitcoin-cli -rpcconnect=bitcoin -named createwallet wallet_name=${wallet} descriptors=${descriptors} load_on_startup=${load_on_startup}  2>&1 > /dev/null)
    ret=$?
    if [ "$ret" -eq "0" ]; then
        echo "        - successfully created named wallet (${wallet})"
    fi
    return $ret
}

function get_address_info(){
    ## checks if an address was imported
    local wallet=${1}
    local address=${2}
    local getaddressinfo=""
    echo "    [func] Get address info"
    echo "        - Checking (${wallet}) for address (${address})"
    getaddressinfo=$(bitcoin-cli -rpcconnect=bitcoin -rpcwait -rpcwallet=${wallet} getaddressinfo ${address} 2> /dev/null)
    local ret="$?"
    local is_found=$(echo "${getaddressinfo}" | awk '/iswatchonly/ { gsub(/[",]/,""); print $2}')
    if [ "$is_found" == "true" ]; then
        echo "        - Address ${address} already imported ($is_found)"
    else
        echo "        - Address ${address} is not imported ($is_found)"
        ret=1 # force a return since the above command *was* successful, just not the data we want
    fi
    return $ret
}

function mine_blocks(){
    echo "[func] Mine blocks"
    local wallet=${1}
    local address=${2}
    local blocks=${3}
    echo "    - Mining ${blocks} blocks to address ${address} in wallet ${wallet}"
    bitcoin-cli -rpcwallet=${wallet} -rpcconnect=bitcoin generatetoaddress ${blocks} ${address} 2>&1 > /dev/null || false
    true
}

function import_address(){
    echo "    [func] import_address"
    local wallet=${1}
    local address=${2}
    local label=${3:-\"\"}
    local rescan=${4:-false}
    echo "        - address: $address"
    echo "        - wallet: $wallet"
    echo "        - Importing address ${btc_address} with label ${label} to wallet ${btc_wallet} (rescan: ${rescan})"
    bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin importaddress ${btc_address} ${label} ${rescan} 2>&1 > /dev/null || false
    true
}

function mining_loop(){
    local mined_block_counter=0 # set the counter before the loop starts
    while true; do
        echo "******************************************"
        local conf_counter=0
        local random_wallet=""
        local confs=""
        local random="" # for tracking which array element we're using
        local sleep_duration=${MINE_INTERVAL}
        local block_height=$(get_height) # get the block height used in the loop
        ## loop through addresses and see if there are any mining txs in the list
        for i in $(seq 0 $((NUM_MINERS - 1)));do
            local btc_address=${!ADDRESSES[$i]}
            local btc_wallet=${!WALLETS[$i]}
            conf_counter=$(( conf_counter + confs ))
            echo="bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin listtransactions '*' 1 0 true | grep -oP '"confirmations": \K\d+' | awk '{print \$1}'"
            confs=$(bitcoin-cli -rpcwallet=${btc_wallet} -rpcconnect=bitcoin listtransactions '*' 1 0 true | grep -oP '"confirmations": \K\d+' | awk '{print $1}' || 2>/dev/null || echo "")
        done
        if [ "${conf_counter}" = "0" ] || [ $(date +%s) -gt $DEFAULT_TIMEOUT ]; then
            if [ $(date +%s) -gt $DEFAULT_TIMEOUT ]; then
                echo "Timed out waiting for a mempool tx, mining a btc block..."
            else
                echo "Detected Stacks mining mempool tx, mining btc block..."
            fi
            random=$((0 + $RANDOM % NUM_MINERS )) # random int with a range based on how many miners are defined
            echo "Mining block to:"
            echo "    - wallet: ${!WALLETS[$random]}"
            echo "    - address: ${!ADDRESSES[$random]}"
            echo "    - block hash: $(bitcoin-cli -rpcwallet=${!WALLETS[$random]} -rpcconnect=bitcoin generatetoaddress 1 "${!ADDRESSES[$random]}" | awk -F, 'NR==2{ gsub(/[",]/,"");gsub (" ", "", $0);print $1}')"
            # bitcoin-cli -rpcwallet=${!WALLETS[$random]} -rpcconnect=bitcoin generatetoaddress 1 "${!ADDRESSES[$random]}"
            # echo "Mined: $(bitcoin-cli -rpcwallet=${!WALLETS[$random]} -rpcconnect=bitcoin generatetoaddress 1 "${!ADDRESSES[$random]}" | awk -F, 'NR==2{ gsub(/[",]/,"");gsub (" ", "", $0);print $1}')"
            mined_block_counter=$((mined_block_counter + 1 )) # increment the mined block counter
            block_height=$((block_height + 1))
            DEFAULT_TIMEOUT=$(($(date +%s) + 30))
        else
            echo "No Stacks mining tx detected"
        fi

        if [ "${block_height}" -eq "${PAUSE_HEIGHT}" ]; then
            echo "At boundary ( ${PAUSE_HEIGHT} ) -  sleeping for ${PAUSE_TIMER}"
            sleep ${PAUSE_TIMER}
        # if we use the default snapshot, mine the next blocks quickly
        elif ! [[ "${CHAINSTATE_DIR}" =~ "genesis" ]] && [[ "${mined_block_counter}" -le "2" ]]; then
            echo "Network resumed. sleeping for 5s for next 2 mined blocks"
            sleep_duration=5
        elif [ "${block_height}" -gt $(( ${STACKS_30_HEIGHT} + 1 )) ]; then
            echo "In Epoch3, sleeping for ${MINE_INTERVAL_EPOCH3} ... "
            sleep_duration=${MINE_INTERVAL_EPOCH3}
        elif [ "${block_height}" -gt $(( ${STACKS_25_HEIGHT} + 1 )) ]; then
            echo "In Epoch2.5, sleeping for ${MINE_INTERVAL_EPOCH25} ... "
            sleep_duration=${MINE_INTERVAL_EPOCH25}
        fi
        echo "Current btc height: ${block_height}"
        # echo "Current btc height: $(( block_height + 1 ))"
        echo "total mined blocks: ${mined_block_counter}"
        echo "sleeping for ${sleep_duration}s"
        sleep ${sleep_duration} &
        wait || exit 0
    done
    true
}

function init(){
    # mine the genesis blocks to epoch 2.0
    # wait until getmininginfo returns successfully before continuing (this is our canary)
    while ! get_mining_info; do
        echo "Waiting indefinitely for a return from 'bitcoin-cli getmininginfo'"
        sleep 1
    done

    local mineable_blocks=$(( (STACKS_2_05_HEIGHT - 1) - RESERVED_BLOCKS )) # calculate the total number of blocks to allocate to the defined stacks-miner wallets
    local remainder_blocks=0 # set the initial remainder as zero before calculating if there is a modulus
    local mined_counter=0 # keep track of initial mined blocks
    local address_count=0 # keep track of how many addresses have an initial balance
    blocks_per_miner=$(( mineable_blocks / NUM_MINERS )) # how many blocks per miner address
    remainder_blocks=$(( (STACKS_2_05_HEIGHT - 1) - (blocks_per_miner * NUM_MINERS + RESERVED_BLOCKS) )) # if there is a modulus, we need to mine them to the last miner address
    for i in $(seq 0 $((NUM_MINERS - 1)));do
        local btc_address=${!ADDRESSES[$i]}
        local btc_wallet=${!WALLETS[$i]}
        echo
        echo "******************************************"
        echo "btc_wallet: ${btc_wallet}"
        echo "btc_address: ${btc_address}"
        if [ "$i" -eq $((NUM_MINERS - 1)) ];then
            blocks_per_miner=$((blocks_per_miner + remainder_blocks)) # this is the last miner address. add the modulus to the defined number of blocks for all miner
        fi
        # echo "ret: $?"
        if ! get_wallet_info ${btc_wallet}; then
            ## we need to create a wallet
            if ! create_wallet ${btc_wallet}; then ## create the named wallet
                ## we failed to create the wallet, we should exit
                echo "ERROR creating wallet (${btc_wallet})"
                exit 1s
            fi
        fi
        if ! get_address_info ${btc_wallet} ${btc_address}; then
            ## if the address is not imported, try to import
            if ! import_address ${btc_wallet} ${btc_address}; then ## import the defined address
                ## failed to import the address. exit
                echo "ERROR importing address (${btc_address}) into wallet (${btc_wallet})"
                exit 1
            fi
        fi
        mine_blocks ${btc_wallet} ${btc_address} ${blocks_per_miner} ## mined the initial balance used for mining
        mined_counter=$((mined_counter + blocks_per_miner))  ## keep track of how many blocks were mined in this stage
    done
    echo ""
    echo "******************************************"
    local depositor_blocks=$(((STACKS_2_05_HEIGHT - 1) - mined_counter)) ## this should be equal to reserved_blocks (100)
    echo "btc_wallet: depositor"
    echo "btc_address: tbd"
    ## we need to create a wallet
    if ! get_wallet_info depositor; then ## create the named wallet
        if ! create_wallet depositor; then
            echo "Error creating depositor wallet"
            exit 1
        fi
        local depositor_addr=$(bitcoin-cli -rpcwallet=depositor -rpcconnect=bitcoin getnewaddress label="" bech32)
    fi
    if ! get_address_info depositor ${depositor_addr}; then
        ## if the address is not imported, try to import
        if ! import_address depositor ${depositor_addr}; then ## import the defined address
            ## failed to import the address. exit
            echo "ERROR importing address (depositor) into wallet (${depositor_addr})"
            exit 1
        fi
    fi
    mine_blocks "depositor" ${depositor_addr} ${depositor_blocks}
    echo ""
    echo "******************************************"
    echo "Mined ${mined_counter} btc to (${NUM_MINERS}) stacks-miner wallets"
    echo "Mined ${depositor_blocks} btc to (1) depositor wallet"
    echo ""
    true
}

if [ $(get_height) -eq "0" ]; then
    init
else
    echo "Skipping genesis functions"
fi
echo
echo "******************************************"
echo "****          Mining forever          ****"
echo "******************************************"
echo
mining_loop

# sleep 1000000000
