#!/usr/bin/env bash
# Creates the storage account that holds Terraform state.
# Run once. Safe to re-run.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # stop Git Bash from rewriting /subscriptions/... into a Windows path

LOCATION="centralindia"
RG="rg-nimbus-tfstate"
CONTAINER="tfstate"

# Storage account names must be globally unique, lowercase, 3-24 chars.
SUFFIX=$(az account show --query id -o tsv | cut -c1-6)
SA="stnimbustf${SUFFIX}"
OWNER=$(az account show --query user.name -o tsv)

echo "Creating resource group ${RG}..."
az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags project=nimbus env=shared owner="$OWNER" managed-by=script \
  -o none

echo "Creating storage account ${SA}..."
az storage account create \
  --name "$SA" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  -o none

echo "Enabling versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name "$SA" \
  --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  -o none

echo "Creating container ${CONTAINER}..."
az storage container-rm create \
  --storage-account "$SA" \
  --resource-group "$RG" \
  --name "$CONTAINER" \
  -o none

echo "Granting you data access (Entra ID login instead of keys)..."
USER_ID=$(az ad signed-in-user show --query id -o tsv)
SA_ID=$(az storage account show --name "$SA" --resource-group "$RG" --query id -o tsv)
az role assignment create \
  --assignee "$USER_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID" \
  -o none || echo "Role assignment already exists."

echo ""
echo "Done. Save these values for the backend config:"
echo "  resource_group_name  = ${RG}"
echo "  storage_account_name = ${SA}"
echo "  container_name       = ${CONTAINER}"