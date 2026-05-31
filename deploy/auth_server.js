// ============================================================
// MathMate 认证服务 v3
// 功能: 注册(验证码+邀请码) | 登录 | 邀请码直登 | 用户管理
// 端口: 3002
// ============================================================

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DATA_DIR = '/opt/mathmate';
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const INVITES_FILE = path.join(DATA_DIR, 'invites.json');
const SECRET_FILE = path.join(DATA_DIR, 'auth_secret.txt');

// ==================== 工具函数 ====================

function getSecret() {
  if (fs.existsSync(SECRET_FILE)) return fs.readFileSync(SECRET_FILE, 'utf-8').trim();
  const s = crypto.randomBytes(32).toString('hex');
  fs.writeFileSync(SECRET_FILE, s);
  return s;
}

function loadUsers() {
  try { if (fs.existsSync(USERS_FILE)) return JSON.parse(fs.readFileSync(USERS_FILE, 'utf-8')); }
  catch (e) { console.error(e.message); }
  return [];
}
function saveUsers(u) { fs.writeFileSync(USERS_FILE, JSON.stringify(u, null, 2)); }

function loadInvites() {
  try { if (fs.existsSync(INVITES_FILE)) return JSON.parse(fs.readFileSync(INVITES_FILE, 'utf-8')); }
  catch (e) { console.error(e.message); }
  return [];
}
function saveInvites(i) { fs.writeFileSync(INVITES_FILE, JSON.stringify(i, null, 2)); }

function hashPassword(pw, salt) {
  salt = salt || crypto.randomBytes(16).toString('hex');
  return { hash: crypto.scryptSync(pw, salt, 64).toString('hex'), salt };
}
function verifyPassword(pw, salt, hash) {
  return crypto.timingSafeEqual(
    Buffer.from(hashPassword(pw, salt).hash),
    Buffer.from(hash)
  );
}

function createToken(payload) {
  const h = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const b = Buffer.from(JSON.stringify({ ...payload, iat: Math.floor(Date.now() / 1000) })).toString('base64url');
  const s = crypto.createHmac('sha256', getSecret()).update(h + '.' + b).digest('base64url');
  return h + '.' + b + '.' + s;
}
function verifyToken(token) {
  try {
    const p = token.split('.');
    if (p.length !== 3) return null;
    const s = crypto.createHmac('sha256', getSecret()).update(p[0] + '.' + p[1]).digest('base64url');
    if (s !== p[2]) return null;
    return JSON.parse(Buffer.from(p[1], 'base64url').toString());
  } catch (e) { return null; }
}
function getUserId(req) {
  const t = (req.headers['authorization'] || '').replace(/^Bearer\s+/i, '');
  const p = verifyToken(t);
  return p ? p.uid : null;
}
function getUserRole(req) {
  const t = (req.headers['authorization'] || '').replace(/^Bearer\s+/i, '');
  const p = verifyToken(t);
  return p ? p.role : null;
}

function parseBody(req, res, cb) {
  const c = [];
  req.on('data', d => c.push(d));
  req.on('end', () => {
    try { cb(JSON.parse(Buffer.concat(c).toString())); }
    catch (e) { res.writeHead(400, cors()); res.end(JSON.stringify({ error: 'Invalid JSON' })); }
  });
}

function cors() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}
function send(res, code, data) {
  res.writeHead(code, cors());
  res.end(JSON.stringify(data));
}

// ==================== 邀请码/验证码 ====================

const VERIFY_CODES = {};

function ensureDefaultInvites() {
  const invites = loadInvites();
  if (invites.length === 0) {
    invites.push({ code: 'MATHMATE2026', role: 'admin', createdBy: 'system', used: false, usedBy: null, reusable: false, createdAt: new Date().toISOString() });
    invites.push({ code: 'DEVMATE2026', role: 'dev', createdBy: 'system', used: false, usedBy: null, reusable: false, createdAt: new Date().toISOString() });
    invites.push({ code: 'DEVLOGIN', role: 'dev', createdBy: 'system', used: false, usedBy: null, reusable: true, devLogin: true, createdAt: new Date().toISOString() });
    invites.push({ code: 'MATHUSER', role: 'user', createdBy: 'system', used: false, usedBy: null, reusable: true, createdAt: new Date().toISOString() });
    saveInvites(invites);
  }
}

function validateInviteCode(code) {
  const invites = loadInvites();
  const invite = invites.find(i => i.code === code.toUpperCase().trim());
  if (!invite) return null;
  if (!invite.reusable && invite.used) return null;
  return { role: invite.role, code: invite.code, devLogin: !!invite.devLogin };
}

function consumeInviteCode(code, username) {
  const invites = loadInvites();
  const invite = invites.find(i => i.code === code.toUpperCase().trim());
  if (invite && !invite.reusable) {
    invite.used = true;
    invite.usedBy = username;
    saveInvites(invites);
  }
}

function genCode() { return String(Math.floor(100000 + Math.random() * 900000)); }

// ==================== 邀请码直登（开发者模式） ====================

function handleDevLogin(req, res, body) {
  const { inviteCode } = body;
  if (!inviteCode) return send(res, 400, { error: '请输入邀请码' });

  const invite = validateInviteCode(inviteCode);
  if (!invite) return send(res, 403, { error: '邀请码无效或已被使用' });
  if (!invite.devLogin && invite.role !== 'admin' && invite.role !== 'dev') {
    return send(res, 403, { error: '此邀请码不支持开发者登录，请通过正常注册流程' });
  }

  // 查找或创建临时开发者账户
  let users = loadUsers();
  let user = users.find(u => u.username === '__dev__' + invite.code);
  if (!user) {
    const { hash, salt } = hashPassword(inviteCode);
    user = {
      id: 'dev_' + Date.now().toString(36),
      username: '__dev__' + invite.code,
      displayName: '开发者 (' + invite.role + ')',
      passwordHash: hash,
      passwordSalt: salt,
      email: '',
      role: invite.role,
      inviteCode: invite.code,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    users.push(user);
    saveUsers(users);
    consumeInviteCode(inviteCode, user.username);
  }

  const token = createToken({ uid: user.id, role: user.role });
  console.log(`[auth] 开发者直登: ${inviteCode} → ${user.role}`);
  return send(res, 200, {
    token,
    devMode: true,
    user: { id: user.id, username: user.displayName || user.username, email: '', role: user.role },
  });
}

// ==================== 注册/登录 ====================

function handleSendCode(req, res, body) {
  const { email, phone } = body;
  const target = (email || phone || '').trim();
  if (!target) return send(res, 400, { error: '请输入邮箱或手机号' });

  const users = loadUsers();
  if (users.find(u => u.email === target || u.phone === target)) {
    return send(res, 409, { error: '该邮箱/手机号已注册' });
  }

  const exist = VERIFY_CODES[target];
  if (exist && (Date.now() - exist.sentAt) < 60000) {
    return send(res, 429, { error: '发送过于频繁，请 60 秒后再试' });
  }

  const code = genCode();
  VERIFY_CODES[target] = { code, expires: Date.now() + 300000, attempts: 0, sentAt: Date.now(), verified: false };

  const isEmail = target.includes('@');
  console.log(`========== 验证码 ==========`);
  console.log(`目标: ${target}`);
  console.log(`验证码: ${code}`);
  console.log(`============================`);

  return send(res, 200, { ok: true, message: `验证码已${isEmail ? '发送至邮箱' : '生成'}，有效期 5 分钟` });
}

function handleVerifyCode(req, res) {
  const { email, phone, code } = req.body;
  const target = (email || phone || '').trim();
  if (!target || !code) return send(res, 400, { error: '参数不完整' });

  const vc = VERIFY_CODES[target];
  if (!vc) return send(res, 400, { error: '请先获取验证码' });
  if (vc.expires < Date.now()) { delete VERIFY_CODES[target]; return send(res, 400, { error: '验证码已过期，请重新获取' }); }

  vc.attempts++;
  if (vc.attempts > 5) { delete VERIFY_CODES[target]; return send(res, 429, { error: '尝试次数过多，请重新获取验证码' }); }

  if (vc.code !== code.trim()) {
    return send(res, 400, { error: `验证码错误，还剩 ${5 - vc.attempts} 次机会` });
  }

  vc.verified = true;
  return send(res, 200, { ok: true, message: '验证成功' });
}

function handleRegister(req, res, body) {
  const { username, password, email, phone, inviteCode } = body;
  const target = (email || phone || '').trim();

  if (!username || username.length < 2) return send(res, 400, { error: '用户名至少 2 个字符' });
  if (!password || password.length < 6) return send(res, 400, { error: '密码至少 6 位' });
  if (!inviteCode) return send(res, 400, { error: '请输入邀请码' });
  if (!target) return send(res, 400, { error: '请输入邮箱或手机号' });

  // 验证邀请码
  const invite = validateInviteCode(inviteCode);
  if (!invite) return send(res, 403, { error: '邀请码无效或已被使用' });

  // 验证邮箱/手机
  const vc = VERIFY_CODES[target];
  if (!vc || !vc.verified) return send(res, 400, { error: '请先完成邮箱/手机号验证' });

  const users = loadUsers();
  if (users.find(u => u.username === username)) return send(res, 409, { error: '用户名已存在' });

  const { hash, salt } = hashPassword(password);
  const user = {
    id: 'u' + Date.now().toString(36) + crypto.randomBytes(3).toString('hex'),
    username, passwordHash: hash, passwordSalt: salt,
    email: email || '', phone: phone || '',
    role: invite.role, inviteCode: invite.code,
    createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
  };
  users.push(user);
  saveUsers(users);
  consumeInviteCode(inviteCode, username);
  delete VERIFY_CODES[target];

  const token = createToken({ uid: user.id, role: user.role });
  console.log(`[auth] 注册成功: ${username} (${user.role})`);
  return send(res, 201, { token, user: { id: user.id, username, email: user.email, role: user.role } });
}

function handleLogin(req, res, body) {
  const { username, password } = body;
  if (!username || !password) return send(res, 400, { error: '请输入用户名和密码' });

  const users = loadUsers();
  const user = users.find(u => u.username === username);
  if (!user || !verifyPassword(password, user.passwordSalt, user.passwordHash)) {
    return send(res, 401, { error: '用户名或密码错误' });
  }
  const token = createToken({ uid: user.id, role: user.role });
  return send(res, 200, { token, user: { id: user.id, username, email: user.email || '', role: user.role } });
}

function handleProfile(req, res) {
  const uid = getUserId(req);
  if (!uid) return send(res, 401, { error: '未登录' });
  const users = loadUsers();
  const user = users.find(u => u.id === uid);
  if (!user) return send(res, 404, { error: '用户不存在' });

  if (req.method === 'GET') {
    return send(res, 200, { id: user.id, username: user.username, email: user.email || '', role: user.role, createdAt: user.createdAt });
  }
  if (req.method === 'PUT') {
    parseBody(req, res, (b) => {
      if (b.email !== undefined) user.email = b.email;
      if (b.password) { const r = hashPassword(b.password); user.passwordHash = r.hash; user.passwordSalt = r.salt; }
      user.updatedAt = new Date().toISOString();
      saveUsers(users);
      return send(res, 200, { ok: true });
    });
    return;
  }
}

function handleUsers(req, res) {
  const role = getUserRole(req);
  if (!role || (role !== 'admin' && role !== 'dev')) return send(res, 403, { error: '无权限' });
  const users = loadUsers();
  if (req.method === 'GET') return send(res, 200, users.map(u => ({ id: u.id, username: u.username, email: u.email || '', role: u.role, createdAt: u.createdAt })));
  if (req.method === 'PUT') {
    parseBody(req, res, (b) => {
      const t = users.find(u => u.id === b.id);
      if (!t) return send(res, 404, { error: '用户不存在' });
      if (b.role) t.role = b.role;
      t.updatedAt = new Date().toISOString();
      saveUsers(users);
      return send(res, 200, { ok: true });
    });
    return;
  }
}

function handleInvites(req, res) {
  const role = getUserRole(req);
  if (!role || (role !== 'admin' && role !== 'dev')) return send(res, 403, { error: '无权限' });
  const uid = getUserId(req);

  if (req.method === 'GET') return send(res, 200, loadInvites());

  if (req.method === 'POST') {
    parseBody(req, res, (b) => {
      if (!['admin', 'dev', 'user'].includes(b.role)) return send(res, 400, { error: '无效角色' });
      const users = loadUsers();
      const creator = users.find(u => u.id === uid);
      const n = Math.min(b.count || 1, 50);
      const codes = [];
      const invites = loadInvites();
      for (let i = 0; i < n; i++) {
        const code = 'MM' + crypto.randomBytes(4).toString('hex').toUpperCase();
        invites.push({ code, role: b.role, createdBy: creator?.username || 'unknown', used: false, usedBy: null, createdAt: new Date().toISOString() });
        codes.push(code);
      }
      saveInvites(invites);
      return send(res, 201, { codes });
    });
    return;
  }
  if (req.method === 'DELETE') {
    parseBody(req, res, (b) => {
      let invites = loadInvites();
      const before = invites.length;
      invites = invites.filter(i => i.code !== b.code);
      saveInvites(invites);
      return send(res, 200, { ok: true, removed: before - invites.length });
    });
    return;
  }
}

// ==================== Server ====================

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') { res.writeHead(200, cors()); res.end(); return; }
  console.log(`[auth] ${req.method} ${req.url}`);

  if (req.url === '/api/auth/register' && req.method === 'POST')
    return parseBody(req, res, b => handleRegister(req, res, b));

  if (req.url === '/api/auth/login' && req.method === 'POST')
    return parseBody(req, res, b => handleLogin(req, res, b));

  if (req.url === '/api/auth/dev-login' && req.method === 'POST')
    return parseBody(req, res, b => handleDevLogin(req, res, b));

  if (req.url === '/api/auth/send-code' && req.method === 'POST')
    return parseBody(req, res, b => handleSendCode(req, res, b));

  if (req.url === '/api/auth/verify-code' && req.method === 'POST')
    return parseBody(req, res, b => handleVerifyCode(req, res, b));

  if (req.url === '/api/auth/profile' && (req.method === 'GET' || req.method === 'PUT'))
    return handleProfile(req, res);

  if (req.url === '/api/auth/users') return handleUsers(req, res);
  if (req.url === '/api/auth/invites') return handleInvites(req, res);

  if (req.url === '/api/auth/health') return send(res, 200, { ok: true });

  send(res, 404, { error: 'Not found' });
});

ensureDefaultInvites();
server.listen(3002, '127.0.0.1', () => console.log('MathMate Auth v3 running on :3002'));
