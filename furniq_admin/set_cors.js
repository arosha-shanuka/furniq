/**
 * Sets CORS on Firebase Storage using firebase-tools' own auth module.
 * No gsutil, gcloud, or client secrets needed.
 * Run: node set_cors.js
 */
const https = require('https');

const BUCKET = 'furniq-78b5a.firebasestorage.app';
const FIREBASE_TOOLS = 'C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools';

const corsConfig = [
  {
    origin: ['*'],
    method: ['GET', 'HEAD'],
    maxAgeSeconds: 3600,
    responseHeader: ['Content-Type', 'Content-Disposition', 'Content-Length'],
  },
];

function setCors(token) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({ cors: corsConfig });
    const bucketEncoded = encodeURIComponent(BUCKET);
    const options = {
      hostname: 'storage.googleapis.com',
      path: `/storage/v1/b/${bucketEncoded}?fields=cors`,
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        if (res.statusCode === 200) resolve(JSON.parse(data));
        else reject(new Error(`HTTP ${res.statusCode}: ${data}`));
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

(async () => {
  try {
    // Use firebase-tools' own auth module to get a valid access token
    console.log('🔑 Getting access token via firebase-tools...');
    const { getAccessToken } = require(`${FIREBASE_TOOLS}/lib/auth`);
    const tokenData = await getAccessToken(undefined, [
      'https://www.googleapis.com/auth/devstorage.full_control',
    ]);
    const token = tokenData.access_token;
    console.log('✅ Got access token');

    console.log(`🌐 Setting CORS on: ${BUCKET}`);
    const result = await setCors(token);
    console.log('✅ CORS set successfully!');
    console.log(JSON.stringify(result.cors, null, 2));
    console.log('\n🎉 Restart your Flutter web app — images will now load.');
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
})();
