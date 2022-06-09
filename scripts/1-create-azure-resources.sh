#!/bin/bash

#set the name of the resources. 
#the keyvault and ACR names need to be globally unique, you may want to change them and make sure they are unique
export RG='az-cosign-rg'
export KVNAME='phxvlabs-dev-kv'
export ACRNAME='phxvlabsdevacr'#create resource group

az group create -n $RG --location eastus #create container registry
az acr create -n $ACRNAME -g $RG --sku Basic 

export ACRHOST=$(az acr show -g $RG -n $ACRNAME --query "loginServer" -o tsv) #create keyvault

az keyvault create -n $KVNAME -g $RG --location eastus --enable-rbac-authorization true #get the resource id for role assignment later

export KVID=$(az keyvault show  -n $KVNAME -g $RG --query "id" -o tsv)
export ACRID=$(az acr show -g $RG -n $ACRNAME --query "id" -o tsv)#set tenant id
export AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)