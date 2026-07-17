-- Index on bookings table for faster user history lookups
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);

-- Index on notifications for faster unread count queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_is_read ON notifications(user_id, is_read);

-- Index on activity_logs for faster auditing lookups by user
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);

-- Index on sessions token for fast lookup during authentication checks
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
