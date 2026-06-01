#!/bin/sh
set -e

echo "==> Running init (base schema) migrations..."
yarn migration:run:init

echo "==> Running pre-deploy migrations..."
yarn migration:run:pre-deploy

echo "==> Running post-deploy migrations..."
yarn migration:run:post-deploy

echo "==> All migrations complete."
