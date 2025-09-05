-- ===============================================
-- Cybersecurity Demo - Sample Data Generation
-- ===============================================
-- This script generates realistic sample data optimized for dashboard visualization
-- Prerequisites: Run 01_cybersecurity_schema.sql first

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_ANALYTICS;
USE WAREHOUSE CYBERSECURITY_WH;

-- Clear existing data for fresh demo (optional - uncomment if needed)
-- TRUNCATE TABLE IF EXISTS USER_AUTHENTICATION_LOGS;
-- TRUNCATE TABLE IF EXISTS EMPLOYEE_DATA;
-- TRUNCATE TABLE IF EXISTS SECURITY_INCIDENTS;
-- TRUNCATE TABLE IF EXISTS THREAT_INTEL_FEED;

-- ===============================================
-- Employee Data Generation
-- ===============================================

-- Generate 500 diverse employees across departments
INSERT INTO EMPLOYEE_DATA (USERNAME, DEPARTMENT, ROLE, MANAGER, HIRE_DATE, SECURITY_CLEARANCE, STATUS)
SELECT 
    'user_' || LPAD(seq4(), 4, '0') as username,
    CASE (seq4() % 7)
        WHEN 0 THEN 'Engineering'
        WHEN 1 THEN 'Sales' 
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'Finance'
        WHEN 4 THEN 'HR'
        WHEN 5 THEN 'IT'
        ELSE 'Security'
    END as department,
    CASE (seq4() % 5)
        WHEN 0 THEN 'Analyst'
        WHEN 1 THEN 'Senior Analyst'
        WHEN 2 THEN 'Manager'
        WHEN 3 THEN 'Director'
        ELSE 'Engineer'
    END as role,
    'manager_' || LPAD((seq4() % 50) + 1, 2, '0') as manager,
    DATEADD(day, -UNIFORM(30, 2000, RANDOM()), CURRENT_DATE()) as hire_date,
    CASE (seq4() % 4)
        WHEN 0 THEN 'Public'
        WHEN 1 THEN 'Internal'
        WHEN 2 THEN 'Confidential'
        ELSE 'Secret'
    END as security_clearance,
    CASE (seq4() % 20)
        WHEN 0 THEN 'inactive'
        ELSE 'active'
    END as status
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- ===============================================
-- Authentication Logs Generation
-- ===============================================

-- Generate authentication data with enhanced time distribution for dashboards
INSERT INTO USER_AUTHENTICATION_LOGS 
(USERNAME, TIMESTAMP, SOURCE_IP, LOCATION, SUCCESS, FAILURE_REASON, USER_AGENT, SESSION_ID, TWO_FACTOR_USED)
SELECT 
    -- Select from actual employees with weighted distribution
    CASE 
        WHEN UNIFORM(1,10,RANDOM()) <= 7 THEN 
            (SELECT USERNAME FROM EMPLOYEE_DATA WHERE STATUS = 'active' ORDER BY RANDOM() LIMIT 1)
        ELSE 
            (SELECT USERNAME FROM EMPLOYEE_DATA ORDER BY RANDOM() LIMIT 1)
    END as username,
    
    -- Enhanced timestamp generation with more recent activity for dashboards
    DATEADD(second, 
        UNIFORM(0, 86400, RANDOM()), -- Random seconds within day
        DATEADD(hour,
            CASE 
                -- 40% in last 7 days (very recent for dashboards)
                WHEN UNIFORM(1,10,RANDOM()) <= 4 THEN 
                    -UNIFORM(0, 168, RANDOM()) -- Last week
                -- 30% in last 30 days (recent)
                WHEN UNIFORM(1,10,RANDOM()) <= 7 THEN 
                    -UNIFORM(168, 720, RANDOM()) -- Last month
                -- 30% in last 90 days (historical)
                ELSE 
                    -UNIFORM(720, 2160, RANDOM()) -- Last 3 months
            END,
            CURRENT_TIMESTAMP()
        )
    ) as timestamp,
    
    -- Enhanced IP generation with suspicious patterns for demos
    CASE (seq4() % 12)
        WHEN 0 THEN '192.168.1.' || UNIFORM(10, 254, RANDOM())
        WHEN 1 THEN '10.0.0.' || UNIFORM(10, 254, RANDOM())
        WHEN 2 THEN '172.16.1.' || UNIFORM(10, 254, RANDOM())
        WHEN 3 THEN '172.16.2.' || UNIFORM(10, 254, RANDOM())
        WHEN 4 THEN '10.1.0.' || UNIFORM(10, 254, RANDOM())
        WHEN 5 THEN '192.168.100.' || UNIFORM(10, 254, RANDOM())
        -- Suspicious/external IPs for demo anomaly detection
        WHEN 6 THEN '203.0.113.' || UNIFORM(1, 254, RANDOM()) -- TEST-NET-3
        WHEN 7 THEN '198.51.100.' || UNIFORM(1, 254, RANDOM()) -- TEST-NET-2
        -- Normal external IPs
        ELSE UNIFORM(1, 223, RANDOM()) || '.' || 
             UNIFORM(0, 255, RANDOM()) || '.' || 
             UNIFORM(0, 255, RANDOM()) || '.' || 
             UNIFORM(1, 254, RANDOM())
    END as source_ip,
    
    -- Generate location data (JSON variant)
    CASE (seq4() % 8)
        WHEN 0 THEN PARSE_JSON('{"country": "US", "state": "CA", "city": "San Francisco"}')
        WHEN 1 THEN PARSE_JSON('{"country": "US", "state": "NY", "city": "New York"}')
        WHEN 2 THEN PARSE_JSON('{"country": "US", "state": "WA", "city": "Seattle"}')
        WHEN 3 THEN PARSE_JSON('{"country": "US", "state": "TX", "city": "Austin"}')
        WHEN 4 THEN PARSE_JSON('{"country": "CA", "state": "ON", "city": "Toronto"}')
        WHEN 5 THEN PARSE_JSON('{"country": "GB", "state": "England", "city": "London"}')
        WHEN 6 THEN PARSE_JSON('{"country": "DE", "state": "Bavaria", "city": "Munich"}')
        ELSE PARSE_JSON('{"country": "SG", "state": "Central", "city": "Singapore"}')
    END as location,
    
    -- Enhanced success/failure patterns for better anomaly detection
    CASE 
        -- Some users have consistent failures (potential compromise)
        WHEN MOD(HASH(username), 50) = 1 AND UNIFORM(1,100,RANDOM()) <= 40 THEN FALSE
        -- Some IPs are consistently suspicious
        WHEN source_ip LIKE '203.0.113.%' AND UNIFORM(1,100,RANDOM()) <= 60 THEN FALSE
        -- Normal pattern: 88% success
        WHEN UNIFORM(1,100,RANDOM()) <= 88 THEN TRUE 
        ELSE FALSE 
    END as success,
    
    -- Failure reasons for unsuccessful logins
    CASE WHEN UNIFORM(1,100,RANDOM()) > 85 THEN
        CASE (UNIFORM(1,5,RANDOM()))
            WHEN 1 THEN 'Invalid password'
            WHEN 2 THEN 'Account locked'
            WHEN 3 THEN 'Invalid username'
            WHEN 4 THEN 'Session timeout'
            ELSE 'Two-factor authentication failed'
        END
    ELSE NULL
    END as failure_reason,
    
    -- Realistic user agents
    CASE (seq4() % 6)
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        WHEN 1 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        WHEN 2 THEN 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        WHEN 3 THEN 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)'
        WHEN 4 THEN 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X)'
        ELSE 'Corporate App v2.1.0'
    END as user_agent,
    
    UUID_STRING() as session_id,
    
    -- 60% use two-factor authentication
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 60 THEN TRUE ELSE FALSE END as two_factor_used

FROM TABLE(GENERATOR(ROWCOUNT => 120000)); -- More data for richer dashboards

-- ===============================================
-- Security Incidents Data
-- ===============================================

-- Generate security incidents with timestamps for dashboard relevance
INSERT INTO SECURITY_INCIDENTS (INCIDENT_TYPE, SEVERITY, STATUS, ASSIGNED_TO, DESCRIPTION, AFFECTED_SYSTEMS, CREATED_AT)
SELECT 
    CASE (seq4() % 8)
        WHEN 0 THEN 'Malware Detection'
        WHEN 1 THEN 'Phishing Attempt'
        WHEN 2 THEN 'Unauthorized Access'
        WHEN 3 THEN 'Data Exfiltration'
        WHEN 4 THEN 'DDoS Attack'
        WHEN 5 THEN 'Insider Threat'
        WHEN 6 THEN 'Policy Violation'
        ELSE 'Anomalous Behavior'
    END as incident_type,
    
    CASE (seq4() % 4)
        WHEN 0 THEN 'CRITICAL'
        WHEN 1 THEN 'HIGH'
        WHEN 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END as severity,
    
    CASE (seq4() % 5)
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'In Progress'
        WHEN 2 THEN 'Resolved'
        WHEN 3 THEN 'Closed'
        ELSE 'Escalated'
    END as status,
    
    (SELECT USERNAME FROM EMPLOYEE_DATA WHERE DEPARTMENT = 'Security' ORDER BY RANDOM() LIMIT 1) as assigned_to,
    
    CASE (seq4() % 6)
        WHEN 0 THEN 'Automated detection triggered for suspicious activity pattern in user authentication logs'
        WHEN 1 THEN 'Multiple failed login attempts detected from single IP address'
        WHEN 2 THEN 'Unusual data access pattern identified during off-hours'
        WHEN 3 THEN 'Suspicious file download activity detected'
        WHEN 4 THEN 'Potential credential stuffing attack identified'
        ELSE 'Anomalous network traffic pattern detected'
    END as description,
    
    ARRAY_CONSTRUCT(
        'server-' || UNIFORM(1,50,RANDOM()), 
        'endpoint-' || UNIFORM(1,200,RANDOM()),
        CASE WHEN UNIFORM(1,3,RANDOM()) = 1 THEN 'database-' || UNIFORM(1,10,RANDOM()) ELSE NULL END
    ) as affected_systems,
    
    -- Recent incident timestamps for dashboard relevance
    DATEADD(hour, 
        -UNIFORM(0, 720, RANDOM()), -- Last 30 days
        CURRENT_TIMESTAMP()
    ) as created_at

FROM TABLE(GENERATOR(ROWCOUNT => 250)); -- More incidents for analysis

-- ===============================================
-- Threat Intelligence Feed
-- ===============================================

-- Generate enhanced threat intelligence data with timestamps
INSERT INTO THREAT_INTEL_FEED (INDICATOR_TYPE, INDICATOR_VALUE, THREAT_TYPE, SEVERITY, CONFIDENCE_SCORE, SOURCE_TYPE, FIRST_SEEN, LAST_SEEN)
SELECT 
    CASE (seq4() % 4)
        WHEN 0 THEN 'IP'
        WHEN 1 THEN 'Domain'
        WHEN 2 THEN 'Hash'
        ELSE 'URL'
    END as indicator_type,
    
    CASE (seq4() % 4)
        WHEN 0 THEN UNIFORM(1, 223, RANDOM()) || '.' || UNIFORM(0, 255, RANDOM()) || '.' || UNIFORM(0, 255, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM())
        WHEN 1 THEN 'malicious-' || UNIFORM(1000, 9999, RANDOM()) || '.com'
        WHEN 2 THEN 'a' || SUBSTR(UUID_STRING(), 1, 32)
        ELSE 'http://suspicious-site-' || UNIFORM(100, 999, RANDOM()) || '.org/malware'
    END as indicator_value,
    
    CASE (seq4() % 6)
        WHEN 0 THEN 'Malware'
        WHEN 1 THEN 'Phishing'
        WHEN 2 THEN 'Botnet'
        WHEN 3 THEN 'APT'
        WHEN 4 THEN 'Ransomware'
        ELSE 'Trojan'
    END as threat_type,
    
    CASE (seq4() % 3)
        WHEN 0 THEN 'HIGH'
        WHEN 1 THEN 'MEDIUM'
        ELSE 'LOW'
    END as severity,
    
    UNIFORM(50, 100, RANDOM()) / 100.0 as confidence_score,
    
    CASE (seq4() % 5)
        WHEN 0 THEN 'Commercial Feed'
        WHEN 1 THEN 'Open Source'
        WHEN 2 THEN 'Government'
        WHEN 3 THEN 'Internal Analysis'
        ELSE 'Threat Hunting'
    END as source_type,
    
    DATEADD(day, -UNIFORM(1, 180, RANDOM()), CURRENT_TIMESTAMP()) as first_seen,
    
    DATEADD(day, -UNIFORM(0, 7, RANDOM()), CURRENT_TIMESTAMP()) as last_seen

FROM TABLE(GENERATOR(ROWCOUNT => 1200)); -- More threat intel for analysis

-- ===============================================
-- Additional Demo Data for Dashboard Richness
-- ===============================================

-- Create some targeted scenarios for CEO account (high-value user)
INSERT INTO USER_AUTHENTICATION_LOGS 
(USERNAME, TIMESTAMP, SOURCE_IP, LOCATION, SUCCESS, FAILURE_REASON, USER_AGENT, SESSION_ID, TWO_FACTOR_USED)
SELECT 
    'user_0001' as username, -- CEO account
    DATEADD(hour, -seq4(), CURRENT_TIMESTAMP()) as timestamp,
    CASE WHEN seq4() <= 5 THEN '192.168.1.100' ELSE '203.0.113.' || UNIFORM(1,50,RANDOM()) END as source_ip,
    CASE WHEN source_ip LIKE '192.168.%' 
        THEN PARSE_JSON('{"country": "US", "state": "CA", "city": "San Francisco"}')
        ELSE PARSE_JSON('{"country": "CN", "state": "Beijing", "city": "Beijing"}')
    END as location,
    CASE WHEN source_ip NOT LIKE '192.168.%' THEN FALSE ELSE TRUE END as success,
    CASE WHEN success = FALSE THEN 'Geo-location policy violation' ELSE NULL END as failure_reason,
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' as user_agent,
    UUID_STRING() as session_id,
    TRUE as two_factor_used
FROM TABLE(GENERATOR(ROWCOUNT => 20));

-- ===============================================
-- Enhanced Data Verification and Analytics
-- ===============================================

SELECT 'Enhanced Data Generation Completed Successfully! 🛡️' as STATUS;

-- Comprehensive summary statistics
SELECT 
    'TABLE SUMMARY' as SECTION,
    '' as TABLE_NAME,
    '' as RECORD_COUNT,
    '' as DATE_RANGE
    
UNION ALL

SELECT 
    '',
    'USER_AUTHENTICATION_LOGS',
    COUNT(*)::VARCHAR,
    MIN(DATE(TIMESTAMP))::VARCHAR || ' to ' || MAX(DATE(TIMESTAMP))::VARCHAR
FROM USER_AUTHENTICATION_LOGS

UNION ALL

SELECT 
    '',
    'EMPLOYEE_DATA',
    COUNT(*)::VARCHAR,
    MIN(DATE(HIRE_DATE))::VARCHAR || ' to ' || MAX(DATE(HIRE_DATE))::VARCHAR
FROM EMPLOYEE_DATA

UNION ALL

SELECT 
    '',
    'SECURITY_INCIDENTS',
    COUNT(*)::VARCHAR,
    MIN(DATE(CREATED_AT))::VARCHAR || ' to ' || MAX(DATE(CREATED_AT))::VARCHAR
FROM SECURITY_INCIDENTS

UNION ALL

SELECT 
    '',
    'THREAT_INTEL_FEED',
    COUNT(*)::VARCHAR,
    MIN(DATE(FIRST_SEEN))::VARCHAR || ' to ' || MAX(DATE(LAST_SEEN))::VARCHAR
FROM THREAT_INTEL_FEED

ORDER BY TABLE_NAME;

-- Authentication patterns summary for dashboard validation
SELECT 
    'AUTH PATTERNS' as ANALYSIS,
    '' as METRIC,
    '' as VALUE

UNION ALL

SELECT 
    '',
    'Overall Success Rate',
    ROUND(AVG(CASE WHEN SUCCESS THEN 1.0 ELSE 0.0 END) * 100, 2)::VARCHAR || '%'
FROM USER_AUTHENTICATION_LOGS

UNION ALL

SELECT 
    '',
    '2FA Usage Rate',
    ROUND(AVG(CASE WHEN TWO_FACTOR_USED THEN 1.0 ELSE 0.0 END) * 100, 2)::VARCHAR || '%'
FROM USER_AUTHENTICATION_LOGS

UNION ALL

SELECT 
    '',
    'Recent Activity (7 days)',
    COUNT(*)::VARCHAR || ' logins'
FROM USER_AUTHENTICATION_LOGS
WHERE TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())

UNION ALL

SELECT 
    '',
    'Suspicious IPs (TEST-NET)',
    COUNT(DISTINCT SOURCE_IP)::VARCHAR || ' IPs'
FROM USER_AUTHENTICATION_LOGS
WHERE SOURCE_IP LIKE '203.0.113.%' OR SOURCE_IP LIKE '198.51.100.%'

ORDER BY METRIC;

-- Department distribution for organizational analysis
SELECT 
    'DEPARTMENTS' as CATEGORY,
    DEPARTMENT,
    COUNT(*) as EMPLOYEE_COUNT,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM EMPLOYEE_DATA), 1)::VARCHAR || '%' as PERCENTAGE
FROM EMPLOYEE_DATA 
GROUP BY DEPARTMENT 
ORDER BY EMPLOYEE_COUNT DESC;

-- Incident summary for security dashboard
SELECT 
    'SECURITY INCIDENTS' as ANALYSIS_TYPE,
    SEVERITY,
    COUNT(*) as INCIDENT_COUNT,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM SECURITY_INCIDENTS), 1)::VARCHAR || '%' as PERCENTAGE
FROM SECURITY_INCIDENTS 
GROUP BY SEVERITY 
ORDER BY 
    CASE SEVERITY 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END;

SELECT 'Next steps: Run 03_native_ml_and_cortex.sql and then the ML notebook!' as NEXT_ACTION;
