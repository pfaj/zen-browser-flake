#!/usr/bin/env bash

# Resolve the directory containing this script
script_dir="$(dirname -- "$0")"

# Initialize variables
upstream="null"
max_attempts=10
attempts=1

# Retry logic to determine new upstream version
while [ "$upstream" == "null" ]; do
    echo "[attempt #${attempts}] Fetching upstream version..."
    upstream=$("$script_dir/new-version.sh")

    if [ "$upstream" != "null" ]; then
        break
    elif [ $attempts -ge $max_attempts ]; then
        echo "Error: Unable to determine new upstream version after $max_attempts attempts"
        exit 1
    fi

    echo "[attempt #${attempts}] Unable to determine new upstream version, retrying in 5 seconds..."
    attempts=$((attempts + 1))
    sleep 5
done

# Sanity check to confirm upstream version
if [ "$upstream" == "null" ]; then
    echo "Error: Unable to determine new upstream version"
    exit 1
fi

echo "Updating to version: $upstream"

# Base URL for downloading release assets
base_url="https://github.com/zen-browser/desktop/releases/download/$upstream"

# Modify the version in flake.nix
flake_file="./flake.nix"
sed -i "s/version = \".*\"/version = \"$upstream\"/" "$flake_file"

# Update specific.sha256
specific=$(nix-prefetch-url --type sha256 --unpack "$base_url/zen.linux-specific.tar.bz2")
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch SHA256 for linux-specific"
    exit 1
fi
sed -i "s/specific.sha256 = \".*\"/specific.sha256 = \"$specific\"/" "$flake_file"

# Update generic.sha256
generic=$(nix-prefetch-url --type sha256 --unpack "$base_url/zen.linux-generic.tar.bz2")
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch SHA256 for linux-generic"
    exit 1
fi
sed -i "s/generic.sha256 = \".*\"/generic.sha256 = \"$generic\"/" "$flake_file"

# Update the flake lock file and build the project
nix flake update
if [ $? -ne 0 ]; then
    echo "Error: Failed to update nix flake"
    exit 1
fi

nix build
if [ $? -ne 0 ]; then
    echo "Error: Failed to build with nix"
    exit 1
fi

echo "Successfully updated to version $upstream"
