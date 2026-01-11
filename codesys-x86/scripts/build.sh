#!/bin/bash
#
# Build multi-architecture Docker images for CODESYS Control for Linux (x86)
#
# This script builds Docker images for both linux/amd64 and linux/386 architectures
# using Docker Buildx
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/YOUR_ORG/codesys-control-x86}"
CODESYS_VERSION="${CODESYS_VERSION:-3.5.19.0}"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Parse arguments
PUSH="${1:-false}"
TAG="${2:-latest}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CODESYS Control x86 Multi-Arch Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Image: $IMAGE_NAME"
echo "Tag: $TAG"
echo "Version: $CODESYS_VERSION"
echo "Platforms: linux/amd64, linux/386"
echo "Push to registry: $PUSH"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Error: Docker Buildx is not available${NC}"
    echo "Please install Docker Buildx or use Docker Desktop"
    exit 1
fi

# Create or use existing buildx builder
BUILDER_NAME="codesys-x86-builder"
if ! docker buildx inspect "$BUILDER_NAME" &> /dev/null; then
    echo -e "${YELLOW}Creating new buildx builder: $BUILDER_NAME${NC}"
    docker buildx create --name "$BUILDER_NAME" --use --platform linux/amd64,linux/386
else
    echo -e "${GREEN}Using existing buildx builder: $BUILDER_NAME${NC}"
    docker buildx use "$BUILDER_NAME"
fi

# Bootstrap the builder
echo "Bootstrapping builder..."
docker buildx inspect --bootstrap

# Navigate to project root
cd "$(dirname "$0")/.."

# Build arguments
BUILD_ARGS=(
    "--build-arg" "CODESYS_VERSION=${CODESYS_VERSION}"
    "--build-arg" "BUILD_DATE=${BUILD_DATE}"
    "--build-arg" "VCS_REF=${VCS_REF}"
    "--platform" "linux/amd64,linux/386"
    "--tag" "${IMAGE_NAME}:${TAG}"
    "--tag" "${IMAGE_NAME}:${CODESYS_VERSION}"
)

# Add labels
BUILD_ARGS+=(
    "--label" "org.opencontainers.image.created=${BUILD_DATE}"
    "--label" "org.opencontainers.image.version=${CODESYS_VERSION}"
    "--label" "org.opencontainers.image.revision=${VCS_REF}"
    "--label" "org.opencontainers.image.title=CODESYS Control for Linux (x86)"
    "--label" "org.opencontainers.image.description=CODESYS PLC Runtime for x86 architectures (amd64/386)"
)

# Determine push or load
if [[ "$PUSH" == "true" ]]; then
    echo -e "${YELLOW}Building and pushing to registry...${NC}"
    BUILD_ARGS+=("--push")
else
    echo -e "${YELLOW}Building for local use only (not pushing)${NC}"
    echo -e "${YELLOW}Note: Multi-arch images cannot be loaded locally. Use --push to push to registry.${NC}"
    BUILD_ARGS+=("--output" "type=image,push=false")
fi

# Build the image
echo ""
echo -e "${GREEN}Starting build...${NC}"
echo "Command: docker buildx build ${BUILD_ARGS[*]} ."
echo ""

if docker buildx build "${BUILD_ARGS[@]}" .; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Image tags:"
    echo "  - ${IMAGE_NAME}:${TAG}"
    echo "  - ${IMAGE_NAME}:${CODESYS_VERSION}"
    echo ""
    
    if [[ "$PUSH" == "true" ]]; then
        echo -e "${GREEN}Images pushed to registry${NC}"
        echo ""
        echo "To pull the image:"
        echo "  docker pull ${IMAGE_NAME}:${TAG}"
        echo ""
        echo "To inspect the manifest:"
        echo "  docker buildx imagetools inspect ${IMAGE_NAME}:${TAG}"
    else
        echo -e "${YELLOW}Images built but not pushed${NC}"
        echo ""
        echo "To push to registry, run:"
        echo "  $0 true ${TAG}"
    fi
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Build failed!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
