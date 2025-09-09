az login

az deployment sub what-if --location EastUS --template-file resume/azure_automation/bicep_templates/1_static_page_deployment.bicep

az storage blob service-properties update --account-name <storage-account-name> --static-website --404-document <error-document-name> --index-document <index-document-name>