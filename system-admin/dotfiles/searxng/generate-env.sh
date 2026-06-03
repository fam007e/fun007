#!/bin/bash

# ==============================================================================
# SearXNG .env Generator
# Generates a secure, standardized .env file with a unique secret key.
# ==============================================================================

ENV_FILE=".env"
PORT=${1:-8888}
BASE_URL=${2:-"http://localhost:$PORT/"}

# Generate a 32-byte hex secret key
SECRET_KEY=$(openssl rand -hex 32)

echo "Generating $ENV_FILE..."

cat <<EOF > "$ENV_FILE"
# Read the documentation before using the \`docker-compose.yml\` file:
# https://docs.searxng.org/admin/installation-docker.html
#
# Additional ENVs:
# https://docs.searxng.org/admin/settings/settings_general.html#settings-general
# https://docs.searxng.org/admin/settings/settings_server.html#settings-server

# Use a specific version tag. E.g. "latest" or "2026.3.25-541c6c3cb".
#SEARXNG_VERSION=latest

# Listen to a specific address.
#SEARXNG_HOST=[::]

# Listen to a specific port.
SEARXNG_PORT=$PORT

SEARXNG_SECRET_KEY=$SECRET_KEY
SEARXNG_BASE_URL=$BASE_URL
EOF

chmod 600 "$ENV_FILE"

echo "Done! Secure .env generated with PORT=$PORT."
echo "Secret Key: $SECRET_KEY"
