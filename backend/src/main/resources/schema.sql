ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS email_verified boolean NOT NULL DEFAULT false;
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS major varchar(100);
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS google_id varchar(100);
ALTER TABLE IF EXISTS users ALTER COLUMN password_hash DROP NOT NULL;
UPDATE users SET email_verified = true WHERE email_verified IS NULL;
