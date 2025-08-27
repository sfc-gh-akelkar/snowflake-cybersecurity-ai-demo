-- ===============================================
-- Cybersecurity Demo - Native ML and Cortex AI Setup
-- ===============================================
-- This script sets up Snowflake Native ML models and Cortex AI integration
-- Prerequisites: Run 01_cybersecurity_schema.sql and 02_sample_data_generation.sql first

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_ANALYTICS;
USE WAREHOUSE CYBERSECURITY_WH;

-- ===============================================
-- Snowflake Native ML - Time Series Anomaly Detection
-- ===============================================

-- Create a view that prepares data for Native ML time-series analysis
CREATE OR REPLACE VIEW USER_LOGIN_TIME_SERIES AS
SELECT 
    USERNAME,
    DATE_TRUNC('hour', TIMESTAMP) as LOGIN_HOUR,
    COUNT(*) as LOGIN_COUNT,
    COUNT(CASE WHEN SUCCESS = FALSE THEN 1 END) as FAILED_ATTEMPTS,
    COUNT(DISTINCT SOURCE_IP) as UNIQUE_IPS,
    COUNT(DISTINCT LOCATION:country::STRING) as UNIQUE_COUNTRIES
FROM USER_AUTHENTICATION_LOGS 
WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY USERNAME, LOGIN_HOUR
ORDER BY USERNAME, LOGIN_HOUR;

-- Create Native ML anomaly detection using built-in functions
-- For this demo, we'll use a simpler approach with window functions and statistical methods
CREATE OR REPLACE VIEW NATIVE_ML_ANOMALY_RESULTS AS
WITH user_stats AS (
    SELECT 
        USERNAME,
        LOGIN_HOUR,
        LOGIN_COUNT,
        FAILED_ATTEMPTS,
        UNIQUE_IPS,
        UNIQUE_COUNTRIES,
        
        -- Calculate rolling averages and standard deviations per user
        AVG(LOGIN_COUNT) OVER (
            PARTITION BY USERNAME 
            ORDER BY LOGIN_HOUR 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ) as avg_login_count,
        
        STDDEV(LOGIN_COUNT) OVER (
            PARTITION BY USERNAME 
            ORDER BY LOGIN_HOUR 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ) as stddev_login_count,
        
        -- Z-score calculation for anomaly detection
        (LOGIN_COUNT - AVG(LOGIN_COUNT) OVER (
            PARTITION BY USERNAME 
            ORDER BY LOGIN_HOUR 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        )) / NULLIF(STDDEV(LOGIN_COUNT) OVER (
            PARTITION BY USERNAME 
            ORDER BY LOGIN_HOUR 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ), 0) as z_score
        
    FROM USER_LOGIN_TIME_SERIES
)
SELECT 
    *,
    ABS(z_score) as ANOMALY_SCORE,
    CASE 
        WHEN ABS(z_score) > 2.5 THEN 1  -- Statistical anomaly threshold
        WHEN FAILED_ATTEMPTS > 5 THEN 1  -- Business rule for failed attempts
        WHEN UNIQUE_IPS > 3 THEN 1       -- Business rule for multiple IPs
        ELSE 0 
    END as IS_ANOMALY
FROM user_stats
WHERE z_score IS NOT NULL;

-- ===============================================
-- Cortex AI - Security Chatbot Function
-- ===============================================

-- Create a UDF for intelligent security analysis using Cortex AI
CREATE OR REPLACE FUNCTION security_ai_chatbot(user_question STRING)
RETURNS STRING
LANGUAGE SQL
AS $$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mixtral-8x7b',
        CONCAT(
            'You are a cybersecurity expert assistant analyzing our security data. ',
            'Our database contains authentication logs, security incidents, threat intelligence, and employee data. ',
            'Recent statistics: ',
            'Total users: ', (SELECT COUNT(*) FROM EMPLOYEE_DATA), ', ',
            'Auth events (last 7 days): ', (SELECT COUNT(*) FROM USER_AUTHENTICATION_LOGS WHERE TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())), ', ',
            'Security incidents (last 30 days): ', (SELECT COUNT(*) FROM SECURITY_INCIDENTS WHERE CREATED_AT >= DATEADD(day, -30, CURRENT_TIMESTAMP())), '. ',
            'User question: ', user_question, 
            '. Provide a helpful, security-focused response based on this context.'
        )
    ) as response
$$;

-- ===============================================
-- Cortex Analyst - Semantic Model Setup
-- ===============================================

-- Create a proper Snowflake Semantic View for Cortex Analyst
-- This enables natural language queries with proper relationships, dimensions, and metrics

-- First, ensure we have ACCOUNTADMIN role for semantic view creation
-- USE ROLE ACCOUNTADMIN;

-- Create the Cybersecurity Semantic View
CREATE OR REPLACE SEMANTIC VIEW CYBERSECURITY_SEMANTIC_MODEL
    tables (
        EMPLOYEES as EMPLOYEE_DATA primary key (USERNAME),
        AUTH_LOGS as USER_AUTHENTICATION_LOGS primary key (LOG_ID),
        INCIDENTS as SECURITY_INCIDENTS primary key (INCIDENT_ID),
        THREATS as THREAT_INTEL_FEED primary key (FEED_ID),
        VULNS as VULNERABILITY_SCANS primary key (SCAN_ID)
    )
    relationships (
        AUTH_TO_USER as AUTH_LOGS(USERNAME) references EMPLOYEES(USERNAME),
        INCIDENT_TO_USER as INCIDENTS(ASSIGNED_TO) references EMPLOYEES(USERNAME)
    )
    dimensions (
        -- Employee dimensions
        EMPLOYEES.USERNAME as employee_username,
        EMPLOYEES.DEPARTMENT as employee_department,
        EMPLOYEES.ROLE as employee_role,
        EMPLOYEES.SECURITY_CLEARANCE as security_clearance_level,
        EMPLOYEES.STATUS as employee_status,
        EMPLOYEES.HIRE_DATE as hire_date,
        
        -- Authentication dimensions
        AUTH_LOGS.SOURCE_IP as source_ip_address,
        AUTH_LOGS.LOCATION as login_location,
        AUTH_LOGS.SUCCESS as login_success,
        AUTH_LOGS.TWO_FACTOR_USED as two_factor_enabled,
        AUTH_LOGS.FAILURE_REASON as failure_reason,
        AUTH_LOGS.TIMESTAMP as auth_timestamp,
        
        -- Security incident dimensions
        INCIDENTS.INCIDENT_TYPE as incident_type,
        INCIDENTS.SEVERITY as incident_severity,
        INCIDENTS.STATUS as incident_status,
        INCIDENTS.CREATED_AT as incident_created_date,
        INCIDENTS.RESOLVED_AT as incident_resolved_date,
        
        -- Threat intelligence dimensions
        THREATS.INDICATOR_TYPE as threat_indicator_type,
        THREATS.THREAT_TYPE as threat_type,
        THREATS.SEVERITY as threat_severity,
        THREATS.SOURCE_TYPE as threat_source,
        
        -- Vulnerability dimensions
        VULNS.CVE_ID as vulnerability_cve,
        VULNS.SEVERITY as vulnerability_severity,
        VULNS.STATUS as vulnerability_status,
        VULNS.PATCH_AVAILABLE as patch_available
    )
    facts (
        -- Authentication facts
        AUTH_LOGS.LOG_ID as auth_event_count,
        
        -- Security incident facts  
        INCIDENTS.INCIDENT_ID as incident_count,
        
        -- Threat intelligence facts
        THREATS.CONFIDENCE_SCORE as threat_confidence,
        
        -- Vulnerability facts
        VULNS.CVSS_SCORE as vulnerability_score
    )
    expressions (
        -- Authentication metrics
        login_success_rate as AVG(CASE WHEN AUTH_LOGS.SUCCESS = TRUE THEN 1.0 ELSE 0.0 END),
        failed_login_count as COUNT(CASE WHEN AUTH_LOGS.SUCCESS = FALSE THEN 1 END),
        total_login_attempts as COUNT(AUTH_LOGS.LOG_ID),
        unique_ip_count as COUNT(DISTINCT AUTH_LOGS.SOURCE_IP),
        two_factor_usage_rate as AVG(CASE WHEN AUTH_LOGS.TWO_FACTOR_USED = TRUE THEN 1.0 ELSE 0.0 END),
        
        -- Security incident metrics
        total_incidents as COUNT(INCIDENTS.INCIDENT_ID),
        open_incidents as COUNT(CASE WHEN INCIDENTS.STATUS = 'Open' THEN 1 END),
        critical_incidents as COUNT(CASE WHEN INCIDENTS.SEVERITY = 'CRITICAL' THEN 1 END),
        avg_resolution_time_hours as AVG(DATEDIFF(hour, INCIDENTS.CREATED_AT, INCIDENTS.RESOLVED_AT)),
        
        -- Threat intelligence metrics
        high_confidence_threats as COUNT(CASE WHEN THREATS.CONFIDENCE_SCORE > 0.8 THEN 1 END),
        total_threats as COUNT(THREATS.FEED_ID),
        avg_threat_confidence as AVG(THREATS.CONFIDENCE_SCORE),
        
        -- Vulnerability metrics
        critical_vulnerabilities as COUNT(CASE WHEN VULNS.SEVERITY = 'Critical' THEN 1 END),
        total_vulnerabilities as COUNT(VULNS.SCAN_ID),
        avg_cvss_score as AVG(VULNS.CVSS_SCORE),
        patchable_vulns as COUNT(CASE WHEN VULNS.PATCH_AVAILABLE = TRUE THEN 1 END)
    );

-- ===============================================
-- Testing and Validation
-- ===============================================

-- Test the Native ML model
SELECT 
    'Testing Native ML Anomaly Detection...' as STATUS,
    COUNT(*) as ANALYZED_RECORDS,
    COUNT(CASE WHEN IS_ANOMALY = 1 THEN 1 END) as ANOMALIES_DETECTED,
    AVG(ANOMALY_SCORE) as AVG_ANOMALY_SCORE,
    MAX(ANOMALY_SCORE) as MAX_ANOMALY_SCORE
FROM NATIVE_ML_ANOMALY_RESULTS;

-- Test the Cortex AI chatbot
SELECT security_ai_chatbot('What are the main security risks in our authentication data?') as AI_RESPONSE;

-- Verify Cortex Analyst semantic view
SELECT 'Cortex Analyst Semantic View Created' as STATUS;

-- Test the semantic view with a sample query
SELECT * FROM SEMANTIC_VIEW (
    CYBERSECURITY_SEMANTIC_MODEL
    DIMENSIONS
        employee_department,
        incident_severity
    EXPRESSIONS
        total_incidents,
        avg_resolution_time_hours
) 
WHERE total_incidents > 0
ORDER BY total_incidents DESC
LIMIT 5;

-- Show semantic view information
SHOW SEMANTIC VIEWS;

-- ===============================================
-- ML Model Comparison View (Placeholder)
-- ===============================================
-- This will be enhanced by the Snowpark ML notebook
-- For now, create a basic version with just Native ML results

CREATE OR REPLACE VIEW ML_MODEL_COMPARISON AS
SELECT 
    n.USERNAME,
    ed.DEPARTMENT,
    ed.ROLE,
    CURRENT_TIMESTAMP() as ANALYSIS_DATE,
    
    -- Native ML Results
    CASE WHEN n.IS_ANOMALY = 1 THEN TRUE ELSE FALSE END as NATIVE_IS_ANOMALY,
    COALESCE(n.ANOMALY_SCORE, 0) as NATIVE_ANOMALY_SCORE,
    
    -- Placeholder Snowpark ML Results (will be populated by notebook)
    FALSE as ISOLATION_FOREST_ANOMALY,
    0.0 as ISOLATION_FOREST_SCORE,
    0 as CLUSTER_LABEL,
    0.0 as CLUSTER_DISTANCE,
    
    -- Basic Risk Assessment (will be enhanced by notebook)
    CASE 
        WHEN n.IS_ANOMALY = 1 AND n.LOGIN_COUNT > 50 THEN 'CRITICAL'
        WHEN n.IS_ANOMALY = 1 THEN 'HIGH'
        WHEN n.FAILED_ATTEMPTS > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END as RISK_LEVEL,
    
    -- Basic confidence score
    CASE WHEN n.IS_ANOMALY = 1 THEN 0.8 ELSE 0.6 END as CONFIDENCE_SCORE,
    
    -- Model agreement (placeholder)
    'NATIVE_ONLY' as MODEL_AGREEMENT
    
FROM NATIVE_ML_ANOMALY_RESULTS n
JOIN EMPLOYEE_DATA ed ON n.USERNAME = ed.USERNAME
WHERE ed.STATUS = 'active';

-- ===============================================
-- Example Natural Language Queries for Cortex Analyst
-- ===============================================

/*
With the CYBERSECURITY_SEMANTIC_MODEL semantic view, you can now ask Cortex Analyst 
natural language questions like:

1. "Show me login success rates by department"
2. "What are the critical security incidents by severity?"
3. "Which employees have the most failed login attempts?"
4. "Show me vulnerability counts by department"
5. "What is the average resolution time for security incidents?"
6. "Which departments have the highest two-factor authentication usage?"
7. "Show me threat intelligence by confidence score"

Cortex Analyst will automatically translate these to semantic SQL queries like:

SELECT * FROM SEMANTIC_VIEW (
    CYBERSECURITY_SEMANTIC_MODEL
    DIMENSIONS employee_department
    EXPRESSIONS login_success_rate, failed_login_count
)
ORDER BY failed_login_count DESC;
*/

SELECT 'Native ML and Cortex AI setup completed!' as FINAL_STATUS;
SELECT 'Next step: Run the Snowpark ML training notebook!' as NEXT_ACTION;

-- Dynamic Cortex Analyst URL (uncomment to use in Snowflake Notebooks)
-- SELECT 'https://app.snowflake.com/' || CURRENT_ORGANIZATION_NAME() || '/' || CURRENT_ACCOUNT_NAME() || 
--        '/#/studio/analyst/databases/CYBERSECURITY_DEMO/schemas/SECURITY_ANALYTICS/semanticView/CYBERSECURITY_SEMANTIC_MODEL/edit' 
--        AS CORTEX_ANALYST_URL;
