@echo off
REM ============================================================
REM JBKnowledge IT Offboarding App - Setup Script (Windows)
REM Run this script to configure your deployment with your own
REM Azure credentials before deploying to Azure Static Web Apps.
REM ============================================================

echo.
echo ======================================================
echo  JBKnowledge IT Offboarding App - Setup
echo ======================================================
echo.
echo This script will configure index.html with your Azure
echo credentials. You will need:
echo.
echo   1. Azure AD App Registration (Client ID + Tenant ID)
echo   2. Azure Blob Storage account + SAS token
echo   3. Azure Functions API URL (for Graph token proxy)
echo.
echo See README.md for step-by-step instructions.
echo.

IF NOT EXIST "index.html" (
    echo Error: index.html not found in current directory.
    echo Run this script from the folder containing index.html.
    pause
    exit /b 1
)

set /p CLIENT_ID="Azure AD Application (Client) ID: "
if "%CLIENT_ID%"=="" (echo Error: Client ID is required. & pause & exit /b 1)

set /p TENANT_ID="Azure AD Tenant ID: "
if "%TENANT_ID%"=="" (echo Error: Tenant ID is required. & pause & exit /b 1)

set /p STORAGE_ACCOUNT="Azure Storage Account name: "
if "%STORAGE_ACCOUNT%"=="" (echo Error: Storage Account is required. & pause & exit /b 1)

set /p SAS_TOKEN="Azure Blob SAS Token: "
if "%SAS_TOKEN%"=="" (echo Error: SAS Token is required. & pause & exit /b 1)

set /p CONTAINER="Blob Container name: "
if "%CONTAINER%"=="" (echo Error: Container name is required. & pause & exit /b 1)

set /p API_URL="Azure Functions API base URL: "
if "%API_URL%"=="" (echo Error: API URL is required. & pause & exit /b 1)

REM Use PowerShell to do the replacements (handles special chars better than cmd)
powershell -Command ^
  "(Get-Content 'index.html') ^
    -replace 'YOUR_AZURE_APP_CLIENT_ID', '%CLIENT_ID%' ^
    -replace 'YOUR_AZURE_TENANT_ID', '%TENANT_ID%' ^
    -replace 'YOUR_STORAGE_ACCOUNT_NAME', '%STORAGE_ACCOUNT%' ^
    -replace 'YOUR_AZURE_BLOB_SAS_TOKEN', '%SAS_TOKEN%' ^
    -replace 'YOUR_BLOB_CONTAINER_NAME', '%CONTAINER%' ^
    -replace 'YOUR_AZURE_FUNCTION_API_URL', '%API_URL%' ^
  | Set-Content 'index.html'"

echo.
echo ======================================================
echo  Configuration applied to index.html successfully!
echo ======================================================
echo.
echo Next steps:
echo   1. Copy index.html to your _deploy\ folder
echo   2. Deploy with SWA CLI:
echo      npx @azure/static-web-apps-cli deploy ^
echo        --app-location .\_deploy ^
echo        --env production ^
echo        --deployment-token YOUR_SWA_DEPLOYMENT_TOKEN
echo.
echo See README.md for full deployment instructions.
echo.
pause
