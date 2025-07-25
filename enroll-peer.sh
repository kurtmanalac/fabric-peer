#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
MSP_DIR=${MSP_DIR:-/app/data/fabric-ca-client/$ENROLL_ID/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client/}
customCmd=${customCmd:---csr.hosts $RAILWAY_SERVICE_NAME,$RAILWAY_PRIVATE_DOMAIN --csr.names C=US,ST=California,L=SanFrancisco,O=upmo,OU=peer}
enroll_json=$(jq -n --arg id "$ENROLL_ID" --arg pw "$ENROLL_PW" --arg cmd "$customCmd" '{userId: $id, userPw: $pw, customCmd: $cmd}')
source=${source:-/app/data/fabric-ca-client/$ENROLL_ID}
zip_json=$(jq -n --arg src "$source" '{sourceFolder: $src, zipPath: ($src+".zip")}')

# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d "$enroll_json" &
ENROLL_PID=$!
wait $ENROLL_PID

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

# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start
