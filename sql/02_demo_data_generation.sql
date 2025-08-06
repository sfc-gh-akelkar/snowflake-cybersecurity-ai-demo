-- =====================================================
-- SNOWFLAKE CYBERSECURITY AI/ML DEMO DATA
-- Realistic sample data for showcasing AI/ML capabilities
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- EMPLOYEE DATA - Foundation for all user activities
-- =====================================================
INSERT INTO EMPLOYEE_DATA
-- Active employees
SELECT 'EMP001', 'john.smith', 'john.smith@company.com', 'John Smith', 'Engineering', 'Senior Developer', 'MGR001', '2020-03-15', NULL, 'active', 'standard', 'elevated', '2023-03-15', 2.1
UNION ALL
SELECT 'EMP002', 'sarah.chen', 'sarah.chen@company.com', 'Sarah Chen', 'Security', 'Security Analyst', 'MGR002', '2021-07-01', NULL, 'active', 'confidential', 'admin', '2023-07-01', 1.5
UNION ALL
SELECT 'EMP003', 'mike.rodriguez', 'mike.rodriguez@company.com', 'Mike Rodriguez', 'DevOps', 'DevOps Engineer', 'MGR001', '2019-11-20', NULL, 'active', 'standard', 'admin', '2023-11-20', 3.2
UNION ALL
SELECT 'EMP004', 'lisa.wang', 'lisa.wang@company.com', 'Lisa Wang', 'Data Science', 'Data Scientist', 'MGR003', '2022-01-10', NULL, 'active', 'standard', 'elevated', '2023-01-10', 1.8
UNION ALL
SELECT 'EMP005', 'david.johnson', 'david.johnson@company.com', 'David Johnson', 'Engineering', 'Principal Engineer', 'MGR001', '2018-05-30', NULL, 'active', 'standard', 'admin', '2023-05-30', 4.5
UNION ALL
-- Recently terminated employees (GRC use case)
SELECT 'EMP006', 'alex.turner', 'alex.turner@company.com', 'Alex Turner', 'Engineering', 'Software Developer', 'MGR001', '2021-03-01', '2024-01-15', 'terminated', 'standard', 'basic', '2023-03-01', 6.8
UNION ALL
SELECT 'EMP007', 'emily.davis', 'emily.davis@company.com', 'Emily Davis', 'Marketing', 'Marketing Manager', 'MGR004', '2020-08-15', '2024-01-20', 'terminated', 'standard', 'basic', '2023-08-15', 7.2
UNION ALL
-- Suspended employee (anomaly detection use case)
SELECT 'EMP008', 'carlos.lopez', 'carlos.lopez@company.com', 'Carlos Lopez', 'Finance', 'Financial Analyst', 'MGR005', '2019-12-01', NULL, 'suspended', 'confidential', 'elevated', '2023-12-01', 9.1;

-- =====================================================
-- ASSET INVENTORY - Critical for vulnerability prioritization
-- =====================================================
-- Step 1: Insert basic asset data without arrays
INSERT INTO ASSET_INVENTORY (
    ASSET_ID, HOSTNAME, IP_ADDRESS, ASSET_TYPE, OPERATING_SYSTEM, OS_VERSION, 
    BUSINESS_UNIT, OWNER, BUSINESS_CRITICALITY, DATA_CLASSIFICATION, 
    LOCATION, ENVIRONMENT, LAST_SCAN_DATE, PATCH_LEVEL, NETWORK_SEGMENT
)
-- Critical production servers
SELECT 'ASSET001', 'prod-db-01', '10.1.1.10', 'server', 'Linux', 'Ubuntu 20.04.6', 'Engineering', 'john.smith', 'critical', 'confidential', 'AWS-US-East-1', 'production', '2024-01-20 08:00:00', 'current', 'DMZ'
UNION ALL
SELECT 'ASSET002', 'prod-web-01', '10.1.1.20', 'server', 'Linux', 'CentOS 8.5', 'Engineering', 'mike.rodriguez', 'critical', 'confidential', 'AWS-US-East-1', 'production', '2024-01-19 08:00:00', 'current-1', 'DMZ'
UNION ALL
SELECT 'ASSET003', 'prod-api-01', '10.1.1.30', 'server', 'Linux', 'Ubuntu 22.04.3', 'Engineering', 'david.johnson', 'critical', 'restricted', 'AWS-US-East-1', 'production', '2024-01-21 08:00:00', 'current', 'Internal'
UNION ALL
-- High-value workstations
SELECT 'ASSET004', 'DEV-JOHN-01', '10.2.1.15', 'workstation', 'Windows', 'Windows 11 Pro', 'Engineering', 'john.smith', 'high', 'internal', 'Office-NYC', 'development', '2024-01-18 10:00:00', 'current-2', 'Corporate'
UNION ALL
SELECT 'ASSET005', 'SEC-SARAH-01', '10.2.1.25', 'workstation', 'macOS', 'macOS 14.2', 'Security', 'sarah.chen', 'high', 'confidential', 'Office-NYC', 'development', '2024-01-20 10:00:00', 'current', 'Corporate'
UNION ALL
-- Medium criticality systems
SELECT 'ASSET006', 'staging-web-01', '10.3.1.10', 'server', 'Linux', 'Ubuntu 18.04.6', 'Engineering', 'mike.rodriguez', 'medium', 'internal', 'AWS-US-West-2', 'staging', '2024-01-15 08:00:00', 'current-5', 'Internal'
UNION ALL
SELECT 'ASSET007', 'dev-db-01', '10.3.1.20', 'server', 'Linux', 'MySQL 8.0.34', 'Engineering', 'lisa.wang', 'medium', 'internal', 'AWS-US-West-2', 'development', '2024-01-16 08:00:00', 'current-3', 'Internal'
UNION ALL
-- IoT and mobile devices
SELECT 'ASSET008', 'CAMERA-LOBBY-01', '10.4.1.10', 'iot', 'Linux', 'Custom IoT OS', 'Facilities', 'facilities@company.com', 'low', 'internal', 'Office-NYC', 'production', '2024-01-10 08:00:00', 'current-10', 'IoT'
UNION ALL
SELECT 'ASSET009', 'MOBILE-CARLOS-01', '192.168.1.150', 'mobile', 'iOS', 'iOS 17.2.1', 'Finance', 'carlos.lopez', 'medium', 'confidential', 'Remote', 'production', '2024-01-12 08:00:00', 'current-2', 'Mobile';

-- Step 2: Update compliance scope arrays separately
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT('PCI', 'SOX') WHERE ASSET_ID = 'ASSET001';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT('PCI') WHERE ASSET_ID = 'ASSET002';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT('PCI', 'HIPAA') WHERE ASSET_ID = 'ASSET003';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT() WHERE ASSET_ID = 'ASSET004';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT('SOX') WHERE ASSET_ID = 'ASSET005';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT() WHERE ASSET_ID = 'ASSET006';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT() WHERE ASSET_ID = 'ASSET007';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT() WHERE ASSET_ID = 'ASSET008';
UPDATE ASSET_INVENTORY SET COMPLIANCE_SCOPE = ARRAY_CONSTRUCT('SOX') WHERE ASSET_ID = 'ASSET009';

-- =====================================================
-- THREAT INTELLIGENCE - IOCs for threat matching
-- =====================================================
-- Step 1: Insert basic threat intelligence data without arrays
INSERT INTO THREAT_INTELLIGENCE (
    IOC_ID, IOC_VALUE, IOC_TYPE, THREAT_TYPE, CONFIDENCE_LEVEL, SEVERITY, 
    FIRST_SEEN, LAST_SEEN, SOURCE, DESCRIPTION, EXPIRY_DATE
)
-- Critical threats
SELECT 'IOC001', '203.0.113.50', 'ip', 'c2_server', 'high', 'critical', '2024-01-01 00:00:00', '2024-01-25 15:30:00', 'external_feed', 'Known C2 server for banking trojan campaigns targeting financial institutions', '2024-12-31 23:59:59'
UNION ALL
SELECT 'IOC002', 'malicious-site.badactor.com', 'domain', 'phishing', 'high', 'high', '2024-01-10 00:00:00', '2024-01-24 12:15:00', 'partner_intel', 'Phishing domain mimicking company login portal', '2024-12-31 23:59:59'
UNION ALL
SELECT 'IOC003', '45.33.32.156', 'ip', 'scanning', 'medium', 'medium', '2024-01-15 00:00:00', '2024-01-23 08:45:00', 'internal', 'Persistent scanner targeting SSH services', '2024-06-30 23:59:59'
UNION ALL
SELECT 'IOC004', 'crypto-miner.pool.com', 'domain', 'cryptomining', 'medium', 'medium', '2024-01-18 00:00:00', '2024-01-25 14:20:00', 'external_feed', 'Cryptocurrency mining pool used by malware', '2024-12-31 23:59:59'
UNION ALL
SELECT 'IOC005', 'a1b2c3d4e5f6789012345678901234567890abcd', 'hash', 'malware', 'high', 'critical', '2024-01-12 00:00:00', '2024-01-25 16:00:00', 'external_feed', 'Emotet banking trojan variant', '2024-12-31 23:59:59';

-- Step 2: Update array columns separately
UPDATE THREAT_INTELLIGENCE SET TAGS = ARRAY_CONSTRUCT('apt', 'c2', 'banking_trojan'), MITRE_TECHNIQUES = ARRAY_CONSTRUCT('T1071.001', 'T1041'), AFFECTED_PRODUCTS = ARRAY_CONSTRUCT('banking_software', 'web_browsers') WHERE IOC_ID = 'IOC001';
UPDATE THREAT_INTELLIGENCE SET TAGS = ARRAY_CONSTRUCT('phishing', 'credential_theft'), MITRE_TECHNIQUES = ARRAY_CONSTRUCT('T1566.002'), AFFECTED_PRODUCTS = ARRAY_CONSTRUCT('corporate_portals') WHERE IOC_ID = 'IOC002';
UPDATE THREAT_INTELLIGENCE SET TAGS = ARRAY_CONSTRUCT('reconnaissance', 'scanning'), MITRE_TECHNIQUES = ARRAY_CONSTRUCT('T1046'), AFFECTED_PRODUCTS = ARRAY_CONSTRUCT('ssh_services') WHERE IOC_ID = 'IOC003';
UPDATE THREAT_INTELLIGENCE SET TAGS = ARRAY_CONSTRUCT('cryptomining', 'malware'), MITRE_TECHNIQUES = ARRAY_CONSTRUCT('T1496'), AFFECTED_PRODUCTS = ARRAY_CONSTRUCT('all_systems') WHERE IOC_ID = 'IOC004';
UPDATE THREAT_INTELLIGENCE SET TAGS = ARRAY_CONSTRUCT('emotet', 'banking_trojan'), MITRE_TECHNIQUES = ARRAY_CONSTRUCT('T1055', 'T1082'), AFFECTED_PRODUCTS = ARRAY_CONSTRUCT('windows_systems') WHERE IOC_ID = 'IOC005';

-- =====================================================
-- VULNERABILITY DATA - For AI risk prioritization
-- =====================================================
INSERT INTO VULNERABILITY_DATA
-- Critical vulnerabilities on critical assets
SELECT 'VULN001', 'CVE-2023-4966', 'ASSET001', 'prod-db-01', '10.1.1.10', 'Citrix NetScaler Buffer Overflow', 'critical', 9.4, 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H', '2024-01-20 09:00:00', TRUE, '2024-01-21 10:00:00', 3.9, 5.9, 'Citrix', 'NetScaler', '13.1-49.15', 'open'
UNION ALL
SELECT 'VULN002', 'CVE-2023-44487', 'ASSET002', 'prod-web-01', '10.1.1.20', 'HTTP/2 Rapid Reset Attack', 'high', 7.5, 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H', '2024-01-19 10:30:00', TRUE, '2024-01-20 12:00:00', 3.9, 3.6, 'Apache', 'HTTP Server', '2.4.57', 'open'
UNION ALL
SELECT 'VULN003', 'CVE-2023-46604', 'ASSET003', 'prod-api-01', '10.1.1.30', 'Apache ActiveMQ RCE', 'critical', 10.0, 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H', '2024-01-21 11:00:00', TRUE, '2024-01-22 08:00:00', 3.9, 6.0, 'Apache', 'ActiveMQ', '5.18.2', 'open'
UNION ALL
-- High vulnerabilities on high-value workstations
SELECT 'VULN004', 'CVE-2023-36884', 'ASSET004', 'DEV-JOHN-01', '10.2.1.15', 'Microsoft Office RCE', 'high', 8.3, 'CVSS:3.1/AV:L/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:H', '2024-01-18 12:00:00', TRUE, '2024-01-19 14:00:00', 1.8, 5.9, 'Microsoft', 'Office', '365', 'open'
UNION ALL
SELECT 'VULN005', 'CVE-2023-32409', 'ASSET005', 'SEC-SARAH-01', '10.2.1.25', 'macOS Kernel Privilege Escalation', 'high', 7.8, 'CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H', '2024-01-20 13:00:00', TRUE, '2024-01-21 16:00:00', 1.8, 5.9, 'Apple', 'macOS', '14.1', 'open'
UNION ALL
-- Medium vulnerabilities on staging/dev systems
SELECT 'VULN006', 'CVE-2023-32784', 'ASSET006', 'staging-web-01', '10.3.1.10', 'Ubuntu Kernel Information Disclosure', 'medium', 5.5, 'CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N', '2024-01-15 14:00:00', TRUE, '2024-01-25 10:00:00', 1.8, 2.5, 'Ubuntu', 'Linux Kernel', '5.4.0', 'patched'
UNION ALL
SELECT 'VULN007', 'CVE-2023-25690', 'ASSET007', 'dev-db-01', '10.3.1.20', 'MySQL Privilege Escalation', 'medium', 6.5, 'CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H', '2024-01-16 15:00:00', TRUE, '2024-01-20 09:00:00', 2.8, 3.6, 'Oracle', 'MySQL', '8.0.32', 'open'
UNION ALL
-- Low priority vulnerabilities
SELECT 'VULN008', 'CVE-2023-12345', 'ASSET008', 'CAMERA-LOBBY-01', '10.4.1.10', 'IoT Firmware Weak Authentication', 'low', 4.3, 'CVSS:3.1/AV:A/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N', '2024-01-10 16:00:00', FALSE, NULL, 2.8, 1.4, 'GenericIoT', 'Camera Firmware', '1.2.3', 'accepted_risk';

-- =====================================================
-- USER AUTHENTICATION LOGS - For anomaly detection
-- =====================================================

-- Generate normal login patterns for users (simplified to avoid complex expressions)
INSERT INTO USER_AUTHENTICATION_LOGS 
SELECT 
    'AUTH_' || ROW_NUMBER() OVER (ORDER BY ts.hour_timestamp, u.username) as LOG_ID,
    DATEADD(second, UNIFORM(0, 3599, RANDOM()), ts.hour_timestamp) as TIMESTAMP,
    'USER_' || u.employee_id as USER_ID,
    u.username,
    u.email,
    'login' as EVENT_TYPE,
    CASE u.username
        WHEN 'john.smith' THEN '10.2.1.15'  -- Normal office IP
        WHEN 'sarah.chen' THEN '10.2.1.25'  -- Normal office IP
        WHEN 'mike.rodriguez' THEN '192.168.1.100'  -- Home IP
        WHEN 'lisa.wang' THEN '10.2.1.35'  -- Normal office IP
        WHEN 'david.johnson' THEN '172.16.1.10'  -- VPN IP
        ELSE '10.2.1.' || (50 + UNIFORM(1, 20, RANDOM()))
    END as SOURCE_IP,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' as USER_AGENT,
    NULL as LOCATION,  -- Will be updated separately
    TRUE as SUCCESS,
    NULL as FAILURE_REASON,
    'SESS_' || UNIFORM(100000, 999999, RANDOM()) as SESSION_ID,
    NULL as DEVICE_INFO,  -- Will be updated separately
    NULL as RISK_FACTORS,  -- Will be updated separately
    TRUE as MFA_USED
FROM (
    SELECT DATEADD(hour, -ROW_NUMBER() OVER (ORDER BY NULL), CURRENT_TIMESTAMP()) as hour_timestamp
    FROM TABLE(GENERATOR(ROWCOUNT => 168)) -- 7 days
) ts
CROSS JOIN (
    SELECT employee_id, username, email FROM EMPLOYEE_DATA WHERE employment_status = 'active'
) u
WHERE EXTRACT(HOUR FROM ts.hour_timestamp) BETWEEN 8 AND 17 -- Normal business hours
    AND UNIFORM(1, 100, RANDOM()) <= 80; -- 80% chance of login during business hours

-- Update complex columns for normal authentication logs
UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE USERNAME = 'john.smith' AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE USERNAME = 'sarah.chen' AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE USERNAME = 'mike.rodriguez' AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE USERNAME = 'lisa.wang' AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'WA', 'city', 'Seattle', 'lat', 47.6062, 'lon', -122.3321),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE USERNAME = 'david.johnson' AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

-- Update any remaining users
UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'NY', 'city', 'New York', 'lat', 40.7128, 'lon', -74.0060),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Chrome'),
    RISK_FACTORS = ARRAY_CONSTRUCT()
WHERE LOCATION IS NULL AND LOG_ID LIKE 'AUTH_%' AND LOG_ID NOT LIKE 'AUTH_ANOMALY_%';

-- Add anomalous login patterns for john.smith (weekend GitHub activity correlation)
-- Step 1: Insert basic authentication data without complex objects/arrays
INSERT INTO USER_AUTHENTICATION_LOGS (
    LOG_ID, TIMESTAMP, USER_ID, USERNAME, EMAIL, EVENT_TYPE, SOURCE_IP, USER_AGENT, 
    SUCCESS, FAILURE_REASON, SESSION_ID, MFA_USED
)
-- Unusual weekend activity
SELECT 'AUTH_ANOMALY_001', '2024-01-21 02:30:15', 'USER_EMP001', 'john.smith', 'john.smith@company.com', 'login', '203.0.113.25', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', TRUE, NULL, 'SESS_ANOMALY_001', FALSE
UNION ALL
SELECT 'AUTH_ANOMALY_002', '2024-01-21 03:15:22', 'USER_EMP001', 'john.smith', 'john.smith@company.com', 'login', '203.0.113.25', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', TRUE, NULL, 'SESS_ANOMALY_002', FALSE
UNION ALL
-- Failed login attempts from suspicious IP
SELECT 'AUTH_ANOMALY_003', '2024-01-24 14:22:10', 'USER_EMP002', 'sarah.chen', 'sarah.chen@company.com', 'failed_login', '203.0.113.50', 'curl/7.68.0', FALSE, 'Invalid credentials', NULL, FALSE
UNION ALL
SELECT 'AUTH_ANOMALY_004', '2024-01-24 14:22:25', 'USER_EMP002', 'sarah.chen', 'sarah.chen@company.com', 'failed_login', '203.0.113.50', 'curl/7.68.0', FALSE, 'Invalid credentials', NULL, FALSE;

-- Step 2: Update complex object and array columns separately
UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'CN', 'region', 'Beijing', 'city', 'Beijing', 'lat', 39.9042, 'lon', 116.4074),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'laptop', 'os', 'macOS', 'browser', 'Safari'),
    RISK_FACTORS = ARRAY_CONSTRUCT('unusual_time', 'suspicious_location', 'new_device')
WHERE LOG_ID = 'AUTH_ANOMALY_001';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'CN', 'region', 'Beijing', 'city', 'Beijing', 'lat', 39.9042, 'lon', 116.4074),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'laptop', 'os', 'macOS', 'browser', 'Safari'),
    RISK_FACTORS = ARRAY_CONSTRUCT('unusual_time', 'suspicious_location')
WHERE LOG_ID = 'AUTH_ANOMALY_002';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'RU', 'region', 'Moscow', 'city', 'Moscow', 'lat', 55.7558, 'lon', 37.6176),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'automated', 'os', 'Linux', 'browser', 'curl'),
    RISK_FACTORS = ARRAY_CONSTRUCT('suspicious_location', 'automated_tool', 'brute_force')
WHERE LOG_ID = 'AUTH_ANOMALY_003';

UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'RU', 'region', 'Moscow', 'city', 'Moscow', 'lat', 55.7558, 'lon', 37.6176),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'automated', 'os', 'Linux', 'browser', 'curl'),
    RISK_FACTORS = ARRAY_CONSTRUCT('suspicious_location', 'automated_tool', 'brute_force')
WHERE LOG_ID = 'AUTH_ANOMALY_004';

-- Terminated employee still trying to access (GRC violation)
INSERT INTO USER_AUTHENTICATION_LOGS (
    LOG_ID, TIMESTAMP, USER_ID, USERNAME, EMAIL, EVENT_TYPE, SOURCE_IP, USER_AGENT, 
    SUCCESS, FAILURE_REASON, SESSION_ID, MFA_USED
)
SELECT 'AUTH_ANOMALY_005', '2024-01-22 09:15:30', 'USER_EMP006', 'alex.turner', 'alex.turner@company.com', 'failed_login', '192.168.100.50', 'Mozilla/5.0 (Windows NT 10.0)', FALSE, 'Account disabled', NULL, FALSE;

-- Update complex columns for terminated employee
UPDATE USER_AUTHENTICATION_LOGS SET 
    LOCATION = OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'Los Angeles', 'lat', 34.0522, 'lon', -118.2437),
    DEVICE_INFO = OBJECT_CONSTRUCT('device_type', 'desktop', 'os', 'Windows 10', 'browser', 'Edge'),
    RISK_FACTORS = ARRAY_CONSTRUCT('account_disabled', 'terminated_user')
WHERE LOG_ID = 'AUTH_ANOMALY_005';

-- =====================================================
-- GITHUB ACTIVITY LOGS - For anomaly detection
-- =====================================================

-- Normal GitHub activity
INSERT INTO GITHUB_ACTIVITY_LOGS
SELECT 
    'GIT_' || ROW_NUMBER() OVER (ORDER BY ts.timestamp, u.username) as EVENT_ID,
    ts.timestamp,
    'USER_' || u.employee_id as USER_ID,
    u.username,
    u.email,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'push'
        WHEN 2 THEN 'pull'
        WHEN 3 THEN 'clone'
        WHEN 4 THEN 'create_branch'
        WHEN 5 THEN 'merge'
        ELSE 'commit'
    END as ACTION,
    CASE u.username
        WHEN 'john.smith' THEN 'company/web-frontend'
        WHEN 'sarah.chen' THEN 'company/security-tools'
        WHEN 'mike.rodriguez' THEN 'company/devops-scripts'
        WHEN 'lisa.wang' THEN 'company/data-analytics'
        WHEN 'david.johnson' THEN 'company/core-api'
        ELSE 'company/general'
    END as REPOSITORY,
    'main' as BRANCH,
    SUBSTR(MD5(RANDOM()::STRING), 1, 8) as COMMIT_HASH,
    CASE u.username
        WHEN 'john.smith' THEN '10.2.1.15'
        WHEN 'sarah.chen' THEN '10.2.1.25'
        WHEN 'mike.rodriguez' THEN '192.168.1.100'
        WHEN 'lisa.wang' THEN '10.2.1.35'
        WHEN 'david.johnson' THEN '172.16.1.10'
        ELSE '10.2.1.50'
    END as SOURCE_IP,
    UNIFORM(1, 15, RANDOM()) as FILES_CHANGED,
    UNIFORM(10, 200, RANDOM()) as LINES_ADDED,
    UNIFORM(5, 50, RANDOM()) as LINES_DELETED,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Fix bug in user authentication'
        WHEN 2 THEN 'Add new feature for dashboard'
        WHEN 3 THEN 'Update dependencies'
        WHEN 4 THEN 'Improve error handling'
        ELSE 'Code refactoring'
    END as COMMIT_MESSAGE,
    CASE u.username
        WHEN 'sarah.chen' THEN TRUE -- Security repo is sensitive
        ELSE FALSE
    END as IS_SENSITIVE_REPO,
    CASE u.username
        WHEN 'david.johnson' THEN 'admin'
        WHEN 'mike.rodriguez' THEN 'admin'
        ELSE 'write'
    END as ACCESS_LEVEL
FROM (
    SELECT DATEADD(second, UNIFORM(0, 3599, RANDOM()), 
                  DATEADD(hour, -ROW_NUMBER() OVER (ORDER BY NULL), CURRENT_TIMESTAMP())) as timestamp
    FROM TABLE(GENERATOR(ROWCOUNT => 72)) -- 3 days
) ts
CROSS JOIN (
    SELECT employee_id, username, email FROM EMPLOYEE_DATA WHERE employment_status = 'active'
) u
WHERE EXTRACT(HOUR FROM ts.timestamp) BETWEEN 9 AND 18 -- Normal working hours
    AND UNIFORM(1, 100, RANDOM()) <= 60; -- 60% chance of GitHub activity

-- Add anomalous GitHub activity for john.smith (correlates with suspicious logins)
INSERT INTO GITHUB_ACTIVITY_LOGS
-- Massive code changes during suspicious login period
SELECT 'GIT_ANOMALY_001', '2024-01-21 02:45:30', 'USER_EMP001', 'john.smith', 'john.smith@company.com', 'push', 'company/core-payment-system', 'main', 'deadbeef', '203.0.113.25', 250, 5000, 2000, 'Major refactoring of payment processing logic', TRUE, 'admin'
UNION ALL
SELECT 'GIT_ANOMALY_002', '2024-01-21 03:20:15', 'USER_EMP001', 'john.smith', 'john.smith@company.com', 'push', 'company/user-authentication', 'feature/backdoor', 'cafebabe', '203.0.113.25', 15, 500, 50, 'Add debug authentication bypass', TRUE, 'admin'
UNION ALL
SELECT 'GIT_ANOMALY_003', '2024-01-21 03:25:45', 'USER_EMP001', 'john.smith', 'john.smith@company.com', 'create_repo', 'john.smith/personal-backup', 'main', 'feedface', '203.0.113.25', 100, 10000, 0, 'Initial commit with company source code', FALSE, 'admin';
-- =====================================================
-- NETWORK SECURITY LOGS - For threat intelligence matching
-- =====================================================

-- Normal network traffic
INSERT INTO NETWORK_SECURITY_LOGS
SELECT 
    'NET_' || ROW_NUMBER() OVER (ORDER BY ts.timestamp) as LOG_ID,
    ts.timestamp,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN '10.2.1.15'  -- john.smith workstation
        WHEN 2 THEN '10.2.1.25'  -- sarah.chen workstation
        WHEN 3 THEN '10.1.1.10'  -- prod-db-01
        WHEN 4 THEN '10.1.1.20'  -- prod-web-01
        ELSE '10.2.1.35'         -- lisa.wang workstation
    END as SOURCE_IP,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN '8.8.8.8'          -- DNS
        WHEN 2 THEN '172.217.14.196'   -- Google
        WHEN 3 THEN '52.84.235.12'     -- AWS
        WHEN 4 THEN '140.82.114.3'     -- GitHub
        WHEN 5 THEN '151.101.1.140'    -- Reddit
        ELSE '104.16.132.229'          -- Cloudflare
    END as DEST_IP,
    UNIFORM(32768, 65535, RANDOM()) as SOURCE_PORT,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 443  -- HTTPS
        WHEN 2 THEN 80   -- HTTP
        WHEN 3 THEN 53   -- DNS
        ELSE 22          -- SSH
    END as DEST_PORT,
    'TCP' as PROTOCOL,
    UNIFORM(100, 10000, RANDOM()) as BYTES_IN,
    UNIFORM(1000, 50000, RANDOM()) as BYTES_OUT,
    UNIFORM(10, 1000, RANDOM()) as PACKETS_IN,
    UNIFORM(20, 2000, RANDOM()) as PACKETS_OUT,
    UNIFORM(0.1, 300.0, RANDOM()) as DURATION_SECONDS,
    'ESTABLISHED' as CONNECTION_STATE,
    FALSE as THREAT_DETECTED,
    NULL as THREAT_TYPE,
    NULL as CONFIDENCE_SCORE,
    FALSE as BLOCKED,
    OBJECT_CONSTRUCT('src_country', 'US', 'dest_country', 'US', 'src_city', 'New York', 'dest_city', 'Mountain View') as GEO_INFO
FROM (
    SELECT DATEADD(minute, -ROW_NUMBER() OVER (ORDER BY NULL), CURRENT_TIMESTAMP()) as timestamp
    FROM TABLE(GENERATOR(ROWCOUNT => 1000)) -- 1000 normal connections
) ts;

-- Add malicious network traffic (matches threat intelligence)
INSERT INTO NETWORK_SECURITY_LOGS 
-- C2 communication (matches IOC001)
SELECT 'NET_THREAT_001', '2024-01-24 14:30:15', '10.2.1.15', '203.0.113.50', 
       49152, 443, 'TCP', 2048, 15000, 20, 150, 300.5, 'ESTABLISHED', TRUE, 
       'c2_communication', 0.95, FALSE, 
       OBJECT_CONSTRUCT('src_country', 'US', 'dest_country', 'RU', 
                       'src_city', 'New York', 'dest_city', 'Moscow')
UNION ALL
SELECT 'NET_THREAT_002', '2024-01-24 15:15:30', '10.1.1.20', '203.0.113.50', 
       52341, 8080, 'TCP', 512, 25000, 15, 200, 180.2, 'ESTABLISHED', TRUE, 
       'data_exfiltration', 0.89, FALSE, 
       OBJECT_CONSTRUCT('src_country', 'US', 'dest_country', 'RU', 
                       'src_city', 'New York', 'dest_city', 'Moscow')
UNION ALL
-- Scanning activity (matches IOC003)
SELECT 'NET_THREAT_003', '2024-01-23 08:45:22', '45.33.32.156', '10.1.1.10', 
       54321, 22, 'TCP', 64, 0, 1, 1, 0.1, 'SYN_SENT', TRUE, 
       'port_scan', 0.78, TRUE, 
       OBJECT_CONSTRUCT('src_country', 'Unknown', 'dest_country', 'US', 
                       'src_city', 'Unknown', 'dest_city', 'New York')
UNION ALL
SELECT 'NET_THREAT_004', '2024-01-23 08:45:25', '45.33.32.156', '10.1.1.20', 
       54322, 22, 'TCP', 64, 0, 1, 1, 0.1, 'SYN_SENT', TRUE, 
       'port_scan', 0.78, TRUE, 
       OBJECT_CONSTRUCT('src_country', 'Unknown', 'dest_country', 'US', 
                       'src_city', 'Unknown', 'dest_city', 'New York')
UNION ALL
-- Cryptomining communication (matches IOC004)
SELECT 'NET_THREAT_005', '2024-01-25 14:20:45', '10.2.1.35', '198.51.100.25', 
       45123, 4444, 'TCP', 1024, 8192, 50, 100, 600.0, 'ESTABLISHED', TRUE, 
       'cryptomining', 0.72, FALSE, 
       OBJECT_CONSTRUCT('src_country', 'US', 'dest_country', 'NL', 
                       'src_city', 'New York', 'dest_city', 'Amsterdam');
-- =====================================================
-- ACCESS CONTROL LOGS - For GRC compliance violations
-- =====================================================

-- Normal access logs
INSERT INTO ACCESS_CONTROL_LOGS
SELECT 
    'ACCESS_' || ROW_NUMBER() OVER (ORDER BY ts.timestamp, u.username) as ACCESS_ID,
    ts.timestamp,
    'USER_' || u.employee_id as USER_ID,
    u.username,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'aws_console'
        WHEN 2 THEN 'database_prod'
        WHEN 3 THEN 'jira'
        ELSE 'github'
    END as RESOURCE,
    'login' as ACTION,
    'cloud_service' as RESOURCE_TYPE,
    u.access_level as PRIVILEGE_LEVEL,
    '10.2.1.' || (10 + UNIFORM(1, 50, RANDOM())) as SOURCE_IP,
    TRUE as SUCCESS,
    UNIFORM(30, 480, RANDOM()) as SESSION_DURATION_MINUTES,
    FALSE as UNUSUAL_ACCESS
FROM (
    SELECT DATEADD(hour, -ROW_NUMBER() OVER (ORDER BY NULL), CURRENT_TIMESTAMP()) as timestamp
    FROM TABLE(GENERATOR(ROWCOUNT => 48)) -- 2 days
) ts
CROSS JOIN (
    SELECT employee_id, username, access_level FROM EMPLOYEE_DATA WHERE employment_status = 'active'
) u
WHERE EXTRACT(HOUR FROM ts.timestamp) BETWEEN 8 AND 18 -- Business hours
    AND UNIFORM(1, 100, RANDOM()) <= 70; -- 70% chance of access

-- Add GRC violations - terminated employees still accessing systems
INSERT INTO ACCESS_CONTROL_LOGS 
-- alex.turner (terminated 2024-01-15) still accessing AWS
SELECT 'ACCESS_VIOLATION_001', '2024-01-18 10:30:00', 'USER_EMP006', 'alex.turner', 'aws_console', 'login', 'cloud_service', 'basic', '192.168.100.25', TRUE, 120, TRUE
UNION ALL
SELECT 'ACCESS_VIOLATION_002', '2024-01-20 14:45:00', 'USER_EMP006', 'alex.turner', 'database_prod', 'login', 'database', 'basic', '192.168.100.25', TRUE, 45, TRUE
UNION ALL
SELECT 'ACCESS_VIOLATION_003', '2024-01-22 09:15:00', 'USER_EMP006', 'alex.turner', 'github', 'login', 'code_repository', 'basic', '192.168.100.25', TRUE, 90, TRUE
UNION ALL
-- emily.davis (terminated 2024-01-20) still accessing Jira
SELECT 'ACCESS_VIOLATION_004', '2024-01-23 11:20:00', 'USER_EMP007', 'emily.davis', 'jira', 'login', 'project_management', 'basic', '172.16.50.10', TRUE, 60, TRUE
UNION ALL
SELECT 'ACCESS_VIOLATION_005', '2024-01-24 16:30:00', 'USER_EMP007', 'emily.davis', 'aws_console', 'login', 'cloud_service', 'basic', '172.16.50.10', TRUE, 30, TRUE;
-- =====================================================
-- SECURITY ALERTS - For AI enrichment demonstration
-- =====================================================
INSERT INTO SECURITY_ALERTS 
-- Critical alerts with unstructured text for AI analysis
SELECT 'ALERT_001', '2024-01-24 14:35:00', 'anomalous_behavior', 'critical', 'Suspicious User Activity Detected', 
 'User john.smith exhibited highly unusual behavior pattern. Multiple failed login attempts from foreign IP address (203.0.113.25) followed by successful authentication and extensive GitHub activity including access to sensitive repositories. The user created a new repository and pushed large amounts of code during off-hours. This activity pattern is consistent with account compromise scenarios. Immediate investigation recommended as the user typically works standard business hours from New York office. The source IP has been flagged in our threat intelligence as associated with previous attack campaigns.', 
 'User authentication logs show failed attempts at 14:22 from IP 203.0.113.25 (Russia), followed by successful login at 14:30. GitHub logs show repository creation and 10,000+ lines of code pushed between 02:45-03:25 AM EST. Source IP matches known C2 infrastructure.',
 ['DEV-JOHN-01', '10.2.1.15'], ['john.smith'], 'investigating', 'sarah.chen', NULL, FALSE, 
 ['Contacted user - claims no knowledge of activity', 'Disabled account pending investigation', 'Initiated forensic imaging of workstation'], 
 ['Block source IP', 'Reset user credentials', 'Review code changes'], 0.92, TRUE
UNION ALL
SELECT 'ALERT_002', '2024-01-23 08:50:00', 'network_scanning', 'high', 'Persistent Port Scanning Detected', 
 'Automated scanning activity detected from external IP address 45.33.32.156 targeting multiple production systems. The scanning appears to be systematic, targeting SSH services (port 22) across our production network range. This represents a reconnaissance attempt that could be preparatory to a more serious attack. The source IP has conducted over 500 connection attempts in the past hour, all blocked by our firewall. Security team should investigate potential vulnerabilities in SSH configurations and consider additional hardening measures.',
 'Firewall logs show 500+ SYN packets from 45.33.32.156 to ports 22, 23, 80, 443 across 10.1.1.0/24 network. All connections blocked. Geolocation shows source as hosting provider commonly used for malicious activity.',
 ['ASSET001', 'ASSET002', 'ASSET003'], [], 'resolved', 'sarah.chen', 45, FALSE,
 ['Confirmed all scans blocked by firewall', 'Added source IP to permanent blocklist', 'Reviewed SSH configurations - no vulnerabilities found'],
 ['IP blocked', 'Monitoring enhanced'], 0.87, TRUE
UNION ALL
SELECT 'ALERT_003', '2024-01-22 16:20:00', 'compliance_violation', 'medium', 'Terminated Employee Access Detected', 
 'System detected that terminated employee alex.turner (terminated 2024-01-15) successfully accessed AWS console on 2024-01-18. This represents a violation of CIS Control 16 (Account Monitoring and Control) which requires prompt removal of access for terminated employees. The access occurred 3 days after termination date, indicating a gap in our offboarding process. HR records confirm termination effective 2024-01-15. IT should verify all systems have been properly updated and access revoked.',
 'HR system shows employee termination effective 2024-01-15. AWS CloudTrail logs show successful console login on 2024-01-18 10:30:00 from IP 192.168.100.25. Session lasted 120 minutes with read access to S3 buckets.',
 ['aws_console'], ['alex.turner'], 'resolved', 'security_compliance', 30, FALSE,
 ['Confirmed employee termination in HR system', 'Disabled all remaining AWS access', 'Updated offboarding checklist'],
 ['Account disabled', 'Process improvement'], 0.95, TRUE
UNION ALL
SELECT 'ALERT_004', '2024-01-25 15:45:00', 'data_exfiltration', 'high', 'Large Data Transfer to External Host', 
 'Unusual large data transfer detected from production web server (prod-web-01) to external IP address 203.0.113.50. Transfer size of 25MB occurred over encrypted connection (port 443) during business hours. The destination IP is flagged in our threat intelligence feeds as known command and control infrastructure. This activity pattern is consistent with data exfiltration attempts. The timing coincides with other suspicious activities from the john.smith account.',
 'Network monitoring detected 25MB outbound transfer from 10.1.1.20 to 203.0.113.50:443 at 15:15:30. Duration 180 seconds. Destination IP matches IOC database entry for C2 infrastructure.',
 ['ASSET002'], ['john.smith'], 'investigating', 'incident_response', NULL, FALSE,
 ['Isolated affected server', 'Captured network traffic for analysis'],
 ['Server isolation', 'Forensic analysis initiated'], 0.89, TRUE
UNION ALL
SELECT 'ALERT_005', '2024-01-20 11:30:00', 'vulnerability_exploit', 'critical', 'Potential Exploitation of CVE-2023-46604', 
 'Security monitoring detected network traffic patterns consistent with exploitation attempts targeting CVE-2023-46604 (Apache ActiveMQ RCE vulnerability). The affected system prod-api-01 hosts critical API services and contains sensitive customer data. Multiple connection attempts were observed from various source IPs attempting to exploit the deserialization vulnerability. System administrators should immediately apply available patches and implement additional monitoring for this critical vulnerability.',
 'IDS detected multiple HTTP POST requests to /admin/activemq.jsp with suspicious payload patterns. Source IPs include 198.51.100.45, 203.0.113.75. Payload analysis shows attempted Java object deserialization attack vectors.',
 ['ASSET003'], [], 'new', 'vulnerability_management', NULL, FALSE, [], [], 0.94, FALSE;
-- =====================================================
-- ML PREDICTIONS - Sample model outputs
-- =====================================================
INSERT INTO ML_PREDICTIONS 
SELECT 'PRED_001', '2024-01-24 14:35:00', 'anomaly_detection_v2', '1.2', OBJECT_CONSTRUCT('user', 'john.smith', 'login_count', 15, 'unique_ips', 2, 'unique_countries', 2), 0.92, 0.95, 'anomaly', NULL, FALSE
UNION ALL
SELECT 'PRED_002', '2024-01-23 08:50:00', 'threat_classification_v1', '1.0', OBJECT_CONSTRUCT('source_ip', '45.33.32.156', 'connection_attempts', 500, 'ports_targeted', [22, 23, 80, 443]), 0.87, 0.91, 'classification', NULL, FALSE
UNION ALL
SELECT 'PRED_003', '2024-01-22 16:20:00', 'compliance_risk_v1', '1.1', OBJECT_CONSTRUCT('user', 'alex.turner', 'days_since_termination', 3, 'access_attempts', 1), 0.95, 0.98, 'risk_score', NULL, FALSE
UNION ALL
SELECT 'PRED_004', '2024-01-25 15:45:00', 'data_exfiltration_v1', '1.0', OBJECT_CONSTRUCT('source_ip', '10.1.1.20', 'bytes_transferred', 25000000, 'destination_reputation', 'malicious'), 0.89, 0.93, 'classification', NULL, FALSE;
COMMIT;