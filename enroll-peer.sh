#!/bin/sh

# Exit on any error
set -e

# curl -v http://github-fabric-ca.railway.internal:8000/health 

# --- CONFIGURATION ---
CA_URL=${CA_URL:-http://github-fabric-ca.railway.internal:8000}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client}
customCmd=${customCmd:---csr.hosts $RAILWAY_SERVICE_NAME,$RAILWAY_PRIVATE_DOMAIN --csr.names C=US,ST=California,L=SanFrancisco,O=upmo,OU=peer}
enroll_json=$(jq -n --arg id "$ENROLL_ID" --arg pw "$ENROLL_PW" --arg cmd "$customCmd" '{userId: $id, userPw: $pw, customCmd: $cmd}')
zip_json=$(jq -n --arg src "$FABRIC_CA_CLIENT_HOME/$ENROLL_ID" '{sourceFolder: $src, zipPath: ($src+".zip")}')
clean_json=$(jq -n --arg script "clean-zip.sh" --arg folder "$FABRIC_CA_CLIENT_HOME/$ENROLL_ID/$ENROLL_ID.zip" '{"shellScript": $script, "envVar": {"CLEAN_ID_ZIP": $folder}}')

# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
curl -X POST $CA_URL/enroll \
    -H "Content-Type: application/json" \
    -d "$enroll_json"

sleep 5

# generate nodeOUs
MSP_DIR=${MSP_DIR:-$FABRIC_CA_CLIENT_HOME/$ENROLL_ID/msp}
CA_CERT_FILE=${CA_CERT_FILE:-cacerts/ca-cert.pem}
nodeou_json=$(jq -n --arg script "nodeOU-create.sh" --arg msp "$MSP_DIR" --arg cert "$CA_CERT_FILE" '{"shellScript": $script, "envVar": {"MSP_DIR": $msp, "CA_CERT_FILE": $cert}}')
curl -X POST $CA_URL/invoke-script \
    -H "Content-Type: application/json" \
    -d "$nodeou_json"

sleep 5

echo "Zipping MSP files from $FABRIC_CA_CLIENT_HOME/$ENROLL_ID ..."
curl -X POST $CA_URL/zip-folder \
    -H "Content-Type: application/json" \
    -d "$zip_json"

sleep 5

echo "copying from $CA_URL to local peer container..."
mkdir -p $FABRIC_CA_CLIENT_HOME/$ENROLL_ID
curl -o $FABRIC_CA_CLIENT_HOME/$ENROLL_ID/$ENROLL_ID.zip $CA_URL$FABRIC_CA_CLIENT_HOME/$ENROLL_ID.zip

sleep 5

echo "deleting zip file from $CA_URL..."
curl -X POST $CA_URL/invoke-script \
    -H "Content-Type: application/json" \
    -d "$clean_json"

echo "deleting zip file from local peer container..."
unzip -o $FABRIC_CA_CLIENT_HOME/$ENROLL_ID/$ENROLL_ID.zip -d $FABRIC_CA_CLIENT_HOME/$ENROLL_ID/

rm -r $FABRIC_CA_CLIENT_HOME/$ENROLL_ID/$ENROLL_ID.zip

# invoke script transfer file to storage
SOURCE_URL=${SOURCE_URL:-http://github-fabric-ca.railway.internal:8000}
SOURCE_FOLDER=${SOURCE_FOLDER:-$FABRIC_CA_CLIENT_HOME/$ENROLL_ID}
FOLDER_NAME=$ENROLL_ID
temp_URL=${temp_URL:-http://fabric-tools-storage.railway.internal:8080}
transfer_json=$(jq -n --arg script "transfer-file.sh" --arg url "$SOURCE_URL" --arg folder "$SOURCE_FOLDER" --arg name "$FOLDER_NAME" '{"shellScript": $script, "envVar": {"SOURCE_URL": $url, "SOURCE_FOLDER": $folder, "FOLDER_NAME": $name}}')
echo "Transferring files to storage..."
curl -X POST $temp_URL/invoke-script \
    -H "Content-Type: application/json" \
    -d "$transfer_json"

# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start