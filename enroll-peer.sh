#!/bin/sh

# Exit on any error
set -e

# --- CONFIGURATION ---
CA_URL=${CA_URL:-github-fabric-ca}
ENROLL_ID=${ENROLL_ID:-peer1}
ENROLL_PW=${ENROLL_PW:-peer1pw}
MSP_DIR=${MSP_DIR:-/app/data/msp}
FABRIC_CA_CLIENT_HOME=${FABRIC_CA_CLIENT_HOME:-/app/data/fabric-ca-client}
# TLS_CERT_PATH=${TLS_CERT_PATH:-$FABRIC_CA_CLIENT_HOME/ca-cert.pem}

# --- Wait for the CA to be reachable ---
echo "⏳ Waiting for Fabric CA at $CA_URL..."
until curl -s --head "$CA_URL" | grep "200 OK" > /dev/null; do
  sleep 2
done
echo "✅ Fabric CA is reachable."

# --- Setup Directories ---
mkdir -p "$FABRIC_CA_CLIENT_HOME"
mkdir -p "$MSP_DIR"

# # --- Download TLS CA cert ---
# echo "⬇️  Downloading CA certificate..."
# curl -s "$CA_URL/cainfo" | jq -r .result.CAChain > "$TLS_CERT_PATH"

# --- Export required environment ---
export FABRIC_CA_CLIENT_HOME
# export FABRIC_CA_CLIENT_TLS_CERTFILES="$TLS_CERT_PATH"

# --- Enroll the peer identity ---
echo "🔐 Enrolling peer with Fabric CA..."
fabric-ca-client enroll \
  -u http://$ENROLL_ID:$ENROLL_PW@${CA_URL#http://} \
  --mspdir "$MSP_DIR"

# --- Start the peer ---
echo "🚀 Starting Fabric peer..."
peer node start
