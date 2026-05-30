#!/bin/sh
set -e
mkdir -p /var/dex && touch /var/dex/dex.db
envsubst < /etc/dex/config.template.yaml > /etc/dex/config.yaml
exec /usr/local/bin/dex serve /etc/dex/config.yaml
