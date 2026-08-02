require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// ── Database ──────────────────────────────────────────────────────────────────

// Railway postgres-ssl uses a self-signed cert — rejectUnauthorized must be false
const useSSL = process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: useSSL ? { rejectUnauthorized: false } : false,
});

async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id            SERIAL PRIMARY KEY,
      username      VARCHAR(50)  UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      wifi_ssid     VARCHAR(100),
      wifi_password VARCHAR(100),
      created_at    TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS robots (
      id         SERIAL PRIMARY KEY,
      user_id    INTEGER REFERENCES users(id) ON DELETE CASCADE,
      robot_uid  VARCHAR(100) NOT NULL,
      robot_name VARCHAR(100),
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(user_id, robot_uid)
    );

    CREATE TABLE IF NOT EXISTS sensor_data (
      id          SERIAL PRIMARY KEY,
      robot_uid   VARCHAR(100) NOT NULL,
      data        JSONB NOT NULL,
      recorded_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS robot_registry (
      id            SERIAL PRIMARY KEY,
      robot_uid     VARCHAR(100) UNIQUE NOT NULL,
      label         VARCHAR(100),
      registered_at TIMESTAMP DEFAULT NOW()
    );
  `);
  console.log('✅ Database tables ready');
}

initDB().catch(err => {
  console.error('❌ DB init failed:', err.message);
});

// ── Auth middleware ───────────────────────────────────────────────────────────

function authenticate(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Missing token' });

  jwt.verify(token, process.env.JWT_SECRET, (err, payload) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = payload;
    next();
  });
}

// ── Health check (used by Railway) ──────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// ── Auth routes ───────────────────────────────────────────────────────────────

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, wifi_ssid, wifi_password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }
    if (username.trim().length < 3) {
      return res.status(400).json({ error: 'Username must be at least 3 characters' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    const existing = await pool.query(
      'SELECT id FROM users WHERE LOWER(username) = LOWER($1)',
      [username.trim()]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const result = await pool.query(
      `INSERT INTO users (username, password_hash, wifi_ssid, wifi_password)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, wifi_ssid, created_at`,
      [username.trim(), passwordHash, wifi_ssid || null, wifi_password || null]
    );

    const user = result.rows[0];
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({ token, user });
  } catch (err) {
    console.error('register error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const result = await pool.query(
      'SELECT * FROM users WHERE LOWER(username) = LOWER($1)',
      [username.trim()]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        wifi_ssid: user.wifi_ssid,
        created_at: user.created_at,
      },
    });
  } catch (err) {
    console.error('login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── User routes ───────────────────────────────────────────────────────────────

// GET /api/user/me
app.get('/api/user/me', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, username, wifi_ssid, created_at FROM users WHERE id = $1',
      [req.user.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/user/wifi  — update WiFi credentials
app.put('/api/user/wifi', authenticate, async (req, res) => {
  try {
    const { wifi_ssid, wifi_password } = req.body;
    await pool.query(
      'UPDATE users SET wifi_ssid = $1, wifi_password = $2 WHERE id = $3',
      [wifi_ssid, wifi_password, req.user.userId]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Robot registry routes ────────────────────────────────────────────────────

// GET /api/robots/validate/:robotUid  — verify a robot UID exists in the registry
app.get('/api/robots/validate/:robotUid', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT robot_uid, label FROM robot_registry WHERE UPPER(robot_uid) = UPPER($1)',
      [req.params.robotUid]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Robot ID not found. Check the ID printed on your robot.' });
    }
    res.json({ valid: true, robot_uid: result.rows[0].robot_uid, label: result.rows[0].label });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/admin/robots  — pre-register a single robot UID (admin only)
app.post('/api/admin/robots', async (req, res) => {
  try {
    const { robot_uid, label, admin_secret } = req.body;
    if (!admin_secret || admin_secret !== process.env.ADMIN_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    if (!robot_uid) return res.status(400).json({ error: 'robot_uid is required' });
    const result = await pool.query(
      `INSERT INTO robot_registry (robot_uid, label)
       VALUES ($1, $2)
       ON CONFLICT (robot_uid) DO UPDATE SET label = EXCLUDED.label
       RETURNING *`,
      [robot_uid.trim(), label || robot_uid]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/admin/robots/bulk  — pre-register multiple robot UIDs at once
// Body: { admin_secret, robots: [{ robot_uid, label }, ...] }
app.post('/api/admin/robots/bulk', async (req, res) => {
  try {
    const { robots, admin_secret } = req.body;
    if (!admin_secret || admin_secret !== process.env.ADMIN_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    if (!Array.isArray(robots) || robots.length === 0) {
      return res.status(400).json({ error: 'robots array is required' });
    }

    // Build a multi-row INSERT with parameterised values
    const values = [];
    const placeholders = robots.map((r, i) => {
      const uid = String(r.robot_uid || '').trim();
      if (!uid) throw new Error(`robots[${i}] missing robot_uid`);
      values.push(uid, r.label || uid);
      const base = i * 2;
      return `($${base + 1}, $${base + 2})`;
    });

    const result = await pool.query(
      `INSERT INTO robot_registry (robot_uid, label)
       VALUES ${placeholders.join(', ')}
       ON CONFLICT (robot_uid) DO UPDATE SET label = EXCLUDED.label
       RETURNING robot_uid, label, registered_at`,
      values
    );
    res.status(201).json({ inserted: result.rowCount, robots: result.rows });
  } catch (err) {
    res.status(400).json({ error: err.message || 'Server error' });
  }
});

// GET /api/admin/robots  — list all registered robot UIDs (admin only)
app.get('/api/admin/robots', async (req, res) => {
  try {
    if (req.query.secret !== process.env.ADMIN_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    const result = await pool.query(
      'SELECT robot_uid, label, registered_at FROM robot_registry ORDER BY registered_at DESC'
    );
    res.json({ total: result.rowCount, robots: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Robot routes ──────────────────────────────────────────────────────────────

// GET /api/robots
app.get('/api/robots', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM robots WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/robots
app.post('/api/robots', authenticate, async (req, res) => {
  try {
    const { robot_uid, robot_name } = req.body;
    if (!robot_uid) return res.status(400).json({ error: 'robot_uid is required' });

    const result = await pool.query(
      `INSERT INTO robots (user_id, robot_uid, robot_name)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, robot_uid) DO UPDATE SET robot_name = EXCLUDED.robot_name
       RETURNING *`,
      [req.user.userId, robot_uid, robot_name || robot_uid]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/robots/:robotUid
app.delete('/api/robots/:robotUid', authenticate, async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM robots WHERE user_id = $1 AND robot_uid = $2',
      [req.user.userId, req.params.robotUid]
    );
    res.json({ message: 'Robot removed' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Sensor data routes ────────────────────────────────────────────────────────

// POST /api/sensor-data
app.post('/api/sensor-data', authenticate, async (req, res) => {
  try {
    const { robot_uid, data } = req.body;
    if (!robot_uid || !data) {
      return res.status(400).json({ error: 'robot_uid and data are required' });
    }

    const result = await pool.query(
      'INSERT INTO sensor_data (robot_uid, data) VALUES ($1, $2) RETURNING *',
      [robot_uid, data]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/sensor-data/:robotUid  — latest 100 records
app.get('/api/sensor-data/:robotUid', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM sensor_data
       WHERE robot_uid = $1
       ORDER BY recorded_at DESC
       LIMIT 100`,
      [req.params.robotUid]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ── ESP WiFi credential fetch ─────────────────────────────────────────────────
// The ESP hits this with its robot_uid and the shared ESP_SECRET to get WiFi creds.
// GET /api/wifi-credentials/:robotUid?secret=<ESP_SECRET>
app.get('/api/wifi-credentials/:robotUid', async (req, res) => {
  try {
    if (req.query.secret !== process.env.ESP_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const result = await pool.query(
      `SELECT u.wifi_ssid, u.wifi_password
       FROM robots r
       JOIN users u ON r.user_id = u.id
       WHERE r.robot_uid = $1`,
      [req.params.robotUid]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Robot not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
