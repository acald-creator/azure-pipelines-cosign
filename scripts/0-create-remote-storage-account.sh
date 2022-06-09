#!/bin/bash

RESOURCE_GROUP_NAME=tfstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

STORAGE_ACCOUNT_ID=az storage account list --query "[].id" -o tsv
SIGNED_IN_USER_OBJECT_ID=az ad signed-in-user show --query objectId

az role assignment create --assignee $(az ad signed-in-user show --query objectId) --role "Storage Blob Data Contributor" --scope $(az storage account list --query "[].id" -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME