#!/bin/sh
set -e
mkdir -p /var/dex && touch /var/dex/dex.db
export DEX_ADMIN_PASSWORD_HASH=$(/usr/local/bin/dex bcrypt-hash "$DEX_ADMIN_PASSWORD")
envsubst < /etc/dex/config.template.yaml > /etc/dex/config.yaml
exec /usr/local/bin/dex serve /etc/dex/config.yaml
