#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/fabric-ca-client/$ENROLL_ID/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client/}
csrNames=${csrNames:-"C=US,ST=California,L=San Francisco,O=upmo,OU=peer"}
command=${command:-fabric-ca-client enroll -u http://$ENROLL_ID:$ENROLL_PW@github-fabric-ca.railway.internal:7054 --mspdir $MSP_DIR --csr.hosts $ENROLL_ID,github-fabric-ca.railway.internal --csr.names $csrNames}
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
    -d "$command_json" &
ENROLL_PID=$!
wait $ENROLL_PID

# --- Sync folders to be exposed ---
# echo "Exposing $source..."
# curl -X GET $CA_URL/mkdir/$ENROLL_ID
# --- Copy MSP files ---

echo "Zipping MSP files from $source..."
curl -X POST $CA_URL/zip-folder \
    -H "Content-Type: application/json" \
    -d "$zip_json"  &
ZIP_PID=$!
wait $ZIP_PID

# if test -f /app/data/$ENROLL_ID.zip; then echo "ok"; else echo "no sad"; fi
mkdir -p /app/data/$ENROLL_ID
curl -o /app/data/$ENROLL_ID/$ENROLL_ID.zip $CA_URL$source.zip &
COPY_PID=$!
wait $COPY_PID

unzip -o /app/data/$ENROLL_ID/$ENROLL_ID.zip -d /app/data/$ENROLL_ID/ &
UNZIP_PID=$!
wait $UNZIP_PID
rm -r /app/data/$ENROLL_ID/$ENROLL_ID.zip

zip_json=$(jq -n --arg src "/app/data/fabric-ca-client/$ADMIN_ID/msp/signcerts" '{sourceFolder: $src, zipPath: ($src+".zip")}')
echo "Zipping MSP files..."
curl -X POST $CA_URL/zip-folder \
    -H "Content-Type: application/json" \
    -d "$zip_json"  &
ZIP_PID=$!
wait $ZIP_PID

mkdir -p /app/data/$ENROLL_ID/msp/admincerts
curl -o /app/data/$ENROLL_ID/msp/admincerts/admincerts.zip $CA_URL/app/data/fabric-ca-client/$ADMIN_ID/msp/signcerts.zip &
ADMIN_PID=$!
wait $ADMIN_PID

unzip -o /app/data/$ENROLL_ID/msp/admincerts/admincerts.zip -d /app/data/$ENROLL_ID/msp/admincerts &
UNZIP_PID=$!
wait $UNZIP_PID
rm -r /app/data/$ENROLL_ID/msp/admincerts/admincerts.zip

# echo "Copying MSP files from $CA_URL$source.zip to $destination..."
# curl -X POST $CA_URL/copy-msp \
#     -H "Content-Type: application/json" \
#     -d "$path_json" 
# # COPY_PID=$!
# # wait $COPY_PID
# if test -d /app/data/$ENROLL_ID/msp; then echo "ok"; else echo "no sad"; fi
# ls
# echo "Copied MSP files from $CA_URL$source.zip to $destination!"
# if test -d /app/peer1; then echo "ok"; else echo "no sad"; fi
# ls /app
# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start
