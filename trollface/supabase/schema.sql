-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extend auth.users table with additional profile fields
ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS display_name TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'offline',
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;

-- Create call_sessions table for 1:1 calls
CREATE TABLE call_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_b_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_sec INTEGER,
    peer_used_turn BOOLEAN DEFAULT false,
    connection_quality TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT different_users CHECK (user_a_id != user_b_id)
);

-- Create call_sessions_filters table for filter usage during calls
CREATE TABLE call_sessions_filters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES call_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    filter_name TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_sec INTEGER,
    triggered_effects BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create call_sessions_stats table for detailed call statistics
CREATE TABLE call_sessions_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES call_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    bitrate INTEGER,
    latency INTEGER,
    packet_loss REAL,
    frame_drop_rate REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_profiles table for additional user data
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    bio TEXT,
    location TEXT,
    timezone TEXT,
    favorite_filters TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_relationships table for friend/contact management
CREATE TABLE user_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    related_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL CHECK (relationship_type IN ('friend', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, related_user_id)
);

-- Create indexes for better query performance
CREATE INDEX idx_call_sessions_user_a ON call_sessions(user_a_id);
CREATE INDEX idx_call_sessions_user_b ON call_sessions(user_b_id);
CREATE INDEX idx_call_sessions_started_at ON call_sessions(started_at);
CREATE INDEX idx_call_sessions_filters_session ON call_sessions_filters(session_id);
CREATE INDEX idx_call_sessions_filters_user ON call_sessions_filters(user_id);
CREATE INDEX idx_call_sessions_stats_session ON call_sessions_stats(session_id);
CREATE INDEX idx_call_sessions_stats_user ON call_sessions_stats(user_id);
CREATE INDEX idx_user_profiles_id ON user_profiles(id);
CREATE INDEX idx_user_relationships_user_id ON user_relationships(user_id);
CREATE INDEX idx_user_relationships_related_user_id ON user_relationships(related_user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create function to calculate call duration
CREATE OR REPLACE FUNCTION calculate_call_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.duration_sec := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for tables with updated_at
CREATE TRIGGER update_call_sessions_updated_at
    BEFORE UPDATE ON call_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_relationships_updated_at
    BEFORE UPDATE ON user_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for call duration calculation
CREATE TRIGGER calculate_call_duration_trigger
    BEFORE INSERT OR UPDATE ON call_sessions
    FOR EACH ROW
    EXECUTE FUNCTION calculate_call_duration();

-- Enable RLS on all tables
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recent_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage_stats_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage_stats_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_effects_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_animations_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_transitions_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_categories_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_tags_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_presets_usage_stats_yearly ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filter_customizations_usage_stats_yearly ENABLE ROW LEVEL SECURITY;

-- Call Sessions Policies
CREATE POLICY "Users can view their own call sessions"
ON call_sessions
FOR SELECT
USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

CREATE POLICY "Users can create their own call sessions"
ON call_sessions
FOR INSERT
WITH CHECK (user_a_id = auth.uid());

CREATE POLICY "Users can update their own call sessions"
ON call_sessions
FOR UPDATE
USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

-- Call Sessions Filters Policies
CREATE POLICY "Users can view filters from their calls"
ON call_sessions_filters
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM call_sessions
    WHERE call_sessions.id = call_sessions_filters.call_session_id
    AND (call_sessions.user_a_id = auth.uid() OR call_sessions.user_b_id = auth.uid())
  )
);

CREATE POLICY "Users can add filters to their calls"
ON call_sessions_filters
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM call_sessions
    WHERE call_sessions.id = call_sessions_filters.call_session_id
    AND call_sessions.user_a_id = auth.uid()
  )
);

-- Call Sessions Stats Policies
CREATE POLICY "Users can view stats from their calls"
ON call_sessions_stats
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM call_sessions
    WHERE call_sessions.id = call_sessions_stats.call_session_id
    AND (call_sessions.user_a_id = auth.uid() OR call_sessions.user_b_id = auth.uid())
  )
);

CREATE POLICY "Users can add stats to their calls"
ON call_sessions_stats
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM call_sessions
    WHERE call_sessions.id = call_sessions_stats.call_session_id
    AND call_sessions.user_a_id = auth.uid()
  )
);

-- User Profiles Policies
CREATE POLICY "Users can view their own profile"
ON user_profiles
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own profile"
ON user_profiles
FOR UPDATE
USING (user_id = auth.uid());

-- User Relationships Policies
CREATE POLICY "Users can view their own relationships"
ON user_relationships
FOR SELECT
USING (user_id = auth.uid() OR related_user_id = auth.uid());

CREATE POLICY "Users can create their own relationships"
ON user_relationships
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own relationships"
ON user_relationships
FOR UPDATE
USING (user_id = auth.uid());

-- User Settings Policies
CREATE POLICY "Users can view their own settings"
ON user_settings
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own settings"
ON user_settings
FOR UPDATE
USING (user_id = auth.uid());

-- User Achievements Policies
CREATE POLICY "Users can view their own achievements"
ON user_achievements
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own achievements"
ON user_achievements
FOR UPDATE
USING (user_id = auth.uid());

-- User Achievement Progress Policies
CREATE POLICY "Users can view their own achievement progress"
ON user_achievement_progress
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own achievement progress"
ON user_achievement_progress
FOR UPDATE
USING (user_id = auth.uid());

-- User Activity Logs Policies
CREATE POLICY "Users can view their own activity logs"
ON user_activity_logs
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own activity logs"
ON user_activity_logs
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Notifications Policies
CREATE POLICY "Users can view their own notifications"
ON user_notifications
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
ON user_notifications
FOR UPDATE
USING (user_id = auth.uid());

-- User Favorites Policies
CREATE POLICY "Users can view their own favorites"
ON user_favorites
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own favorites"
ON user_favorites
FOR ALL
USING (user_id = auth.uid());

-- User Recent Filters Policies
CREATE POLICY "Users can view their own recent filters"
ON user_recent_filters
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own recent filters"
ON user_recent_filters
FOR ALL
USING (user_id = auth.uid());

-- User Filter Presets Policies
CREATE POLICY "Users can view their own filter presets"
ON user_filter_presets
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter presets"
ON user_filter_presets
FOR ALL
USING (user_id = auth.uid());

-- User Filter Customizations Policies
CREATE POLICY "Users can view their own filter customizations"
ON user_filter_customizations
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter customizations"
ON user_filter_customizations
FOR ALL
USING (user_id = auth.uid());

-- User Filter Effects Policies
CREATE POLICY "Users can view their own filter effects"
ON user_filter_effects
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter effects"
ON user_filter_effects
FOR ALL
USING (user_id = auth.uid());

-- User Filter Animations Policies
CREATE POLICY "Users can view their own filter animations"
ON user_filter_animations
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter animations"
ON user_filter_animations
FOR ALL
USING (user_id = auth.uid());

-- User Filter Transitions Policies
CREATE POLICY "Users can view their own filter transitions"
ON user_filter_transitions
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter transitions"
ON user_filter_transitions
FOR ALL
USING (user_id = auth.uid());

-- User Filter Categories Policies
CREATE POLICY "Users can view their own filter categories"
ON user_filter_categories
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter categories"
ON user_filter_categories
FOR ALL
USING (user_id = auth.uid());

-- User Filter Tags Policies
CREATE POLICY "Users can view their own filter tags"
ON user_filter_tags
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own filter tags"
ON user_filter_tags
FOR ALL
USING (user_id = auth.uid());

-- User Filter Usage Policies
CREATE POLICY "Users can view their own filter usage"
ON user_filter_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter usage"
ON user_filter_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Effects Usage Policies
CREATE POLICY "Users can view their own filter effects usage"
ON user_filter_effects_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter effects usage"
ON user_filter_effects_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Animations Usage Policies
CREATE POLICY "Users can view their own filter animations usage"
ON user_filter_animations_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter animations usage"
ON user_filter_animations_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Transitions Usage Policies
CREATE POLICY "Users can view their own filter transitions usage"
ON user_filter_transitions_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter transitions usage"
ON user_filter_transitions_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Categories Usage Policies
CREATE POLICY "Users can view their own filter categories usage"
ON user_filter_categories_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter categories usage"
ON user_filter_categories_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Tags Usage Policies
CREATE POLICY "Users can view their own filter tags usage"
ON user_filter_tags_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter tags usage"
ON user_filter_tags_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Presets Usage Policies
CREATE POLICY "Users can view their own filter presets usage"
ON user_filter_presets_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter presets usage"
ON user_filter_presets_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Customizations Usage Policies
CREATE POLICY "Users can view their own filter customizations usage"
ON user_filter_customizations_usage
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own filter customizations usage"
ON user_filter_customizations_usage
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- User Filter Effects Usage Stats Policies
CREATE POLICY "Users can view their own filter effects usage stats"
ON user_filter_effects_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Animations Usage Stats Policies
CREATE POLICY "Users can view their own filter animations usage stats"
ON user_filter_animations_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Transitions Usage Stats Policies
CREATE POLICY "Users can view their own filter transitions usage stats"
ON user_filter_transitions_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Categories Usage Stats Policies
CREATE POLICY "Users can view their own filter categories usage stats"
ON user_filter_categories_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Tags Usage Stats Policies
CREATE POLICY "Users can view their own filter tags usage stats"
ON user_filter_tags_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Presets Usage Stats Policies
CREATE POLICY "Users can view their own filter presets usage stats"
ON user_filter_presets_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- User Filter Customizations Usage Stats Policies
CREATE POLICY "Users can view their own filter customizations usage stats"
ON user_filter_customizations_usage_stats
FOR SELECT
USING (user_id = auth.uid());

-- Daily Stats Policies
CREATE POLICY "Users can view their own daily stats"
ON user_filter_effects_usage_stats_daily
FOR SELECT
USING (user_id = auth.uid());

-- Weekly Stats Policies
CREATE POLICY "Users can view their own weekly stats"
ON user_filter_effects_usage_stats_weekly
FOR SELECT
USING (user_id = auth.uid());

-- Monthly Stats Policies
CREATE POLICY "Users can view their own monthly stats"
ON user_filter_effects_usage_stats_monthly
FOR SELECT
USING (user_id = auth.uid());

-- Yearly Stats Policies
CREATE POLICY "Users can view their own yearly stats"
ON user_filter_effects_usage_stats_yearly
FOR SELECT
USING (user_id = auth.uid());

-- Create view for call history
CREATE VIEW call_history AS
SELECT 
    cs.id as session_id,
    cs.started_at,
    cs.ended_at,
    cs.duration_sec,
    cs.peer_used_turn,
    cs.connection_quality,
    ua.display_name as user_a_name,
    ub.display_name as user_b_name,
    COUNT(DISTINCT csf.id) as total_filters_used,
    COUNT(DISTINCT CASE WHEN csf.triggered_effects THEN csf.id END) as effects_triggered
FROM call_sessions cs
JOIN auth.users ua ON ua.id = cs.user_a_id
JOIN auth.users ub ON ub.id = cs.user_b_id
LEFT JOIN call_sessions_filters csf ON csf.session_id = cs.id
GROUP BY cs.id, ua.display_name, ub.display_name;

-- Create view for user statistics
CREATE VIEW user_statistics AS
SELECT 
    u.id as user_id,
    u.display_name,
    COUNT(DISTINCT cs.id) as total_calls,
    SUM(cs.duration_sec) as total_duration,
    AVG(cs.duration_sec) as avg_duration,
    COUNT(DISTINCT csf.filter_name) as unique_filters_used,
    COUNT(DISTINCT ur.related_user_id) as total_contacts,
    COUNT(DISTINCT CASE WHEN cs.peer_used_turn THEN cs.id END) as calls_using_turn
FROM auth.users u
LEFT JOIN call_sessions cs ON u.id = cs.user_a_id OR u.id = cs.user_b_id
LEFT JOIN call_sessions_filters csf ON csf.session_id = cs.id AND csf.user_id = u.id
LEFT JOIN user_relationships ur ON u.id = ur.user_id
GROUP BY u.id, u.display_name;

-- Create function to update user's last_seen
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE auth.users
    SET last_seen = NOW()
    WHERE id = NEW.user_a_id OR id = NEW.user_b_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updating last_seen
CREATE TRIGGER update_last_seen_on_call
    AFTER INSERT ON call_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen(); 