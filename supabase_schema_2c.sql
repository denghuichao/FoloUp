-- B2C Interview Practice Platform Schema
-- Created for FoloUp refactor to job seeker focused platform

-- Create enum types
CREATE TYPE plan_type AS ENUM ('free', 'one_time_purchase', 'subscription', 'enterprise');
CREATE TYPE plan_status AS ENUM ('active', 'inactive', 'deprecated');
CREATE TYPE difficulty_level AS ENUM ('easy', 'medium', 'hard', 'expert');
CREATE TYPE interview_status AS ENUM ('scheduled', 'in_progress', 'completed', 'abandoned');
CREATE TYPE candidate_performance AS ENUM ('excellent', 'good', 'average', 'needs_improvement');
CREATE TYPE interviewer_personality AS ENUM ('analytical', 'creative', 'aggressive', 'empathetic', 'casual', 'formal');

-- Pricing plans table - supports flexible usage-based billing
CREATE TABLE plan (
    id TEXT PRIMARY KEY, -- e.g., 'free', 'starter_10', 'professional_50', 'unlimited'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    
    -- Plan metadata
    name TEXT NOT NULL, -- e.g., 'Free Plan', 'Starter Pack', 'Professional'
    description TEXT, -- detailed plan description
    plan_type plan_type NOT NULL,
    status plan_status DEFAULT 'active',
    
    -- Pricing information
    price_cents INTEGER NOT NULL DEFAULT 0, -- price in cents (0 for free)
    currency TEXT DEFAULT 'USD',
    billing_interval TEXT, -- 'one_time', 'monthly', 'yearly', null for free
    
    -- Usage limits and features
    allowed_interview_count INTEGER NOT NULL, -- number of interviews allowed
    max_interview_duration_minutes INTEGER DEFAULT 30, -- max duration per interview
    max_concurrent_interviews INTEGER DEFAULT 1, -- how many interviews can run simultaneously
    
    -- Feature access
    has_unlimited_retakes BOOLEAN DEFAULT true,
    has_advanced_analytics BOOLEAN DEFAULT false,
    has_custom_interviewers BOOLEAN DEFAULT false,
    has_resume_optimization BOOLEAN DEFAULT false,
    has_priority_support BOOLEAN DEFAULT false,
    has_api_access BOOLEAN DEFAULT false,
    
    -- AI and premium features
    ai_feedback_detail_level INTEGER DEFAULT 1 CHECK (ai_feedback_detail_level >= 1 AND ai_feedback_detail_level <= 5), -- 1=basic, 5=comprehensive
    available_interviewer_personalities TEXT[], -- which personalities user can access
    max_resumes_count INTEGER DEFAULT 1, -- how many resumes user can store
    
    -- Plan ordering and visibility
    sort_order INTEGER DEFAULT 0, -- for display ordering
    is_popular BOOLEAN DEFAULT false, -- highlight as popular choice
    is_visible BOOLEAN DEFAULT true, -- show in pricing page
    
    -- Promotional and trial
    has_free_trial BOOLEAN DEFAULT false,
    trial_duration_days INTEGER DEFAULT 0,
    trial_interview_count INTEGER DEFAULT 0,
    
    -- Plan restrictions
    allowed_job_applications_per_month INTEGER, -- limit job application tracking
    max_job_searches_per_day INTEGER -- limit job search queries
);

-- User table - Individual job seekers (no organization dependency)
CREATE TABLE "user" (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    profile_image_url TEXT,
    
    -- Current plan and usage tracking
    current_plan_id TEXT REFERENCES plan(id) DEFAULT 'free',
    used_interview_count INTEGER DEFAULT 0, -- interviews used in current billing period
    billing_period_start TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    billing_period_end TIMESTAMP WITH TIME ZONE,
    
    -- User preferences
    timezone TEXT DEFAULT 'UTC',
    preferred_industries TEXT[], -- array of industry strings for flexibility. Suggested values: 'technology', 'finance', 'healthcare', 'marketing', 'sales', 'consulting', 'design', 'education', 'manufacturing', 'retail', 'startup', 'non-profit', 'government', 'media', 'real-estate', 'automotive', 'energy', 'telecommunications', 'aerospace', 'biotechnology'
    career_level TEXT, -- 'entry', 'mid', 'senior', 'executive'
    is_active BOOLEAN DEFAULT true,
    
    -- Profile information (merged from user_profile)
    skills TEXT[],
    experience_years INTEGER,
    social_links JSONB, -- {'linkedin': 'url', 'github': 'url', 'twitter': 'url', etc.}
    portfolio_url TEXT,
    key_achievements TEXT[]
);

-- Resume management table - supports multiple resumes per user
CREATE TABLE user_resume (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    
    -- Resume metadata
    title TEXT NOT NULL, -- e.g., 'Software Engineer Resume', 'Data Scientist Resume'
    is_primary BOOLEAN DEFAULT false, -- only one primary resume per user
    is_active BOOLEAN DEFAULT true,
    
    -- Resume content
    resume_text TEXT, -- extracted/parsed text content
    resume_file_url TEXT, -- original file URL
    file_name TEXT,
    file_type TEXT, -- 'pdf', 'docx', etc.
    
    -- Structured resume data (AI parsed)
    structured_data JSONB, -- parsed sections like experience, education, skills
    
    -- AI optimization features
    target_job_title TEXT, -- what job this resume is optimized for
    target_industry TEXT, -- flexible industry string. Suggested values: 'technology', 'finance', 'healthcare', 'marketing', 'sales', 'consulting', 'design', 'education', 'manufacturing', 'retail', 'startup', 'non-profit', 'government', 'media', 'real-estate', 'automotive', 'energy', 'telecommunications', 'aerospace', 'biotechnology'
    optimization_notes TEXT, -- AI suggestions for improvement
    ats_score INTEGER CHECK (ats_score >= 0 AND ats_score <= 100), -- ATS compatibility score
    
    -- Version control for AI optimizations
    original_resume_id INTEGER REFERENCES user_resume(id), -- reference to original if this is an optimized version
    optimization_type TEXT, -- 'ats_optimized', 'job_specific', 'skills_enhanced', etc.
    optimization_prompt TEXT, -- the prompt used for AI optimization
    
    -- Usage statistics
    interview_sessions_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- Enhanced interviewer table with personality types
CREATE TABLE interviewer (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    created_by TEXT REFERENCES "user"(id), -- who created this interviewer (admin or user)
    agent_id TEXT UNIQUE,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    personality_description TEXT,
    image TEXT NOT NULL,
    audio TEXT,
    voice_id TEXT,
    empathy INTEGER NOT NULL CHECK (empathy >= 1 AND empathy <= 10),
    exploration INTEGER NOT NULL CHECK (exploration >= 1 AND exploration <= 10),
    rapport INTEGER NOT NULL CHECK (rapport >= 1 AND rapport <= 10),
    speed INTEGER NOT NULL CHECK (speed >= 1 AND speed <= 10),
    personality_type interviewer_personality NOT NULL,
    industry_focus TEXT NOT NULL, -- flexible industry string. Suggested values: 'technology', 'finance', 'healthcare', 'marketing', 'sales', 'consulting', 'design', 'education', 'manufacturing', 'retail', 'startup', 'non-profit', 'government', 'media', 'real-estate', 'automotive', 'energy', 'telecommunications', 'aerospace', 'biotechnology', 'general'
    is_premium BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_system_default BOOLEAN DEFAULT false, -- system provided vs user created
    sample_questions TEXT[],
    interview_style_notes TEXT
);

-- Job opportunities table - supports admin added and crawled jobs
CREATE TABLE job (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    created_by TEXT REFERENCES "user"(id), -- who created/added this job (admin or user)
    
    -- Basic job information
    job_title TEXT NOT NULL,
    company_name TEXT NOT NULL,
    job_description TEXT,
    job_requirements TEXT[],
    salary_range TEXT,
    job_url TEXT,
    location TEXT,
    work_type TEXT, -- 'remote', 'hybrid', 'onsite'
    employment_type TEXT, -- 'full_time', 'part_time', 'contract', 'internship'
    
    -- Job categorization
    industry TEXT, -- flexible industry string. Suggested values: 'technology', 'finance', 'healthcare', 'marketing', 'sales', 'consulting', 'design', 'education', 'manufacturing', 'retail', 'startup', 'non-profit', 'government', 'media', 'real-estate', 'automotive', 'energy', 'telecommunications', 'aerospace', 'biotechnology'
    seniority_level TEXT, -- 'entry', 'mid', 'senior', 'executive', 'director'
    department TEXT, -- 'engineering', 'marketing', 'sales', 'design', etc.
    
    -- Data source and management
    source TEXT DEFAULT 'admin', -- 'admin', 'crawler', 'user_submitted'
    source_url TEXT, -- original job posting URL if crawled
    external_job_id TEXT, -- ID from external source (LinkedIn, Indeed, etc.)
    crawled_at TIMESTAMP WITH TIME ZONE, -- when it was crawled
    
    -- Job status and visibility
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false, -- featured jobs shown prominently
    is_verified BOOLEAN DEFAULT false, -- admin verified jobs
    is_system_default BOOLEAN DEFAULT false, -- system provided vs user created
    
    -- Usage statistics
    interview_sessions_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- SEO and discovery
    tags TEXT[], -- searchable tags like ['react', 'nodejs', 'startup']
    skill_keywords TEXT[], -- extracted skill keywords for matching
    
    -- Admin notes
    admin_notes TEXT,
    quality_score INTEGER CHECK (quality_score >= 1 AND quality_score <= 5), -- job posting quality rating
    
    -- Constraints
    UNIQUE(external_job_id, source) -- prevent duplicate crawled jobs
);



-- Interview sessions (renamed from interview)
CREATE TABLE interview_session (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    interviewer_id INTEGER REFERENCES interviewer(id),
    resume_id INTEGER REFERENCES user_resume(id), -- which resume to use for this interview
    job_id INTEGER REFERENCES job(id), -- reference to job table instead of inline fields
    
    -- Interview configuration
    session_name TEXT,
    difficulty_level difficulty_level DEFAULT 'medium',
    estimated_duration INTEGER DEFAULT 30, -- minutes
    focus_areas TEXT[], -- e.g., ['behavioral', 'technical', 'cultural_fit']
    
    -- Session state
    status interview_status DEFAULT 'scheduled',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Generated content
    questions JSONB,
    personalized_context JSONB, -- AI analysis of user profile vs job
    interview_objectives TEXT[],
    
    -- Session settings
    is_timed BOOLEAN DEFAULT true,
    allow_retakes BOOLEAN DEFAULT true,
    
    -- URLs and access
    interview_url TEXT,
    readable_slug TEXT,
    
    -- Analytics
    total_questions INTEGER,
    completed_questions INTEGER,
    session_rating INTEGER CHECK (session_rating >= 1 AND session_rating <= 5)
);

-- Interview records (renamed from response)
CREATE TABLE interview_record (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    interview_session_id TEXT REFERENCES interview_session(id) ON DELETE CASCADE,
    
    -- Session details
    call_id TEXT,
    duration INTEGER, -- seconds
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    
    -- Performance data
    transcript TEXT,
    audio_url TEXT,
    details JSONB, -- structured conversation data
    
    -- AI Analysis results
    analytics JSONB, -- overall performance metrics
    communication_score INTEGER CHECK (communication_score >= 0 AND communication_score <= 100),
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    technical_score INTEGER CHECK (technical_score >= 0 AND technical_score <= 100),
    overall_performance candidate_performance,
    
    -- Feedback and improvements
    strengths TEXT[],
    improvement_areas TEXT[],
    specific_feedback TEXT[],
    improvement_suggestions TEXT[],
    recommended_interview_topics TEXT[],
    
    -- Behavioral indicators
    speech_pace_rating INTEGER CHECK (speech_pace_rating >= 1 AND speech_pace_rating <= 5),
    clarity_rating INTEGER CHECK (clarity_rating >= 1 AND clarity_rating <= 5),
    enthusiasm_rating INTEGER CHECK (enthusiasm_rating >= 1 AND enthusiasm_rating <= 5),
    
    -- System flags
    is_analysed BOOLEAN DEFAULT false,
    is_completed BOOLEAN DEFAULT false,
    was_interrupted BOOLEAN DEFAULT false,
    technical_issues BOOLEAN DEFAULT false,
    
    -- User engagement
    tab_switch_count INTEGER DEFAULT 0,
    total_silence_duration INTEGER DEFAULT 0 -- seconds of silence
);

-- User feedback on interview sessions
CREATE TABLE interview_feedback (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    interview_session_id TEXT REFERENCES interview_session(id) ON DELETE CASCADE,
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    
    -- Feedback ratings
    overall_satisfaction INTEGER CHECK (overall_satisfaction >= 1 AND overall_satisfaction <= 5),
    interviewer_rating INTEGER CHECK (interviewer_rating >= 1 AND interviewer_rating <= 5),
    question_relevance INTEGER CHECK (question_relevance >= 1 AND question_relevance <= 5),
    difficulty_appropriateness INTEGER CHECK (difficulty_appropriateness >= 1 AND difficulty_appropriateness <= 5),
    feedback_quality INTEGER CHECK (feedback_quality >= 1 AND feedback_quality <= 5),
    
    -- Qualitative feedback
    what_helped_most TEXT,
    what_could_improve TEXT,
    would_recommend BOOLEAN,
    additional_comments TEXT,
    
    -- Feature requests
    requested_improvements TEXT[],
    suggested_interview_topics TEXT[]
);

-- User progress tracking
CREATE TABLE user_progress (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    
    -- Interview statistics
    total_sessions INTEGER DEFAULT 0,
    completed_sessions INTEGER DEFAULT 0,
    total_interview_time INTEGER DEFAULT 0, -- minutes
    
    -- Skill progression
    communication_trend JSONB, -- array of scores over time
    confidence_trend JSONB,
    technical_trend JSONB,
    
    -- Areas of focus
    weakest_areas TEXT[],
    strongest_areas TEXT[],
    recent_improvements TEXT[],
    
    -- Goals and targets
    target_roles TEXT[],
    interview_goals TEXT[],
    weekly_interview_target INTEGER DEFAULT 2,
    
    -- Achievements
    milestones_achieved TEXT[],
    streak_days INTEGER DEFAULT 0,
    best_session_score INTEGER,
    
    UNIQUE(user_id)
);

-- Billing history table - tracks user subscription and payment records
CREATE TABLE billing_history (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    
    -- Plan information
    plan_id TEXT REFERENCES plan(id), -- which plan was purchased
    plan_name TEXT NOT NULL, -- snapshot of plan name at time of purchase
    plan_type plan_type NOT NULL,
    
    -- Transaction details
    transaction_id TEXT UNIQUE, -- external payment processor transaction ID
    payment_processor TEXT, -- 'stripe', 'paypal', 'manual', etc.
    payment_method TEXT, -- 'card', 'paypal', 'bank_transfer', etc.
    
    -- Pricing information (snapshot at time of purchase)
    amount_cents INTEGER NOT NULL, -- amount paid in cents
    currency TEXT DEFAULT 'USD',
    original_price_cents INTEGER, -- original price if there was a discount
    discount_amount_cents INTEGER DEFAULT 0, -- discount applied
    discount_code TEXT, -- promo code used
    
    -- Billing period
    billing_period_start TIMESTAMP WITH TIME ZONE,
    billing_period_end TIMESTAMP WITH TIME ZONE,
    
    -- Transaction status
    status TEXT NOT NULL, -- 'pending', 'completed', 'failed', 'refunded', 'cancelled'
    payment_date TIMESTAMP WITH TIME ZONE,
    
    -- Refund information
    refund_date TIMESTAMP WITH TIME ZONE,
    refund_amount_cents INTEGER,
    refund_reason TEXT,
    
    -- Subscription management
    subscription_id TEXT, -- external subscription ID for recurring plans
    is_auto_renewal BOOLEAN DEFAULT false,
    next_billing_date TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    notes TEXT, -- admin notes or special circumstances
    metadata JSONB -- flexible field for additional payment processor data
);

-- Job application tracking (optional feature)
CREATE TABLE job_application (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    
    company_name TEXT NOT NULL,
    job_title TEXT NOT NULL,
    job_id INTEGER REFERENCES job(id), -- reference to job table
    job_url TEXT, -- can be different from job.job_url if user applied through different source
    application_date DATE,
    status TEXT, -- 'applied', 'interview_scheduled', 'interviewed', 'rejected', 'offer', 'accepted'
    
    -- Link to interview sessions for this role
    related_interview_sessions TEXT[], -- array of interview_session ids
    
    -- Interview experience
    interview_date DATE,
    interview_format TEXT, -- 'phone', 'video', 'in_person', 'panel'
    interview_feedback TEXT,
    outcome TEXT,
    
    -- Notes
    application_notes TEXT,
    company_culture_notes TEXT
);

-- System analytics and insights
CREATE TABLE platform_analytics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    
    -- User metrics
    new_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    premium_conversions INTEGER DEFAULT 0,
    
    -- Interview metrics
    total_sessions INTEGER DEFAULT 0,
    completed_sessions INTEGER DEFAULT 0,
    average_session_duration DECIMAL,
    
    -- Popular content
    most_used_interviewers INTEGER[],
    popular_job_titles TEXT[],
    common_improvement_areas TEXT[],
    
    -- Performance metrics
    average_user_satisfaction DECIMAL,
    platform_uptime_percentage DECIMAL,
    
    UNIQUE(date)
);

-- Indexes for performance
CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_user_current_plan_id ON "user"(current_plan_id);
CREATE INDEX idx_plan_status ON plan(status);
CREATE INDEX idx_plan_type ON plan(plan_type);
CREATE INDEX idx_plan_is_visible ON plan(is_visible);
CREATE INDEX idx_plan_sort_order ON plan(sort_order);
CREATE INDEX idx_user_resume_user_id ON user_resume(user_id);
CREATE INDEX idx_user_resume_is_primary ON user_resume(is_primary);
CREATE INDEX idx_user_resume_target_industry ON user_resume(target_industry);
CREATE INDEX idx_interviewer_created_by ON interviewer(created_by);
CREATE INDEX idx_interviewer_is_system_default ON interviewer(is_system_default);
CREATE INDEX idx_interviewer_industry_focus ON interviewer(industry_focus); -- updated for TEXT type, indexes industry focus for efficient filtering
CREATE INDEX idx_job_created_by ON job(created_by);
CREATE INDEX idx_job_company_name ON job(company_name);
CREATE INDEX idx_job_industry ON job(industry); -- updated for TEXT type, indexes industry for efficient job filtering by industry
CREATE INDEX idx_job_is_active ON job(is_active);
CREATE INDEX idx_job_is_featured ON job(is_featured);
CREATE INDEX idx_job_is_system_default ON job(is_system_default);
CREATE INDEX idx_job_source ON job(source);
CREATE INDEX idx_job_tags ON job USING GIN(tags);
CREATE INDEX idx_job_skill_keywords ON job USING GIN(skill_keywords);
CREATE INDEX idx_interview_session_user_id ON interview_session(user_id);
CREATE INDEX idx_interview_session_job_id ON interview_session(job_id);
CREATE INDEX idx_interview_session_resume_id ON interview_session(resume_id);
CREATE INDEX idx_interview_session_status ON interview_session(status);
CREATE INDEX idx_interview_session_created_at ON interview_session(created_at);
CREATE INDEX idx_interview_record_session_id ON interview_record(interview_session_id);
CREATE INDEX idx_interview_record_created_at ON interview_record(created_at);
CREATE INDEX idx_interviewer_personality ON interviewer(personality_type);
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_billing_history_user_id ON billing_history(user_id);
CREATE INDEX idx_billing_history_plan_id ON billing_history(plan_id);
CREATE INDEX idx_billing_history_status ON billing_history(status);
CREATE INDEX idx_billing_history_transaction_id ON billing_history(transaction_id);
CREATE INDEX idx_billing_history_subscription_id ON billing_history(subscription_id);
CREATE INDEX idx_billing_history_payment_date ON billing_history(payment_date);
CREATE INDEX idx_billing_history_billing_period ON billing_history(billing_period_start, billing_period_end);
CREATE INDEX idx_job_application_user_id ON job_application(user_id);
CREATE INDEX idx_job_application_status ON job_application(status);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_user_updated_at BEFORE UPDATE ON "user" 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plan_updated_at BEFORE UPDATE ON plan 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_resume_updated_at BEFORE UPDATE ON user_resume 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_updated_at BEFORE UPDATE ON job 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interview_session_updated_at BEFORE UPDATE ON interview_session 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_billing_history_updated_at BEFORE UPDATE ON billing_history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_application_updated_at BEFORE UPDATE ON job_application 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default plans
INSERT INTO plan (id, name, description, plan_type, price_cents, allowed_interview_count, max_interview_duration_minutes, ai_feedback_detail_level, available_interviewer_personalities, max_resumes_count, sort_order, is_visible) VALUES
('free', 'Free Plan', 'Get started with basic interview practice', 'free', 0, 1, 10, 1, ARRAY['empathetic'], 1, 1, true),
('starter_5', 'Starter Pack', '5 interview sessions to build confidence', 'one_time_purchase', 999, 5, 30, 2, ARRAY['empathetic', 'analytical'], 2, 2, true),
('professional_20', 'Professional Pack', '20 comprehensive interview sessions', 'one_time_purchase', 2999, 20, 45, 3, ARRAY['empathetic', 'analytical', 'creative'], 3, 3, true),
('unlimited_monthly', 'Unlimited Monthly', 'Unlimited interviews with all features', 'subscription', 1999, -1, 60, 5, ARRAY['empathetic', 'analytical', 'creative', 'aggressive', 'casual', 'formal'], 10, 4, true);

-- Insert sample interviewers with different personalities
INSERT INTO interviewer (agent_id, name, description, personality_description, image, audio, empathy, exploration, rapport, speed, personality_type, industry_focus, sample_questions, is_system_default) VALUES
('tech-sarah-001', 'Sarah Chen', 'Senior Engineering Manager at top tech company', 'Direct, technical-focused, appreciates concise answers and problem-solving approach', '/interviewers/Lisa.png', '/audio/Lisa.wav', 6, 9, 7, 8, 'analytical', 'technology', 
 ARRAY['Walk me through your approach to debugging a complex system issue', 'How do you handle technical debt in your projects?', 'Describe a time you had to learn a new technology quickly'], true),

('creative-marcus-001', 'Marcus Rodriguez', 'Creative Director with 15 years in advertising', 'Collaborative, story-focused, values creativity and innovative thinking', '/interviewers/Bob.png', '/audio/Bob.wav', 9, 8, 9, 6, 'creative', 'design',
 ARRAY['Tell me about a project where you had to think outside the box', 'How do you handle creative differences with stakeholders?', 'Walk me through your creative process'], true),

('finance-david-001', 'David Kim', 'Investment Banking VP on Wall Street', 'High-pressure, rapid-fire questioning, results and numbers oriented', '/interviewers/Bob.png', '/audio/Bob.wav', 4, 7, 5, 10, 'aggressive', 'finance',
 ARRAY['Give me three reasons why this company is a good investment', 'How do you perform under extreme pressure?', 'Walk me through a DCF model'], true),

('hr-jennifer-001', 'Jennifer Thompson', 'Head of People Operations', 'Warm, behavioral-focused, emphasizes culture fit and soft skills', '/interviewers/Lisa.png', '/audio/Lisa.wav', 10, 6, 10, 7, 'empathetic', 'general',
 ARRAY['Tell me about a time you had to work with a difficult team member', 'How do you handle work-life balance?', 'What motivates you in your career?'], true),

('consultant-alex-001', 'Alex Parker', 'Principal Consultant at Big 4 firm', 'Structured, case-study focused, analytical and methodical', '/interviewers/Bob.png', '/audio/Bob.wav', 7, 9, 8, 7, 'analytical', 'consulting',
 ARRAY['How would you approach entering a new market?', 'Walk me through how you would solve this business problem', 'What framework would you use to analyze this situation?'], true);
-- Insert sample jobs for practice
INSERT INTO job (job_title, company_name, job_description, job_requirements, salary_range, location, work_type, employment_type, industry, seniority_level, department, source, is_active, is_featured, is_system_default, tags, skill_keywords, quality_score) VALUES
('Senior Software Engineer', 'Google', 'Join our team to build scalable systems that serve billions of users. You will work on cutting-edge technologies and solve complex technical challenges.', 
 ARRAY['5+ years of software development experience', 'Proficiency in Java, Python, or Go', 'Experience with distributed systems', 'Strong problem-solving skills'], 
 '$180,000 - $280,000', 'Mountain View, CA', 'hybrid', 'full_time', 'technology', 'senior', 'engineering', 'admin', true, true, true,
 ARRAY['java', 'python', 'distributed-systems', 'google', 'faang'], 
 ARRAY['Java', 'Python', 'Go', 'Distributed Systems', 'Microservices'], 5),

('Product Marketing Manager', 'Meta', 'Drive product marketing strategy for our core products. Work cross-functionally with product, engineering, and sales teams.',
 ARRAY['3+ years of product marketing experience', 'Strong analytical skills', 'Experience with B2B SaaS', 'Excellent communication skills'],
 '$140,000 - $220,000', 'Menlo Park, CA', 'hybrid', 'full_time', 'technology', 'mid', 'marketing', 'admin', true, true, true,
 ARRAY['product-marketing', 'meta', 'b2b', 'saas', 'strategy'],
 ARRAY['Product Marketing', 'Analytics', 'B2B SaaS', 'Strategy', 'Communication'], 5),

('Investment Banking Analyst', 'Goldman Sachs', 'Join our Investment Banking division to work on high-profile M&A transactions and capital raising activities.',
 ARRAY['Bachelor degree in Finance, Economics, or related field', 'Strong financial modeling skills', 'Proficiency in Excel and PowerPoint', 'Ability to work in fast-paced environment'],
 '$100,000 - $150,000', 'New York, NY', 'onsite', 'full_time', 'finance', 'entry', 'investment_banking', 'admin', true, false, true,
 ARRAY['investment-banking', 'goldman-sachs', 'finance', 'modeling', 'ma'],
 ARRAY['Financial Modeling', 'Excel', 'PowerPoint', 'M&A', 'Valuation'], 4),

('UX Designer', 'Airbnb', 'Design intuitive and delightful experiences for millions of travelers and hosts worldwide. Work on mobile and web platforms.',
 ARRAY['3+ years of UX/UI design experience', 'Proficiency in Figma, Sketch, or similar tools', 'Strong portfolio demonstrating user-centered design', 'Experience with design systems'],
 '$120,000 - $180,000', 'San Francisco, CA', 'remote', 'full_time', 'design', 'mid', 'design', 'admin', true, false, true,
 ARRAY['ux-design', 'ui-design', 'figma', 'airbnb', 'remote'],
 ARRAY['UX Design', 'UI Design', 'Figma', 'Sketch', 'Design Systems'], 4),

('Data Scientist', 'Netflix', 'Use machine learning and statistical analysis to improve content recommendations and user experience.',
 ARRAY['PhD or Masters in Statistics, Computer Science, or related field', 'Experience with Python, R, SQL', 'Machine learning expertise', '3+ years of industry experience'],
 '$160,000 - $240,000', 'Los Gatos, CA', 'hybrid', 'full_time', 'technology', 'senior', 'data_science', 'admin', true, true, true,
 ARRAY['data-science', 'machine-learning', 'python', 'netflix', 'recommendations'],
 ARRAY['Python', 'R', 'SQL', 'Machine Learning', 'Statistics'], 5);

-- RLS (Row Level Security) policies
ALTER TABLE "user" ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_resume ENABLE ROW LEVEL SECURITY;
ALTER TABLE job ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_application ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view their own data" ON "user"
    FOR ALL USING (auth.uid()::text = id);

CREATE POLICY "Anyone can view active plans" ON plan
    FOR SELECT USING (status = 'active' AND is_visible = true);

CREATE POLICY "Users can manage their own resumes" ON user_resume
    FOR ALL USING (auth.uid()::text = user_id);

CREATE POLICY "Anyone can view active jobs" ON job
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can manage their own interview sessions" ON interview_session
    FOR ALL USING (auth.uid()::text = user_id);

CREATE POLICY "Users can view their own interview records" ON interview_record
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM interview_session is_table 
            WHERE is_table.id = interview_record.interview_session_id 
            AND is_table.user_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can manage their own feedback" ON interview_feedback
    FOR ALL USING (auth.uid()::text = user_id);

CREATE POLICY "Users can view their own progress" ON user_progress
    FOR ALL USING (auth.uid()::text = user_id);

CREATE POLICY "Users can view their own billing history" ON billing_history
    FOR ALL USING (auth.uid()::text = user_id);

CREATE POLICY "Users can manage their own applications" ON job_application
    FOR ALL USING (auth.uid()::text = user_id);

-- Public read access for interviewers
CREATE POLICY "Anyone can view active interviewers" ON interviewer
    FOR SELECT USING (is_active = true);
