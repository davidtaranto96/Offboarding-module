module.exports = async function (context, req) {
  // Set these as Azure Static Web App environment variables (Application settings)
  const CLIENT_ID = process.env.CLIENT_ID || 'YOUR_CLIENT_ID';
  const CLIENT_SECRET = process.env.CLIENT_SECRET || 'YOUR_CLIENT_SECRET';
  const TENANT_ID = process.env.TENANT_ID || 'YOUR_TENANT_ID';
  const { groupEmail, memberEmail } = req.body || {};

  if (!groupEmail || !memberEmail) {
    context.res = { status: 400, body: { error: 'groupEmail and memberEmail required' } };
    return;
  }

  try {
    // Get Exchange Online token
    const tokenBody = new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      scope: 'https://outlook.office365.com/.default'
    });

    const tokenRes = await fetch(`https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: tokenBody
    });

    const tokenData = await tokenRes.json();
    if (!tokenRes.ok) {
      context.res = { status: 400, body: { error: 'Token error', details: tokenData.error_description || JSON.stringify(tokenData) } };
      return;
    }

    const token = tokenData.access_token;
    const baseUrl = `https://outlook.office365.com/adminapi/beta/${TENANT_ID}`;

    // Use Exchange Online PowerShell REST API (InvokeCommand)
    const cmdRes = await fetch(`${baseUrl}/InvokeCommand`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        CmdletInput: {
          CmdletName: 'Remove-DistributionGroupMember',
          Parameters: {
            Identity: groupEmail,
            Member: memberEmail,
            Confirm: false
          }
        }
      })
    });

    if (cmdRes.ok || cmdRes.status === 204) {
      context.res = { status: 200, body: { success: true } };
    } else {
      const errBody = await cmdRes.text();
      // Try parsing for a friendly error message
      let errMsg = errBody;
      try {
        const errJson = JSON.parse(errBody);
        errMsg = errJson.error?.message || errJson.ErrorRecord?.Exception?.Message || errBody;
      } catch {}
      context.res = { status: cmdRes.status, body: { error: errMsg } };
    }
  } catch (e) {
    context.res = { status: 500, body: { error: e.message } };
  }
};
