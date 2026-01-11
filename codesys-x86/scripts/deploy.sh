#!/bin/bash
#
# Deploy CODESYS Control for Linux to K3s cluster
#
# This script deploys the CODESYS runtime to a K3s cluster using the
# Kubernetes manifests in the kubernetes/ directory
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="codesys-x86"
MANIFEST_DIR="$(dirname "$0")/../kubernetes"
ARCHITECTURE="${1:-amd64}"  # Default to amd64

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CODESYS Control x86 K3s Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Namespace: $NAMESPACE"
echo "Architecture: $ARCHITECTURE"
echo "Manifest directory: $MANIFEST_DIR"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    echo "Please install kubectl to interact with your K3s cluster"
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

# Step 1: Create namespace
echo -e "${YELLOW}[1/6] Creating namespace...${NC}"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Namespace '$NAMESPACE' already exists"
else
    kubectl apply -f "$MANIFEST_DIR/namespace.yaml"
    echo -e "${GREEN}Namespace created${NC}"
fi
echo ""

# Step 2: Apply ConfigMap
echo -e "${YELLOW}[2/6] Applying ConfigMap...${NC}"
kubectl apply -f "$MANIFEST_DIR/configmap.yaml"
echo -e "${GREEN}ConfigMap applied${NC}"
echo ""

# Step 3: Create PersistentVolumeClaims
echo -e "${YELLOW}[3/6] Creating PersistentVolumeClaims...${NC}"
kubectl apply -f "$MANIFEST_DIR/pvc.yaml"
echo -e "${GREEN}PVCs created${NC}"
echo ""

# Wait for PVCs to be bound
echo "Waiting for PVCs to be bound..."
kubectl wait --for=condition=Bound pvc/codesys-projects-pvc -n "$NAMESPACE" --timeout=60s || true
kubectl wait --for=condition=Bound pvc/codesys-license-pvc -n "$NAMESPACE" --timeout=60s || true
echo ""

# Step 4: Create Service
echo -e "${YELLOW}[4/6] Creating Service...${NC}"
kubectl apply -f "$MANIFEST_DIR/service.yaml"
echo -e "${GREEN}Service created${NC}"
echo ""

# Step 5: Deploy runtime
echo -e "${YELLOW}[5/6] Deploying CODESYS runtime...${NC}"
kubectl apply -f "$MANIFEST_DIR/deployment.yaml"

# Scale the appropriate deployment based on architecture
if [[ "$ARCHITECTURE" == "amd64" ]]; then
    echo "Scaling amd64 deployment to 1 replica..."
    kubectl scale deployment/codesys-runtime-amd64 -n "$NAMESPACE" --replicas=1
    kubectl scale deployment/codesys-runtime-386 -n "$NAMESPACE" --replicas=0 || true
elif [[ "$ARCHITECTURE" == "386" ]]; then
    echo "Scaling 386 deployment to 1 replica..."
    kubectl scale deployment/codesys-runtime-386 -n "$NAMESPACE" --replicas=1
    kubectl scale deployment/codesys-runtime-amd64 -n "$NAMESPACE" --replicas=0
else
    echo -e "${RED}Error: Invalid architecture '$ARCHITECTURE'. Must be 'amd64' or '386'${NC}"
    exit 1
fi

echo -e "${GREEN}Deployment created${NC}"
echo ""

# Step 6: Wait for deployment
echo -e "${YELLOW}[6/6] Waiting for deployment to be ready...${NC}"
DEPLOYMENT_NAME="codesys-runtime-${ARCHITECTURE}"
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=180s

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Display deployment information
echo -e "${BLUE}Deployment Information:${NC}"
echo ""
kubectl get all -n "$NAMESPACE"
echo ""

# Get NodePort information
echo -e "${BLUE}Service Access Information:${NC}"
echo ""
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
PLC_PORT=$(kubectl get svc codesys-runtime-service -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.name=="plc-comm")].nodePort}')
WEB_PORT=$(kubectl get svc codesys-runtime-service -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.name=="webvisu")].nodePort}')

echo "Node IP: $NODE_IP"
echo "PLC Communication Port: $PLC_PORT"
echo "Web Visualization Port: $WEB_PORT"
echo ""
echo "Access URLs:"
echo "  - CODESYS IDE: Connect to ${NODE_IP}:${PLC_PORT}"
echo "  - Web Visualization: http://${NODE_IP}:${WEB_PORT}"
echo ""

# Display logs
echo -e "${BLUE}Recent logs:${NC}"
kubectl logs -n "$NAMESPACE" -l app=codesys-runtime --tail=20 --all-containers=true || echo "No logs available yet"
echo ""

echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo "Useful commands:"
echo "  - View logs: kubectl logs -n $NAMESPACE -l app=codesys-runtime -f"
echo "  - Get pod status: kubectl get pods -n $NAMESPACE"
echo "  - Describe pod: kubectl describe pod -n $NAMESPACE -l app=codesys-runtime"
echo "  - Shell into container: kubectl exec -it -n $NAMESPACE deployment/$DEPLOYMENT_NAME -- /bin/bash"
echo "  - Delete deployment: kubectl delete namespace $NAMESPACE"
