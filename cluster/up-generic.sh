#!/usr/bin/env bash
export COMPOSE_PROJECT_NAME=plebnet-playground-cluster

if [ -z "$TRIPLET" ]; then
    count=5
else
    count=$1
fi
echo "Auto Detect"
    if [ "$(uname -m)" == "arm64" ]; then
        echo "ARM Chip found"
        if [ "$(sysctl -n machdep.cpu.brand_string)" == "Apple M1" ]; then
            echo "M1 ARM detected"
            export TRIPLET="aarch64-linux-gnu"
        else
            export TRIPLET="arm64-linux-gnu"
        fi
    elif [ "$(uname -m)" == "x86_64" ]; then
        #echo 'You must provide TRIPLET as first parameter'
        #echo './install.sh x86_64-linux-gnu'
        export TRIPLET="x86_64-linux-gnu"
    fi
# : ${TRIPLET:=x86_64-linux-gnu}
lnd=$count
echo "lnd Count:"  $lnd

bitcoincount=$(expr ${lnd} / 2 + 1)
bitcoind=$bitcoincount
echo "bitcoind Count:"  $bitcoind
torcount=$(expr ${lnd} / 16 + 1)
tor=$torcount
echo "tor Count:"  $tor
$(which python3) plebnet_generate.py TRIPLET=$TRIPLET bitcoind=$bitcoind lnd=$lnd tor=$tor

#Remove
docker compose down || docker-compose down

#Create data directories
mkdir -p volumes

#REF: https://docs.docker.com/engine/install/linux-postinstall
while ! docker system info > /dev/null 2>&1; do
    echo "Waiting for docker to start..."
    if [[ "$(uname -s)" == "Linux" ]]; then
        systemctl restart docker
    fi
    if [[ "$(uname -s)" == "Darwin" ]]; then
        open --background -a /./Applications/Docker.app/Contents/MacOS/Docker
    fi

    sleep 1;
done

for (( i=0; i<=$bitcoind-1; i++ ))
do
    mkdir -p volumes/bitcoin_datadir_$i
done
for (( i=0; i<=$lnd-1; i++ ))
do
    mkdir -p volumes/lnd_datadir_$i
done
for (( i=0; i<=$tor-1; i++ ))
do
    mkdir -p volumes/tor_datadir_$i
    mkdir -p volumes/tor_servicesdir_$i
    mkdir -p volumes/tor_torrcdir_$i
done

docker compose build $PARALLEL $NOCACHE --build-arg TRIPLET=$TRIPLET || docker-compose build $PARALLEL $NOCACHE --build-arg TRIPLET=$TRIPLET
docker compose -p plebnet-playground-cluster up --remove-orphans -d || docker-compose -p plebnet-playground-cluster up --remove-orphans -d
