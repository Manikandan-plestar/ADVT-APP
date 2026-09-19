const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Load environment variables from .env
dotenv.config();

// ==========================================
// 1. CONFIGURATION & ENVIRONMENT VARIABLES
// ==========================================
const PORT = process.env.PORT || 5000;
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT || '3306', 10);
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'ADVT_APP';

const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '587', 10);
const SMTP_SECURE = process.env.SMTP_SECURE === 'true';
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const FROM_EMAIL = process.env.FROM_EMAIL || `"ADVT App" <${SMTP_USER || 'no-reply@advtapp.com'}>`;

const JWT_SECRET = process.env.JWT_SECRET || 'advt_app_jwt_super_secret_key_2026_xyz';
const OTP_EXPIRY_MINUTES = parseInt(process.env.OTP_EXPIRY_MINUTES || '5', 10);
const RATE_LIMIT_MAX = parseInt(process.env.RATE_LIMIT_MAX_ATTEMPTS || '3', 10);
const RATE_LIMIT_WINDOW_MIN = parseInt(process.env.RATE_LIMIT_WINDOW_MINUTES || '10', 10);

// ==========================================
// 2. MYSQL DATABASE CONNECTION POOL
// ==========================================
const pool = mysql.createPool({
  host: DB_HOST,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: '+00:00'
});

/**
 * Automatically creates the email_otp table if it does not exist
 */
async function initDatabase() {
  try {
    const connection = await pool.getConnection();
    console.log(`[Database] Connected successfully to MySQL database: "${DB_NAME}"`);

    // Ensure email_otp table is created
    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS email_otp (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        otp VARCHAR(6) NOT NULL,
        expires_at DATETIME NOT NULL,
        is_used TINYINT DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email),
        INDEX idx_expires (expires_at),
        INDEX idx_created (created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;

    await connection.query(createTableQuery);
    console.log('[Database] Table "email_otp" is verified and ready.');

    connection.release();
  } catch (error) {
    console.error('[Database] MySQL Connection/Initialization Error:', error.message);
    if (error.code === 'ER_BAD_DB_ERROR') {
      console.error(`[Database] Tip: Make sure database "${DB_NAME}" exists in MySQL.`);
    }
  }
}

// ==========================================
// 3. NODEMAILER EMAIL TRANSPORTER
// ==========================================
const cleanSmtpPass = (SMTP_PASS || '').replace(/\s+/g, '');

const transporterConfig = SMTP_HOST === 'smtp.gmail.com'
  ? {
      service: 'gmail',
      auth: {
        user: SMTP_USER,
        pass: cleanSmtpPass,
      },
    }
  : {
      host: SMTP_HOST,
      port: SMTP_PORT,
      secure: SMTP_SECURE,
      auth: {
        user: SMTP_USER,
        pass: cleanSmtpPass,
      },
      tls: {
        rejectUnauthorized: false
      }
    };

const transporter = nodemailer.createTransport(transporterConfig);

// Verify email transporter on startup
transporter.verify((error) => {
  if (error) {
    console.warn('[Mailer] SMTP Warning: Could not verify SMTP credentials. Please check .env settings.');
    console.warn(`[Mailer] Error details: ${error.message}`);
  } else {
    console.log(`[Mailer] SMTP Transporter ready to send emails from: ${SMTP_USER}`);
  }
});

function buildOtpHtmlTemplate(otp, expiryMinutes = 5) {
  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verification Code</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; margin: 0; padding: 0; }
      .container { max-width: 500px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e2e8f0; }
      .header { background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%); padding: 30px 20px; text-align: center; color: #ffffff; }
      .header h1 { margin: 0; font-size: 24px; font-weight: 700; }
      .content { padding: 30px 24px; text-align: center; color: #334155; }
      .otp-box { display: inline-block; background: #eef2ff; border: 2px dashed #4f46e5; border-radius: 12px; padding: 14px 32px; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #4f46e5; margin: 15px 0 20px 0; }
      .expiry { font-size: 13px; color: #ef4444; font-weight: 600; margin-bottom: 16px; }
      .security { font-size: 12px; color: #94a3b8; line-height: 1.5; border-top: 1px solid #f1f5f9; padding-top: 16px; margin-top: 20px; }
      .footer { background: #f8fafc; padding: 14px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>ADVT APP</h1>
        <p style="margin: 4px 0 0 0; opacity: 0.9; font-size: 14px;">Email Verification Code</p>
      </div>
      <div class="content">
        <p style="font-size: 15px; margin-bottom: 16px;">Please use the following 6-digit code to complete your verification:</p>
        <div class="otp-box">${otp}</div>
        <p class="expiry">⚠️ This code expires in ${expiryMinutes} minutes.</p>
        <div class="security">If you did not request this code, please ignore this email. Never share your OTP with anyone.</div>
      </div>
      <div class="footer">&copy; ${new Date().getFullYear()} ADVT APP. All rights reserved.</div>
    </div>
  </body>
  </html>
  `;
}

/**
 * Sends OTP email using Nodemailer. Throws error if email fails.
 */
async function sendOtpEmail(email, otp) {
  if (!SMTP_USER || !SMTP_PASS) {
    throw new Error('SMTP credentials are not configured in backend .env file.');
  }

  const mailOptions = {
    from: FROM_EMAIL,
    to: email,
    subject: `${otp} is your ADVT APP verification code`,
    text: `Your ADVT APP verification code is: ${otp}. It will expire in ${OTP_EXPIRY_MINUTES} minutes.`,
    html: buildOtpHtmlTemplate(otp, OTP_EXPIRY_MINUTES),
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`[Mailer] Verification OTP sent successfully to ${email} (MessageID: ${info.messageId})`);
  return info;
}

// ==========================================
// 4. HELPER FUNCTIONS & LOGIC
// ==========================================
const IS_DEV = process.env.NODE_ENV !== 'production';

// Configured Development-Only Test Accounts
const DEV_TEST_ACCOUNTS = {
  'test1@gmail.com': '123456',
  'test2@gmail.com': '123456'
};

function isDevTestAccount(email) {
  return IS_DEV && Object.prototype.hasOwnProperty.call(DEV_TEST_ACCOUNTS, (email || '').toLowerCase().trim());
}

function verifyDevTestCredentials(email, otp) {
  if (!IS_DEV) return false;
  const cleanEmail = (email || '').toLowerCase().trim();
  const cleanOtp = (otp || '').toString().trim();
  return DEV_TEST_ACCOUNTS[cleanEmail] === cleanOtp;
}

function generate6DigitOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

function isValidEmailFormat(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return email && emailRegex.test(email.trim());
}

async function checkRateLimit(email) {
  const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MIN * 60 * 1000);
  const [rows] = await pool.query(
    `SELECT COUNT(*) AS attempt_count 
     FROM email_otp 
     WHERE email = ? AND created_at >= ?`,
    [email, windowStart]
  );

  const attemptCount = rows[0]?.attempt_count || 0;
  return {
    isLimited: attemptCount >= RATE_LIMIT_MAX,
    attemptCount
  };
}

/**
 * Generates OTP, saves to email_otp table, and delivers via email.
 */
async function processAndSendOtp(email) {
  const cleanEmail = email.trim().toLowerCase();

  // Development-only test accounts bypass real email sending
  if (isDevTestAccount(cleanEmail)) {
    console.log(`[Auth DEV] Recognized test account: ${cleanEmail}. Skipping email dispatch.`);
    return {
      email: cleanEmail,
      expiresInSeconds: OTP_EXPIRY_MINUTES * 60
    };
  }

  // 1. Rate limiting check (max 3 per 10 minutes)
  const rateStatus = await checkRateLimit(cleanEmail);
  if (rateStatus.isLimited) {
    const error = new Error(`Rate limit exceeded. Maximum ${RATE_LIMIT_MAX} requests per ${RATE_LIMIT_WINDOW_MIN} minutes.`);
    error.statusCode = 429;
    throw error;
  }

  // 2. Invalidate any existing unused OTPs for this email
  await pool.query(
    `UPDATE email_otp SET is_used = 1 WHERE email = ? AND is_used = 0`,
    [cleanEmail]
  );

  // 3. Generate secure 6-digit OTP
  const otp = generate6DigitOtp();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // 4. Save record to MySQL database table email_otp
  const [insertResult] = await pool.query(
    `INSERT INTO email_otp (email, otp, expires_at, is_used) VALUES (?, ?, ?, 0)`,
    [cleanEmail, otp, expiresAt]
  );

  // 5. Send OTP via Email service (Strict - Do not ignore errors)
  try {
    await sendOtpEmail(cleanEmail, otp);
  } catch (mailErr) {
    // If sending fails, delete the OTP record from database so invalid records don't persist
    await pool.query(`DELETE FROM email_otp WHERE id = ?`, [insertResult.insertId]);
    console.error(`[Auth] Failed to deliver OTP email to ${cleanEmail}:`, mailErr.message);
    const error = new Error(`Failed to send verification email: ${mailErr.message}`);
    error.statusCode = 500;
    throw error;
  }

  return {
    email: cleanEmail,
    expiresInSeconds: OTP_EXPIRY_MINUTES * 60
  };
}

// ==========================================
// 5. EXPRESS APP & API ROUTE HANDLERS
// ==========================================
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request Logger
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

// Health Check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    timestamp: new Date().toISOString(),
    service: 'ADVT APP Authentication Server'
  });
});

/**
 * 1. POST /api/send-email-otp
 * Body: { "email": "user@example.com" }
 */
app.post(['/api/send-email-otp', '/api/send-otp'], async (req, res) => {
  try {
    const { email } = req.body;
    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'A valid email address is required.'
      });
    }

    const data = await processAndSendOtp(email);
    return res.status(200).json({
      success: true,
      message: `Verification code sent to ${data.email}.`,
      expiresInSeconds: data.expiresInSeconds
    });
  } catch (error) {
    const status = error.statusCode || 500;
    return res.status(status).json({
      success: false,
      message: error.message || 'Failed to send OTP.'
    });
  }
});

/**
 * 2. POST /api/resend-email-otp
 * Body: { "email": "user@example.com" }
 */
app.post(['/api/resend-email-otp', '/api/resend-otp'], async (req, res) => {
  try {
    const { email } = req.body;
    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'A valid email address is required.'
      });
    }

    const data = await processAndSendOtp(email);
    return res.status(200).json({
      success: true,
      message: `A new verification code was sent to ${data.email}.`,
      expiresInSeconds: data.expiresInSeconds
    });
  } catch (error) {
    const status = error.statusCode || 500;
    return res.status(status).json({
      success: false,
      message: error.message || 'Failed to resend OTP.'
    });
  }
});

/**
 * 3. POST /api/verify-email-otp
 * Body: { "email": "user@example.com", "otp": "654321" }
 */
app.post(['/api/verify-email-otp', '/api/verify-otp'], async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'A valid email address is required.'
      });
    }

    if (!otp || otp.toString().trim().length !== 6) {
      return res.status(400).json({
        success: false,
        message: 'Wrong OTP'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = otp.toString().trim();

    // 1. Development Test Account Bypass (test1@gmail.com, test2@gmail.com with PIN 123456)
    if (isDevTestAccount(cleanEmail)) {
      if (verifyDevTestCredentials(cleanEmail, cleanOtp)) {
        const token = jwt.sign(
          { email: cleanEmail, isVerified: true, isDevTest: true },
          JWT_SECRET,
          { expiresIn: '7d' }
        );

        console.log(`[Auth DEV] Test account authenticated successfully: ${cleanEmail}`);
        return res.status(200).json({
          success: true,
          message: 'Email verified successfully!',
          token,
          user: {
            email: cleanEmail,
            isEmailVerified: true
          }
        });
      } else {
        return res.status(400).json({
          success: false,
          message: 'Wrong OTP'
        });
      }
    }

    // 2. Normal Users: Query the latest active OTP record from database
    const [rows] = await pool.query(
      `SELECT * FROM email_otp 
       WHERE email = ? AND is_used = 0
       ORDER BY created_at DESC 
       LIMIT 1`,
      [cleanEmail]
    );

    if (!rows || rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Wrong OTP'
      });
    }

    const record = rows[0];

    // Check expiration
    const now = new Date();
    const expiresAt = new Date(record.expires_at);
    if (now > expiresAt) {
      await pool.query(`UPDATE email_otp SET is_used = 1 WHERE id = ?`, [record.id]);
      return res.status(400).json({
        success: false,
        message: 'OTP expired. Please resend the OTP.'
      });
    }

    // Check code match
    if (record.otp !== cleanOtp) {
      return res.status(400).json({
        success: false,
        message: 'Wrong OTP'
      });
    }

    // Mark OTP as used (invalidate single-use)
    await pool.query(`UPDATE email_otp SET is_used = 1 WHERE id = ?`, [record.id]);

    // Generate JWT session token
    const token = jwt.sign(
      { email: cleanEmail, isVerified: true },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log(`[Auth] Email successfully verified: ${cleanEmail}`);

    return res.status(200).json({
      success: true,
      message: 'Email verified successfully!',
      token,
      user: {
        email: cleanEmail,
        isEmailVerified: true
      }
    });
  } catch (error) {
    console.error('[Auth] Verification error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while verifying OTP.'
    });
  }
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} not found.`
  });
});

// ==========================================
// 6. BOOTSTRAP SERVER
// ==========================================
async function startServer() {
  await initDatabase();

  app.listen(PORT, '0.0.0.0', () => {
    // console.log(`====================================================`);
    // console.log(`🚀 ADVT APP Server running on http://localhost:${PORT}`);
    // console.log(`📡 Endpoints:`);
    // console.log(`   - POST http://localhost:${PORT}/api/send-email-otp`);
    // console.log(`   - POST http://localhost:${PORT}/api/verify-email-otp`);
    // console.log(`   - POST http://localhost:${PORT}/api/resend-email-otp`);
    // console.log(`   - GET  http://localhost:${PORT}/api/health`);
    // console.log(`====================================================`);
  });
}

startServer();
