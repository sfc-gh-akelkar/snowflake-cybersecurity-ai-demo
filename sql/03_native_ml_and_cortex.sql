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

-- Create training data for Native ML (older data for training)
CREATE OR REPLACE VIEW USER_LOGIN_TIME_SERIES_TRAINING AS
SELECT 
    USERNAME,
    DATE_TRUNC('hour', TIMESTAMP) as LOGIN_HOUR,
    COUNT(*) as LOGIN_COUNT,
    COUNT(CASE WHEN SUCCESS = FALSE THEN 1 END) as FAILED_ATTEMPTS,
    COUNT(DISTINCT SOURCE_IP) as UNIQUE_IPS,
    COUNT(DISTINCT LOCATION:country::STRING) as UNIQUE_COUNTRIES
FROM USER_AUTHENTICATION_LOGS 
WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    AND TIMESTAMP <= DATEADD(day, -7, CURRENT_TIMESTAMP())  -- Train on older data
GROUP BY USERNAME, LOGIN_HOUR
ORDER BY USERNAME, LOGIN_HOUR;

-- Create evaluation data for Native ML (newer data for evaluation)
CREATE OR REPLACE VIEW USER_LOGIN_TIME_SERIES_EVALUATION AS
SELECT 
    USERNAME,
    DATE_TRUNC('hour', TIMESTAMP) as LOGIN_HOUR,
    COUNT(*) as LOGIN_COUNT,
    COUNT(CASE WHEN SUCCESS = FALSE THEN 1 END) as FAILED_ATTEMPTS,
    COUNT(DISTINCT SOURCE_IP) as UNIQUE_IPS,
    COUNT(DISTINCT LOCATION:country::STRING) as UNIQUE_COUNTRIES
FROM USER_AUTHENTICATION_LOGS 
WHERE TIMESTAMP > DATEADD(day, -7, CURRENT_TIMESTAMP())  -- Evaluate on recent data
GROUP BY USERNAME, LOGIN_HOUR
ORDER BY USERNAME, LOGIN_HOUR;

-- ===============================================
-- Snowflake Native ML Anomaly Detection
-- ===============================================
-- This showcases Snowflake's built-in ML capabilities using the 
-- SNOWFLAKE.ML.ANOMALY_DETECTION class for time-series anomaly detection

-- Create and train the Native ML anomaly detection model using training data
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION USER_BEHAVIOR_ANOMALY_DETECTOR(
    INPUT_DATA => TABLE(USER_LOGIN_TIME_SERIES_TRAINING),
    TIMESTAMP_COLNAME => 'LOGIN_HOUR',
    TARGET_COLNAME => 'LOGIN_COUNT',
    LABEL_COLNAME => ''
);

-- Create table to store Native ML anomaly detection results
-- Note: Views cannot contain procedure calls, so we use a table approach
-- Train on older data, evaluate on newer data to satisfy time-series requirements
CREATE OR REPLACE TABLE NATIVE_ML_ANOMALY_RESULTS AS
SELECT * FROM TABLE(
    USER_BEHAVIOR_ANOMALY_DETECTOR!DETECT_ANOMALIES(
        INPUT_DATA => TABLE(USER_LOGIN_TIME_SERIES_EVALUATION),
        TIMESTAMP_COLNAME => 'LOGIN_HOUR', 
        TARGET_COLNAME => 'LOGIN_COUNT',
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    )
);

-- Create a view for easier access to the anomaly results
CREATE OR REPLACE VIEW ANOMALY_DETECTION_VIEW AS
SELECT * FROM NATIVE_ML_ANOMALY_RESULTS;

-- Create a stored procedure to refresh anomaly detection results
-- This can be called periodically or on-demand to update anomaly analysis
CREATE OR REPLACE PROCEDURE REFRESH_ANOMALY_DETECTION()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Truncate and repopulate the anomaly results table
    TRUNCATE TABLE NATIVE_ML_ANOMALY_RESULTS;
    
    INSERT INTO NATIVE_ML_ANOMALY_RESULTS
    SELECT * FROM TABLE(
        USER_BEHAVIOR_ANOMALY_DETECTOR!DETECT_ANOMALIES(
            INPUT_DATA => TABLE(USER_LOGIN_TIME_SERIES_EVALUATION),
            TIMESTAMP_COLNAME => 'LOGIN_HOUR', 
            TARGET_COLNAME => 'LOGIN_COUNT',
            CONFIG_OBJECT => {'prediction_interval': 0.95}
        )
    );
    
    RETURN 'Anomaly detection results refreshed successfully';
END;
$$;

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

-- Note: The semantic model is created manually via Snowflake UI using the YAML definition.
-- 
-- To create the semantic model:
-- 1. Navigate to Snowflake UI > Data > Semantic Views
-- 2. Click "Create Semantic View" 
-- 3. Upload or paste the YAML content from: semantic_models/cybersecurity_semantic_model.yaml
-- 4. This enables natural language queries through Cortex Analyst
--
-- The semantic model includes:
-- - 5 tables: EMPLOYEE_DATA, USER_AUTHENTICATION_LOGS, SECURITY_INCIDENTS, THREAT_INTEL_FEED, VULNERABILITY_SCANS
-- - Rich dimensions with synonyms for natural language understanding
-- - Facts and metrics for cybersecurity KPIs
-- - Relationships between users, authentication events, and incidents

-- ===============================================
-- Testing and Validation
-- ===============================================

-- Run initial anomaly detection to populate results table
CALL REFRESH_ANOMALY_DETECTION();

-- Test the Snowflake Native ML anomaly detection model
SELECT 
    'Testing Snowflake Native ML Anomaly Detection...' as STATUS,
    COUNT(*) as ANALYZED_RECORDS,
    COUNT(CASE WHEN IS_ANOMALY THEN 1 END) as ANOMALIES_DETECTED,
    AVG(CASE WHEN FORECAST IS NOT NULL THEN ABS(LOGIN_COUNT - FORECAST) ELSE NULL END) as AVG_FORECAST_ERROR,
    COUNT(CASE WHEN LOWER_BOUND IS NOT NULL AND UPPER_BOUND IS NOT NULL THEN 1 END) as RECORDS_WITH_BOUNDS
FROM NATIVE_ML_ANOMALY_RESULTS
WHERE LOGIN_COUNT IS NOT NULL;

-- Test the Cortex AI chatbot
SELECT security_ai_chatbot('What are the main security risks in our authentication data?') as AI_RESPONSE;

-- Verify Cortex Analyst setup
SELECT 'Cortex Analyst components ready' as STATUS;
SELECT 'Create semantic model manually via Snowflake UI or YAML file' as NEXT_STEP;

-- ===============================================
-- ML Model Comparison View (Placeholder)
-- ===============================================
-- This will be enhanced by the Snowpark ML notebook
-- For now, create a basic version with Native ML results using proper Snowflake Native ML output

CREATE OR REPLACE VIEW ML_MODEL_COMPARISON AS
SELECT 
    n.USERNAME,
    ed.DEPARTMENT,
    ed.ROLE,
    CURRENT_TIMESTAMP() as ANALYSIS_DATE,
    
    -- Native ML Results (from Snowflake's DETECT_ANOMALIES output)
    n.IS_ANOMALY as NATIVE_IS_ANOMALY,
    COALESCE(ABS(n.LOGIN_COUNT - n.FORECAST), 0) as NATIVE_ANOMALY_SCORE,
    
    -- Placeholder Snowpark ML Results (will be populated by notebook)
    FALSE as ISOLATION_FOREST_ANOMALY,
    0.0 as ISOLATION_FOREST_SCORE,
    0 as CLUSTER_LABEL,
    0.0 as CLUSTER_DISTANCE,
    
    -- Enhanced Risk Assessment using Native ML predictions
    CASE 
        WHEN n.IS_ANOMALY = TRUE AND n.LOGIN_COUNT > 50 THEN 'CRITICAL'
        WHEN n.IS_ANOMALY = TRUE THEN 'HIGH'
        WHEN n.LOGIN_COUNT < n.LOWER_BOUND OR n.LOGIN_COUNT > n.UPPER_BOUND THEN 'MEDIUM'
        ELSE 'LOW'
    END as RISK_LEVEL,
    
    -- Confidence score based on prediction bounds
    CASE 
        WHEN n.IS_ANOMALY = TRUE THEN 0.9
        WHEN n.FORECAST IS NOT NULL THEN 0.7
        ELSE 0.5 
    END as CONFIDENCE_SCORE,
    
    -- Model agreement (placeholder - will be enhanced by Snowpark ML)
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
