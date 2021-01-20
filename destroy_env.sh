#!/bin/sh
# This is the script to use that runs through and automates resource removes for an environment
# Set variables for env and resource group to deploy to
env=${1} 

#get azure setup
if [ "$env" = "prd" ]
then
    echo "Prod Resources Must be Manually Removed"
    spName=$"prod-az-crxbi-sp"
    rg=$"rg-prod-bi-uscentral"
    exit 1
else 
    az account set --subscription "Development"
    echo "Starting Deployment for Development"
    spName=$"dev-az-crxbi-sp"
    rg=$"rg-dev-bi-uscentral"
fi

while true; do
    read -p  "Are you really sure you want to delete $env? Press y or n" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Exit"; exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done

resources=$(az resource list -g $rg --query "[?contains(name,'$env')].[id]" -o tsv)
resourcesArray=($resources)

echo "Resources marked for deletion: $resources"

IFS="\t";
# iterate over the ARM templates for deployment of initial resources where needed
for ((i=0; i<${#resourcesArray[@]}; ++i));
do
    unset IFS
    resource=${resourcesArray[$i]}
    read -p  "Are you really sure you want to delete $resource? Press y if yes" yn
    if [[ $yn == "y" ]];
    then
        az resource delete --ids $resource
        echo "Delete complete for $resource"
    fi
done 

echo "Complete for $env"

