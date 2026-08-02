// Run: node seed-robots.js
// Requires: ADMIN_SECRET env var  OR  edit the value below directly.
// Make sure the backend is deployed and reachable before running.

const API_URL = 'https://sunvibee-api-production.up.railway.app';
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'your-admin-secret-here';

const robots = Array.from({ length: 100 }, (_, i) => {
  const num = String(i + 1).padStart(2, '0');
  return { robot_uid: `SolarCleaner${num}`, label: `Solar Cleaner Unit ${num}` };
});

async function main() {
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
  console.log(`✅ Registered ${data.inserted} robots`);
  data.robots.forEach(r => console.log(`  • ${r.robot_uid}  →  ${r.label}`));
}

main().catch(err => { console.error(err); process.exit(1); });
