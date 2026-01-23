'use strict';

const crypto = require('crypto');

const ALGORITHM = 'AWS4-HMAC-SHA256';
const SERVICE = 's3';
const REGION = 'auto';

function hmac(key, data) {
  return crypto.createHmac('sha256', key).update(data).digest();
}

function sha256(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

function getSigningKey(secretKey, dateStamp) {
  const kDate = hmac(`AWS4${secretKey}`, dateStamp);
  const kRegion = hmac(kDate, REGION);
  const kService = hmac(kRegion, SERVICE);
  return hmac(kService, 'aws4_request');
}

function generatePresignedUrl({ method, key, contentType, expiresIn = 3600 }) {
  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
  const bucket = process.env.R2_BUCKET_NAME;

  if (!accountId || !accessKeyId || !secretAccessKey || !bucket) {
    throw new Error('R2 environment variables not configured');
  }

  const host = `${accountId}.r2.cloudflarestorage.com`;
  const endpoint = `https://${host}/${bucket}/${key}`;

  const now = new Date();
  const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  const dateStamp = amzDate.slice(0, 8);
  const credential = `${accessKeyId}/${dateStamp}/${REGION}/${SERVICE}/aws4_request`;

  const queryParams = new URLSearchParams({
    'X-Amz-Algorithm': ALGORITHM,
    'X-Amz-Credential': credential,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expiresIn),
    'X-Amz-SignedHeaders': 'content-type;host',
  });

  // Sort params for canonical request
  queryParams.sort();
  const canonicalQueryString = queryParams.toString();

  const canonicalHeaders = `content-type:${contentType}\nhost:${host}\n`;
  const signedHeaders = 'content-type;host';

  const canonicalRequest = [
    method,
    `/${bucket}/${key}`,
    canonicalQueryString,
    canonicalHeaders,
    signedHeaders,
    'UNSIGNED-PAYLOAD'
  ].join('\n');

  const scope = `${dateStamp}/${REGION}/${SERVICE}/aws4_request`;
  const stringToSign = [
    ALGORITHM,
    amzDate,
    scope,
    sha256(canonicalRequest)
  ].join('\n');

  const signingKey = getSigningKey(secretAccessKey, dateStamp);
  const signature = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex');

  return `${endpoint}?${canonicalQueryString}&X-Amz-Signature=${signature}`;
}

function getPublicUrl(key) {
  const publicUrl = process.env.R2_PUBLIC_URL;
  if (!publicUrl) throw new Error('R2_PUBLIC_URL not configured');
  return `${publicUrl.replace(/\/$/, '')}/${key}`;
}

function deleteObject(key) {
  // For deletion we make a signed DELETE request
  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
  const bucket = process.env.R2_BUCKET_NAME;
  const host = `${accountId}.r2.cloudflarestorage.com`;

  const now = new Date();
  const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  const dateStamp = amzDate.slice(0, 8);

  const canonicalUri = `/${bucket}/${key}`;
  const canonicalHeaders = `host:${host}\nx-amz-content-sha256:UNSIGNED-PAYLOAD\nx-amz-date:${amzDate}\n`;
  const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

  const canonicalRequest = [
    'DELETE',
    canonicalUri,
    '',
    canonicalHeaders,
    signedHeaders,
    'UNSIGNED-PAYLOAD'
  ].join('\n');

  const scope = `${dateStamp}/${REGION}/${SERVICE}/aws4_request`;
  const stringToSign = [ALGORITHM, amzDate, scope, sha256(canonicalRequest)].join('\n');
  const signingKey = getSigningKey(secretAccessKey, dateStamp);
  const signature = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex');
  const authorization = `${ALGORITHM} Credential=${accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return new Promise((resolve, reject) => {
    const https = require('https');
    const req = https.request({
      hostname: host,
      path: canonicalUri,
      method: 'DELETE',
      headers: {
        'Host': host,
        'X-Amz-Date': amzDate,
        'X-Amz-Content-Sha256': 'UNSIGNED-PAYLOAD',
        'Authorization': authorization,
      }
    }, (res) => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve();
        else reject(new Error(`R2 DELETE failed: ${res.statusCode} ${body}`));
      });
    });
    req.on('error', reject);
    req.end();
  });
}

module.exports = { generatePresignedUrl, getPublicUrl, deleteObject };
