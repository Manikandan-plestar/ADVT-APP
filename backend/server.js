const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const http = require('http');
const https = require('https');

// Load environment variables from .env
dotenv.config();

// ==========================================
// 1. CONFIGURATION & ENVIRONMENT VARIABLES
// ==========================================
const PORT = parseInt(process.env.PORT || '5000', 10);
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT || '3306', 10);
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'advt_app';

const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '465', 10);
const SMTP_SECURE = process.env.SMTP_SECURE !== 'false';
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const FROM_EMAIL = process.env.FROM_EMAIL || `"ADVT APP" <${SMTP_USER || 'no-reply@advtapp.com'}>`;

const JWT_SECRET = process.env.JWT_SECRET || 'advt_app_jwt_super_secret_key_2026_xyz';
const OTP_EXPIRY_MINUTES = parseInt(process.env.OTP_EXPIRY_MINUTES || '5', 10);
const RATE_LIMIT_MAX = parseInt(process.env.RATE_LIMIT_MAX_ATTEMPTS || '3', 10);
const RATE_LIMIT_WINDOW_MIN = parseInt(process.env.RATE_LIMIT_WINDOW_MINUTES || '10', 10);

// ==========================================
// 2. MYSQL DATABASE CONNECTION POOL & SCHEMA
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
 * Automatically creates the Database & all required Tables (email_otp, users)
 */
async function initDatabase() {
  try {
    // 1. Verify/Create database connection
    const rawConnection = await mysql.createConnection({
      host: DB_HOST,
      port: DB_PORT,
      user: DB_USER,
      password: DB_PASSWORD
    });

    await rawConnection.query(`
      CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
      CHARACTER SET utf8mb4 
      COLLATE utf8mb4_unicode_ci;
    `);
    await rawConnection.end();

    const connection = await pool.getConnection();
    console.log(`[Database] Connected successfully to MySQL database: "${DB_NAME}"`);

    // 2. Table: email_otp (Email Verification Codes)
    const createOtpTableQuery = `
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
    await connection.query(createOtpTableQuery);
    console.log('[Database] Table "email_otp" is verified and ready.');

    // 3. Table: users (Registered App Users with 1-Email-Per-User rule)
    const createUsersTableQuery = `
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        full_name VARCHAR(255) NOT NULL,
        mobile_number VARCHAR(20) NOT NULL,
        country_code VARCHAR(10) DEFAULT '+91',
        full_address TEXT NOT NULL,
        locality VARCHAR(100),
        city VARCHAR(100),
        state VARCHAR(100),
        country VARCHAR(100),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_email (email),
        INDEX idx_city (city),
        INDEX idx_state (state)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;
    await connection.query(createUsersTableQuery);
    console.log('[Database] Table "users" is verified and ready.');

    // Seed test accounts if not already present
    await connection.query(`
      INSERT IGNORE INTO users (email, full_name, mobile_number, country_code, full_address, locality, city, state, country)
      VALUES 
        ('test1@gmail.com', 'Test User 1', '9876543210', '+91', '123 Test Street, Anna Nagar, Chennai, Tamil Nadu, India', 'Anna Nagar', 'Chennai', 'Tamil Nadu', 'India'),
        ('test2@gmail.com', 'Test User 2', '9876543211', '+91', '456 Demo Avenue, T Nagar, Chennai, Tamil Nadu, India', 'T Nagar', 'Chennai', 'Tamil Nadu', 'India');
    `);

    // 4. Table: business_profile (Business Profiles owned by users)
    const createBusinessProfileTableQuery = `
      CREATE TABLE IF NOT EXISTS business_profile (
        business_id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        business_name VARCHAR(255) NOT NULL,
        category VARCHAR(100),
        business_phone VARCHAR(30) NOT NULL,
        country_code VARCHAR(10) DEFAULT '+91',
        full_address TEXT NOT NULL,
        locality VARCHAR(100),
        city VARCHAR(100),
        state VARCHAR(100),
        country VARCHAR(100) DEFAULT 'India',
        latitude DECIMAL(10, 7) DEFAULT 0.0,
        longitude DECIMAL(10, 7) DEFAULT 0.0,
        profile_image TEXT,
        images TEXT,
        about TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_user_id (user_id),
        INDEX idx_city (city),
        INDEX idx_category (category)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;
    await connection.query(createBusinessProfileTableQuery);
    console.log('[Database] Table "business_profile" is verified and ready.');

    // 5. Table: posts (Posts for Jobs, Offers, and Coupons)
    const createPostsTableQuery = `
      CREATE TABLE IF NOT EXISTS posts (
        post_id INT AUTO_INCREMENT PRIMARY KEY,
        business_id INT NOT NULL,
        user_id INT NOT NULL,
        post_type ENUM('job', 'offer', 'coupon') NOT NULL,
        title VARCHAR(255) NOT NULL,
        subtitle VARCHAR(255),
        description TEXT,
        coupon_code VARCHAR(50),
        discount_label VARCHAR(100),
        job_type VARCHAR(50),
        experience VARCHAR(100),
        validity VARCHAR(100),
        badge_text VARCHAR(50),
        terms TEXT,
        target_location VARCHAR(255) NOT NULL,
        target_city VARCHAR(100),
        target_district VARCHAR(100),
        target_state VARCHAR(100) DEFAULT 'Tamil Nadu',
        target_locations_json TEXT,
        images TEXT,
        brand_logo TEXT,
        is_active TINYINT DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_business_id (business_id),
        INDEX idx_user_id (user_id),
        INDEX idx_location_type (target_location, post_type, is_active),
        INDEX idx_created (created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;
    await connection.query(createPostsTableQuery);
    console.log('[Database] Table "posts" is verified and ready.');

    // Auto-migrate/heal existing records if locality, city, or country are empty
    try {
      const [existingUsers] = await connection.query(
        `SELECT id, full_address, locality, city, state, country 
         FROM users 
         WHERE (locality IS NULL OR locality = '') 
            OR (city IS NULL OR city = '') 
            OR (country IS NULL OR country = '')`
      );
      for (const u of existingUsers) {
        if (u.full_address && u.full_address.trim().length > 0) {
          const comps = extractAddressComponents(u.full_address, u.locality, u.city, u.state, u.country);
          await connection.query(
            `UPDATE users SET locality = ?, city = ?, state = ?, country = ? WHERE id = ?`,
            [comps.locality, comps.city, comps.state, comps.country, u.id]
          );
          console.log(`[Database] Auto-populated address components for user ID ${u.id} (${comps.locality}, ${comps.city}, ${comps.country})`);
        }
      }
    } catch (healErr) {
      console.warn('[Database] Note on address healing:', healErr.message);
    }

    connection.release();
  } catch (error) {
    console.error('[Database] MySQL Initialization Error:', error.message);
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

transporter.verify((error) => {
  if (error) {
    console.warn('[Mailer] SMTP Warning: Could not verify SMTP credentials. Please check .env settings.');
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

async function sendOtpEmail(email, otp) {
  if (!SMTP_USER || !cleanSmtpPass) {
    throw new Error('SMTP credentials are not configured in backend .env file.');
  }

  const senderAddress = FROM_EMAIL && FROM_EMAIL.includes('<') && FROM_EMAIL.includes('>')
    ? FROM_EMAIL
    : `"ADVT APP" <${SMTP_USER}>`;

  const mailOptions = {
    from: senderAddress,
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
// Test / Demo Accounts (Enabled in both Development & Production for Testing & App Store / Play Store Review)
const TEST_ACCOUNTS = {
  'test1@gmail.com': '123456',
  'test2@gmail.com': '123456'
};

function isTestAccount(email) {
  return Object.prototype.hasOwnProperty.call(TEST_ACCOUNTS, (email || '').toLowerCase().trim());
}

function verifyTestCredentials(email, otp) {
  const cleanEmail = (email || '').toLowerCase().trim();
  const cleanOtp = (otp || '').toString().trim();
  return TEST_ACCOUNTS[cleanEmail] === cleanOtp;
}

function generate6DigitOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

function isValidEmailFormat(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return email && emailRegex.test(email.trim());
}

/**
 * Extracts locality, city, state, and country from full address string
 * if any of those individual fields are empty or missing.
 * The full_address is ALWAYS preserved 100% completely.
 */
function extractAddressComponents(fullAddress, existingLocality = '', existingCity = '', existingState = '', existingCountry = '') {
  let locality = (existingLocality || '').trim();
  let city = (existingCity || '').trim();
  let state = (existingState || '').trim();
  let country = (existingCountry || '').trim();

  const rawAddress = (fullAddress || '').trim();
  if (!rawAddress) {
    return {
      full_address: '',
      locality: locality || 'Local Area',
      city: city || 'City',
      state: state || 'State',
      country: country || 'India'
    };
  }

  // Split address by commas and clean each component
  const parts = rawAddress
    .split(',')
    .map(p => p.trim())
    .filter(p => p.length > 0);

  if (parts.length > 0) {
    // 1. Country extraction (last segment)
    if (!country) {
      const lastPart = parts[parts.length - 1];
      const cleanedCountry = lastPart.replace(/[0-9-]/g, '').trim();
      if (cleanedCountry.length > 1) {
        country = cleanedCountry;
      } else {
        country = 'India';
      }
    }

    // 2. State extraction (2nd from last, or segment containing postal code)
    if (!state) {
      if (parts.length >= 2) {
        const stateCandidate = parts[parts.length - 2];
        const cleanedState = stateCandidate.replace(/[0-9-]/g, '').trim();
        if (cleanedState.length > 0) {
          state = cleanedState;
        }
      }
      if (!state && parts.length === 1) {
        state = 'Tamil Nadu';
      }
    }

    // 3. City extraction (3rd from last, or 1st/2nd segment)
    if (!city) {
      if (parts.length >= 3) {
        city = parts[parts.length - 3].replace(/[0-9-]/g, '').trim();
      } else if (parts.length === 2) {
        city = parts[0].replace(/[0-9-]/g, '').trim();
      } else if (parts.length === 1) {
        city = parts[0].trim();
      }
      if (!city) city = 'Chennai';
    }

    // 4. Locality extraction (street, sublocality, or leading segment)
    if (!locality) {
      if (parts.length >= 4) {
        locality = parts.slice(0, parts.length - 3).join(', ').trim();
      } else if (parts.length === 3) {
        locality = parts[0].trim();
      } else if (parts.length === 2) {
        locality = parts[0].trim();
      } else {
        locality = parts[0].trim();
      }
      if (!locality) locality = city || 'Local Area';
    }
  }

  if (!country) country = 'India';
  if (!state) state = 'State';
  if (!city) city = 'City';
  if (!locality) locality = city;

  return {
    full_address: rawAddress,
    locality,
    city,
    state,
    country
  };
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

async function processAndSendOtp(email) {
  const cleanEmail = email.trim().toLowerCase();

  // Test accounts bypass real email sending (instant OTP 123456)
  if (isTestAccount(cleanEmail)) {
    console.log(`[Auth] Recognized test account: ${cleanEmail}. Skipping email dispatch (Fixed OTP: 123456).`);
    return {
      email: cleanEmail,
      expiresInSeconds: OTP_EXPIRY_MINUTES * 60
    };
  }

  // 1. Rate limiting check (max 3 requests per 10 minutes)
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
    service: 'ADVT APP Single-File Server'
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
 * Verifies OTP and checks if user already exists in `users` table.
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

    let isVerified = false;

    // A. Test Account Bypass (test1@gmail.com, test2@gmail.com with PIN 123456)
    if (isTestAccount(cleanEmail)) {
      if (verifyTestCredentials(cleanEmail, cleanOtp)) {
        isVerified = true;
        console.log(`[Auth] Test account authenticated successfully: ${cleanEmail}`);
      } else {
        return res.status(400).json({
          success: false,
          message: 'Wrong OTP'
        });
      }
    } else {
      // B. Normal Users: Query latest active OTP from database
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

      // Expiration check
      const now = new Date();
      const expiresAt = new Date(record.expires_at);
      if (now > expiresAt) {
        await pool.query(`UPDATE email_otp SET is_used = 1 WHERE id = ?`, [record.id]);
        return res.status(400).json({
          success: false,
          message: 'OTP expired. Please resend the OTP.'
        });
      }

      // Code match check
      if (record.otp !== cleanOtp) {
        return res.status(400).json({
          success: false,
          message: 'Wrong OTP'
        });
      }

      // Mark single-use OTP as used
      await pool.query(`UPDATE email_otp SET is_used = 1 WHERE id = ?`, [record.id]);
      isVerified = true;
    }

    if (!isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Wrong OTP'
      });
    }

    // C. Check if user already exists in `users` table
    const [userRows] = await pool.query(
      `SELECT * FROM users WHERE email = ? LIMIT 1`,
      [cleanEmail]
    );

    const token = jwt.sign(
      { email: cleanEmail, isVerified: true },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    if (userRows && userRows.length > 0) {
      const existingUser = userRows[0];
      console.log(`[Auth] Existing user verified: ${cleanEmail} (ID: ${existingUser.id})`);

      // Ensure address components are parsed if missing
      const addrComponents = extractAddressComponents(
        existingUser.full_address,
        existingUser.locality,
        existingUser.city,
        existingUser.state,
        existingUser.country
      );

      return res.status(200).json({
        success: true,
        message: 'Email verified successfully!',
        token,
        isExistingUser: true,
        user: {
          id: existingUser.id,
          userId: `U${existingUser.id.toString().padStart(3, '0')}`,
          email: existingUser.email,
          full_name: existingUser.full_name,
          mobile_number: existingUser.mobile_number,
          country_code: existingUser.country_code || '+91',
          full_address: existingUser.full_address,
          locality: addrComponents.locality,
          city: addrComponents.city,
          state: addrComponents.state,
          country: addrComponents.country,
          isEmailVerified: true
        }
      });
    }

    // New user (requires registration)
    console.log(`[Auth] New user verified: ${cleanEmail} -> Requires registration`);
    return res.status(200).json({
      success: true,
      message: 'Email verified successfully!',
      token,
      isExistingUser: false,
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

/**
 * 4. POST /api/register-user
 * Body: { email, full_name, mobile_number, country_code, full_address, locality, city, state, country }
 * Inserts new user into `users` table with strict 1-email-per-user enforcement.
 */
app.post(['/api/register-user', '/api/register'], async (req, res) => {
  try {
    const {
      email,
      full_name,
      mobile_number,
      country_code = '+91',
      full_address,
      locality = '',
      city = '',
      state = '',
      country = ''
    } = req.body;

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'A valid email address is required.'
      });
    }

    if (!full_name || full_name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Full Name is required.'
      });
    }

    if (!mobile_number || mobile_number.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Mobile Number is required.'
      });
    }

    if (!full_address || full_address.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Address is required.'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanName = full_name.trim();
    const cleanPhone = mobile_number.trim();
    const cleanAddress = full_address.trim();

    // Extract separated address components (locality, city, state, country) from address
    const addr = extractAddressComponents(cleanAddress, locality, city, state, country);

    // Check if email already registered (Database Unique Check)
    const [existing] = await pool.query(
      `SELECT id FROM users WHERE email = ? LIMIT 1`,
      [cleanEmail]
    );

    if (existing && existing.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'An account with this email address already exists. Please login.'
      });
    }

    // Insert new user into MySQL `users` table
    const insertQuery = `
      INSERT INTO users (email, full_name, mobile_number, country_code, full_address, locality, city, state, country)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await pool.query(insertQuery, [
      cleanEmail,
      cleanName,
      cleanPhone,
      country_code.trim(),
      addr.full_address,
      addr.locality,
      addr.city,
      addr.state,
      addr.country
    ]);

    const newUserId = result.insertId;
    console.log(`[Users] Successfully registered user: ${cleanEmail} (ID: ${newUserId})`);

    const token = jwt.sign(
      { id: newUserId, email: cleanEmail, isVerified: true },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(201).json({
      success: true,
      message: 'User registered successfully!',
      token,
      user: {
        id: newUserId,
        userId: `U${newUserId.toString().padStart(3, '0')}`,
        email: cleanEmail,
        full_name: cleanName,
        mobile_number: cleanPhone,
        country_code: country_code.trim(),
        full_address: addr.full_address,
        locality: addr.locality,
        city: addr.city,
        state: addr.state,
        country: addr.country
      }
    });
  } catch (error) {
    console.error('[Users] Registration error:', error.message);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({
        success: false,
        message: 'An account with this email address already exists.'
      });
    }
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error while registering user.'
    });
  }
});

/**
 * 5. GET /api/user-profile
 * Query: ?email=user@example.com
 */
app.get('/api/user-profile', async (req, res) => {
  try {
    const email = req.query.email;
    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'Valid email query parameter is required.'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const [rows] = await pool.query(
      `SELECT * FROM users WHERE email = ? LIMIT 1`,
      [cleanEmail]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found.'
      });
    }

    const user = rows[0];
    const addr = extractAddressComponents(
      user.full_address,
      user.locality,
      user.city,
      user.state,
      user.country
    );

    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        userId: `U${user.id.toString().padStart(3, '0')}`,
        email: user.email,
        full_name: user.full_name,
        mobile_number: user.mobile_number,
        country_code: user.country_code || '+91',
        full_address: user.full_address,
        locality: addr.locality,
        city: addr.city,
        state: addr.state,
        country: addr.country
      }
    });
  } catch (error) {
    console.error('[Users] Fetch profile error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching user profile.'
    });
  }
});

/**
 * 6. PUT /api/update-profile
 * Body: { email, full_name, mobile_number, country_code, full_address, locality, city, state, country }
 */
app.put('/api/update-profile', async (req, res) => {
  try {
    const {
      email,
      full_name,
      mobile_number,
      country_code = '+91',
      full_address,
      locality = '',
      city = '',
      state = '',
      country = ''
    } = req.body;

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'Valid email is required.'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const addr = extractAddressComponents(full_address, locality, city, state, country);

    const updateQuery = `
      UPDATE users 
      SET full_name = ?, mobile_number = ?, country_code = ?, full_address = ?, locality = ?, city = ?, state = ?, country = ?
      WHERE email = ?
    `;

    const [result] = await pool.query(updateQuery, [
      (full_name || '').trim(),
      (mobile_number || '').trim(),
      (country_code || '+91').trim(),
      addr.full_address,
      addr.locality,
      addr.city,
      addr.state,
      addr.country,
      cleanEmail
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found to update.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully!',
      user: {
        email: cleanEmail,
        full_name: (full_name || '').trim(),
        mobile_number: (mobile_number || '').trim(),
        country_code: (country_code || '+91').trim(),
        full_address: addr.full_address,
        locality: addr.locality,
        city: addr.city,
        state: addr.state,
        country: addr.country
      }
    });
  } catch (error) {
    console.error('[Users] Update profile error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while updating profile.'
    });
  }
});

// ==========================================
// 5.1 BUSINESS PROFILE AUTHENTICATION & APIS
// ==========================================

/**
 * Authentication Middleware:
 * Resolves authenticated user from:
 * 1. Authorization: Bearer <jwt_token>
 * 2. x-user-id header or x-user-email header (active session fallback)
 * 3. query param ?user_id=... or ?email=...
 */
async function authenticateUser(req, res, next) {
  try {
    let user = null;

    // 1. Try JWT Bearer token
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7).trim();
      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        if (decoded.id) {
          const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [decoded.id]);
          if (rows && rows.length > 0) user = rows[0];
        } else if (decoded.email) {
          const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [decoded.email.toLowerCase().trim()]);
          if (rows && rows.length > 0) user = rows[0];
        }
      } catch (jwtErr) {
        // Token invalid or expired, continue to fallback checks
      }
    }

    // 2. Fallback to session headers
    if (!user && req.headers['x-user-id']) {
      const rawId = req.headers['x-user-id'].toString().replace(/^U0*/i, '');
      const numericId = parseInt(rawId, 10);
      if (!isNaN(numericId)) {
        const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [numericId]);
        if (rows && rows.length > 0) user = rows[0];
      }
    }

    if (!user && req.headers['x-user-email']) {
      const cleanEmail = req.headers['x-user-email'].toString().toLowerCase().trim();
      const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [cleanEmail]);
      if (rows && rows.length > 0) user = rows[0];
    }

    // 3. Fallback to query parameters
    if (!user && req.query && req.query.user_id) {
      const rawId = req.query.user_id.toString().replace(/^U0*/i, '');
      const numericId = parseInt(rawId, 10);
      if (!isNaN(numericId)) {
        const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [numericId]);
        if (rows && rows.length > 0) user = rows[0];
      }
    }

    if (!user && req.query && req.query.email) {
      const cleanEmail = req.query.email.toString().toLowerCase().trim();
      const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [cleanEmail]);
      if (rows && rows.length > 0) user = rows[0];
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required. Please login.'
      });
    }

    req.user = user;
    next();
  } catch (err) {
    console.error('[Auth Middleware] Error:', err.message);
    return res.status(500).json({
      success: false,
      message: 'Server error during authentication check.'
    });
  }
}

/**
 * 7. POST /api/business-profiles
 * Create a new Business Profile associated with the authenticated logged-in user.
 * Body: { business_name, category, business_phone, country_code, full_address, locality, city, state, country, latitude, longitude, profile_image, images, about }
 */
app.post('/api/business-profiles', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      business_name,
      category = 'General Store',
      business_phone,
      country_code = '+91',
      full_address,
      locality = '',
      city = '',
      state = '',
      country = 'India',
      latitude = 0.0,
      longitude = 0.0,
      profile_image = '',
      images = [],
      about = ''
    } = req.body;

    if (!business_name || business_name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Business name is required.'
      });
    }

    if (!business_phone || business_phone.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Business phone number is required.'
      });
    }

    if (!full_address || full_address.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Business address is required.'
      });
    }

    const addr = extractAddressComponents(full_address, locality, city, state, country);
    const imagesJson = Array.isArray(images) ? JSON.stringify(images) : (typeof images === 'string' ? images : '[]');
    const primaryImage = profile_image || (Array.isArray(images) && images.length > 0 ? images[0] : '');

    const insertQuery = `
      INSERT INTO business_profile 
      (user_id, business_name, category, business_phone, country_code, full_address, locality, city, state, country, latitude, longitude, profile_image, images, about)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await pool.query(insertQuery, [
      userId,
      business_name.trim(),
      (category || 'General Store').trim(),
      business_phone.trim(),
      (country_code || '+91').trim(),
      addr.full_address,
      addr.locality,
      addr.city,
      addr.state,
      addr.country,
      parseFloat(latitude) || 0.0,
      parseFloat(longitude) || 0.0,
      primaryImage,
      imagesJson,
      (about || '').trim()
    ]);

    const newBusinessId = result.insertId;
    console.log(`[Business Profile] Created business_id ${newBusinessId} for user_id ${userId} ("${business_name.trim()}")`);

    return res.status(201).json({
      success: true,
      message: 'Business profile created successfully!',
      profile: {
        business_id: newBusinessId,
        business_profile_id: `BP${newBusinessId.toString().padStart(3, '0')}`,
        user_id: userId,
        owner_user_id: `U${userId.toString().padStart(3, '0')}`,
        business_name: business_name.trim(),
        category: (category || 'General Store').trim(),
        business_phone: business_phone.trim(),
        country_code: (country_code || '+91').trim(),
        full_address: addr.full_address,
        locality: addr.locality,
        city: addr.city,
        state: addr.state,
        country: addr.country,
        latitude: parseFloat(latitude) || 0.0,
        longitude: parseFloat(longitude) || 0.0,
        profile_image: primaryImage,
        images: Array.isArray(images) ? images : [],
        about: (about || '').trim(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('[Business Profile] Create error:', error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error while creating business profile.'
    });
  }
});

/**
 * 8. GET /api/business-profiles/my & GET /api/business-profiles
 * Retrieve ONLY Business Profiles owned by the currently logged-in user.
 * Query logic: SELECT * FROM business_profile WHERE user_id = logged_in_user_id;
 */
app.get(['/api/business-profiles/my', '/api/business-profiles'], authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      `SELECT * FROM business_profile 
       WHERE user_id = ? 
       ORDER BY created_at DESC, business_id DESC`,
      [userId]
    );

    const profiles = rows.map(r => {
      let parsedImages = [];
      try {
        parsedImages = r.images ? (typeof r.images === 'string' ? JSON.parse(r.images) : r.images) : [];
      } catch (_) {
        parsedImages = r.profile_image ? [r.profile_image] : [];
      }
      return {
        business_id: r.business_id,
        business_profile_id: `BP${r.business_id.toString().padStart(3, '0')}`,
        user_id: r.user_id,
        owner_user_id: `U${r.user_id.toString().padStart(3, '0')}`,
        business_name: r.business_name,
        category: r.category || 'General Store',
        business_phone: r.business_phone,
        country_code: r.country_code || '+91',
        full_address: r.full_address,
        locality: r.locality || '',
        city: r.city || '',
        state: r.state || '',
        country: r.country || 'India',
        latitude: parseFloat(r.latitude) || 0.0,
        longitude: parseFloat(r.longitude) || 0.0,
        profile_image: r.profile_image || (parsedImages.length > 0 ? parsedImages[0] : ''),
        images: parsedImages,
        about: r.about || '',
        created_at: r.created_at,
        updated_at: r.updated_at
      };
    });

    return res.status(200).json({
      success: true,
      count: profiles.length,
      profiles
    });
  } catch (error) {
    console.error('[Business Profile] Fetch user profiles error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching business profiles.'
    });
  }
});

/**
 * 9. GET /api/business-profiles/:id
 * Retrieve one specific Business Profile by unique Business ID.
 */
app.get('/api/business-profiles/:id', async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^BP0*/i, '');
    const businessId = parseInt(rawId, 10);

    if (isNaN(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID.'
      });
    }

    const [rows] = await pool.query(
      `SELECT * FROM business_profile WHERE business_id = ? LIMIT 1`,
      [businessId]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business profile not found.'
      });
    }

    const r = rows[0];
    let parsedImages = [];
    try {
      parsedImages = r.images ? (typeof r.images === 'string' ? JSON.parse(r.images) : r.images) : [];
    } catch (_) {
      parsedImages = r.profile_image ? [r.profile_image] : [];
    }

    return res.status(200).json({
      success: true,
      profile: {
        business_id: r.business_id,
        business_profile_id: `BP${r.business_id.toString().padStart(3, '0')}`,
        user_id: r.user_id,
        owner_user_id: `U${r.user_id.toString().padStart(3, '0')}`,
        business_name: r.business_name,
        category: r.category || 'General Store',
        business_phone: r.business_phone,
        country_code: r.country_code || '+91',
        full_address: r.full_address,
        locality: r.locality || '',
        city: r.city || '',
        state: r.state || '',
        country: r.country || 'India',
        latitude: parseFloat(r.latitude) || 0.0,
        longitude: parseFloat(r.longitude) || 0.0,
        profile_image: r.profile_image || (parsedImages.length > 0 ? parsedImages[0] : ''),
        images: parsedImages,
        about: r.about || '',
        created_at: r.created_at,
        updated_at: r.updated_at
      }
    });
  } catch (error) {
    console.error('[Business Profile] Fetch by ID error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching business profile.'
    });
  }
});

/**
 * 10. PUT /api/business-profiles/:id
 * Update only own Business Profile by Business ID (Ownership validation required).
 */
app.put('/api/business-profiles/:id', authenticateUser, async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^BP0*/i, '');
    const businessId = parseInt(rawId, 10);
    const userId = req.user.id;

    if (isNaN(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID.'
      });
    }

    // Ownership check: verify that this profile belongs to the authenticated user
    const [existing] = await pool.query(
      `SELECT * FROM business_profile WHERE business_id = ? LIMIT 1`,
      [businessId]
    );

    if (!existing || existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business profile not found.'
      });
    }

    if (existing[0].user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to modify this business profile.'
      });
    }

    const {
      business_name,
      category,
      business_phone,
      country_code,
      profile_image,
      images,
      about
    } = req.body;

    const current = existing[0];
    const updatedName = business_name !== undefined ? business_name.trim() : current.business_name;
    const updatedCat = category !== undefined ? category.trim() : current.category;
    const updatedPhone = business_phone !== undefined ? business_phone.trim() : current.business_phone;
    const updatedCc = country_code !== undefined ? country_code.trim() : current.country_code;
    const updatedAbout = about !== undefined ? about.trim() : current.about;

    let updatedImagesJson = current.images;
    let updatedPrimaryImg = current.profile_image;

    if (images !== undefined) {
      updatedImagesJson = Array.isArray(images) ? JSON.stringify(images) : (typeof images === 'string' ? images : '[]');
      if (Array.isArray(images) && images.length > 0) {
        updatedPrimaryImg = images[0];
      }
    }
    if (profile_image !== undefined && profile_image.trim().length > 0) {
      updatedPrimaryImg = profile_image.trim();
    }

    const updateQuery = `
      UPDATE business_profile 
      SET business_name = ?, category = ?, business_phone = ?, country_code = ?, profile_image = ?, images = ?, about = ?
      WHERE business_id = ? AND user_id = ?
    `;

    await pool.query(updateQuery, [
      updatedName,
      updatedCat,
      updatedPhone,
      updatedCc,
      updatedPrimaryImg,
      updatedImagesJson,
      updatedAbout,
      businessId,
      userId
    ]);

    console.log(`[Business Profile] Updated business_id ${businessId} by user_id ${userId}`);

    let parsedImages = [];
    try {
      parsedImages = typeof updatedImagesJson === 'string' ? JSON.parse(updatedImagesJson) : updatedImagesJson;
    } catch (_) {
      parsedImages = updatedPrimaryImg ? [updatedPrimaryImg] : [];
    }

    return res.status(200).json({
      success: true,
      message: 'Business profile updated successfully!',
      profile: {
        business_id: businessId,
        business_profile_id: `BP${businessId.toString().padStart(3, '0')}`,
        user_id: userId,
        owner_user_id: `U${userId.toString().padStart(3, '0')}`,
        business_name: updatedName,
        category: updatedCat,
        business_phone: updatedPhone,
        country_code: updatedCc,
        full_address: current.full_address,
        locality: current.locality,
        city: current.city,
        state: current.state,
        country: current.country,
        latitude: parseFloat(current.latitude) || 0.0,
        longitude: parseFloat(current.longitude) || 0.0,
        profile_image: updatedPrimaryImg,
        images: parsedImages,
        about: updatedAbout,
        created_at: current.created_at,
        updated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('[Business Profile] Update error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while updating business profile.'
    });
  }
});

/**
 * 11. DELETE /api/business-profiles/:id
 * Delete only own Business Profile by Business ID (Ownership validation required).
 */
app.delete('/api/business-profiles/:id', authenticateUser, async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^BP0*/i, '');
    const businessId = parseInt(rawId, 10);
    const userId = req.user.id;

    if (isNaN(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID.'
      });
    }

    const [existing] = await pool.query(
      `SELECT * FROM business_profile WHERE business_id = ? LIMIT 1`,
      [businessId]
    );

    if (!existing || existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business profile not found.'
      });
    }

    if (existing[0].user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to delete this business profile.'
      });
    }

    await pool.query(
      `DELETE FROM business_profile WHERE business_id = ? AND user_id = ?`,
      [businessId, userId]
    );

    console.log(`[Business Profile] Deleted business_id ${businessId} for user_id ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Business profile deleted successfully.'
    });
  } catch (error) {
    console.error('[Business Profile] Delete error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while deleting business profile.'
    });
  }
});

// ==========================================
// 5. POSTS CRUD & LOCATION FILTERING APIS
// ==========================================

function calculateTimeAgo(dateInput) {
  if (!dateInput) return 'Just now';
  const diffMs = Date.now() - new Date(dateInput).getTime();
  const diffMinutes = Math.floor(diffMs / (1000 * 60));
  if (diffMinutes < 1) return 'Just now';
  if (diffMinutes < 60) return `${diffMinutes}m ago`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return `${Math.floor(diffDays / 7)}w ago`;
}

function formatPostRow(r) {
  let parsedImages = [];
  try {
    parsedImages = r.images ? (typeof r.images === 'string' ? JSON.parse(r.images) : r.images) : [];
  } catch (_) {
    parsedImages = [];
  }

  let parsedTargetLocations = [];
  try {
    parsedTargetLocations = r.target_locations_json ? (typeof r.target_locations_json === 'string' ? JSON.parse(r.target_locations_json) : r.target_locations_json) : [];
  } catch (_) {
    parsedTargetLocations = [];
  }

  const prefix = r.post_type === 'coupon' ? 'C' : 'P';
  const postIdStr = `${prefix}${r.post_id.toString().padStart(3, '0')}`;
  const bizProfileIdStr = `BP${r.business_id.toString().padStart(3, '0')}`;

  return {
    post_id: r.post_id,
    postId: postIdStr,
    business_id: r.business_id,
    businessProfileId: bizProfileIdStr,
    user_id: r.user_id,
    ownerUserId: `U${r.user_id.toString().padStart(3, '0')}`,
    bizName: r.business_name || '',
    type: r.post_type,
    post_type: r.post_type,
    title: r.title,
    subtitle: r.subtitle || '',
    description: r.description || '',
    couponCode: r.coupon_code || null,
    coupon_code: r.coupon_code || null,
    discount: r.discount_label || null,
    discount_label: r.discount_label || null,
    jobType: r.job_type || null,
    job_type: r.job_type || null,
    exp: r.experience || null,
    experience: r.experience || null,
    validity: r.validity || null,
    badgeText: r.badge_text || null,
    badge_text: r.badge_text || null,
    terms: r.terms || null,
    targetLocation: r.target_location,
    target_location: r.target_location,
    target_city: r.target_city || null,
    target_district: r.target_district || null,
    target_state: r.target_state || 'Tamil Nadu',
    targetLocationItems: parsedTargetLocations,
    target_locations: parsedTargetLocations,
    images: parsedImages,
    brandLogo: r.brand_logo || r.business_profile_image || null,
    brand_logo: r.brand_logo || r.business_profile_image || null,
    is_active: r.is_active === 1,
    timeAgo: calculateTimeAgo(r.created_at),
    createdAt: r.created_at,
    created_at: r.created_at,
    updatedAt: r.updated_at,
    updated_at: r.updated_at
  };
}

/**
 * 12. POST /api/posts
 * Create a new Post (Job, Offer, Coupon) stored in a separate relational row.
 */
app.post('/api/posts', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      business_id,
      businessProfileId,
      type,
      post_type,
      title,
      subtitle,
      description,
      coupon_code,
      couponCode,
      discount,
      discount_label,
      job_type,
      jobType,
      exp,
      experience,
      validity,
      badge_text,
      badgeText,
      terms,
      target_location,
      targetLocation,
      target_city,
      target_district,
      target_state,
      target_locations,
      targetLocations,
      images,
      brand_logo,
      brandLogo
    } = req.body;

    const rawBizId = business_id || businessProfileId;
    if (!rawBizId) {
      return res.status(400).json({ success: false, message: 'business_id is required.' });
    }
    const cleanBizId = parseInt(rawBizId.toString().replace(/^BP0*/i, ''), 10);
    if (isNaN(cleanBizId)) {
      return res.status(400).json({ success: false, message: 'Invalid business_id.' });
    }

    // Check ownership of the business profile
    const [bizRows] = await pool.query(
      `SELECT * FROM business_profile WHERE business_id = ? LIMIT 1`,
      [cleanBizId]
    );
    if (!bizRows || bizRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Business profile not found.' });
    }
    if (bizRows[0].user_id !== userId) {
      return res.status(403).json({ success: false, message: 'You do not own this business profile.' });
    }

    const postTypeVal = (type || post_type || 'offer').toLowerCase().trim();
    if (!['job', 'offer', 'coupon'].includes(postTypeVal)) {
      return res.status(400).json({ success: false, message: 'Invalid post type. Allowed: job, offer, coupon.' });
    }

    const postTitle = (title || '').trim();
    if (!postTitle) {
      return res.status(400).json({ success: false, message: 'Post title is required.' });
    }

    const postSubtitle = (subtitle || '').trim();
    const postDesc = (description || '').trim();
    const targetLoc = (target_location || targetLocation || bizRows[0].city || 'Tamil Nadu').trim();

    // Prepare JSON arrays
    let imagesJson = '[]';
    if (images) {
      imagesJson = Array.isArray(images) ? JSON.stringify(images) : (typeof images === 'string' ? images : '[]');
    }
    let targetLocsJson = '[]';
    const locsList = target_locations || targetLocations;
    if (locsList) {
      targetLocsJson = Array.isArray(locsList) ? JSON.stringify(locsList) : (typeof locsList === 'string' ? locsList : '[]');
    }

    const postCouponCode = (coupon_code || couponCode || '').trim() || null;
    const postDiscount = (discount || discount_label || (postTypeVal === 'coupon' ? postTitle : null));
    const postJobType = (job_type || jobType || (postTypeVal === 'job' ? 'Full Time' : null));
    const postExp = (exp || experience || (postTypeVal === 'job' ? 'Open' : null));
    const postValidity = (validity || (postTypeVal === 'offer' ? 'Active now' : (postTypeVal === 'coupon' ? 'Active deal' : null)));
    const postBadge = (badge_text || badgeText || (postTypeVal === 'coupon' ? 'Active' : null));
    const postTerms = (terms || (postTypeVal === 'coupon' ? '1. Present this coupon in store or enter code during booking.' : null));
    const postBrandLogo = brand_logo || brandLogo || bizRows[0].profile_image || null;

    const insertQuery = `
      INSERT INTO posts (
        business_id, user_id, post_type, title, subtitle, description,
        coupon_code, discount_label, job_type, experience, validity,
        badge_text, terms, target_location, target_city, target_district,
        target_state, target_locations_json, images, brand_logo, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    `;

    const [result] = await pool.query(insertQuery, [
      cleanBizId,
      userId,
      postTypeVal,
      postTitle,
      postSubtitle,
      postDesc,
      postCouponCode,
      postDiscount,
      postJobType,
      postExp,
      postValidity,
      postBadge,
      postTerms,
      targetLoc,
      target_city || null,
      target_district || null,
      target_state || 'Tamil Nadu',
      targetLocsJson,
      imagesJson,
      postBrandLogo
    ]);

    const newPostId = result.insertId;

    // Query back the newly inserted post with business join
    const [insertedRows] = await pool.query(`
      SELECT p.*, b.business_name, b.category AS business_category, b.city AS business_city, b.profile_image AS business_profile_image
      FROM posts p
      LEFT JOIN business_profile b ON p.business_id = b.business_id
      WHERE p.post_id = ?
      LIMIT 1
    `, [newPostId]);

    const formattedPost = formatPostRow(insertedRows[0]);

    console.log(`[Posts] Created new post ID ${newPostId} (${postTypeVal}) for business_id ${cleanBizId} by user_id ${userId}`);

    return res.status(201).json({
      success: true,
      message: 'Post created successfully!',
      post: formattedPost
    });
  } catch (error) {
    console.error('[Posts] Create post error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while creating post.'
    });
  }
});

/**
 * 13. GET /api/posts
 * Query all active posts with optional filtering by type, location, business_id, user_id, search keyword.
 */
app.get('/api/posts', async (req, res) => {
  try {
    const { type, post_type, location, target_location, business_id, user_id, search, q } = req.query;

    let query = `
      SELECT p.*, b.business_name, b.category AS business_category, b.city AS business_city, b.profile_image AS business_profile_image
      FROM posts p
      LEFT JOIN business_profile b ON p.business_id = b.business_id
      WHERE p.is_active = 1
    `;
    const params = [];

    const pType = type || post_type;
    if (pType && pType !== 'all') {
      const types = pType.split(',').map(t => t.trim().toLowerCase()).filter(Boolean);
      if (types.length > 0) {
        query += ` AND p.post_type IN (${types.map(() => '?').join(',')})`;
        params.push(...types);
      }
    }

    const pLoc = location || target_location;
    if (pLoc && pLoc.trim().length > 0 && pLoc.toLowerCase() !== 'all') {
      query += ` AND (p.target_location LIKE ? OR p.target_city LIKE ? OR p.target_district LIKE ? OR b.city LIKE ?)`;
      const locPattern = `%${pLoc.trim()}%`;
      params.push(locPattern, locPattern, locPattern, locPattern);
    }

    if (business_id) {
      const cleanBizId = parseInt(business_id.toString().replace(/^BP0*/i, ''), 10);
      if (!isNaN(cleanBizId)) {
        query += ` AND p.business_id = ?`;
        params.push(cleanBizId);
      }
    }

    if (user_id) {
      const cleanUserId = parseInt(user_id.toString().replace(/^U0*/i, ''), 10);
      if (!isNaN(cleanUserId)) {
        query += ` AND p.user_id = ?`;
        params.push(cleanUserId);
      }
    }

    const searchTerm = search || q;
    if (searchTerm && searchTerm.trim().length > 0) {
      query += ` AND (p.title LIKE ? OR p.subtitle LIKE ? OR p.description LIKE ? OR p.coupon_code LIKE ? OR b.business_name LIKE ?)`;
      const sPattern = `%${searchTerm.trim()}%`;
      params.push(sPattern, sPattern, sPattern, sPattern, sPattern);
    }

    query += ` ORDER BY p.created_at DESC`;

    const [rows] = await pool.query(query, params);
    const posts = rows.map(formatPostRow);

    return res.status(200).json({
      success: true,
      count: posts.length,
      posts
    });
  } catch (error) {
    console.error('[Posts] Fetch posts error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching posts.'
    });
  }
});

/**
 * 14. GET /api/posts/:id
 * Retrieve single post details by post ID.
 */
app.get('/api/posts/:id', async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^[CP0]*/i, '');
    const postId = parseInt(rawId, 10);

    if (isNaN(postId)) {
      return res.status(400).json({ success: false, message: 'Invalid post ID.' });
    }

    const [rows] = await pool.query(`
      SELECT p.*, b.business_name, b.category AS business_category, b.city AS business_city, b.profile_image AS business_profile_image
      FROM posts p
      LEFT JOIN business_profile b ON p.business_id = b.business_id
      WHERE p.post_id = ? AND p.is_active = 1
      LIMIT 1
    `, [postId]);

    if (!rows || rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    return res.status(200).json({
      success: true,
      post: formatPostRow(rows[0])
    });
  } catch (error) {
    console.error('[Posts] Fetch post by ID error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching post.'
    });
  }
});

/**
 * 15. PUT /api/posts/:id
 * Update an existing post (Ownership verified).
 */
app.put('/api/posts/:id', authenticateUser, async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^[CP0]*/i, '');
    const postId = parseInt(rawId, 10);
    const userId = req.user.id;

    if (isNaN(postId)) {
      return res.status(400).json({ success: false, message: 'Invalid post ID.' });
    }

    const [existing] = await pool.query(`SELECT * FROM posts WHERE post_id = ? LIMIT 1`, [postId]);
    if (!existing || existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    if (existing[0].user_id !== userId) {
      return res.status(403).json({ success: false, message: 'You do not have permission to modify this post.' });
    }

    const {
      title,
      subtitle,
      description,
      coupon_code,
      discount_label,
      job_type,
      experience,
      validity,
      badge_text,
      terms,
      target_location,
      target_locations,
      images
    } = req.body;

    const current = existing[0];
    const updatedTitle = title !== undefined ? title.trim() : current.title;
    const updatedSubtitle = subtitle !== undefined ? subtitle.trim() : current.subtitle;
    const updatedDesc = description !== undefined ? description.trim() : current.description;
    const updatedCoupon = coupon_code !== undefined ? (coupon_code ? coupon_code.trim() : null) : current.coupon_code;
    const updatedDiscount = discount_label !== undefined ? (discount_label ? discount_label.trim() : null) : current.discount_label;
    const updatedJobType = job_type !== undefined ? (job_type ? job_type.trim() : null) : current.job_type;
    const updatedExp = experience !== undefined ? (experience ? experience.trim() : null) : current.experience;
    const updatedValidity = validity !== undefined ? (validity ? validity.trim() : null) : current.validity;
    const updatedBadge = badge_text !== undefined ? (badge_text ? badge_text.trim() : null) : current.badge_text;
    const updatedTerms = terms !== undefined ? (terms ? terms.trim() : null) : current.terms;
    const updatedLoc = target_location !== undefined ? target_location.trim() : current.target_location;

    let updatedImages = current.images;
    if (images !== undefined) {
      updatedImages = Array.isArray(images) ? JSON.stringify(images) : (typeof images === 'string' ? images : '[]');
    }

    let updatedTargetLocs = current.target_locations_json;
    if (target_locations !== undefined) {
      updatedTargetLocs = Array.isArray(target_locations) ? JSON.stringify(target_locations) : (typeof target_locations === 'string' ? target_locations : '[]');
    }

    await pool.query(`
      UPDATE posts
      SET title = ?, subtitle = ?, description = ?, coupon_code = ?, discount_label = ?,
          job_type = ?, experience = ?, validity = ?, badge_text = ?, terms = ?,
          target_location = ?, target_locations_json = ?, images = ?
      WHERE post_id = ? AND user_id = ?
    `, [
      updatedTitle, updatedSubtitle, updatedDesc, updatedCoupon, updatedDiscount,
      updatedJobType, updatedExp, updatedValidity, updatedBadge, updatedTerms,
      updatedLoc, updatedTargetLocs, updatedImages,
      postId, userId
    ]);

    const [updatedRows] = await pool.query(`
      SELECT p.*, b.business_name, b.category AS business_category, b.city AS business_city, b.profile_image AS business_profile_image
      FROM posts p
      LEFT JOIN business_profile b ON p.business_id = b.business_id
      WHERE p.post_id = ?
      LIMIT 1
    `, [postId]);

    return res.status(200).json({
      success: true,
      message: 'Post updated successfully!',
      post: formatPostRow(updatedRows[0])
    });
  } catch (error) {
    console.error('[Posts] Update post error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while updating post.'
    });
  }
});

/**
 * 16. DELETE /api/posts/:id
 * Delete post by ID (Ownership verified).
 */
app.delete('/api/posts/:id', authenticateUser, async (req, res) => {
  try {
    const rawId = req.params.id.toString().replace(/^[CP0]*/i, '');
    const postId = parseInt(rawId, 10);
    const userId = req.user.id;

    if (isNaN(postId)) {
      return res.status(400).json({ success: false, message: 'Invalid post ID.' });
    }

    const [existing] = await pool.query(`SELECT * FROM posts WHERE post_id = ? LIMIT 1`, [postId]);
    if (!existing || existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    if (existing[0].user_id !== userId) {
      return res.status(403).json({ success: false, message: 'You do not have permission to delete this post.' });
    }

    await pool.query(`DELETE FROM posts WHERE post_id = ? AND user_id = ?`, [postId, userId]);
    console.log(`[Posts] Deleted post_id ${postId} by user_id ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Post deleted successfully.'
    });
  } catch (error) {
    console.error('[Posts] Delete post error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while deleting post.'
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
// 6. BOOTSTRAP SERVER (AUTO HTTP / HTTPS)
// ==========================================
const privKeyPath = '/etc/letsencrypt/live/apps.plestarinc.com/privkey.pem';
const certPath = '/etc/letsencrypt/live/apps.plestarinc.com/fullchain.pem';

async function startServer() {
  await initDatabase();

  if (fs.existsSync(privKeyPath) && fs.existsSync(certPath)) {
    // Production HTTPS Server (Google Cloud Console / Live)
    const credentials = {
      key: fs.readFileSync(privKeyPath, 'utf8'),
      cert: fs.readFileSync(certPath, 'utf8')
    };
    const httpsPort = PORT === 5000 ? 3003 : PORT;
    const httpsServer = https.createServer(credentials, app);
    httpsServer.listen(httpsPort, '0.0.0.0', () => {
      console.log(`====================================================`);
      console.log(`🚀 ADVT APP Live Server running on https://apps.plestarinc.com:${httpsPort}`);
      console.log(`====================================================`);
    });
  } else {
    // Development HTTP Server (Local PC)
    const httpServer = http.createServer(app);
    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(`====================================================`);
      console.log(`🚀 ADVT APP Local Server running on http://localhost:${PORT}`);
      console.log(`====================================================`);
    });
  }
}

startServer();
