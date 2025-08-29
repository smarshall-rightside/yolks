#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $(NF-2);exit}'`

FRAMEWORK_TYPE="vanilla"
if [[ "${FRAMEWORK}" == "carbon" ]]; then
    FRAMEWORK_TYPE="carbon"
elif [[ "${OXIDE}" == "1" ]] || [[ "${FRAMEWORK}" == "oxide" ]]; then
    FRAMEWORK_TYPE="oxide"
fi

# Auto update Rust and selected framework if enabled
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 258550 +quit

    if [[ "${FRAMEWORK_TYPE}" == "carbon" ]]; then
        echo "Updating Carbon..."

        if [[ "${RUST_STAGING}" == "1" ]]; then
            echo "Fetching Carbon (staging build)..."
            curl -sSL "https://api.carbonmod.org/download/staging" -o carbon.zip
        else
            echo "Fetching Carbon (stable build)..."
            curl -sSL "https://api.carbonmod.org/download/latest" -o carbon.zip
        fi

        unzip -o -q carbon.zip
        rm carbon.zip
        echo "Done updating Carbon!"
    elif [[ "${FRAMEWORK_TYPE}" == "oxide" ]]; then
        echo "Updating uMod..."
        curl -sSL "https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip" > umod.zip
        unzip -o -q umod.zip
        rm umod.zip
        echo "Done updating uMod!"
    fi
else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Framework runtime configuration
if [[ "${FRAMEWORK_TYPE}" == "carbon" ]]; then
    export DOORSTOP_ENABLED=1
    export DOORSTOP_TARGET_ASSEMBLY="$(pwd)/carbon/managed/Carbon.Preloader.dll"
    MODIFIED_STARTUP="LD_PRELOAD=$(pwd)/libdoorstop.so ${MODIFIED_STARTUP}"
fi

# Fix for Rust not starting
export LD_LIBRARY_PATH=$(pwd)/RustDedicated_Data/Plugins/x86_64:$(pwd)

# Run the Server
node /wrapper.js "${MODIFIED_STARTUP}"
