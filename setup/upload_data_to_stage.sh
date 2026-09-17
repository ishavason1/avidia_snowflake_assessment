#!/bin/bash

set -e

echo "Uploading CSV files to Snowflake stage..."

# Upload files directly (stage will be created if doesn't exist)
snow stage upload --remote-stage @RAW_DATA_STAGE \
  --local-path data/ \
  --overwrite \
  --recursive

echo "✓ Files uploaded to @RAW_DATA_STAGE"
