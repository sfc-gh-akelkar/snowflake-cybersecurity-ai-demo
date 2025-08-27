-- ===============================================
-- Cybersecurity Demo - Sample Data Generation
-- ===============================================
-- This script generates realistic sample data for the cybersecurity demo
-- Prerequisites: Run 01_cybersecurity_schema.sql first

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_ANALYTICS;
USE WAREHOUSE CYBERSECURITY_WH;

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

-- Generate 90 days of authentication data (realistic patterns)
INSERT INTO USER_AUTHENTICATION_LOGS 
(USERNAME, TIMESTAMP, SOURCE_IP, LOCATION, SUCCESS, FAILURE_REASON, USER_AGENT, SESSION_ID, TWO_FACTOR_USED)
SELECT 
    -- Select random users from our employee data
    (SELECT USERNAME FROM EMPLOYEE_DATA ORDER BY RANDOM() LIMIT 1) as username,
    
    -- Generate timestamps over last 90 days with business hour bias
    DATEADD(minute, 
        CASE 
            -- 70% during business hours (8 AM - 6 PM on weekdays)
            WHEN UNIFORM(1,10,RANDOM()) <= 7 THEN 
                UNIFORM(480, 1080, RANDOM()) -- 8 AM to 6 PM in minutes
            -- 20% during extended hours (6 AM - 10 PM)
            WHEN UNIFORM(1,10,RANDOM()) <= 9 THEN 
                UNIFORM(360, 1320, RANDOM()) -- 6 AM to 10 PM
            -- 10% during off hours (night/weekend)
            ELSE 
                UNIFORM(0, 1440, RANDOM()) -- Any time
        END,
        DATEADD(day, -UNIFORM(0, 90, RANDOM()), CURRENT_TIMESTAMP())
    ) as timestamp,
    
    -- Generate realistic IP addresses (mix of corporate and remote)
    CASE (seq4() % 10)
        WHEN 0 THEN '192.168.1.' || UNIFORM(10, 254, RANDOM())
        WHEN 1 THEN '10.0.0.' || UNIFORM(10, 254, RANDOM())
        WHEN 2 THEN '172.16.1.' || UNIFORM(10, 254, RANDOM())
        -- External IPs for remote work
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
    
    -- 85% success rate, 15% failures
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 85 THEN TRUE ELSE FALSE END as success,
    
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

FROM TABLE(GENERATOR(ROWCOUNT => 100000));

-- ===============================================
-- Security Incidents Data
-- ===============================================

-- Generate security incidents
INSERT INTO SECURITY_INCIDENTS (INCIDENT_TYPE, SEVERITY, STATUS, ASSIGNED_TO, DESCRIPTION, AFFECTED_SYSTEMS)
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
    
    'Automated detection triggered for suspicious activity pattern' as description,
    
    ARRAY_CONSTRUCT('server-' || UNIFORM(1,20,RANDOM()), 'endpoint-' || UNIFORM(1,100,RANDOM())) as affected_systems

FROM TABLE(GENERATOR(ROWCOUNT => 200));

-- ===============================================
-- Threat Intelligence Feed
-- ===============================================

-- Generate threat intelligence data
INSERT INTO THREAT_INTEL_FEED (INDICATOR_TYPE, INDICATOR_VALUE, THREAT_TYPE, SEVERITY, CONFIDENCE_SCORE, SOURCE_TYPE)
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
    
    CASE (seq4() % 4)
        WHEN 0 THEN 'Commercial'
        WHEN 1 THEN 'Open Source'
        WHEN 2 THEN 'Government'
        ELSE 'Internal'
    END as source_type

FROM TABLE(GENERATOR(ROWCOUNT => 1000));

-- ===============================================
-- Data Verification
-- ===============================================

-- Verify data counts
SELECT 'Data Generation Completed!' as STATUS;

SELECT 
    'USER_AUTHENTICATION_LOGS' as TABLE_NAME,
    COUNT(*) as RECORD_COUNT
FROM USER_AUTHENTICATION_LOGS

UNION ALL

SELECT 
    'EMPLOYEE_DATA' as TABLE_NAME,
    COUNT(*) as RECORD_COUNT
FROM EMPLOYEE_DATA

UNION ALL

SELECT 
    'SECURITY_INCIDENTS' as TABLE_NAME,
    COUNT(*) as RECORD_COUNT
FROM SECURITY_INCIDENTS

UNION ALL

SELECT 
    'THREAT_INTEL_FEED' as TABLE_NAME,
    COUNT(*) as RECORD_COUNT
FROM THREAT_INTEL_FEED

ORDER BY TABLE_NAME;

-- Show department distribution
SELECT 
    'Department Distribution:' as INFO,
    DEPARTMENT,
    COUNT(*) as EMPLOYEE_COUNT
FROM EMPLOYEE_DATA 
GROUP BY DEPARTMENT 
ORDER BY EMPLOYEE_COUNT DESC;

SELECT 'Next step: Run the ML training notebook!' as NEXT_ACTION;
