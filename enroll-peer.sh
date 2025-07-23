#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client}
command=${command:-fabric-ca-client enroll -u http://$ENROLL_ID:$ENROLL_PW@localhost:7054 --mspdir $FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
command_json=$(jq -n --arg cmd "$command" '{command: $cmd}')
source=${source:-$FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
destination=${dest:-$CORE_PEER_MSPCONFIGPATH}
path_json=$(jq -n --arg src "$source" --arg dest "$destination" '{sourcePath: $src, destinationPath: $dest}')

# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d "$command_json"

# --- Copy MSP files ---
echo "Copying MSP files from $source to $dest..."
curl -X POST $CA_URL/copy-msp \
    -H "Content-Type: application/json" \
    -d "$path_json"

# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start
