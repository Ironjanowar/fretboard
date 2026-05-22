#!/bin/bash
set -e
echo "Deploying Fretboard..."
git pull
docker compose build
docker compose up -d
echo "Fretboard is running on port ${PORT:-4000}"
