#!/bin/bash
set -e
echo "Building Fretboard Docker image..."
docker compose build
echo "Done!"
