#!/bin/sh

echo "Fetching upstream version from GitHub API..." >&2
# Fetch all releases data
upstream_data=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases)

# Log the raw upstream data
echo "Raw upstream data: $upstream_data" >&2

# Extract the latest pre-release tag (or stable release if preferred)
upstream=$(echo "$upstream_data" | jq -r 'map(select(.prerelease == true)) | .[0].tag_name')

if [ -z "$upstream" ]; then
    echo "No pre-releases found, checking stable releases..." >&2
    upstream=$(echo "$upstream_data" | jq -r '.[0].tag_name')
fi

echo "Upstream version is: $upstream" >&2

# Extract local version
local=$(grep -oP 'version = "\K[^"]+' flake.nix)
echo "Current version (local) is: $local" >&2

# Compare versions and set GitHub Actions outputs
if [ "$upstream" != "$local" ]; then
    echo "new_version=true" >>"$GITHUB_OUTPUT"
    echo "upstream=$upstream" >>"$GITHUB_OUTPUT"
fi

# Output the upstream version for debugging
echo "$upstream"
