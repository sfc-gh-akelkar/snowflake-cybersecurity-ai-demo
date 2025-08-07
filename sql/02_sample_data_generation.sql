-- =====================================================
-- SNOWFLAKE CYBERSECURITY DEMO - SAMPLE DATA
-- Realistic sample data for all cybersecurity use cases
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. EMPLOYEE DATA (Foundation)
-- =====================================================

INSERT INTO EMPLOYEE_DATA VALUES
('EMP001', 'john.smith', 'john.smith@company.com', 'Engineering', 'Senior Developer', 'EMP010', '2020-01-15', 'Standard', 'High', 'active'),
('EMP002', 'sarah.chen', 'sarah.chen@company.com', 'Security', 'Security Analyst', 'EMP011', '2021-03-10', 'Secret', 'Critical', 'active'),
('EMP003', 'mike.rodriguez', 'mike.rodriguez@company.com', 'Finance', 'Financial Analyst', 'EMP012', '2019-11-20', 'Standard', 'Medium', 'active'),
('EMP004', 'lisa.wang', 'lisa.wang@company.com', 'Data Science', 'Senior Data Scientist', 'EMP010', '2020-07-01', 'Standard', 'High', 'active'),
('EMP005', 'david.kim', 'david.kim@company.com', 'IT Operations', 'DevOps Engineer', 'EMP011', '2021-09-15', 'Standard', 'High', 'active'),
('EMP006', 'emma.watson', 'emma.watson@company.com', 'Legal', 'Compliance Officer', 'EMP012', '2022-01-10', 'Confidential', 'Medium', 'active'),
('EMP007', 'alex.brown', 'alex.brown@company.com', 'Engineering', 'Junior Developer', 'EMP010', '2023-03-01', 'Standard', 'Low', 'active'),
('EMP008', 'maria.garcia', 'maria.garcia@company.com', 'HR', 'HR Manager', 'EMP012', '2018-05-15', 'Confidential', 'Medium', 'active'),
('EMP009', 'james.wilson', 'james.wilson@company.com', 'Engineering', 'Lead Architect', 'EMP010', '2017-08-20', 'Standard', 'Critical', 'terminated'),
('EMP010', 'robert.taylor', 'robert.taylor@company.com', 'Engineering', 'Engineering Manager', NULL, '2015-01-01', 'Standard', 'Critical', 'active'),
('EMP011', 'jennifer.davis', 'jennifer.davis@company.com', 'Security', 'CISO', NULL, '2016-06-01', 'Top Secret', 'Critical', 'active'),
('EMP012', 'michael.johnson', 'michael.johnson@company.com', 'Finance', 'CFO', NULL, '2014-03-01', 'Confidential', 'Critical', 'active');

-- =====================================================
-- 2. THREAT INTELLIGENCE FEED (Marketplace Data Simulation)
-- =====================================================

INSERT INTO THREAT_INTEL_FEED 
SELECT 'TI001', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'ip', '185.220.100.240', 'botnet', 'high', 0.95, 'Known Emotet C2 server', 'commercial_feed', ARRAY_CONSTRUCT('emotet', 'banking_trojan', 'c2')
UNION ALL
SELECT 'TI002', DATEADD(day, -1, CURRENT_TIMESTAMP()), 'ip', '203.0.113.45', 'apt', 'critical', 0.98, 'APT29 infrastructure', 'government_feed', ARRAY_CONSTRUCT('apt29', 'cozy_bear', 'russia')
UNION ALL
SELECT 'TI003', DATEADD(hour, -6, CURRENT_TIMESTAMP()), 'domain', 'evil-phishing-site.com', 'phishing', 'medium', 0.85, 'Credential harvesting campaign', 'open_source', ARRAY_CONSTRUCT('phishing', 'credential_theft')
UNION ALL
SELECT 'TI004', DATEADD(hour, -12, CURRENT_TIMESTAMP()), 'hash', 'a1b2c3d4e5f6789012345678901234567890abcd', 'malware', 'high', 0.92, 'Ransomware payload', 'commercial_feed', ARRAY_CONSTRUCT('ransomware', 'encryption')
UNION ALL
SELECT 'TI005', DATEADD(hour, -3, CURRENT_TIMESTAMP()), 'ip', '198.51.100.150', 'scanning', 'low', 0.70, 'Automated vulnerability scanner', 'internal', ARRAY_CONSTRUCT('scanning', 'reconnaissance')
UNION ALL
SELECT 'TI006', DATEADD(day, -2, CURRENT_TIMESTAMP()), 'domain', 'fake-bank-login.net', 'phishing', 'high', 0.89, 'Banking credential phishing', 'commercial_feed', ARRAY_CONSTRUCT('banking', 'phishing', 'financial');

-- =====================================================
-- 3. USER AUTHENTICATION LOGS (With Anomalies for ML)
-- =====================================================

-- Normal baseline patterns (last 30 days) - simplified approach
INSERT INTO USER_AUTHENTICATION_LOGS 
SELECT 
    'AUTH_' || ROW_NUMBER() OVER (ORDER BY emp.EMPLOYEE_ID, days.day_offset) as LOG_ID,
    DATEADD(day, -days.day_offset, CURRENT_TIMESTAMP()) - 
    UNIFORM(8, 18, RANDOM()) * INTERVAL '1 HOUR' - 
    UNIFORM(0, 59, RANDOM()) * INTERVAL '1 MINUTE' as TIMESTAMP,
    emp.EMPLOYEE_ID as USER_ID,
    emp.USERNAME,
    emp.EMAIL,
    'login' as EVENT_TYPE,
    '192.168.' || UNIFORM(1, 254, RANDOM()) || '.' || UNIFORM(1, 254, RANDOM()) as SOURCE_IP,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' as USER_AGENT,
    OBJECT_CONSTRUCT(
        'country', 'US',
        'region', CASE UNIFORM(1, 4, RANDOM()) 
            WHEN 1 THEN 'CA' 
            WHEN 2 THEN 'NY' 
            WHEN 3 THEN 'TX' 
            ELSE 'WA' 
        END,
        'city', 'San Francisco',
        'lat', 37.7749,
        'lon', -122.4194
    ) as LOCATION,
    TRUE as SUCCESS,
    NULL as FAILURE_REASON,
    'SESS_' || UNIFORM(100000, 999999, RANDOM()) as SESSION_ID,
    OBJECT_CONSTRUCT(
        'device_type', 'laptop',
        'os', 'Windows',
        'browser', 'Chrome'
    ) as DEVICE_INFO,
    ARRAY_CONSTRUCT() as RISK_FACTORS,
    TRUE as MFA_USED
FROM EMPLOYEE_DATA emp
CROSS JOIN (
    SELECT 1 as day_offset UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
    SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
    SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL
    SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL
    SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
) days
WHERE emp.STATUS = 'active';

-- Recent anomalous activities (last 7 days)
INSERT INTO USER_AUTHENTICATION_LOGS 
-- Suspicious login from known threat IP
SELECT 'AUTH_ANOMALY_001', DATEADD(hour, -2, CURRENT_TIMESTAMP()), 'EMP001', 'john.smith', 'john.smith@company.com', 'login', '203.0.113.45', 'Mozilla/5.0 (Linux)', 
 OBJECT_CONSTRUCT('country', 'RU', 'region', 'Moscow', 'city', 'Moscow', 'lat', 55.7558, 'lon', 37.6176), 
 TRUE, NULL, 'SESS_THREAT_001', OBJECT_CONSTRUCT('device_type', 'unknown', 'os', 'Linux', 'browser', 'Unknown'), 
 ARRAY_CONSTRUCT('threat_intel_match', 'unusual_location', 'unusual_device'), FALSE
UNION ALL
-- After-hours access by terminated employee
SELECT 'AUTH_ANOMALY_002', DATEADD(hour, -6, CURRENT_TIMESTAMP()), 'EMP009', 'james.wilson', 'james.wilson@company.com', 'login', '10.0.0.45', 'curl/7.68.0',
 OBJECT_CONSTRUCT('country', 'US', 'region', 'CA', 'city', 'San Francisco', 'lat', 37.7749, 'lon', -122.4194),
 TRUE, NULL, 'SESS_TERMINATED_001', OBJECT_CONSTRUCT('device_type', 'server', 'os', 'Linux', 'browser', 'CLI'),
 ARRAY_CONSTRUCT('terminated_employee', 'unusual_time', 'unusual_user_agent'), FALSE
UNION ALL
-- Multiple failed login attempts
SELECT 'AUTH_ANOMALY_003', DATEADD(hour, -1, CURRENT_TIMESTAMP()), 'EMP003', 'mike.rodriguez', 'mike.rodriguez@company.com', 'failed_login', '185.220.100.240', 'automated_scanner',
 OBJECT_CONSTRUCT('country', 'DE', 'region', 'Bavaria', 'city', 'Munich', 'lat', 48.1351, 'lon', 11.5820),
 FALSE, 'Invalid credentials', 'SESS_BRUTE_001', OBJECT_CONSTRUCT('device_type', 'bot', 'os', 'Unknown', 'browser', 'Bot'),
 ARRAY_CONSTRUCT('brute_force_attempt', 'threat_intel_match', 'unusual_location'), FALSE;

-- =====================================================
-- 4. NETWORK SECURITY LOGS (Threat Hunting Data)
-- =====================================================

-- Generate normal network traffic
INSERT INTO NETWORK_SECURITY_LOGS
SELECT 
    'NET_' || ROW_NUMBER() OVER (ORDER BY seq.value) as LOG_ID,
    DATEADD(minute, -seq.value * 5, CURRENT_TIMESTAMP()) as TIMESTAMP,
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
);

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
    'TXN_' || ROW_NUMBER() OVER (ORDER BY seq.value) as TRANSACTION_ID,
    DATEADD(hour, -seq.value, CURRENT_TIMESTAMP()) as TIMESTAMP,
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
);

-- Suspicious transactions
INSERT INTO FINANCIAL_TRANSACTIONS VALUES
('TXN_FRAUD_001', DATEADD(hour, -2, CURRENT_TIMESTAMP()), 'USER_1234', 'ACC_567890', 'transfer', 9999.99, 'USD', 'CRYPTO_EXCHANGE', 
 OBJECT_CONSTRUCT('country', 'RU', 'city', 'Moscow'), 'FP_UNKNOWN', '203.0.113.45', TRUE, 0.95),
('TXN_FRAUD_002', DATEADD(hour, -1, CURRENT_TIMESTAMP()), 'USER_5678', 'ACC_123456', 'withdrawal', 5000.00, 'USD', 'ATM_FOREIGN',
 OBJECT_CONSTRUCT('country', 'CN', 'city', 'Shanghai'), 'FP_SUSPICIOUS', '185.220.100.240', TRUE, 0.88),
('TXN_FRAUD_003', DATEADD(minute, -30, CURRENT_TIMESTAMP()), 'USER_9999', 'ACC_999999', 'purchase', 15000.00, 'USD', 'LUXURY_GOODS',
 OBJECT_CONSTRUCT('country', 'US', 'city', 'Miami'), 'FP_NEW_DEVICE', '198.51.100.150', TRUE, 0.92);

-- =====================================================
-- 8. DATA ACCESS LOGS (For Insider Threat Detection)
-- =====================================================

-- Normal data access patterns
INSERT INTO DATA_ACCESS_LOGS
SELECT 
    'DA_' || ROW_NUMBER() OVER (ORDER BY emp.EMPLOYEE_ID, seq.value) as ACCESS_ID,
    DATEADD(hour, -seq.value, CURRENT_TIMESTAMP()) as TIMESTAMP,
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
