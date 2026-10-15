// Run: node seed-robots.js
// Requires: ADMIN_SECRET env var  OR  edit the value below directly.
// Make sure the backend is deployed and reachable before running.

const crypto = require('crypto');
const API_URL = process.env.API_URL || 'https://sunvibee-api-production.up.railway.app';
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'your-admin-secret-here';

const CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function generatePassword(robotId) {
  const hash = crypto.createHash('sha256').update('SUNVIBEE_SECRET_KEY_ROBOT_AUTH_' + robotId).digest('hex');
  let code = '';
  for (let i = 0; i < 6; i++) {
    const val = parseInt(hash.substr(i * 3, 3), 16);
    code += CHARS[val % CHARS.length];
  }
  return `SVB-${code}`;
}

// 1. SolarCleaner01 .. SolarCleaner100
const robots = Array.from({ length: 100 }, (_, i) => {
  const num = String(i + 1).padStart(2, '0');
  const uid = `SolarCleaner${num}`;
  return {
    robot_uid: uid,
    label: `Solar Cleaner Unit ${num}`,
    password: generatePassword(uid),
  };
});

// 2. Hardware Master Units
const hardwareUnits = [
  "SB-ASDU-3NHE",
  "SB-NV76-4BS5",
  "SB-KWF6-B8LU",
  "SB-95ZU-R79F",
  "SB-U25N-KGPT",
  "SB-BTVJ-BBEG",
  "SB-QGA4-9PLP"
];

hardwareUnits.forEach(uid => {
  robots.push({
    robot_uid: uid,
    label: `SunviBee Unit ${uid}`,
    password: generatePassword(uid),
  });
});

async function main() {
  console.log(`Seeding ${robots.length} robots to ${API_URL}...`);
  const res = await fetch(`${API_URL}/api/admin/robots/bulk`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ admin_secret: ADMIN_SECRET, robots }),
  });

  const data = await res.json();
  if (!res.ok) {
    console.error('❌ Failed:', data);
    process.exit(1);
  }
  console.log(`✅ Registered ${data.inserted} robots with unique passwords`);
  data.robots.forEach(r => console.log(`  • ${r.robot_uid}  →  Password: ${r.password || 'set'}  (${r.label})`));
}

main().catch(err => { console.error(err); process.exit(1); });
