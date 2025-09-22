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

# Login and set subscription (only if SUBSCRIPTION_ID is set)
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

# Deploy Table API resources
echo "Deploying Table API resources..."

# Set Table API specific variables
COSMOS_ACCOUNT_NAME="resume-cosmos-$(date +%s)"
DATABASE_NAME="ResumeDatabase"

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file azure_automation/bicep_templates/tableapi.bicep \
    --parameters cosmosDbAccountName=$COSMOS_ACCOUNT_NAME \
                 databaseName=$DATABASE_NAME \
                 location=$LOCATION
check_result "Table API deployment"

echo "Table API deployment completed!"
echo "Cosmos DB Account: $COSMOS_ACCOUNT_NAME"
echo "Database: $DATABASE_NAME"