#!/usr/bin/env bash

# Script for installing TAC node, configuring, and setting up as a service

# Uncomment the next line when debugging
# set -x

# Check that there isn't already an install folder
if [[ -d ~/.tac ]]
then
  echo "*** The ~/.tac folder already exists. Have you previously installed TAC? ***"
  exit 1
fi

# Check if Java is installed - if not, install it
REQUIRED_PKG="openjdk-8-jre"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo "Checking if $REQUIRED_PKG is installed: $PKG_OK"
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get install $REQUIRED_PKG
fi
echo

# Make .tac folder in home directory
mkdir ~/.tac
cd ~/.tac

# Download latest .jar file
echo -e "Downloading the TAC node jar file..."
if wget "https://network.tactokens.com/downloads/tac-latest.jar"; then
  echo "TAC jar file downloaded succesfully"
else
  echo "Failed to download the TAC jar file - tell Bruce.\nExiting."
  exit 1
fi

# Just to be safe, backup any existing conf file
if [[ -f "./tac.conf" ]]; then
  mv tac.conf tac.bak
fi
touch tac.config

# Get input from user for config file

PORT="6864"
NAME="myNode$((RANDOM%8999+1000))"
NONCE=$((RANDOM%8999+1000))
DECLAREDADDRESS="127.0.0.1"
PEEREXCHANGE="yes"
ENABLE="yes"
APIENABLE="no"
APIPORT="6869"
APIKEYHASH="replace with your API Key Hash"
SEED=""
PASSWORD=""

echo -e "\nInstallation of the TAC node requires you to provide a few configuration"
echo -e "details. If in doubt, just press enter to accept the default."

echo -e "\nYour node requires a node name. This is how the rest of the network"
echo -e "identifies your specific node."
read -e -i "$NAME" -p "A name to identify your node: " input
NAME="${input:-$NAME}"

echo -e "\nIf you wish your node to be a public node others can connect to, you need to"
echo -e "change your declared address to your public IP. Being public is not required"
echo -e "for mining nor node operaction, however it does help strengthen the network"
echo -e "by allowing others to sync with your node."
read -e -i "$DECLAREDADDRESS" -p "The declared address of your node: " input
DECLAREDADDRESS="${input:-$DECLAREDADDRESS}"

read -e -i "$PORT" -p "The port your node will listen on: " input
PORT="${input:-$PORT}"

echo
read -e -i "$ENABLE" -p "Change this to no if you do not want your node to mine: " input
ENABLE="${input:-$ENABLE}"
if [[ "$ENABLE" == "yes" ]] || [[ "$ENABLE" == "Yes" ]] || [[ "$ENABLE" == "YES" ]] || [[ "$ENABLE" == "y" ]] || [[ "$ENABLE" == "Y" ]]
then
  ENABLE="yes"
else
  ENABLE="no"
fi

# *** Add API enable section later, for now let's just leave it at 'no'

echo -e "\nNow for the tricky part. You will be adding your wallet seed."
echo -e "You can find this in the TAC wallet."
read -e -i "$SEED" -p "Your wallet seed: " input
SEED="${input:-$SEED}"

echo -e "\nFinally, provide a password, which should be unique and different from the one"
echo -e "used during your desktop wallet creation."
read -e -i "$PASSWORD" -p "Your node password: " input
PASSWORD="${input:-$PASSWORD}"

# Create conf file
CONF="tac {
  directory = \"./node\"
  data-directory = \"./node/data\"
  blockchain {
    type: MAINNET
  }
  network {
    bind-address = \"0.0.0.0\"
    port = \"${PORT}\"
    node-name = \"${NAME}\"
    declared-address = \"${DECLAREDADDRESS}:${PORT}\"
    known-peers = [\"198.23.213.66:6860\",\"198.23.213.67:6864\",\"192.227.210.138:6860\",\"23.95.84.10:6860\",\"192.227.210.142:6864\"]
    nonce = \"${NONCE}\"
    enable-peers-exchange = "${PEEREXCHANGE}"
  }
  miner {
    enable = $ENABLE
    interval-after-last-block-then-generation-is-allowed = 1d
    max-transactions-in-micro-block = 500
    micro-block-interval = 10000ms
    min-micro-block-age = 0s
    quorum = 3
  }
  rest-api {
    enable = ${APIENABLE}
    cors = no
    bind-address = \"127.0.0.1\"
    port = ${APIPORT}
    api-key-hash = \"${APIKEYHASH}\"
  }
  wallet {
    seed = \"${SEED}\"
    password = \"${PASSWORD}\"
  }
  synchronization {
    #increase the value below if your node stops earning or auto-forks
    max-rollback: 1000
  }
}"

echo -e "${CONF}" >> tac.config

# Create TAC run file (replace with service later)

RUNTAC="#!/bin/bash
java -jar tac-latest.jar tac.config 2>&1 | tee mainnet-log-$(date '+%Y-%m-%d-%H-%M').txt"

echo -e "${RUNTAC}" > run-tac.sh
chmod +x run-tac.sh

echo -e "\nInstallation is complete. You can run the node with:"
echo -e "cd ~/.tac"
echo -e "./run-tac.sh"


