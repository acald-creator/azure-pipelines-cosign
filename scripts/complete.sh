#!/bin/bash

AZ_RG='az-cosign-rg'
AZ_REGION='eastus'
AZ_ACRNAME='phxvlabsdevacr'
AZ_KVNAME='phxvlabs-dev-kv'

# Create Azure Resource Group
az group create -n $AZ_RG --location $AZ_REGION

# Create Azure Container Registry and attach existing Azure Resource Group: az-cosign-rg
az acr create -n $AZ_ACRNAME -g $AZ_RG --sku Basic
AZ_ACRHOST=$(az acr show -g $AZ_RG -n $AZ_ACRNAME --query "loginServer" -o tsv)

# Create Azure Key Vault with --enable-rbac-authorization true
az keyvault create -n $AZ_KVNAME -g $AZ_RG --location $AZ_REGION --enable-rbac-authorization true

# Show Azure Key Vault ID
AZ_KVNAME_ID=$(az keyvault show -n $AZ_KVNAME -g $AZ_RG --query "id" -o tsv)

# Show ACR ID
AZ_ACR_ID=$(az acr show -g $AZ_RG -n $AZ_ACRNAME --query "id" -o tsv)

# Show Subscription ID and Azure Tenant ID
SUBSCRIPTIONID=$(az account show --query id -o tsv)
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)

KEYADMIN=sp-cosign-keyadmin
KEYSIGNER=sp-cosign-signer
KEYREADER=sp-cosign-reader

KEYVAULT_ADMIN_SECRET=$(az ad sp create-for-rbac -n $KEYADMIN --role "Key Vault Crypto Officer" --scopes $AZ_KVNAME_ID --query password -o tsv)
KEYVAULT_ADMIN_CLIENT_ID=$(az ad sp list --display-name $KEYADMIN --query "[].appId" -o tsv)

KEYVAULT_SIGNER_SECRET=$(az ad sp create-for-rbac -n $KEYSIGNER --query password -o tsv)
KEYVAULT_SIGNER_CLIENT_ID=$(az ad sp list --display-name $KEYSIGNER --query "[].appId" -o tsv)
KEYVAULT_SIGNER_OBJECT_ID=$(az ad sp list --display-name $KEYSIGNER --query "[].objectId" -o tsv)

KEYVAULT_READER_SECRET=$(az ad sp create-for-rbac -n $KEYREADER --query password -o tsv)
KEYVAULT_READER_CLIENT_ID=$(az ad sp list --display-name $KEYREADER --query "[].appId" -o tsv)
KEYVAULT_READER_OBJECT_ID=$(az ad sp list --display-name $KEYREADER --query "[].objectId" -o tsv)

AZURE_CLIENT_ID=$KEYVAULT_ADMIN_CLIENT_ID
AZURE_CLIENT_SECRET=$KEYVAULT_ADMIN_SECRET

# Generate the keypair and store it in Azure Key Vault
cosign generate-key-pair --kms "azurekms://$AZ_KVNAME.vault.azure.net/cosignkey"

# Give yourselfe access to the Azure Key Vault keys
az role assignment create --role "Key Vault Crypto Officer" --scope $AZ_KVNAME_ID --assignee-object-id $(az ad signed-in-user show --query objectId -o tsv) --assignee-principal-type User

az keyvault key show --name cosignkey --vault-name $AZ_KVNAME

az role assignment create --role "Key Vault Crypto User" --scope "$AZ_KVNAME_ID/keys/cosignkey" --assignee-object-id $KEYVAULT_SIGNER_OBJECT_ID --assignee-principal-type ServicePrincipal

# Set the Subscription ID in the custom role definition file key-vault-verify-.json
sed -i "s/<subid>/$SUBSCRIPTIONID/" key-vault-verify.json 

# Create the custom role
az role definition create --role-definition key-vault-verify.json

az role assignment create --role "Key Reader + Verify" --scope "$AZ_KVNAME_ID/keys/cosignkey" --assignee-object-id $KEYVAULT_READER_OBJECT_ID --assignee-principal-type ServicePrincipal

# docker pull nginx:latest
# docker tag nginx $AZ_ACRHOST/nginx:v1
az acr login -n $AZ_ACRNAME
docker build -t $AZ_ACRHOST/hello:v1 -f ../Dockerfile
docker tag nginx $AZ_ACRHOST/hello:v1
docker push $AZ_ACRHOST/hello:v1

# Sign tagged docker image with cosign
AZURE_CLIENT_ID=$KEYVAULT_SIGNER_CLIENT_ID
AZURE_CLIENT_SECRET=$KEYVAULT_SIGNER_SECRET
cosign sign -a last_commit=$(git rev-parse HEAD) --key "azurekms://$AZ_KVNAME.vault.azure.net/cosignkey" $AZ_ACRHOST/hello:v1

# Verify signed docker image
AZURE_CLIENT_ID=$KEYVAULT_READER_CLIENT_ID
AZURE_CLIENT_SECRET=$KEYVAULT_READER_SECRET
cosign verify --key "azurekms://$AZ_KVNAME.vault.azure.net/cosignkey" $AZ_ACRHOST/hello:v1

az role assignment create --role "AcrPush" --scope $AZ_ACR_ID --assignee-object-id $KEYVAULT_SIGNER_OBJECT_ID --assignee-principal-type ServicePrincipal