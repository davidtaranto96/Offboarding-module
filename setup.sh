#!/bin/bash
# ============================================================
# JBKnowledge IT Offboarding App — Setup Script
# Run this script to configure your deployment with your own
# Azure credentials before deploying to Azure Static Web Apps.
# ============================================================

set -e

echo ""
echo "======================================================"
echo " JBKnowledge IT Offboarding App — Setup"
echo "======================================================"
echo ""
echo "This script will configure index.html with your Azure"
echo "credentials. You will need:"
echo ""
echo "  1. Azure AD App Registration (Client ID + Tenant ID)"
echo "  2. Azure Blob Storage account + SAS token"
echo "  3. Azure Functions API URL (for Graph token proxy)"
echo ""
echo "See README.md for step-by-step instructions on how to"
echo "create each resource."
echo ""

# ---- Prompt for each value ----

read -p "Azure AD Application (Client) ID: " CLIENT_ID
if [ -z "$CLIENT_ID" ]; then echo "Error: Client ID is required."; exit 1; fi

read -p "Azure AD Tenant ID: " TENANT_ID
if [ -z "$TENANT_ID" ]; then echo "Error: Tenant ID is required."; exit 1; fi

read -p "Azure Storage Account name (e.g. mystorageaccount): " STORAGE_ACCOUNT
if [ -z "$STORAGE_ACCOUNT" ]; then echo "Error: Storage Account name is required."; exit 1; fi

read -p "Azure Blob SAS Token (paste full token string): " SAS_TOKEN
if [ -z "$SAS_TOKEN" ]; then echo "Error: SAS Token is required."; exit 1; fi

read -p "Blob Container name (e.g. offboarding-backups): " CONTAINER
if [ -z "$CONTAINER" ]; then echo "Error: Container name is required."; exit 1; fi

read -p "Azure Functions API base URL (e.g. https://my-api.azurewebsites.net): " API_URL
if [ -z "$API_URL" ]; then echo "Error: API URL is required."; exit 1; fi

# ---- Apply substitutions ----

TARGET="index.html"

if [ ! -f "$TARGET" ]; then
  echo "Error: index.html not found in current directory."
  echo "Run this script from the folder containing index.html."
  exit 1
fi

# Escape special characters for sed
escape_sed() { printf '%s\n' "$1" | sed 's/[[\.*^$()+?{|]/\\&/g; s/]/\\]/g'; }

SAS_ESCAPED=$(escape_sed "$SAS_TOKEN")
API_ESCAPED=$(escape_sed "$API_URL")

sed -i \
  -e "s|YOUR_AZURE_APP_CLIENT_ID|${CLIENT_ID}|g" \
  -e "s|YOUR_AZURE_TENANT_ID|${TENANT_ID}|g" \
  -e "s|YOUR_STORAGE_ACCOUNT_NAME|${STORAGE_ACCOUNT}|g" \
  -e "s|YOUR_AZURE_BLOB_SAS_TOKEN|${SAS_ESCAPED}|g" \
  -e "s|YOUR_BLOB_CONTAINER_NAME|${CONTAINER}|g" \
  -e "s|YOUR_AZURE_FUNCTION_API_URL|${API_ESCAPED}|g" \
  "$TARGET"

echo ""
echo "======================================================"
echo " Configuration applied to index.html successfully!"
echo "======================================================"
echo ""
echo "Next steps:"
echo "  1. Copy index.html to your _deploy/ folder"
echo "  2. Deploy with SWA CLI:"
echo "     npx @azure/static-web-apps-cli deploy \\"
echo "       --app-location ./_deploy \\"
echo "       --env production \\"
echo "       --deployment-token YOUR_SWA_DEPLOYMENT_TOKEN"
echo ""
echo "See README.md for full deployment instructions."
echo ""
