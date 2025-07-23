#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client}
command=${command:-fabric-ca-client enroll -u http://$ENROLL_ID:$ENROLL_PW@localhost:7054 --mspdir $FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
command_json=$(jq -n --arg cmd $command '{command: $cmd}')
source=${source:-$FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
source_json=$(jq -n --arg cmd $source '{sourcePath: $cmd}')
dest=${dest:-$CORE_PEER_MSPCONFIGPATH}
dest_json=$(jq -n --arg cmd $dest '{destinationPath: $cmd}')
# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# --- Wait for the CA to be reachable ---
# echo "⏳ Waiting for Fabric CA at $CA_URL..."
# until curl -s --head "$CA_URL/cainfo" | grep "200 OK" > /dev/null; do
#   sleep 2
# done
# echo "✅ Fabric CA is reachable."

# --- Setup Directories ---
# mkdir -p "$FABRIC_CA_CLIENT_HOME"
# mkdir -p "$MSP_DIR"

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Export required environment ---
export FABRIC_CA_CLIENT_HOME
# export FABRIC_CA_CLIENT_TLS_CERTFILES="$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d $command_json

# --- Copy MSP files ---
echo "Copying MSP files..."
curl -X POST $CA_URL/copy-msp \
    -H "Content-Type: application/json" \
    -d $source_json, $dest_json

# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start
