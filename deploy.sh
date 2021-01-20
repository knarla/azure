#!/bin/sh
# This is the script to use that runs through and automates deployments for the initial ARM templates

# Set variables for env and resource group to deploy to
env=${1:-"dev"}
rg=${2:-"rg-dev-bi-uscentral"} 
tier=${3:-"standard"}
subscription_id=${4:-""}
service_app_plan=${5:-""}

set -x

echo "parameters: $env, $rg, $tier, $server_farm_id"

#get azure setup
if [ "$env" = "prd" ]
then
    az account set --subscription "Production"
    echo "Starting Deployment for Production"
    spName=$"prod-az-crxbi-sp"
	funcName="rg-prod-biapps-uscentral"
else 
    az account set --subscription "Development"
    echo "Starting Deployment for Development"
    spName=$"dev-az-crxbi-sp"
	funcName="rg-$env-biapps-uscentral"
fi

# Get the Azure Devops Service Principal Object ID and the ADB App Service Object ID. DO NOT USE THE APPID, USE OBJECTID
spId=$(az ad sp list --all --query "[?displayName=='$spName'].objectId" --output tsv)
adbId=$(az ad sp list --all --query "[?displayName=='AzureDatabricks'].objectId" --output tsv)
funcId=$(az ad sp list --all --query "[?displayName=='SnowflakeAcl$env'].objectId" --output tsv)
biDevGroupId=$(az ad group list --query "[?displayName=='AzureBIDeveloper'].objectId" --output tsv)
biAdminGroupId=$(az ad group list --query "[?displayName=='AzureBiAdmins'].objectId" --output tsv)

# iterate over the ARM templates for deployment of initial resources where needed
for filename in template/*.json; do
  if [[ $filename =~ "6-kv.json" ]]
  then
    az group deployment create --resource-group $rg \
            --parameters env=$env objectId=$spId adbId=$adbId funcId=$funcId biDevGroupId=$biDevGroupId biAdminGroupId=$biAdminGroupId \
            --template-file $filename \
            --mode Incremental
  elif [[ $filename =~ "5-function.json" ]]
  then
    az group deployment create --verbose --resource-group $funcName \
            --parameters env=$env tier=$tier \
              subscriptionId=$subscription_id serviceAppPlan=$service_app_plan rg=$funcName storage_rg=$rg \
            --template-file $filename \
            --mode Incremental
  else
    az group deployment create --resource-group $rg \
            --parameters env=$env tier=$tier subscriptionId=$subscription_id \
            --template-file $filename \
            --mode Incremental
  fi
done

echo "Remember to fix the ADB link to Key Vault using the ADB Create Secret Scope screen"