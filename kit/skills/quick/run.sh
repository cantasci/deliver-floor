#!/usr/bin/env bash
# This command's entry (its own file: a permission rule cannot name a path with "..").
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../deliver/bin/slash.sh" "$@"
