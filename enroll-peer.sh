#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/fabric-ca-client/$ENROLL_ID/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client/}
command=${command:-fabric-ca-client enroll -u http://$ENROLL_ID:$ENROLL_PW@localhost:7054 --mspdir $MSP_DIR}
command_json=$(jq -n --arg cmd "$command" '{command: $cmd}')
source=${source:-/app/data/fabric-ca-client/$ENROLL_ID}
zip_json=$(jq -n --arg src "$source" '{sourceFolder: $src, zipPath: ($src+".zip")}')
destination=${destination:-/app/data/$ENROLL_ID}
path_json=$(jq -n --arg src "$CA_URL$source.zip" --arg dest "$destination" '{sourcePath: $src, destinationPath: $dest}')

# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d "$command_json" 
# ENROLL_PID=$!
# wait $ENROLL_PID

# --- Sync folders to be exposed ---
# echo "Exposing $source..."
# curl -X GET $CA_URL/mkdir/$ENROLL_ID
curl -I $CA_URL/app/data/fabric-ca-client
# --- Copy MSP files ---

echo "Zipping MSP files from $source..."
curl -X POST $CA_URL/zip-folder \
    -H "Content-Type: application/json" \
    -d "$zip_json" 
# ZIP_PID=$!
# wait $ZIP_PID

curl -I $CA_URL$source.zip
curl -o /app/data/$ENROLL_ID/$ENROLL_ID.zip $CA_URL$source.zip
if test -f /app/data/$ENROLL_ID.zip; then echo "ok"; else echo "no sad"; fi
unzip -o /app/data/$ENROLL_ID.zip
# echo "Copying MSP files from $CA_URL$source.zip to $destination..."
# curl -X POST $CA_URL/copy-msp \
#     -H "Content-Type: application/json" \
#     -d "$path_json" 
# # COPY_PID=$!
# # wait $COPY_PID
if test -d /app/data/$ENROLL_ID/msp; then echo "ok"; else echo "no sad"; fi
# ls
# echo "Copied MSP files from $CA_URL$source.zip to $destination!"
# if test -d /app/peer1; then echo "ok"; else echo "no sad"; fi
# ls /app
# --- Start the peer ---
# echo "🚀 Starting Fabric peer..."
# peer node start
