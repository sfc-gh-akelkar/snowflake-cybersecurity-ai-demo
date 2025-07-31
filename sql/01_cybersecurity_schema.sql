-- =====================================================
-- SNOWFLAKE CYBERSECURITY AI/ML DEMO SCHEMA
-- Solution Engineering Demo for Security Data Cloud
-- =====================================================

-- Create database and schema
CREATE OR REPLACE DATABASE CYBERSECURITY_DEMO;
USE DATABASE CYBERSECURITY_DEMO;
CREATE OR REPLACE SCHEMA SECURITY_AI;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- USER AUTHENTICATION & ACTIVITY LOGS
-- =====================================================
CREATE OR REPLACE TABLE USER_AUTHENTICATION_LOGS (
    LOG_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    USER_ID STRING,
    USERNAME STRING,
    EMAIL STRING,
    EVENT_TYPE STRING, -- login, logout, failed_login, mfa_challenge
    SOURCE_IP STRING,
    USER_AGENT STRING,
    LOCATION OBJECT, -- {country, region, city, lat, lon}
    SUCCESS BOOLEAN,
    FAILURE_REASON STRING,
    SESSION_ID STRING,
    DEVICE_INFO OBJECT, -- {device_type, os, browser}
    RISK_FACTORS ARRAY, -- [suspicious_location, unusual_time, etc.]
    MFA_USED BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- GITHUB ACTIVITY LOGS
-- =====================================================
CREATE OR REPLACE TABLE GITHUB_ACTIVITY_LOGS (
    EVENT_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    USER_ID STRING,
    USERNAME STRING,
    EMAIL STRING,
    ACTION STRING, -- push, pull, clone, create_repo, delete_repo, etc.
    REPOSITORY STRING,
    BRANCH STRING,
    COMMIT_HASH STRING,
    SOURCE_IP STRING,
    FILES_CHANGED INT,
    LINES_ADDED INT,
    LINES_DELETED INT,
    COMMIT_MESSAGE STRING,
    IS_SENSITIVE_REPO BOOLEAN DEFAULT FALSE,
    ACCESS_LEVEL STRING -- admin, write, read
);

-- =====================================================
-- NETWORK SECURITY LOGS
-- =====================================================
CREATE OR REPLACE TABLE NETWORK_SECURITY_LOGS (
    LOG_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    SOURCE_IP STRING,
    DEST_IP STRING,
    SOURCE_PORT INT,
    DEST_PORT INT,
    PROTOCOL STRING,
    BYTES_IN BIGINT,
    BYTES_OUT BIGINT,
    PACKETS_IN INT,
    PACKETS_OUT INT,
    DURATION_SECONDS FLOAT,
    CONNECTION_STATE STRING,
    THREAT_DETECTED BOOLEAN DEFAULT FALSE,
    THREAT_TYPE STRING,
    CONFIDENCE_SCORE FLOAT,
    BLOCKED BOOLEAN DEFAULT FALSE,
    GEO_INFO OBJECT -- {src_country, dest_country, src_city, dest_city}
);

-- =====================================================
-- THREAT INTELLIGENCE DATA
-- =====================================================
CREATE OR REPLACE TABLE THREAT_INTELLIGENCE (
    IOC_ID STRING PRIMARY KEY,
    IOC_VALUE STRING,
    IOC_TYPE STRING, -- ip, domain, url, hash, email
    THREAT_TYPE STRING, -- malware, phishing, botnet, c2, etc.
    CONFIDENCE_LEVEL STRING, -- low, medium, high, critical
    SEVERITY STRING, -- low, medium, high, critical
    FIRST_SEEN TIMESTAMP_NTZ,
    LAST_SEEN TIMESTAMP_NTZ,
    SOURCE STRING, -- internal, external_feed, partner
    TAGS ARRAY,
    DESCRIPTION TEXT,
    MITRE_TECHNIQUES ARRAY,
    AFFECTED_PRODUCTS ARRAY,
    EXPIRY_DATE TIMESTAMP_NTZ
);

-- =====================================================
-- VULNERABILITY DATA
-- =====================================================
CREATE OR REPLACE TABLE VULNERABILITY_DATA (
    VULN_ID STRING PRIMARY KEY,
    CVE_ID STRING,
    ASSET_ID STRING,
    HOSTNAME STRING,
    IP_ADDRESS STRING,
    VULNERABILITY_NAME STRING,
    SEVERITY STRING, -- critical, high, medium, low
    CVSS_SCORE FLOAT,
    CVSS_VECTOR STRING,
    DISCOVERY_DATE TIMESTAMP_NTZ,
    PATCH_AVAILABLE BOOLEAN,
    PATCH_DATE TIMESTAMP_NTZ,
    EXPLOITABILITY_SCORE FLOAT,
    IMPACT_SCORE FLOAT,
    VENDOR STRING,
    PRODUCT STRING,
    VERSION STRING,
    STATUS STRING -- open, patched, accepted_risk, false_positive
);

-- =====================================================
-- ASSET INVENTORY
-- =====================================================
CREATE OR REPLACE TABLE ASSET_INVENTORY (
    ASSET_ID STRING PRIMARY KEY,
    HOSTNAME STRING,
    IP_ADDRESS STRING,
    ASSET_TYPE STRING, -- server, workstation, mobile, iot
    OPERATING_SYSTEM STRING,
    OS_VERSION STRING,
    BUSINESS_UNIT STRING,
    OWNER STRING,
    BUSINESS_CRITICALITY STRING, -- critical, high, medium, low
    DATA_CLASSIFICATION STRING, -- public, internal, confidential, restricted
    LOCATION STRING,
    ENVIRONMENT STRING, -- production, staging, development
    COMPLIANCE_SCOPE ARRAY, -- [PCI, HIPAA, SOX, etc.]
    LAST_SCAN_DATE TIMESTAMP_NTZ,
    PATCH_LEVEL STRING,
    NETWORK_SEGMENT STRING
);

-- =====================================================
-- HR/EMPLOYEE DATA
-- =====================================================
CREATE OR REPLACE TABLE EMPLOYEE_DATA (
    EMPLOYEE_ID STRING PRIMARY KEY,
    USERNAME STRING,
    EMAIL STRING,
    FULL_NAME STRING,
    DEPARTMENT STRING,
    JOB_TITLE STRING,
    MANAGER_ID STRING,
    HIRE_DATE DATE,
    TERMINATION_DATE DATE,
    EMPLOYMENT_STATUS STRING, -- active, terminated, suspended
    SECURITY_CLEARANCE_LEVEL STRING,
    ACCESS_LEVEL STRING, -- basic, elevated, admin
    LAST_BACKGROUND_CHECK DATE,
    RISK_SCORE FLOAT DEFAULT 0.0
);

-- =====================================================
-- ACCESS CONTROL LOGS
-- =====================================================
CREATE OR REPLACE TABLE ACCESS_CONTROL_LOGS (
    ACCESS_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    USER_ID STRING,
    USERNAME STRING,
    RESOURCE STRING, -- aws_console, database, application
    ACTION STRING, -- login, logout, access_granted, access_denied
    RESOURCE_TYPE STRING,
    PRIVILEGE_LEVEL STRING,
    SOURCE_IP STRING,
    SUCCESS BOOLEAN,
    SESSION_DURATION_MINUTES INT,
    UNUSUAL_ACCESS BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- SECURITY ALERTS
-- =====================================================
CREATE OR REPLACE TABLE SECURITY_ALERTS (
    ALERT_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    ALERT_TYPE STRING,
    SEVERITY STRING, -- critical, high, medium, low, info
    TITLE STRING,
    DESCRIPTION TEXT,
    RAW_LOG_DATA TEXT,
    AFFECTED_ASSETS ARRAY,
    RELATED_USERS ARRAY,
    STATUS STRING, -- new, investigating, resolved, false_positive
    ASSIGNED_TO STRING,
    RESOLUTION_TIME_MINUTES INT,
    FALSE_POSITIVE BOOLEAN DEFAULT FALSE,
    INVESTIGATION_NOTES ARRAY,
    REMEDIATION_ACTIONS ARRAY,
    CONFIDENCE_SCORE FLOAT,
    AUTOMATED_RESPONSE BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- COMPLIANCE AUDIT TRAIL
-- =====================================================
CREATE OR REPLACE TABLE COMPLIANCE_AUDIT_TRAIL (
    AUDIT_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    CONTROL_ID STRING, -- e.g., CIS_16, SOX_404, PCI_8.1
    CONTROL_DESCRIPTION STRING,
    COMPLIANCE_STATUS STRING, -- compliant, non_compliant, needs_review
    EVIDENCE_COLLECTED ARRAY,
    AUTOMATED_CHECK BOOLEAN,
    RESPONSIBLE_PARTY STRING,
    REMEDIATION_REQUIRED BOOLEAN,
    DUE_DATE DATE,
    RISK_LEVEL STRING
);

-- =====================================================
-- ML MODEL PREDICTIONS
-- =====================================================
CREATE OR REPLACE TABLE ML_PREDICTIONS (
    PREDICTION_ID STRING PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ,
    MODEL_NAME STRING,
    MODEL_VERSION STRING,
    INPUT_DATA OBJECT,
    PREDICTION_VALUE FLOAT,
    CONFIDENCE_SCORE FLOAT,
    PREDICTION_TYPE STRING, -- anomaly, risk_score, classification
    ACTUAL_VALUE FLOAT, -- for model accuracy tracking
    FEEDBACK_PROVIDED BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- PERFORMANCE OPTIMIZATIONS
-- =====================================================

-- Add search optimization for faster queries
ALTER TABLE USER_AUTHENTICATION_LOGS ADD SEARCH OPTIMIZATION;
ALTER TABLE GITHUB_ACTIVITY_LOGS ADD SEARCH OPTIMIZATION;
ALTER TABLE NETWORK_SECURITY_LOGS ADD SEARCH OPTIMIZATION;
ALTER TABLE SECURITY_ALERTS ADD SEARCH OPTIMIZATION;

-- Create time-based clustering for better performance
ALTER TABLE USER_AUTHENTICATION_LOGS CLUSTER BY (DATE_TRUNC('day', TIMESTAMP));
ALTER TABLE GITHUB_ACTIVITY_LOGS CLUSTER BY (DATE_TRUNC('day', TIMESTAMP));
ALTER TABLE NETWORK_SECURITY_LOGS CLUSTER BY (DATE_TRUNC('day', TIMESTAMP));

-- =====================================================
-- VIEWS FOR COMMON ANALYTICS
-- =====================================================

-- Real-time user activity summary
CREATE OR REPLACE VIEW USER_ACTIVITY_SUMMARY AS
SELECT 
    USERNAME,
    COUNT(*) as total_logins_24h,
    COUNT(DISTINCT SOURCE_IP) as unique_ips_24h,
    COUNT(DISTINCT LOCATION:country::STRING) as unique_countries_24h,
    COUNT(CASE WHEN SUCCESS = FALSE THEN 1 END) as failed_logins_24h,
    MAX(TIMESTAMP) as last_activity,
    ARRAY_AGG(DISTINCT CASE WHEN ARRAY_SIZE(RISK_FACTORS) > 0 THEN RISK_FACTORS END) as risk_indicators
FROM USER_AUTHENTICATION_LOGS 
WHERE TIMESTAMP >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
GROUP BY USERNAME;

-- Threat intelligence matches
CREATE OR REPLACE VIEW ACTIVE_THREAT_MATCHES AS
SELECT 
    n.TIMESTAMP,
    n.SOURCE_IP,
    n.DEST_IP,
    t.IOC_VALUE,
    t.THREAT_TYPE,
    t.CONFIDENCE_LEVEL,
    t.SEVERITY,
    'NETWORK_MATCH' as MATCH_TYPE
FROM NETWORK_SECURITY_LOGS n
JOIN THREAT_INTELLIGENCE t ON n.DEST_IP = t.IOC_VALUE
WHERE t.EXPIRY_DATE > CURRENT_TIMESTAMP()
    AND n.TIMESTAMP >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
ORDER BY n.TIMESTAMP DESC, t.CONFIDENCE_LEVEL DESC;

-- High-risk vulnerability summary
CREATE OR REPLACE VIEW HIGH_RISK_VULNERABILITIES AS
SELECT 
    v.CVE_ID,
    v.VULNERABILITY_NAME,
    v.CVSS_SCORE,
    a.BUSINESS_CRITICALITY,
    a.DATA_CLASSIFICATION,
    COUNT(*) as affected_assets,
    MAX(v.DISCOVERY_DATE) as latest_discovery,
    CASE 
        WHEN a.BUSINESS_CRITICALITY = 'critical' AND v.CVSS_SCORE >= 9.0 THEN 10.0
        WHEN a.BUSINESS_CRITICALITY = 'critical' AND v.CVSS_SCORE >= 7.0 THEN 9.0
        WHEN a.BUSINESS_CRITICALITY = 'high' AND v.CVSS_SCORE >= 9.0 THEN 9.0
        WHEN a.BUSINESS_CRITICALITY = 'high' AND v.CVSS_SCORE >= 7.0 THEN 8.0
        ELSE v.CVSS_SCORE
    END as ai_risk_score
FROM VULNERABILITY_DATA v
JOIN ASSET_INVENTORY a ON v.ASSET_ID = a.ASSET_ID
WHERE v.STATUS = 'open'
    AND v.CVSS_SCORE >= 7.0
GROUP BY v.CVE_ID, v.VULNERABILITY_NAME, v.CVSS_SCORE, a.BUSINESS_CRITICALITY, a.DATA_CLASSIFICATION
ORDER BY ai_risk_score DESC;

-- Compliance violations
CREATE OR REPLACE VIEW COMPLIANCE_VIOLATIONS AS
SELECT 
    e.EMPLOYEE_ID,
    e.USERNAME,
    e.TERMINATION_DATE,
    MAX(a.TIMESTAMP) as last_access,
    DATEDIFF(day, e.TERMINATION_DATE, MAX(a.TIMESTAMP)) as days_overdue,
    a.RESOURCE,
    'CIS_16' as control_violated
FROM EMPLOYEE_DATA e
JOIN ACCESS_CONTROL_LOGS a ON e.USERNAME = a.USERNAME
WHERE e.EMPLOYMENT_STATUS = 'terminated'
    AND a.TIMESTAMP > e.TERMINATION_DATE
    AND a.SUCCESS = TRUE
GROUP BY e.EMPLOYEE_ID, e.USERNAME, e.TERMINATION_DATE, a.RESOURCE
HAVING days_overdue > 0
ORDER BY days_overdue DESC;

COMMIT;