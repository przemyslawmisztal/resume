#!/bin/bash

# Load configuration
source config.sh

# Function to check if command succeeded
check_result() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Set Azure context
echo "Setting up Azure context..."
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo "Setting subscription to: $SUBSCRIPTION_ID"
    az account set --subscription $SUBSCRIPTION_ID
    check_result "Setting subscription"
else
    echo "Using default subscription..."
    CURRENT_SUB=$(az account show --query name --output tsv)
    echo "Current subscription: $CURRENT_SUB"
fi

# Check if resource group exists
echo "Checking if resource group '$RESOURCE_GROUP' exists..."
RG_EXISTS=$(az group exists --name $RESOURCE_GROUP)

if [ "$RG_EXISTS" = "true" ]; then
    echo "Found resource group: $RESOURCE_GROUP"
    
    # List resources in the group
    echo "Resources in the resource group:"
    az resource list --resource-group $RESOURCE_GROUP --output table
    
    echo ""
    echo "⚠️  WARNING: This will delete the entire resource group and ALL resources within it!"
    echo "Resource Group: $RESOURCE_GROUP"
    echo ""
    
    read -p "Are you sure you want to delete this resource group? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting resource group '$RESOURCE_GROUP'..."
        az group delete --name $RESOURCE_GROUP --yes --no-wait
        
        echo "✅ Deletion initiated. The resource group and all its resources are being deleted in the background."
        echo "You can check the status with: az group show --name $RESOURCE_GROUP"
    else
        echo "Deletion cancelled."
    fi
else
    echo "Resource group '$RESOURCE_GROUP' does not exist. Nothing to clean up."
fi