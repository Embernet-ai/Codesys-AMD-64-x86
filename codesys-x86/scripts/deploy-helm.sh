#!/bin/bash
#
# Deploy CODESYS Control for Linux using Helm
#
# This script deploys the CODESYS runtime to a K3s cluster using Helm charts
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHART_DIR="$(dirname "$0")/../helm/codesys-x86"
RELEASE_NAME="${RELEASE_NAME:-codesys-x86}"
NAMESPACE="${NAMESPACE:-codesys-x86}"
ARCHITECTURE="${1:-amd64}"  # Default to amd64
VALUES_FILE="${2:-}"  # Optional custom values file

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CODESYS Control x86 Helm Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Architecture: $ARCHITECTURE"
echo "Chart: $CHART_DIR"
if [[ -n "$VALUES_FILE" ]]; then
    echo "Custom values: $VALUES_FILE"
fi
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: Helm is not installed${NC}"
    echo "Please install Helm 3.x from https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check Helm version
HELM_VERSION=$(helm version --short | grep -oP 'v\d+' | head -1 | sed 's/v//')
if [[ "$HELM_VERSION" -lt 3 ]]; then
    echo -e "${RED}Error: Helm 3.x or later is required${NC}"
    echo "Current version: $(helm version --short)"
    exit 1
fi

echo -e "${GREEN}Helm version: $(helm version --short)${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure your kubeconfig is properly configured"
    exit 1
fi

echo -e "${GREEN}Connected to cluster${NC}"
kubectl cluster-info | head -n 1
echo ""

# Validate architecture
if [[ "$ARCHITECTURE" != "amd64" && "$ARCHITECTURE" != "386" ]]; then
    echo -e "${RED}Error: Invalid architecture '$ARCHITECTURE'. Must be 'amd64' or '386'${NC}"
    exit 1
fi

# Check if chart directory exists
if [[ ! -d "$CHART_DIR" ]]; then
    echo -e "${RED}Error: Chart directory not found: $CHART_DIR${NC}"
    exit 1
fi

# Validate Helm chart
echo -e "${YELLOW}Validating Helm chart...${NC}"
if ! helm lint "$CHART_DIR"; then
    echo -e "${RED}Error: Helm chart validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}Chart validation passed${NC}"
echo ""

# Check if release already exists
if helm list -n "$NAMESPACE" | grep -q "^$RELEASE_NAME"; then
    echo -e "${YELLOW}Release '$RELEASE_NAME' already exists in namespace '$NAMESPACE'${NC}"
    echo "Do you want to upgrade it? (y/n)"
    read -r RESPONSE
    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        ACTION="upgrade"
    else
        echo "Deployment cancelled"
        exit 0
    fi
else
    ACTION="install"
fi

# Prepare Helm command
HELM_CMD="helm $ACTION $RELEASE_NAME $CHART_DIR"
HELM_CMD="$HELM_CMD --namespace $NAMESPACE"
HELM_CMD="$HELM_CMD --create-namespace"
HELM_CMD="$HELM_CMD --set architecture=$ARCHITECTURE"

# Add custom values file if provided
if [[ -n "$VALUES_FILE" ]]; then
    if [[ ! -f "$VALUES_FILE" ]]; then
        echo -e "${RED}Error: Values file not found: $VALUES_FILE${NC}"
        exit 1
    fi
    HELM_CMD="$HELM_CMD --values $VALUES_FILE"
fi

# Add wait flag
HELM_CMD="$HELM_CMD --wait --timeout 5m"

# Execute Helm command
echo -e "${YELLOW}${ACTION^}ing CODESYS runtime...${NC}"
echo "Command: $HELM_CMD"
echo ""

if eval "$HELM_CMD"; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Get deployment status
    echo -e "${BLUE}Deployment Status:${NC}"
    helm status "$RELEASE_NAME" -n "$NAMESPACE"
    echo ""
    
    # Get pods
    echo -e "${BLUE}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    echo ""
    
    # Get service info
    echo -e "${BLUE}Services:${NC}"
    kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    echo ""
    
    # Get NodePort information
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    PLC_PORT=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME" -o jsonpath='{.items[0].spec.ports[?(@.name=="plc-comm")].nodePort}')
    WEB_PORT=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME" -o jsonpath='{.items[0].spec.ports[?(@.name=="webvisu")].nodePort}')
    
    if [[ -n "$NODE_IP" && -n "$PLC_PORT" ]]; then
        echo -e "${BLUE}Access Information:${NC}"
        echo "  Node IP: $NODE_IP"
        echo "  PLC Communication Port: $PLC_PORT"
        echo "  Web Visualization Port: $WEB_PORT"
        echo ""
        echo "  CODESYS IDE: Connect to ${NODE_IP}:${PLC_PORT}"
        echo "  Web Visualization: http://${NODE_IP}:${WEB_PORT}"
        echo ""
    fi
    
    echo -e "${GREEN}Deployment complete!${NC}"
    echo ""
    echo "Useful commands:"
    echo "  - View release: helm list -n $NAMESPACE"
    echo "  - Get values: helm get values $RELEASE_NAME -n $NAMESPACE"
    echo "  - View logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME -f"
    echo "  - Upgrade: helm upgrade $RELEASE_NAME $CHART_DIR -n $NAMESPACE --set architecture=$ARCHITECTURE"
    echo "  - Uninstall: helm uninstall $RELEASE_NAME -n $NAMESPACE"
    
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Deployment failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check the error messages above"
    echo "  2. Verify your values: helm get values $RELEASE_NAME -n $NAMESPACE"
    echo "  3. Check pod status: kubectl get pods -n $NAMESPACE"
    echo "  4. View pod logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"
    exit 1
fi
