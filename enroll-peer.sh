#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/$ENROLL_ID}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client}
command=${command:-fabric-ca-client enroll -u http://$ENROLL_ID:$ENROLL_PW@localhost:7054 --mspdir $MSP_DIR}
command_json=$(jq -n --arg cmd "$command" '{command: $cmd}')
source=${source:-$CA_URL$FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
zip_json=$(jq -n --arg src "$source" '{sourcePath: $src, zipPath: $src}')
destination=${destination:-$MSP_DIR}
path_json=$(jq -n --arg src "$source" --arg dest "$destination" '{sourcePath: ($src + ".zip"), destinationPath: $dest}')

# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d "$command_json"

# --- Sync folders to be exposed ---
echo "Exposing $source..."
curl -X GET $CA_URL/mkdir/$ENROLL_ID

# --- Copy MSP files ---

echo "Zipping MSP files from $source..."
curl -X POST $CA_URL/zip-folder \
    -H "Content-Type: application/json" \
    -d "$zip_json"&
ZIP_ID=$!
wait $ZIP_ID

curl -I ("$source" + ".zip")
echo "Copying MSP files from $source to $destination..."
curl -X POST $CA_URL/copy-msp \
    -H "Content-Type: application/json" \
    -d "$path_json" &
COPY_ID=$!
wait $COPY_ID
echo "Copied MSP files from $source to $destination!"
# --- Start the peer ---
# echo "🚀 Starting Fabric peer..."
# peer node start
