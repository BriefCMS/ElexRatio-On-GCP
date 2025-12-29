#!/bin/bash
set -e

# Marketplace validator calls this script.
# We delegate to the real deploy script.

exec /bin/deploy.sh "$@"
