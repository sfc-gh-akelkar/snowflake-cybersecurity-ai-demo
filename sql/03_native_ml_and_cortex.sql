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

-- Create Native ML anomaly detection model for time-series data
CREATE OR REPLACE MODEL USER_BEHAVIOR_ANOMALY_DETECTOR(
    INPUT(USERNAME VARCHAR, LOGIN_HOUR TIMESTAMP, LOGIN_COUNT NUMBER, FAILED_ATTEMPTS NUMBER, UNIQUE_IPS NUMBER, UNIQUE_COUNTRIES NUMBER),
    OUTPUT(ANOMALY_SCORE FLOAT, IS_ANOMALY BOOLEAN)
) AS 
SELECT 
    USERNAME,
    LOGIN_HOUR,
    LOGIN_COUNT,
    FAILED_ATTEMPTS,
    UNIQUE_IPS,
    UNIQUE_COUNTRIES,
    SNOWFLAKE.ML.ANOMALY_DETECTION(LOGIN_COUNT, FAILED_ATTEMPTS, UNIQUE_IPS, UNIQUE_COUNTRIES) OVER (
        PARTITION BY USERNAME 
        ORDER BY LOGIN_HOUR
        ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
    ) as (ANOMALY_SCORE, IS_ANOMALY)
FROM USER_LOGIN_TIME_SERIES;

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

-- Create a semantic model definition for Cortex Analyst
-- This enables natural language queries against our security data

-- Note: In practice, you would upload the semantic model YAML file
-- For this demo, we'll create the key views that support natural language queries

-- Create a comprehensive view for Cortex Analyst
CREATE OR REPLACE VIEW SECURITY_ANALYTICS_SUMMARY AS
SELECT 
    -- User information
    ed.USERNAME,
    ed.DEPARTMENT,
    ed.ROLE,
    ed.SECURITY_CLEARANCE,
    
    -- Authentication patterns (last 30 days)
    COUNT(ual.LOG_ID) as TOTAL_LOGINS,
    COUNT(CASE WHEN ual.SUCCESS = FALSE THEN 1 END) as FAILED_LOGINS,
    COUNT(DISTINCT ual.SOURCE_IP) as UNIQUE_IPS_USED,
    COUNT(DISTINCT ual.LOCATION:country::STRING) as COUNTRIES_ACCESSED_FROM,
    AVG(CASE WHEN ual.TWO_FACTOR_USED THEN 1 ELSE 0 END) as TWO_FACTOR_USAGE_RATE,
    
    -- Risk indicators
    CASE 
        WHEN COUNT(CASE WHEN ual.SUCCESS = FALSE THEN 1 END) > 10 THEN 'HIGH'
        WHEN COUNT(DISTINCT ual.SOURCE_IP) > 5 THEN 'MEDIUM'
        WHEN COUNT(DISTINCT ual.LOCATION:country::STRING) > 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END as AUTHENTICATION_RISK_LEVEL,
    
    -- Recent activity
    MAX(ual.TIMESTAMP) as LAST_LOGIN,
    MIN(ual.TIMESTAMP) as FIRST_LOGIN_IN_PERIOD

FROM EMPLOYEE_DATA ed
LEFT JOIN USER_AUTHENTICATION_LOGS ual ON ed.USERNAME = ual.USERNAME 
    AND ual.TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY ed.USERNAME, ed.DEPARTMENT, ed.ROLE, ed.SECURITY_CLEARANCE;

-- Create incident summary view for Cortex Analyst
CREATE OR REPLACE VIEW INCIDENT_ANALYTICS AS
SELECT 
    INCIDENT_TYPE,
    SEVERITY,
    STATUS,
    COUNT(*) as INCIDENT_COUNT,
    AVG(CASE 
        WHEN RESOLVED_AT IS NOT NULL THEN 
            DATEDIFF(hour, CREATED_AT, RESOLVED_AT) 
        ELSE NULL 
    END) as AVG_RESOLUTION_TIME_HOURS,
    COUNT(CASE WHEN STATUS = 'Open' THEN 1 END) as OPEN_INCIDENTS,
    COUNT(CASE WHEN CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP()) THEN 1 END) as RECENT_INCIDENTS
FROM SECURITY_INCIDENTS
GROUP BY INCIDENT_TYPE, SEVERITY, STATUS;

-- ===============================================
-- Testing and Validation
-- ===============================================

-- Test the Native ML model
SELECT 
    'Testing Native ML Anomaly Detection...' as STATUS,
    COUNT(*) as ANALYZED_RECORDS,
    AVG(ANOMALY_SCORE) as AVG_ANOMALY_SCORE,
    COUNT(CASE WHEN IS_ANOMALY THEN 1 END) as ANOMALIES_DETECTED
FROM (
    SELECT * FROM ML.PREDICT(
        MODEL USER_BEHAVIOR_ANOMALY_DETECTOR,
        (SELECT * FROM USER_LOGIN_TIME_SERIES LIMIT 1000)
    )
);

-- Test the Cortex AI chatbot
SELECT security_ai_chatbot('What are the main security risks in our authentication data?') as AI_RESPONSE;

-- Verify Cortex Analyst views
SELECT 'Cortex Analyst Views Created' as STATUS;
SELECT COUNT(*) as USERS_WITH_RISK_ANALYSIS FROM SECURITY_ANALYTICS_SUMMARY;
SELECT COUNT(*) as INCIDENT_ANALYTICS_RECORDS FROM INCIDENT_ANALYTICS;

SELECT 'Native ML and Cortex AI setup completed!' as FINAL_STATUS;
SELECT 'Next step: Run the Snowpark ML training notebook!' as NEXT_ACTION;
