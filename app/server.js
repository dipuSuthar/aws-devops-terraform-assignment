const os = require("os");
const express = require("express");
const mysql = require("mysql2/promise");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const region = process.env.AWS_REGION || "ap-south-1";
const app = express();
app.use(express.json());
let pool;

// DB credentials are read from Secrets Manager at startup (never stored on disk / in env)
async function initDb() {
  const sm = new SecretsManagerClient({ region });
  const res = await sm.send(new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN }));
  const s = JSON.parse(res.SecretString);
  pool = mysql.createPool({
    host: s.host, port: 3306, user: s.username, password: s.password, database: s.dbname,
    ssl: { rejectUnauthorized: false }, connectionLimit: 5,
  });
  await pool.query(
    "CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, text VARCHAR(255) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
  );
}

// Lightweight liveness check used by the ALB target group
app.get("/health", (_req, res) => res.json({ status: "ok", host: os.hostname() }));

// Deep check: verifies DB connectivity (used in pipeline validation)
app.get("/health/db", async (_req, res) => {
  try { await pool.query("SELECT 1"); res.json({ status: "ok", db: "connected" }); }
  catch (e) { res.status(503).json({ status: "error", db: e.message }); }
});

app.get("/", (_req, res) =>
  res.send(`<h1>DevOps Task App</h1><p>Served by: ${os.hostname()}</p><p>Try <a href="/api/notes">/api/notes</a>, <a href="/health/db">/health/db</a></p>`)
);

app.get("/api/notes", async (_req, res) => {
  const [rows] = await pool.query("SELECT * FROM notes ORDER BY id DESC LIMIT 50");
  res.json(rows);
});

app.post("/api/notes", async (req, res) => {
  const text = (req.body.text || "").toString().slice(0, 255);
  if (!text) return res.status(400).json({ error: "text required" });
  const [r] = await pool.query("INSERT INTO notes (text) VALUES (?)", [text]);
  res.status(201).json({ id: r.insertId, text });
});

// Writes a small object to the application S3 bucket (proves IAM role -> S3 access)
app.post("/api/upload", async (req, res) => {
  const key = `uploads/${Date.now()}.txt`;
  await new S3Client({ region }).send(
    new PutObjectCommand({ Bucket: process.env.APP_BUCKET, Key: key, Body: JSON.stringify(req.body || {}), ServerSideEncryption: "AES256" })
  );
  res.status(201).json({ key });
});

initDb()
  .then(() => app.listen(process.env.PORT || 3000, () => console.log("listening")))
  .catch((e) => { console.error("startup failed", e); process.exit(1); });
