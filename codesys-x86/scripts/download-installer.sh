#!/bin/bash
#
# Download CODESYS Control for Linux installer from GitHub releases
#
# Usage: ./download-installer.sh <architecture> <version>
#   architecture: x64 or x86
#   version: e.g., 3.5.19.0
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GITHUB_ORG="${GITHUB_ORG:-YOUR_ORG}"
GITHUB_REPO="${GITHUB_REPO:-YOUR_REPO}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-./installers}"

# Parse arguments
ARCH="${1:-x64}"
VERSION="${2:-3.5.19.0}"

# Validate architecture
if [[ "$ARCH" != "x64" && "$ARCH" != "x86" ]]; then
    echo -e "${RED}Error: Invalid architecture '$ARCH'. Must be 'x64' or 'x86'${NC}"
    exit 1
fi

# Create download directory
mkdir -p "$DOWNLOAD_DIR"

# Construct download URL
# Expected format: codesyscontrol-linux-<arch>-<version>.tar.gz
FILENAME="codesyscontrol-linux-${ARCH}-${VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/v${VERSION}/${FILENAME}"

echo -e "${GREEN}Downloading CODESYS Control for Linux${NC}"
echo "Architecture: $ARCH"
echo "Version: $VERSION"
echo "URL: $DOWNLOAD_URL"
echo "Destination: ${DOWNLOAD_DIR}/${FILENAME}"
echo ""

# Download with wget (with retry and progress)
if ! wget -c -O "${DOWNLOAD_DIR}/${FILENAME}" "$DOWNLOAD_URL"; then
    echo -e "${RED}Error: Failed to download installer${NC}"
    echo -e "${YELLOW}Please ensure:${NC}"
    echo "  1. The release version v${VERSION} exists in the GitHub repository"
    echo "  2. The installer file '${FILENAME}' is uploaded to the release"
    echo "  3. You have network connectivity to GitHub"
    echo "  4. The GITHUB_ORG and GITHUB_REPO variables are set correctly"
    exit 1
fi

# Verify download
if [[ ! -f "${DOWNLOAD_DIR}/${FILENAME}" ]]; then
    echo -e "${RED}Error: Download failed - file not found${NC}"
    exit 1
fi

FILE_SIZE=$(stat -f%z "${DOWNLOAD_DIR}/${FILENAME}" 2>/dev/null || stat -c%s "${DOWNLOAD_DIR}/${FILENAME}" 2>/dev/null)
if [[ "$FILE_SIZE" -lt 1000000 ]]; then
    echo -e "${YELLOW}Warning: Downloaded file is smaller than expected (${FILE_SIZE} bytes)${NC}"
    echo "This might indicate an incomplete download or incorrect file."
fi

echo -e "${GREEN}Successfully downloaded installer to ${DOWNLOAD_DIR}/${FILENAME}${NC}"
echo "File size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo ${FILE_SIZE} bytes)"

# Optional: Verify checksum if available
CHECKSUM_FILE="${DOWNLOAD_DIR}/${FILENAME}.sha256"
CHECKSUM_URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/v${VERSION}/${FILENAME}.sha256"

if wget -q -O "$CHECKSUM_FILE" "$CHECKSUM_URL" 2>/dev/null; then
    echo ""
    echo "Verifying checksum..."
    if sha256sum -c "$CHECKSUM_FILE" 2>/dev/null; then
        echo -e "${GREEN}Checksum verification passed${NC}"
    else
        echo -e "${YELLOW}Warning: Checksum verification failed${NC}"
    fi
else
    echo -e "${YELLOW}Note: No checksum file available for verification${NC}"
fi

echo ""
echo -e "${GREEN}Download complete!${NC}"
