#!/bin/sh
set -e

echo "==> Running pre-deploy migrations..."
yarn migration:run:pre-deploy

echo "==> Running init migrations..."
yarn migration:run:init

echo "==> Running post-deploy migrations..."
yarn migration:run:post-deploy

echo "==> All migrations complete."
