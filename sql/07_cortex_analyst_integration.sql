-- =====================================================
-- CORTEX ANALYST INTEGRATION WITH SEMANTIC MODEL
-- Advanced business intelligence for cybersecurity analytics
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. CREATE CORTEX ANALYST SEMANTIC MODEL
-- =====================================================

-- Create stage for semantic model file
CREATE STAGE IF NOT EXISTS semantic_models
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for Cortex Analyst semantic model files';

-- Upload the semantic model YAML file to the stage
-- PUT file://semantic_models/cybersecurity_semantic_model.yaml @semantic_models;

-- Register the semantic model with Cortex Analyst
CREATE OR REPLACE CORTEX SEARCH SERVICE cybersecurity_semantic_model
  FROM '@semantic_models/cybersecurity_semantic_model.yaml'
  TARGET_LAG = '1 minute'
  COMMENT = 'Cybersecurity analytics semantic model for Cortex Analyst';

-- =====================================================
-- 2. CORTEX ANALYST QUERY FUNCTIONS
-- =====================================================

-- Function to query Cortex Analyst with natural language
CREATE OR REPLACE FUNCTION ask_security_analyst(user_question STRING)
RETURNS TABLE (
    query_id STRING,
    sql_query STRING,
    results VARIANT,
    explanation STRING
)
LANGUAGE SQL
AS
$$
    SELECT 
        SNOWFLAKE.CORTEX.ANALYST(
            user_question,
            'cybersecurity_semantic_model'
        ) as cortex_response
$$;

-- Enhanced function with context and error handling
CREATE OR REPLACE FUNCTION security_analytics_query(
    question STRING,
    context STRING DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    WITH enhanced_question AS (
        SELECT 
            CASE 
                WHEN context IS NOT NULL THEN 
                    'Context: ' || context || '\n\nQuestion: ' || question
                ELSE question
            END as enhanced_query
    )
    SELECT SNOWFLAKE.CORTEX.ANALYST(
        enhanced_query,
        'cybersecurity_semantic_model',
        {
            'include_explanation': true,
            'include_sql': true,
            'max_results': 100
        }
    )
    FROM enhanced_question
$$;

-- =====================================================
-- 3. SECURITY-SPECIFIC ANALYST FUNCTIONS
-- =====================================================

-- Incident analysis with Cortex Analyst
CREATE OR REPLACE FUNCTION analyze_security_incidents(timeframe STRING DEFAULT '7 days')
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    SELECT security_analytics_query(
        'Show me security incident trends and critical incidents for the last ' || timeframe || 
        '. Include severity breakdown, incident types, and resolution status.',
        'Security Operations Center dashboard requiring immediate incident visibility and prioritization'
    )
$$;

-- User risk analysis with Cortex Analyst
CREATE OR REPLACE FUNCTION analyze_user_risk(department STRING DEFAULT NULL)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    SELECT security_analytics_query(
        'Analyze user risk levels and behavioral anomalies' ||
        CASE WHEN department IS NOT NULL THEN ' for ' || department || ' department' ELSE '' END ||
        '. Show high-risk users, ML anomaly scores, and recommended actions.',
        'Insider threat investigation requiring user behavior analysis and risk assessment'
    )
$$;

-- Vulnerability prioritization with Cortex Analyst
CREATE OR REPLACE FUNCTION prioritize_security_vulnerabilities()
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    SELECT security_analytics_query(
        'Prioritize our current vulnerabilities by risk. Show critical CVEs, affected assets, 
         vulnerability age, and recommended patching order.',
        'Vulnerability management requiring risk-based prioritization and remediation planning'
    )
$$;

-- Threat landscape analysis with Cortex Analyst
CREATE OR REPLACE FUNCTION analyze_threat_landscape()
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    SELECT security_analytics_query(
        'Analyze our current threat landscape. Show threat types, confidence levels, 
         geographic threats, and emerging threat patterns.',
        'Threat intelligence analysis for proactive defense and threat hunting'
    )
$$;

-- =====================================================
-- 4. STREAMLIT INTEGRATION VIEWS
-- =====================================================

-- View for Cortex Analyst capabilities
CREATE OR REPLACE VIEW CORTEX_ANALYST_CAPABILITIES AS
SELECT 
    'Cortex Analyst Integration Status' as feature,
    'Natural language queries against cybersecurity data' as description,
    ARRAY_CONSTRUCT(
        'How many critical incidents this week?',
        'Which users have highest risk scores?',
        'What are our top vulnerability priorities?',
        'Show login trends by department',
        'Analyze threat intelligence by country',
        'What is our security posture trend?'
    ) as example_questions,
    'Use ask_security_analyst() or security_analytics_query() functions' as usage;

-- =====================================================
-- 5. CORTEX ANALYST WRAPPER FOR STREAMLIT
-- =====================================================

-- Comprehensive security analytics function for Streamlit
CREATE OR REPLACE FUNCTION cortex_security_assistant(
    user_question STRING,
    analysis_type STRING DEFAULT 'general'
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    WITH context_mapping AS (
        SELECT 
            CASE analysis_type
                WHEN 'incidents' THEN 'Security incident response and investigation context'
                WHEN 'users' THEN 'User behavior analysis and insider threat detection context'
                WHEN 'vulnerabilities' THEN 'Vulnerability management and risk assessment context'
                WHEN 'threats' THEN 'Threat intelligence and landscape analysis context'
                WHEN 'trends' THEN 'Security metrics trending and performance analysis context'
                ELSE 'General cybersecurity analytics and threat hunting context'
            END as context_string
    )
    SELECT security_analytics_query(
        user_question,
        context_string
    )
    FROM context_mapping
$$;

-- =====================================================
-- 6. SEMANTIC MODEL VALIDATION QUERIES
-- =====================================================

-- Test basic Cortex Analyst functionality
CREATE OR REPLACE VIEW test_cortex_analyst AS
SELECT 
    'Testing Cortex Analyst Integration' as test_status,
    'Run these queries to validate semantic model:' as instructions,
    ARRAY_CONSTRUCT(
        'SELECT ask_security_analyst(''How many incidents do we have?'')',
        'SELECT analyze_security_incidents(''30 days'')',
        'SELECT analyze_user_risk(''Engineering'')',
        'SELECT prioritize_security_vulnerabilities()',
        'SELECT analyze_threat_landscape()'
    ) as test_queries;

-- =====================================================
-- 7. CORTEX ANALYST PERFORMANCE MONITORING
-- =====================================================

-- View to monitor Cortex Analyst usage and performance
CREATE OR REPLACE VIEW cortex_analyst_metrics AS
WITH query_stats AS (
    SELECT 
        COUNT(*) as total_queries,
        AVG(execution_time_ms) as avg_response_time,
        COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_queries,
        COUNT(CASE WHEN status = 'error' THEN 1 END) as failed_queries
    FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
        dateadd('hour', -24, current_timestamp()),
        current_timestamp()
    ))
    WHERE query_text ILIKE '%CORTEX.ANALYST%'
)
SELECT 
    total_queries,
    avg_response_time,
    successful_queries,
    failed_queries,
    ROUND((successful_queries::FLOAT / total_queries) * 100, 2) as success_rate_pct
FROM query_stats;

-- =====================================================
-- VALIDATION AND DEPLOYMENT STEPS
-- =====================================================

/*
DEPLOYMENT CHECKLIST:

1. Upload semantic model:
   PUT file://semantic_models/cybersecurity_semantic_model.yaml @semantic_models;

2. Enable Cortex Analyst (requires admin privileges):
   ALTER ACCOUNT SET ENABLE_CORTEX_ANALYST = TRUE;

3. Test basic functionality:
   SELECT ask_security_analyst('How many incidents do we have this week?');

4. Validate semantic model:
   SELECT * FROM test_cortex_analyst;

5. Test specific functions:
   SELECT analyze_security_incidents('7 days');
   SELECT analyze_user_risk('Engineering');
   SELECT prioritize_security_vulnerabilities();

6. Integration with Streamlit:
   Use cortex_security_assistant() function in Streamlit app

7. Monitor performance:
   SELECT * FROM cortex_analyst_metrics;

EXAMPLE NATURAL LANGUAGE QUERIES:
- "How many critical incidents happened this week?"
- "Which users have the highest risk scores?"
- "What vulnerabilities should we patch first?"
- "Show me login trends by department over time"
- "What threat types are we seeing from different countries?"
- "How is our overall security posture trending?"
- "Which departments have the most failed logins?"
- "What are the most common incident types?"
- "Show me anomaly detection results for high-risk users"
- "What's our vulnerability remediation performance?"

*/
