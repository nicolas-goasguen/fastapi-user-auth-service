CREATE EXTENSION IF NOT EXISTS citext;

CREATE DOMAIN email_address AS citext CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$');
CREATE DOMAIN code_4_digits AS TEXT CHECK (LENGTH(VALUE) = 4 AND VALUE ~ '^[0-9]{4}$');

CREATE TABLE IF NOT EXISTS user_data (
    id SERIAL PRIMARY KEY,
    email email_address UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT FALSE
);
-- speeds up searches for inactive users
CREATE INDEX idx_user_data_is_active ON user_data(is_active);

CREATE TABLE IF NOT EXISTS user_verification (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_data(id) ON DELETE CASCADE,
    code code_4_digits NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
 -- speeds up searches for user_id, user_id + code, user_id + code + created_at
CREATE INDEX idx_user_verification_created_at ON user_verification(created_at);
CREATE INDEX idx_user_verification_user_id_code_created_at ON user_verification(user_id, code, created_at);
ALTER TABLE user_verification
    ADD CONSTRAINT chk_created_at_not_in_future CHECK (created_at <= NOW());

CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule(
    '*/5 * * * *',
    $$
    DELETE FROM user_verification
    WHERE created_at < NOW() - INTERVAL '2 minutes';
    $$
);
