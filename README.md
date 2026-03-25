# Microsoft 365 Offboarding App

A single-page web application for IT administrators to automate employee offboarding in Microsoft 365 environments. Built with vanilla JavaScript, MSAL.js, and Azure services.

![Azure Static Web Apps](https://img.shields.io/badge/Azure-Static%20Web%20Apps-blue?logo=microsoftazure)
![Microsoft Graph](https://img.shields.io/badge/Microsoft-Graph%20API-green?logo=microsoft)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Features

### User Management
- **Search users** by email, name, or partial match via Microsoft Graph API
- **User profile card** with avatar, job title, department, groups, and licenses
- **Pre-flight checklist** validating OneDrive access, mailbox access, license status, and data retention window
- **Refresh button** to reload user data after changes

### Backup
- **OneDrive backup** — recursive full backup of all files and folders to Azure Blob Storage
- **Email backup** — all mail folders with full message content (paginated)
- **Parallel processing** — 15 concurrent OneDrive uploads, 30 concurrent email uploads
- **Smart deduplication** — lists existing blobs in bulk before uploading, skips already-backed-up files
- **Real-time progress** — files/emails processed, MB transferred, speed (MB/s or emails/s), ETA
- **Cancel/Resume** — stop backup mid-process, resume later (skips existing files automatically)
- **Retry logic** — automatic retry with exponential backoff for transient blob auth failures

### Offboarding Actions
- **Remove licenses** — strips all M365 licenses from the user
- **Remove groups** — removes from Azure AD security groups + attempts Exchange distribution lists via Exchange Online REST API
- **Block sign-in** — disables the user account immediately
- **Confirmation gate** — requires checkbox confirmation before executing irreversible actions

### Notifications
- **Email notification** via Microsoft Graph (Mail.Send)
- **Multiple recipients** — add recipients by searching the directory or typing email addresses
- **Chips UI** — visual email badges with add/remove functionality

### History
- **Offboarding log** stored in Azure Blob Storage (`_history/log.json`)
- **Detailed records** — type (backup/offboarding), user, date, actions performed, reason, admin, status, notes
- **History tab** with sortable table view

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Browser (SPA)                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  MSAL.js │  │ Graph API│  │  Blob Storage │  │
│  │  (login) │  │ (users,  │  │  (SharedKey   │  │
│  │          │  │  mail,   │  │   auth from   │  │
│  │          │  │  drive)  │  │   browser)    │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────┘  │
│       │              │                │          │
├───────┼──────────────┼────────────────┼──────────┤
│       │     Azure Static Web App API             │
│       │  ┌──────────────────────────────┐        │
│       │  │  /api/token (client creds)   │        │
│       │  │  /api/removeExchangeMember   │        │
│       │  └──────────────────────────────┘        │
└───────┼──────────────┼────────────────┼──────────┘
        │              │                │
   Azure AD      Graph API     Blob Storage
   (Auth)        (M365 data)   (Backups)
```

## Prerequisites

- **Azure subscription** with:
  - Azure Static Web App
  - Azure Storage Account with a blob container
- **Azure AD App Registration** with these permissions (all with admin consent):

| Permission | Type | Purpose |
|---|---|---|
| User.ReadWrite.All | Delegated + Application | Read/write user profiles |
| Directory.ReadWrite.All | Delegated + Application | Manage directory objects |
| Group.ReadWrite.All | Delegated + Application | Manage group memberships |
| Files.Read.All | Delegated + Application | Read OneDrive files |
| Mail.Read | Delegated + Application | Read mailboxes |
| Mail.Send | Application | Send notification emails |
| Exchange.ManageAsApp | Application | Manage Exchange distribution lists |

- **Global Administrator** or **User Administrator** role for the admin account

## Setup

### 1. Clone and configure

```bash
git clone https://github.com/YOUR_USERNAME/Offboarding-module.git
cd Offboarding-module
```

Edit `index.html` and replace the placeholder values:
```javascript
const CLIENT_ID='YOUR_CLIENT_ID';
const TENANT_ID='YOUR_TENANT_ID';
const STORAGE_ACCOUNT='YOUR_STORAGE_ACCOUNT';
const STORAGE_KEY='YOUR_STORAGE_KEY';
const CONTAINER='offboarding-backups';
```

### 2. Configure Azure App Registration

1. Go to **Azure Portal** > **App registrations** > **New registration**
2. Set redirect URI as **SPA**: `https://your-app.azurestaticapps.net`
3. Enable **Access tokens** under Authentication > Implicit grant
4. Add all API permissions listed above
5. Create a **Client Secret** under Certificates & secrets
6. Click **Grant admin consent**

### 3. Configure Azure Static Web App environment variables

In the Azure Portal, go to your Static Web App > **Configuration** > **Application settings**:

| Setting | Value |
|---|---|
| `CLIENT_ID` | Your App Registration client ID |
| `CLIENT_SECRET` | Your App Registration client secret |
| `TENANT_ID` | Your Azure AD tenant ID |

### 4. Deploy

```bash
npx @azure/static-web-apps-cli deploy \
  --app-location . \
  --output-location . \
  --api-location ./api \
  --deployment-token YOUR_DEPLOYMENT_TOKEN \
  --env production
```

### 5. Exchange Online (optional, for distribution list removal)

1. Add **Exchange.ManageAsApp** application permission
2. In **Entra ID** > **Roles and administrators**, assign **Exchange Recipient Administrator** to the app

## Blob Storage Structure

```
offboarding-backups/
├── _history/
│   └── log.json              ← All offboarding/backup records
└── [User Display Name]/
    ├── OneDrive/
    │   ├── Documents/
    │   │   └── file.pdf
    │   └── Desktop/
    │       └── notes.txt
    └── Emails/
        ├── Inbox/
        │   └── 2026-01-15_Meeting notes.eml
        ├── Sent Items/
        │   └── 2026-01-14_Re Project update.eml
        └── [Other Folders]/
```

## Tech Stack

- **Frontend**: Vanilla JavaScript, HTML5, CSS3 (no frameworks)
- **Auth**: MSAL.js 2.x (popup flow)
- **APIs**: Microsoft Graph API v1.0, Azure Blob Storage REST API, Exchange Online REST API
- **Hosting**: Azure Static Web Apps (with built-in Azure Functions for API)
- **Crypto**: Web Crypto API (HMAC-SHA256 for Blob Storage SharedKey auth)

## Security Notes

> **Important**: The Storage Account access key is currently embedded in the client-side HTML. For production use, consider:
> - Moving blob operations to the Azure Functions API backend
> - Using SAS tokens with limited scope and expiration
> - Implementing Azure Managed Identity

## License

MIT
