module.exports = async function (context, req) {
  // Set these as Azure Static Web App environment variables (Application settings)
  const CLIENT_ID = process.env.CLIENT_ID || 'YOUR_CLIENT_ID';
  const CLIENT_SECRET = process.env.CLIENT_SECRET || 'YOUR_CLIENT_SECRET';
  const TENANT_ID = process.env.TENANT_ID || 'YOUR_TENANT_ID';

  try {
    const body = new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      scope: 'https://graph.microsoft.com/.default'
    });

    const r = await fetch(`https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body
    });

    const data = await r.json();

    if (!r.ok) {
      context.res = { status: 400, body: data };
      return;
    }

    context.res = {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
      body: { access_token: data.access_token, expires_in: data.expires_in }
    };
  } catch (e) {
    context.res = { status: 500, body: { error: e.message } };
  }
};
