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

# Create resource group if it doesn't exist
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# What-if deployment
echo "Running what-if analysis..."
az deployment group what-if \
    --resource-group $RESOURCE_GROUP \
    --template-file azure_automation/bicep_templates/storageAccount.bicep \
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME

read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Actual deployment
    echo "Deploying resources..."
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file azure_automation/bicep_templates/storageAccount.bicep \
        --parameters storageAccountName=$STORAGE_ACCOUNT_NAME \
        --query 'properties.outputs' \
        --output json)
    check_result "Resource deployment"
    
    # Extract storage account name from deployment output
    DEPLOYED_STORAGE_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.storageAccountName.value')
    echo "Deployed storage account: $DEPLOYED_STORAGE_NAME"
    
    # Enable static website hosting
    echo "Enabling static website hosting..."
    az storage blob service-properties update \
        --account-name $DEPLOYED_STORAGE_NAME \
        --static-website \
        --404-document 404.html \
        --index-document resume.html
    check_result "Static website configuration"

    # Upload website files
    echo "Uploading website files..."
    
    PATTERNS=("*.html" "*.css")
    
    for pattern in "${PATTERNS[@]}"; do
        echo "Uploading $pattern files..."
        az storage blob upload-batch \
            --account-name $DEPLOYED_STORAGE_NAME \
            --source "." \
            --destination '$web' \
            --pattern "$pattern" \
            --overwrite 2>/dev/null || echo "No $pattern files found"
    done
    
    check_result "File upload"
    
    echo "Deployment completed successfully!"
    echo "Website URL: https://$STORAGE_ACCOUNT_NAME.z13.web.core.windows.net/"

    # Deploy Front Door CDN for global distribution and custom domain
    echo "Deploying Front Door CDN..."
    az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file azure_automation/bicep_templates/frontDoor.bicep \
        --parameters storageAccountName=$STORAGE_ACCOUNT_NAME
    check_result "Front Door deployment"

    echo "Front Door CDN deployment completed!"

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
else
    echo "Deployment cancelled."
fi

