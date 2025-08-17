-- =====================================================
-- SNOWFLAKE CYBERSECURITY DEMO - ENHANCED SAMPLE DATA
-- High-volume, realistic sample data optimized for ML model training
-- Features: 500+ users, 180+ days, seasonal patterns, diverse personas
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. ENHANCED EMPLOYEE DATA (500+ Users with Personas)
-- =====================================================

-- Clear existing data for fresh ML-optimized dataset
DELETE FROM DATA_ACCESS_LOGS;
DELETE FROM FINANCIAL_TRANSACTIONS;
DELETE FROM USER_AUTHENTICATION_LOGS;
DELETE FROM EMPLOYEE_DATA;

-- Generate 500+ realistic users with diverse behavioral personas
INSERT INTO EMPLOYEE_DATA 
WITH user_personas AS (
  SELECT 
    persona_type,
    department,
    role_title,
    security_clearance,
    timezone_offset,
    typical_hours_start,
    typical_hours_end,
    weekend_work_probability,
    travel_frequency,
    location_diversity,
    users_per_persona
  FROM VALUES
    -- Regular Business Users (40% - 200 users)
    ('REGULAR_BUSINESS', 'Finance', 'Financial Analyst', 'Standard', -8, 9, 17, 0.05, 'none', 'single', 200),
    ('REGULAR_BUSINESS', 'Marketing', 'Marketing Specialist', 'Standard', -8, 9, 18, 0.10, 'low', 'single', 50),
    ('REGULAR_BUSINESS', 'Legal', 'Legal Counsel', 'Confidential', -8, 9, 18, 0.15, 'low', 'single', 30),
    
    -- IT/DevOps (24/7 operations) (20% - 100 users)
    ('DEVOPS_247', 'IT Operations', 'DevOps Engineer', 'Standard', -8, 6, 22, 0.70, 'none', 'single', 60),
    ('DEVOPS_247', 'Engineering', 'Software Engineer', 'Standard', -8, 10, 20, 0.40, 'low', 'single', 80),
    ('DEVOPS_247', 'Data Science', 'Data Scientist', 'Standard', -8, 8, 20, 0.50, 'low', 'single', 40),
    
    -- Sales/Consultants (Frequent travelers) (15% - 75 users)
    ('FREQUENT_TRAVELER', 'Sales', 'Sales Representative', 'Standard', -8, 8, 19, 0.30, 'high', 'multi', 50),
    ('FREQUENT_TRAVELER', 'Consulting', 'Senior Consultant', 'Standard', -8, 7, 21, 0.40, 'high', 'multi', 25),
    
    -- Security Team (Incident response, 24/7) (10% - 50 users)
    ('SECURITY_ANALYST', 'Security', 'Security Analyst', 'Secret', -8, 0, 23, 0.80, 'low', 'single', 30),
    ('SECURITY_ANALYST', 'Security', 'Incident Responder', 'Secret', -8, 0, 23, 0.90, 'low', 'single', 20),
    
    -- Executives (High access, irregular hours) (5% - 25 users)
    ('EXECUTIVE', 'Executive', 'VP Engineering', 'Confidential', -8, 7, 20, 0.60, 'medium', 'multi', 10),
    ('EXECUTIVE', 'Executive', 'Chief Financial Officer', 'Top Secret', -8, 8, 19, 0.50, 'medium', 'multi', 5),
    ('EXECUTIVE', 'Executive', 'Chief Security Officer', 'Top Secret', -8, 6, 22, 0.70, 'medium', 'multi', 5),
    ('EXECUTIVE', 'Executive', 'Chief Technology Officer', 'Top Secret', -8, 8, 21, 0.60, 'medium', 'multi', 5),
    
    -- Part-time/Contractors (5% - 25 users)
    ('PART_TIME', 'Consulting', 'Contract Developer', 'Standard', -8, 10, 15, 0.00, 'none', 'single', 15),
    ('PART_TIME', 'Support', 'Customer Support', 'Standard', -8, 9, 17, 0.10, 'none', 'single', 10)
    
  AS personas(persona_type, department, role_title, security_clearance, timezone_offset, 
              typical_hours_start, typical_hours_end, weekend_work_probability, 
              travel_frequency, location_diversity, users_per_persona)
),
user_generation AS (
  SELECT 
    'EMP' || LPAD(ROW_NUMBER() OVER (ORDER BY persona_type, user_num), 4, '0') as employee_id,
    LOWER(persona_type) || '_user_' || LPAD(ROW_NUMBER() OVER (ORDER BY persona_type, user_num), 4, '0') as username,
    persona_type,
    department,
    role_title,
    security_clearance,
    timezone_offset,
    typical_hours_start,
    typical_hours_end,
    weekend_work_probability,
    travel_frequency,
    location_diversity,
    -- Add hire date with realistic distribution
    DATEADD(day, -UNIFORM(30, 2000, RANDOM()), CURRENT_DATE()) as hire_date
  FROM user_personas up
  CROSS JOIN (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as user_num
    FROM TABLE(GENERATOR(ROWCOUNT => 300))  -- Generate enough rows
  ) gen
  WHERE gen.user_num <= up.users_per_persona
)
SELECT 
  employee_id,
  username,
  username || '@company.com' as email,
  department,
  role_title,
  CASE 
    WHEN department = 'Executive' THEN NULL
    WHEN ROW_NUMBER() OVER (PARTITION BY department ORDER BY username) = 1 THEN NULL
    ELSE 'EMP' || LPAD(UNIFORM(1, 50, RANDOM()), 4, '0')  -- Random manager assignment
  END as manager_id,
  hire_date,
  security_clearance,
  CASE 
    WHEN security_clearance = 'Top Secret' THEN 'Critical'
    WHEN security_clearance = 'Secret' THEN 'High'
    WHEN security_clearance = 'Confidential' THEN 'Medium'
    ELSE 'Low'
  END as access_level,
  CASE 
    WHEN UNIFORM(0.0, 1.0, RANDOM()) < 0.02 THEN 'terminated'  -- 2% terminated users
    WHEN UNIFORM(0.0, 1.0, RANDOM()) < 0.01 THEN 'suspended'   -- 1% suspended users
    ELSE 'active'
  END as status
FROM user_generation;

-- =====================================================
-- 2. ENHANCED THREAT INTELLIGENCE FEED (Marketplace Data)
-- =====================================================

INSERT INTO THREAT_INTEL_FEED 
WITH threat_indicators AS (
  SELECT 
    indicator_type,
    indicator_value,
    threat_type,
    severity,
    confidence_score,
    description,
    source_type,
    tags
  FROM VALUES
    -- Known APT Infrastructure
    ('ip', '203.0.113.45', 'apt', 'critical', 0.98, 'APT29 Cozy Bear infrastructure', 'government_feed', ARRAY_CONSTRUCT('apt29', 'cozy_bear', 'russia')),
    ('ip', '185.220.100.240', 'apt', 'critical', 0.95, 'APT28 Fancy Bear C2 server', 'government_feed', ARRAY_CONSTRUCT('apt28', 'fancy_bear', 'russia')),
    ('ip', '192.0.2.100', 'apt', 'high', 0.92, 'Lazarus Group infrastructure', 'commercial_feed', ARRAY_CONSTRUCT('lazarus', 'north_korea')),
    
    -- Botnet Infrastructure
    ('ip', '198.51.100.150', 'botnet', 'high', 0.90, 'Emotet C2 server', 'commercial_feed', ARRAY_CONSTRUCT('emotet', 'banking_trojan')),
    ('ip', '198.51.100.200', 'botnet', 'high', 0.88, 'Trickbot C2 infrastructure', 'commercial_feed', ARRAY_CONSTRUCT('trickbot', 'banking')),
    ('ip', '203.0.113.100', 'botnet', 'medium', 0.75, 'Dridex botnet node', 'open_source', ARRAY_CONSTRUCT('dridex', 'banking')),
    
    -- Phishing Infrastructure
    ('domain', 'fake-microsoft-login.com', 'phishing', 'high', 0.89, 'Microsoft credential phishing', 'commercial_feed', ARRAY_CONSTRUCT('phishing', 'microsoft', 'credentials')),
    ('domain', 'secure-bank-update.net', 'phishing', 'high', 0.87, 'Banking credential harvesting', 'commercial_feed', ARRAY_CONSTRUCT('phishing', 'banking', 'credentials')),
    ('domain', 'paypal-security-alert.org', 'phishing', 'medium', 0.82, 'PayPal phishing campaign', 'open_source', ARRAY_CONSTRUCT('phishing', 'paypal', 'financial')),
    
    -- Malware Hashes
    ('hash', 'a1b2c3d4e5f6789012345678901234567890abcd', 'malware', 'critical', 0.96, 'WannaCry ransomware variant', 'commercial_feed', ARRAY_CONSTRUCT('ransomware', 'wannacry')),
    ('hash', 'b2c3d4e5f6789012345678901234567890abcde1', 'malware', 'high', 0.94, 'Ryuk ransomware payload', 'commercial_feed', ARRAY_CONSTRUCT('ransomware', 'ryuk')),
    ('hash', 'c3d4e5f6789012345678901234567890abcdef12', 'malware', 'high', 0.91, 'Cobalt Strike beacon', 'government_feed', ARRAY_CONSTRUCT('cobalt_strike', 'apt')),
    
    -- Scanning/Reconnaissance
    ('ip', '192.0.2.50', 'scanning', 'low', 0.70, 'Automated vulnerability scanner', 'internal', ARRAY_CONSTRUCT('scanning', 'reconnaissance')),
    ('ip', '192.0.2.51', 'scanning', 'medium', 0.75, 'Aggressive port scanning', 'commercial_feed', ARRAY_CONSTRUCT('scanning', 'reconnaissance')),
    
    -- Cryptocurrency Related
    ('ip', '198.51.100.250', 'cryptomining', 'medium', 0.80, 'Cryptocurrency mining pool', 'open_source', ARRAY_CONSTRUCT('cryptomining', 'pool')),
    ('domain', 'crypto-wallet-stealer.com', 'malware', 'high', 0.85, 'Cryptocurrency wallet stealer', 'commercial_feed', ARRAY_CONSTRUCT('stealer', 'cryptocurrency'))
    
  AS indicators(indicator_type, indicator_value, threat_type, severity, confidence_score, description, source_type, tags)
)
SELECT 
  'TI' || LPAD(ROW_NUMBER() OVER (ORDER BY indicator_type, indicator_value), 4, '0') as feed_id,
  DATEADD(hour, -UNIFORM(1, 168, RANDOM()), CURRENT_TIMESTAMP()) as timestamp,  -- Random within last week
  indicator_type,
  indicator_value,
  threat_type,
  severity,
  confidence_score,
  description,
  source_type,
  tags
FROM threat_indicators;

-- =====================================================
-- 3. REALISTIC USER AUTHENTICATION LOGS (180+ Days with Seasonality)
-- =====================================================

INSERT INTO USER_AUTHENTICATION_LOGS
WITH persona_mapping AS (
  SELECT 
    employee_id,
    username,
    email,
    department,
    role,
    status,
    -- Extract persona from username for behavior modeling
    CASE 
      WHEN username LIKE 'regular_business%' THEN 'REGULAR_BUSINESS'
      WHEN username LIKE 'devops_247%' THEN 'DEVOPS_247'
      WHEN username LIKE 'frequent_traveler%' THEN 'FREQUENT_TRAVELER'
      WHEN username LIKE 'security_analyst%' THEN 'SECURITY_ANALYST'
      WHEN username LIKE 'executive%' THEN 'EXECUTIVE'
      WHEN username LIKE 'part_time%' THEN 'PART_TIME'
      ELSE 'REGULAR_BUSINESS'
    END as persona_type
  FROM EMPLOYEE_DATA
  WHERE status IN ('active', 'suspended')  -- Include suspended for realistic insider threat scenarios
),
time_series AS (
  SELECT 
    DATEADD(day, -day_offset, CURRENT_DATE()) as login_date,
    EXTRACT(DOW FROM DATEADD(day, -day_offset, CURRENT_DATE())) as day_of_week,  -- 0=Sunday
    EXTRACT(MONTH FROM DATEADD(day, -day_offset, CURRENT_DATE())) as month_num,
    EXTRACT(WEEK FROM DATEADD(day, -day_offset, CURRENT_DATE())) as week_num,
    hour_val as login_hour,
    -- Seasonal factors
    CASE 
      WHEN month_num IN (12, 1) THEN 0.7  -- Holiday season - reduced activity
      WHEN month_num IN (6, 7, 8) THEN 0.8  -- Summer vacation - reduced activity
      WHEN month_num IN (3, 9) THEN 1.2  -- Quarter end - increased activity
      ELSE 1.0
    END as seasonal_factor,
    -- Weekly patterns
    CASE 
      WHEN day_of_week IN (0, 6) THEN 0.2  -- Weekend - much lower activity
      WHEN day_of_week = 1 THEN 1.3  -- Monday - catch-up activity
      WHEN day_of_week = 5 THEN 0.9  -- Friday - winding down
      ELSE 1.0
    END as weekly_factor
  FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 as day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 180))  -- 180 days of data
  ) days
  CROSS JOIN (
    SELECT VALUE as hour_val
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT_COMPACT(
      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
    )))
  ) hours
),
behavior_patterns AS (
  SELECT 
    pm.employee_id,
    pm.username,
    pm.email,
    pm.persona_type,
    pm.status,
    ts.login_date,
    ts.day_of_week,
    ts.login_hour,
    ts.seasonal_factor,
    ts.weekly_factor,
    
    -- Persona-specific login probability calculation
    CASE pm.persona_type
      WHEN 'REGULAR_BUSINESS' THEN
        CASE 
          WHEN ts.login_hour BETWEEN 9 AND 17 AND ts.day_of_week NOT IN (0,6) THEN 0.6
          WHEN ts.login_hour BETWEEN 8 AND 18 AND ts.day_of_week NOT IN (0,6) THEN 0.3
          WHEN ts.day_of_week NOT IN (0,6) THEN 0.05
          ELSE 0.01
        END
      WHEN 'DEVOPS_247' THEN
        CASE 
          WHEN ts.login_hour BETWEEN 6 AND 22 THEN 0.4
          WHEN ts.day_of_week NOT IN (0,6) THEN 0.2
          ELSE 0.15
        END
      WHEN 'FREQUENT_TRAVELER' THEN
        CASE 
          WHEN ts.day_of_week NOT IN (0,6) THEN 0.3
          ELSE 0.1
        END
      WHEN 'SECURITY_ANALYST' THEN 0.25  -- 24/7 incident response
      WHEN 'EXECUTIVE' THEN
        CASE 
          WHEN ts.login_hour BETWEEN 7 AND 20 THEN 0.4
          ELSE 0.1
        END
      WHEN 'PART_TIME' THEN
        CASE 
          WHEN ts.login_hour BETWEEN 10 AND 15 AND ts.day_of_week BETWEEN 1 AND 5 THEN 0.5
          ELSE 0.01
        END
      ELSE 0.2
    END * ts.seasonal_factor * ts.weekly_factor as base_login_probability,
    
    -- Geographic distribution based on persona
    CASE pm.persona_type
      WHEN 'FREQUENT_TRAVELER' THEN
        CASE UNIFORM(1, 10, RANDOM())
          WHEN 1 THEN OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194)
          WHEN 2 THEN OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060)
          WHEN 3 THEN OBJECT_CONSTRUCT('country', 'UK', 'region', 'England', 'city', 'London', 'lat', 51.5074, 'lon', -0.1278)
          WHEN 4 THEN OBJECT_CONSTRUCT('country', 'DE', 'region', 'Bavaria', 'city', 'Munich', 'lat', 48.1351, 'lon', 11.5820)
          WHEN 5 THEN OBJECT_CONSTRUCT('country', 'JP', 'region', 'Tokyo', 'city', 'Tokyo', 'lat', 35.6762, 'lon', 139.6503)
          ELSE OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194)
        END
      WHEN 'EXECUTIVE' THEN
        CASE UNIFORM(1, 5, RANDOM())
          WHEN 1 THEN OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194)
          WHEN 2 THEN OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060)
          ELSE OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194)
        END
      ELSE 
        OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194)
    END as location_pattern,
    
    -- IP address patterns
    CASE pm.persona_type
      WHEN 'FREQUENT_TRAVELER' THEN
        CASE 
          WHEN UNIFORM(0.0, 1.0, RANDOM()) < 0.3 THEN 
            UNIFORM(1, 223, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
          ELSE '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
        END
      WHEN 'EXECUTIVE' THEN
        CASE 
          WHEN UNIFORM(0.0, 1.0, RANDOM()) < 0.2 THEN 
            UNIFORM(1, 223, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
          ELSE '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
        END
      ELSE '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
    END as source_ip_pattern
  FROM persona_mapping pm
  CROSS JOIN time_series ts
  WHERE pm.status = 'active'  -- Only generate logins for active users for now
)
SELECT 
  'AUTH_REALISTIC_' || ROW_NUMBER() OVER (ORDER BY employee_id, login_date, login_hour) as log_id,
  (login_date + INTERVAL login_hour || ' hours' + INTERVAL UNIFORM(0, 59, RANDOM()) || ' minutes')::TIMESTAMP_NTZ as timestamp,
  employee_id as user_id,
  username,
  email,
  'login' as event_type,
  source_ip_pattern as source_ip,
  CASE UNIFORM(1, 4, RANDOM())
    WHEN 1 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    WHEN 2 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    WHEN 3 THEN 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
    ELSE 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
  END as user_agent,
  location_pattern as location,
  TRUE as success,
  NULL as failure_reason,
  'SESS_' || UNIFORM(100000, 999999, RANDOM()) as session_id,
  CASE UNIFORM(1, 3, RANDOM())
    WHEN 1 THEN OBJECT_CONSTRUCT('device_type', 'laptop', 'os', 'Windows', 'browser', 'Chrome')
    WHEN 2 THEN OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'MacOS', 'browser', 'Safari')
    ELSE OBJECT_CONSTRUCT('device_type', 'mobile', 'os', 'iOS', 'browser', 'Safari')
  END as device_info,
  ARRAY_CONSTRUCT() as risk_factors,
  CASE 
    WHEN persona_type IN ('EXECUTIVE', 'SECURITY_ANALYST') THEN TRUE
    WHEN UNIFORM(0.0, 1.0, RANDOM()) < 0.8 THEN TRUE
    ELSE FALSE
  END as mfa_used
FROM behavior_patterns
WHERE UNIFORM(0.0, 1.0, RANDOM()) < base_login_probability  -- Probabilistic login generation
ORDER BY timestamp;

-- =====================================================
-- 4. SOPHISTICATED ANOMALY SCENARIOS (ML Training Data)
-- =====================================================

-- Generate realistic anomaly scenarios for ML model training
INSERT INTO USER_AUTHENTICATION_LOGS
WITH anomaly_scenarios AS (
  SELECT 
    scenario_type,
    target_username,
    target_employee_id,
    start_time,
    duration_hours,
    anomaly_severity
  FROM VALUES
    -- Gradual account compromise (APT-style)
    ('GRADUAL_COMPROMISE', 'regular_business_user_0050', 'EMP0050', DATEADD(day, -14, CURRENT_TIMESTAMP()), 240, 'high'),
    ('GRADUAL_COMPROMISE', 'devops_247_user_0025', 'EMP0060', DATEADD(day, -7, CURRENT_TIMESTAMP()), 120, 'medium'),
    
    -- Insider threat scenarios
    ('INSIDER_THREAT', 'security_analyst_user_0010', 'EMP0400', DATEADD(day, -21, CURRENT_TIMESTAMP()), 360, 'critical'),
    ('INSIDER_THREAT', 'executive_user_0005', 'EMP0450', DATEADD(day, -30, CURRENT_TIMESTAMP()), 480, 'high'),
    
    -- Account takeover (immediate foreign access)
    ('ACCOUNT_TAKEOVER', 'frequent_traveler_user_0015', 'EMP0300', DATEADD(hour, -48, CURRENT_TIMESTAMP()), 24, 'critical'),
    ('ACCOUNT_TAKEOVER', 'regular_business_user_0100', 'EMP0100', DATEADD(hour, -72, CURRENT_TIMESTAMP()), 12, 'high'),
    
    -- Credential stuffing attacks
    ('CREDENTIAL_STUFFING', 'regular_business_user_0075', 'EMP0075', DATEADD(hour, -6, CURRENT_TIMESTAMP()), 2, 'medium'),
    ('CREDENTIAL_STUFFING', 'part_time_user_0005', 'EMP0500', DATEADD(hour, -12, CURRENT_TIMESTAMP()), 4, 'medium')
    
  AS scenarios(scenario_type, target_username, target_employee_id, start_time, duration_hours, anomaly_severity)
),
anomaly_events AS (
  SELECT 
    asco.scenario_type,
    asco.target_username,
    asco.target_employee_id,
    asco.anomaly_severity,
    DATEADD(hour, event_offset, asco.start_time) as event_time,
    event_offset,
    
    -- Scenario-specific anomalous behaviors
    CASE asco.scenario_type
      WHEN 'GRADUAL_COMPROMISE' THEN
        CASE 
          WHEN event_offset < 24 THEN '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
          WHEN event_offset < 72 THEN '10.0.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
          ELSE '203.0.113.' || UNIFORM(40, 50, RANDOM())  -- Escalate to threat intel IPs
        END
      WHEN 'INSIDER_THREAT' THEN '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
      WHEN 'ACCOUNT_TAKEOVER' THEN '185.220.100.' || UNIFORM(200, 250, RANDOM())
      WHEN 'CREDENTIAL_STUFFING' THEN '198.51.100.' || UNIFORM(100, 200, RANDOM())
      ELSE '203.0.113.45'
    END as anomalous_ip,
    
    CASE asco.scenario_type
      WHEN 'GRADUAL_COMPROMISE' THEN
        CASE 
          WHEN event_offset < 48 THEN OBJECT_CONSTRUCT('country', 'US', 'city', 'San Francisco')
          ELSE OBJECT_CONSTRUCT('country', 'RU', 'city', 'Moscow', 'lat', 55.7558, 'lon', 37.6176)
        END
      WHEN 'INSIDER_THREAT' THEN OBJECT_CONSTRUCT('country', 'US', 'city', 'San Francisco')
      WHEN 'ACCOUNT_TAKEOVER' THEN OBJECT_CONSTRUCT('country', 'CN', 'city', 'Shanghai', 'lat', 31.2304, 'lon', 121.4737)
      WHEN 'CREDENTIAL_STUFFING' THEN OBJECT_CONSTRUCT('country', 'BR', 'city', 'São Paulo', 'lat', -23.5505, 'lon', -46.6333)
      ELSE OBJECT_CONSTRUCT('country', 'RU', 'city', 'Moscow')
    END as anomalous_location,
    
    CASE asco.scenario_type
      WHEN 'GRADUAL_COMPROMISE' THEN
        CASE 
          WHEN event_offset < 24 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          ELSE 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        END
      WHEN 'INSIDER_THREAT' THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      WHEN 'ACCOUNT_TAKEOVER' THEN 'Mozilla/5.0 (X11; Linux x86_64; Tor) AppleWebKit/537.36'
      WHEN 'CREDENTIAL_STUFFING' THEN 'python-requests/2.25.1'
      ELSE 'Mozilla/5.0 (Linux; Android) AppleWebKit/537.36'
    END as anomalous_user_agent,
    
    -- Success rate based on scenario realism
    CASE asco.scenario_type
      WHEN 'GRADUAL_COMPROMISE' THEN TRUE  -- APT attacks are often successful
      WHEN 'INSIDER_THREAT' THEN TRUE      -- Insiders have legitimate access
      WHEN 'ACCOUNT_TAKEOVER' THEN UNIFORM(0.0, 1.0, RANDOM()) < 0.7  -- 70% success rate
      WHEN 'CREDENTIAL_STUFFING' THEN UNIFORM(0.0, 1.0, RANDOM()) < 0.1  -- 10% success rate
      ELSE UNIFORM(0.0, 1.0, RANDOM()) < 0.5
    END as login_success
    
  FROM anomaly_scenarios asco
  CROSS JOIN (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as event_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 100))
  ) event_gen
  WHERE event_offset <= asco.duration_hours
    AND DATEADD(hour, event_offset, asco.start_time) <= CURRENT_TIMESTAMP()
    AND UNIFORM(0.0, 1.0, RANDOM()) < 0.3  -- 30% chance of activity each hour
)
SELECT 
  'AUTH_ANOMALY_' || scenario_type || '_' || ROW_NUMBER() OVER (ORDER BY target_username, event_time) as log_id,
  event_time as timestamp,
  target_employee_id as user_id,
  target_username as username,
  target_username || '@company.com' as email,
  CASE WHEN login_success THEN 'login' ELSE 'failed_login' END as event_type,
  anomalous_ip as source_ip,
  anomalous_user_agent as user_agent,
  anomalous_location as location,
  login_success as success,
  CASE WHEN NOT login_success THEN 'Invalid credentials' ELSE NULL END as failure_reason,
  'SESS_ANOMALY_' || UNIFORM(100000, 999999, RANDOM()) as session_id,
  CASE scenario_type
    WHEN 'CREDENTIAL_STUFFING' THEN OBJECT_CONSTRUCT('device_type', 'bot', 'os', 'unknown', 'browser', 'automated')
    ELSE OBJECT_CONSTRUCT('device_type', 'laptop', 'os', 'Linux', 'browser', 'Chrome')
  END as device_info,
  CASE scenario_type
    WHEN 'GRADUAL_COMPROMISE' THEN ARRAY_CONSTRUCT('unusual_location', 'threat_intel_match', 'user_agent_change')
    WHEN 'INSIDER_THREAT' THEN ARRAY_CONSTRUCT('off_hours_access', 'unusual_data_volume')
    WHEN 'ACCOUNT_TAKEOVER' THEN ARRAY_CONSTRUCT('foreign_ip', 'immediate_location_change', 'threat_intel_match')
    WHEN 'CREDENTIAL_STUFFING' THEN ARRAY_CONSTRUCT('automated_behavior', 'high_failure_rate', 'bot_user_agent')
    ELSE ARRAY_CONSTRUCT('suspicious_activity')
  END as risk_factors,
  FALSE as mfa_used
FROM anomaly_events
ORDER BY timestamp;

-- =====================================================
-- 4. NETWORK SECURITY LOGS (Threat Hunting Data)
-- =====================================================

-- Generate normal network traffic
INSERT INTO NETWORK_SECURITY_LOGS
SELECT 
    'NET_' || ROW_NUMBER() OVER (ORDER BY net_gen.row_num) as LOG_ID,
    DATEADD(minute, -net_gen.row_num * 5, CURRENT_TIMESTAMP()) as TIMESTAMP,
    '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) as SOURCE_IP,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN '8.8.8.8'
        WHEN 2 THEN '1.1.1.1'
        WHEN 3 THEN '208.67.222.222'
        ELSE '74.125.224.72'
    END as DEST_IP,
    UNIFORM(1024, 65535, RANDOM()) as SOURCE_PORT,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 443
        WHEN 2 THEN 80
        WHEN 3 THEN 53
        ELSE 25
    END as DEST_PORT,
    'TCP' as PROTOCOL,
    UNIFORM(100, 10000, RANDOM()) as BYTES_TRANSFERRED,
    'allow' as ACTION,
    'ALLOW_OUTBOUND_HTTPS' as RULE_NAME,
    'legitimate' as THREAT_CATEGORY,
    'low' as SEVERITY
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as row_num
    FROM EMPLOYEE_DATA e1
    CROSS JOIN EMPLOYEE_DATA e2
    CROSS JOIN EMPLOYEE_DATA e3
    LIMIT 10000
) net_gen;

-- Suspicious network activities
INSERT INTO NETWORK_SECURITY_LOGS VALUES
('NET_THREAT_001', DATEADD(hour, -1, CURRENT_TIMESTAMP()), '192.168.1.100', '203.0.113.45', 52341, 443, 'TCP', 524288, 'block', 'BLOCK_THREAT_INTEL', 'apt_communication', 'critical'),
('NET_THREAT_002', DATEADD(hour, -2, CURRENT_TIMESTAMP()), '192.168.1.150', '185.220.100.240', 45123, 8080, 'TCP', 1048576, 'block', 'BLOCK_BOTNET_C2', 'botnet_communication', 'high'),
('NET_THREAT_003', DATEADD(minute, -30, CURRENT_TIMESTAMP()), '192.168.1.200', '198.51.100.150', 33445, 22, 'TCP', 2048, 'allow', 'ALLOW_SSH_ADMIN', 'scanning_activity', 'medium'),
('NET_THREAT_004', DATEADD(hour, -3, CURRENT_TIMESTAMP()), '10.0.0.45', '203.0.113.45', 54321, 443, 'TCP', 10485760, 'allow', 'ALLOW_HTTPS', 'data_exfiltration', 'high');

-- =====================================================
-- 5. VULNERABILITY SCAN RESULTS (For Prioritization)
-- =====================================================

INSERT INTO VULNERABILITY_SCANS VALUES
('VULN_001', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'SRV001', 'web-server-01', 'CVE-2021-44228', 10.0, 'critical', 'Apache Log4j Remote Code Execution', 9.8, 10.0, 'open', DATEADD(day, -30, CURRENT_TIMESTAMP()), DATEADD(day, -1, CURRENT_TIMESTAMP())),
('VULN_002', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'SRV002', 'database-server-01', 'CVE-2021-34527', 8.8, 'high', 'Windows Print Spooler Privilege Escalation', 8.1, 8.8, 'open', DATEADD(day, -15, CURRENT_TIMESTAMP()), DATEADD(day, -1, CURRENT_TIMESTAMP())),
('VULN_003', DATEADD(day, -2, CURRENT_TIMESTAMP()), 'SRV003', 'file-server-01', 'CVE-2020-1472', 9.3, 'critical', 'Netlogon Privilege Escalation', 9.1, 9.3, 'patched', DATEADD(day, -60, CURRENT_TIMESTAMP()), DATEADD(day, -2, CURRENT_TIMESTAMP())),
('VULN_004', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'WKS001', 'employee-laptop-01', 'CVE-2021-40444', 7.8, 'high', 'Microsoft Office Remote Code Execution', 7.5, 7.8, 'open', DATEADD(day, -45, CURRENT_TIMESTAMP()), DATEADD(day, -1, CURRENT_TIMESTAMP())),
('VULN_005', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'SRV004', 'api-server-01', 'CVE-2022-22965', 9.8, 'critical', 'Spring Framework Remote Code Execution', 9.6, 9.8, 'open', DATEADD(day, -7, CURRENT_TIMESTAMP()), DATEADD(day, -1, CURRENT_TIMESTAMP())),
('VULN_006', DATEADD(day, -3, CURRENT_TIMESTAMP()), 'SRV005', 'backup-server-01', 'CVE-2021-26855', 7.2, 'high', 'Microsoft Exchange Server SSRF', 6.8, 7.2, 'accepted_risk', DATEADD(day, -90, CURRENT_TIMESTAMP()), DATEADD(day, -3, CURRENT_TIMESTAMP()));

-- =====================================================
-- 6. SECURITY INCIDENTS (For Threat Prioritization)
-- =====================================================

INSERT INTO SECURITY_INCIDENTS 
SELECT 'INC_001', DATEADD(hour, -4, CURRENT_TIMESTAMP()), 'Suspicious Login from Threat Actor IP', 'User john.smith logged in from known APT29 infrastructure IP', 'critical', 'investigating', 'sarah.chen', 
 ARRAY_CONSTRUCT('web-server-01', 'employee-laptop-john'), ARRAY_CONSTRUCT('203.0.113.45', 'unusual_login_pattern'), 9.5, NULL, NULL
UNION ALL
SELECT 'INC_002', DATEADD(hour, -8, CURRENT_TIMESTAMP()), 'Terminated Employee Access Attempt', 'Former employee james.wilson attempted system access after termination', 'high', 'open', 'jennifer.davis',
 ARRAY_CONSTRUCT('hr-system', 'file-server-01'), ARRAY_CONSTRUCT('terminated_employee_access', 'off_hours_activity'), 8.0, NULL, NULL
UNION ALL
SELECT 'INC_003', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'Potential Data Exfiltration', 'Large data transfer detected from internal server to external IP', 'high', 'resolved', 'sarah.chen',
 ARRAY_CONSTRUCT('database-server-01'), ARRAY_CONSTRUCT('large_data_transfer', 'external_communication'), 7.5, 6.0, 24
UNION ALL
SELECT 'INC_004', DATEADD(day, -2, CURRENT_TIMESTAMP()), 'Vulnerability Exploitation Attempt', 'Attempted exploitation of Log4j vulnerability on web server', 'medium', 'closed', 'david.kim',
 ARRAY_CONSTRUCT('web-server-01'), ARRAY_CONSTRUCT('CVE-2021-44228', 'exploitation_attempt'), 6.0, 2.0, 4
UNION ALL
SELECT 'INC_005', DATEADD(hour, -12, CURRENT_TIMESTAMP()), 'Ransomware Indicators Detected', 'Multiple file encryption activities detected on file server', 'critical', 'investigating', 'jennifer.davis',
 ARRAY_CONSTRUCT('file-server-01', 'backup-server-01'), ARRAY_CONSTRUCT('file_encryption', 'ransom_note', 'lateral_movement'), 9.8, NULL, NULL;

-- =====================================================
-- 7. FINANCIAL TRANSACTIONS (For Fraud Detection)
-- =====================================================

-- Normal transactions
INSERT INTO FINANCIAL_TRANSACTIONS
SELECT 
    'TXN_' || ROW_NUMBER() OVER (ORDER BY txn_gen.row_num) as TRANSACTION_ID,
    DATEADD(hour, -txn_gen.row_num, CURRENT_TIMESTAMP()) as TIMESTAMP,
    'USER_' || UNIFORM(1000, 9999, RANDOM()) as USER_ID,
    'ACC_' || UNIFORM(100000, 999999, RANDOM()) as ACCOUNT_ID,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'purchase'
        WHEN 2 THEN 'transfer'
        WHEN 3 THEN 'withdrawal'
        ELSE 'deposit'
    END as TRANSACTION_TYPE,
    UNIFORM(10, 1000, RANDOM()) as AMOUNT,
    'USD' as CURRENCY,
    'MERCHANT_' || UNIFORM(1, 100, RANDOM()) as MERCHANT,
    OBJECT_CONSTRUCT('country', 'US', 'city', 'San Francisco') as LOCATION,
    'FP_' || UNIFORM(100000, 999999, RANDOM()) as DEVICE_FINGERPRINT,
    '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) as IP_ADDRESS,
    FALSE as IS_SUSPICIOUS,
    UNIFORM(0.1, 0.3, RANDOM()) as FRAUD_SCORE
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as row_num
    FROM EMPLOYEE_DATA e1
    CROSS JOIN EMPLOYEE_DATA e2
    CROSS JOIN EMPLOYEE_DATA e3
    LIMIT 5000
) txn_gen;

-- Suspicious transactions
INSERT INTO FINANCIAL_TRANSACTIONS 
SELECT 'TXN_FRAUD_001', DATEADD(hour, -2, CURRENT_TIMESTAMP()), 'USER_1234', 'ACC_567890', 'transfer', 9999.99, 'USD', 'CRYPTO_EXCHANGE', 
 OBJECT_CONSTRUCT('country', 'RU', 'city', 'Moscow'), 'FP_UNKNOWN', '203.0.113.45', TRUE, 0.95
UNION ALL
SELECT 'TXN_FRAUD_002', DATEADD(hour, -1, CURRENT_TIMESTAMP()), 'USER_5678', 'ACC_123456', 'withdrawal', 5000.00, 'USD', 'ATM_FOREIGN',
 OBJECT_CONSTRUCT('country', 'CN', 'city', 'Shanghai'), 'FP_SUSPICIOUS', '185.220.100.240', TRUE, 0.88
UNION ALL
SELECT 'TXN_FRAUD_003', DATEADD(minute, -30, CURRENT_TIMESTAMP()), 'USER_9999', 'ACC_999999', 'purchase', 15000.00, 'USD', 'LUXURY_GOODS',
 OBJECT_CONSTRUCT('country', 'US', 'city', 'Miami'), 'FP_NEW_DEVICE', '198.51.100.150', TRUE, 0.92;

-- =====================================================
-- 8. DATA ACCESS LOGS (For Insider Threat Detection)
-- =====================================================

-- Normal data access patterns
INSERT INTO DATA_ACCESS_LOGS
SELECT 
    'DA_' || ROW_NUMBER() OVER (ORDER BY emp.EMPLOYEE_ID, seq.seq_num) as ACCESS_ID,
    DATEADD(hour, -seq.seq_num, CURRENT_TIMESTAMP()) as TIMESTAMP,
    emp.EMPLOYEE_ID as USER_ID,
    emp.USERNAME,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'database'
        WHEN 2 THEN 'file_share'
        ELSE 'application'
    END as RESOURCE_TYPE,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'customer_db'
        WHEN 2 THEN 'financial_reports'
        WHEN 3 THEN 'hr_system'
        WHEN 4 THEN 'source_code'
        ELSE 'documentation'
    END as RESOURCE_NAME,
    'read' as ACTION,
    CASE emp.SECURITY_CLEARANCE
        WHEN 'Standard' THEN 'internal'
        WHEN 'Confidential' THEN 'confidential'
        WHEN 'Secret' THEN 'confidential'
        ELSE 'restricted'
    END as DATA_CLASSIFICATION,
    UNIFORM(1000, 100000, RANDOM()) as BYTES_ACCESSED,
    '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) as SOURCE_IP,
    TRUE as SUCCESS
FROM EMPLOYEE_DATA emp
CROSS JOIN (
    SELECT 1 as seq_num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
    SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
    SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL
    SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL
    SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL
    SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL
    SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL
    SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL
    SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50 UNION ALL
    SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL
    SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL SELECT 60 UNION ALL
    SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65 UNION ALL
    SELECT 66 UNION ALL SELECT 67 UNION ALL SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70 UNION ALL
    SELECT 71 UNION ALL SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75 UNION ALL
    SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL SELECT 80 UNION ALL
    SELECT 81 UNION ALL SELECT 82 UNION ALL SELECT 83 UNION ALL SELECT 84 UNION ALL SELECT 85 UNION ALL
    SELECT 86 UNION ALL SELECT 87 UNION ALL SELECT 88 UNION ALL SELECT 89 UNION ALL SELECT 90 UNION ALL
    SELECT 91 UNION ALL SELECT 92 UNION ALL SELECT 93 UNION ALL SELECT 94 UNION ALL SELECT 95 UNION ALL
    SELECT 96 UNION ALL SELECT 97 UNION ALL SELECT 98 UNION ALL SELECT 99 UNION ALL SELECT 100
) seq
WHERE emp.STATUS = 'active';

-- Suspicious data access
INSERT INTO DATA_ACCESS_LOGS VALUES
('DA_INSIDER_001', DATEADD(hour, -2, CURRENT_TIMESTAMP()), 'EMP009', 'james.wilson', 'database', 'customer_db', 'download', 'restricted', 104857600, '10.0.0.45', TRUE),
('DA_INSIDER_002', DATEADD(hour, -1, CURRENT_TIMESTAMP()), 'EMP007', 'alex.brown', 'file_share', 'financial_reports', 'download', 'confidential', 52428800, '192.168.1.75', TRUE),
('DA_INSIDER_003', DATEADD(minute, -30, CURRENT_TIMESTAMP()), 'EMP003', 'mike.rodriguez', 'database', 'hr_system', 'read', 'confidential', 20971520, '203.0.113.45', TRUE);

COMMIT;
