-- =====================================================
-- SNOWFLAKE CORTEX AI INTEGRATION
-- Replace simulated chatbot with real AI
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. REAL AI SECURITY CHATBOT FUNCTIONS
-- =====================================================

-- Function to analyze security incidents with AI
CREATE OR REPLACE FUNCTION analyze_security_incident(incident_data STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'You are a cybersecurity expert. Analyze this security incident and provide recommendations:

        Incident Data: ' || incident_data || '

        Please provide:
        1. Risk assessment (Critical/High/Medium/Low)
        2. Potential attack vector analysis
        3. Immediate response actions
        4. Long-term mitigation strategies

        Format your response clearly with bullet points.'
    )
$$;

-- Function to analyze threat intelligence with AI
CREATE OR REPLACE FUNCTION analyze_threat_intelligence(threat_indicators STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'You are a threat intelligence analyst. Analyze these indicators and provide threat assessment:

        Threat Indicators: ' || threat_indicators || '

        Please provide:
        1. Threat actor attribution (if possible)
        2. Attack campaign analysis
        3. Recommended defensive measures
        4. IOC validation and confidence scoring

        Be specific and actionable in your recommendations.'
    )
$$;

-- Function to analyze user behavior anomalies with AI
CREATE OR REPLACE FUNCTION analyze_user_anomaly(user_behavior_data STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'You are a cybersecurity analyst specializing in insider threats. Analyze this user behavior:

        User Behavior Data: ' || user_behavior_data || '

        Please provide:
        1. Anomaly classification (Insider Threat/Compromised Account/Normal)
        2. Risk factors identified
        3. Investigation priorities
        4. Recommended monitoring actions

        Focus on actionable insights for the security team.'
    )
$$;

-- Function to generate vulnerability remediation guidance
CREATE OR REPLACE FUNCTION generate_vuln_remediation(vulnerability_info STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'You are a vulnerability management expert. Provide remediation guidance for:

        Vulnerability Information: ' || vulnerability_info || '

        Please provide:
        1. Patch priority assessment
        2. Workaround options if patching is delayed
        3. Exploitation likelihood
        4. Business impact assessment
        5. Step-by-step remediation plan

        Consider both technical and business constraints.'
    )
$$;

-- =====================================================
-- 2. ENHANCED VIEWS WITH AI ANALYSIS
-- =====================================================

-- AI-powered incident analysis view
CREATE OR REPLACE VIEW AI_INCIDENT_ANALYSIS AS
SELECT 
    si.*,
    analyze_security_incident(
        'Incident ID: ' || si.INCIDENT_ID || 
        ', Severity: ' || si.SEVERITY || 
        ', Type: ' || si.INCIDENT_TYPE || 
        ', Affected Systems: ' || ARRAY_TO_STRING(si.AFFECTED_SYSTEMS, ', ') ||
        ', Description: ' || si.DESCRIPTION ||
        ', Created: ' || si.CREATED_AT::STRING
    ) as ai_analysis,
    
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Based on this incident: ' || si.DESCRIPTION || 
        ' - Provide a single sentence summary of the threat level and primary concern.'
    ) as ai_summary
FROM SECURITY_INCIDENTS si
WHERE si.CREATED_AT >= DATEADD(day, -30, CURRENT_TIMESTAMP());

-- AI-powered threat intelligence analysis
CREATE OR REPLACE VIEW AI_THREAT_INTELLIGENCE AS
SELECT 
    ti.*,
    analyze_threat_intelligence(
        'Indicator Type: ' || ti.INDICATOR_TYPE ||
        ', Indicator Value: ' || ti.INDICATOR_VALUE ||
        ', Threat Type: ' || ti.THREAT_TYPE ||
        ', Severity: ' || ti.SEVERITY ||
        ', Confidence: ' || ti.CONFIDENCE_SCORE ||
        ', Description: ' || ti.DESCRIPTION ||
        ', Source: ' || ti.SOURCE_TYPE ||
        ', Tags: ' || ARRAY_TO_STRING(ti.TAGS, ', ')
    ) as ai_threat_analysis
FROM THREAT_INTEL_FEED ti
WHERE ti.SEVERITY IN ('critical', 'high');

-- AI-powered vulnerability remediation guidance
CREATE OR REPLACE VIEW AI_VULNERABILITY_GUIDANCE AS
SELECT 
    vs.*,
    generate_vuln_remediation(
        'CVE ID: ' || vs.CVE_ID ||
        ', CVSS Score: ' || vs.CVSS_SCORE ||
        ', Asset: ' || vs.ASSET_NAME ||
        ', Description: ' || vs.VULNERABILITY_DESCRIPTION ||
        ', Status: ' || vs.STATUS ||
        ', Age: ' || DATEDIFF(day, vs.FIRST_DETECTED, CURRENT_DATE()) || ' days'
    ) as ai_remediation_guidance
FROM VULNERABILITY_SCANS vs
WHERE vs.STATUS = 'open'
AND vs.CVSS_SCORE >= 7.0;

-- =====================================================
-- 3. REAL-TIME AI CHATBOT INTERFACE
-- =====================================================

-- Function to handle general security questions with REAL DATA
CREATE OR REPLACE FUNCTION security_ai_chatbot(user_question STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH current_security_context AS (
        -- Get recent incidents
        SELECT 
            COUNT(*) as total_incidents,
            COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_incidents,
            COUNT(CASE WHEN severity = 'high' THEN 1 END) as high_incidents,
            LISTAGG(DISTINCT incident_type, ', ') as incident_types,
            MAX(created_at) as latest_incident
        FROM SECURITY_INCIDENTS 
        WHERE created_at >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    ),
    threat_intelligence_context AS (
        -- Get active threats
        SELECT 
            COUNT(*) as active_threats,
            COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_threats,
            LISTAGG(DISTINCT threat_type, ', ') as threat_types
        FROM THREAT_INTEL_FEED 
        WHERE severity IN ('critical', 'high')
    ),
    vulnerability_context AS (
        -- Get open vulnerabilities
        SELECT 
            COUNT(*) as open_vulns,
            COUNT(CASE WHEN cvss_score >= 9.0 THEN 1 END) as critical_vulns,
            COUNT(CASE WHEN cvss_score >= 7.0 THEN 1 END) as high_vulns
        FROM VULNERABILITY_SCANS 
        WHERE status = 'open'
    ),
    anomaly_context AS (
        -- Get recent anomalies
        SELECT 
            COUNT(*) as total_anomalies,
            COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) as critical_anomalies
        FROM ML_MODEL_COMPARISON 
        WHERE analysis_date >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'You are an AI cybersecurity assistant analyzing REAL DATA from our security systems.

        CURRENT SECURITY CONTEXT (Last 7 Days):
        📊 Incidents: ' || sc.total_incidents || ' total (' || sc.critical_incidents || ' critical, ' || sc.high_incidents || ' high)
        📝 Incident Types: ' || sc.incident_types || '
        🚨 Active Threats: ' || tc.active_threats || ' (' || tc.critical_threats || ' critical)
        🎯 Threat Types: ' || tc.threat_types || '
        🔍 Open Vulnerabilities: ' || vc.open_vulns || ' (' || vc.critical_vulns || ' critical CVSS 9+, ' || vc.high_vulns || ' high CVSS 7+)
        🤖 ML Anomalies: ' || ac.total_anomalies || ' detected (' || ac.critical_anomalies || ' critical)
        
        User Question: ' || user_question || '
        
        Provide analysis based on this REAL DATA. Be specific about:
        - Current numbers and trends from our actual systems
        - Actionable recommendations based on our real security posture
        - Priority areas based on actual risk levels
        - Investigation steps using our specific data
        
        Reference the actual metrics provided above in your response.'
    )
    FROM current_security_context sc, threat_intelligence_context tc, vulnerability_context vc, anomaly_context ac
$$;

-- =====================================================
-- 4. CONTEXTUAL AI ANALYSIS FUNCTIONS
-- =====================================================

-- AI-powered anomaly explanation
CREATE OR REPLACE FUNCTION explain_user_anomaly(
    username STRING,
    anomaly_score FLOAT,
    risk_level STRING,
    behavioral_indicators ARRAY
)
RETURNS STRING
LANGUAGE SQL
AS
$$
    SELECT analyze_user_anomaly(
        'Username: ' || username ||
        ', Anomaly Score: ' || anomaly_score ||
        ', Risk Level: ' || risk_level ||
        ', Behavioral Indicators: ' || ARRAY_TO_STRING(behavioral_indicators, ', ') ||
        ', Analysis needed for: Investigation priority and recommended actions'
    )
$$;

-- AI-powered trend analysis
CREATE OR REPLACE FUNCTION analyze_security_trends(time_period STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH recent_activity AS (
        SELECT 
            COUNT(*) as total_incidents,
            COUNT(CASE WHEN SEVERITY = 'critical' THEN 1 END) as critical_incidents,
            COUNT(CASE WHEN SEVERITY = 'high' THEN 1 END) as high_incidents,
            LISTAGG(DISTINCT INCIDENT_TYPE, ', ') as incident_types
        FROM SECURITY_INCIDENTS 
        WHERE CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Analyze these security trends for the past ' || time_period || ':
        
        Total Incidents: ' || ra.total_incidents ||
        ', Critical: ' || ra.critical_incidents ||
        ', High: ' || ra.high_incidents ||
        ', Incident Types: ' || ra.incident_types ||
        
        Please provide:
        1. Trend analysis and patterns
        2. Potential campaign identification
        3. Resource allocation recommendations
        4. Proactive security measures'
    )
    FROM recent_activity ra
$$;

-- =====================================================
-- 5. SPECIFIC DATA-DRIVEN AI FUNCTIONS
-- =====================================================

-- Get analysis of specific incidents with real data
CREATE OR REPLACE FUNCTION analyze_recent_incidents()
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH incident_details AS (
        SELECT 
            incident_id,
            incident_type,
            severity,
            description,
            ARRAY_TO_STRING(affected_systems, ', ') as systems,
            created_at,
            ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
        FROM SECURITY_INCIDENTS 
        WHERE created_at >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND severity IN ('critical', 'high')
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Analyze these REAL security incidents from our systems:

        ' || LISTAGG(
            'Incident ' || incident_id || ': ' || incident_type || ' (' || severity || ') - ' || 
            description || ' affecting ' || systems || ' at ' || created_at,
            '\n'
        ) || '

        Provide:
        1. Pattern analysis across these incidents
        2. Potential attack campaign identification  
        3. Priority ranking for investigation
        4. Recommended response actions
        5. Indicators to monitor for related activity

        Base your analysis on the specific details provided above.'
    )
    FROM incident_details
    WHERE rn <= 10  -- Analyze top 10 recent incidents
$$;

-- Get user anomaly analysis with real ML data
CREATE OR REPLACE FUNCTION analyze_user_anomalies()
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH anomaly_details AS (
        SELECT 
            username,
            risk_level,
            snowpark_score,
            model_agreement,
            cluster_label,
            threat_intel_match,
            analysis_date
        FROM ML_MODEL_COMPARISON 
        WHERE analysis_date >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND risk_level IN ('CRITICAL', 'HIGH')
        ORDER BY ABS(snowpark_score) DESC
        LIMIT 10
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Analyze these REAL user behavior anomalies detected by our ML models:

        ' || LISTAGG(
            'User: ' || username || ' | Risk: ' || risk_level || 
            ' | ML Score: ' || ROUND(snowpark_score, 3) || 
            ' | Agreement: ' || model_agreement || 
            ' | Cluster: ' || cluster_label ||
            ' | Threat Intel Match: ' || threat_intel_match ||
            ' | Date: ' || analysis_date,
            '\n'
        ) || '

        These are real ML-detected anomalies. Provide:
        1. Risk assessment for each user
        2. Investigation priority ranking
        3. Potential insider threat indicators
        4. Recommended monitoring actions
        5. False positive likelihood analysis

        Focus on actionable insights for our security team.'
    )
    FROM anomaly_details
$$;

-- Get vulnerability prioritization with real scan data
CREATE OR REPLACE FUNCTION prioritize_vulnerabilities()
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH vuln_analysis AS (
        SELECT 
            cve_id,
            asset_name,
            cvss_score,
            severity,
            vulnerability_description,
            status,
            DATEDIFF(day, first_detected, CURRENT_DATE()) as days_open,
            last_scanned
        FROM VULNERABILITY_SCANS 
        WHERE status = 'open'
        AND cvss_score >= 7.0
        ORDER BY cvss_score DESC, days_open DESC
        LIMIT 15
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Prioritize these REAL vulnerabilities from our security scans:

        ' || LISTAGG(
            'CVE: ' || cve_id || ' | Asset: ' || asset_name || 
            ' | CVSS: ' || cvss_score || ' | Severity: ' || severity ||
            ' | Days Open: ' || days_open || ' | Description: ' || vulnerability_description,
            '\n'
        ) || '

        Based on this real vulnerability data, provide:
        1. Risk-based prioritization ranking
        2. Patch deployment timeline recommendations
        3. Temporary mitigation strategies
        4. Business impact assessment
        5. Exploitation likelihood analysis

        Consider both technical risk and business impact in your analysis.'
    )
    FROM vuln_analysis
$$;

-- Get threat intelligence analysis with real IoCs
CREATE OR REPLACE FUNCTION analyze_threat_landscape()
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH threat_summary AS (
        SELECT 
            threat_type,
            COUNT(*) as indicator_count,
            AVG(confidence_score) as avg_confidence,
            LISTAGG(DISTINCT source_type, ', ') as sources,
            MAX(ARRAY_TO_STRING(tags, ', ')) as threat_tags
        FROM THREAT_INTEL_FEED 
        WHERE severity IN ('critical', 'high')
        GROUP BY threat_type
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Analyze our current threat intelligence landscape:

        ' || LISTAGG(
            'Threat Type: ' || threat_type || 
            ' | Indicators: ' || indicator_count || 
            ' | Avg Confidence: ' || ROUND(avg_confidence, 2) ||
            ' | Sources: ' || sources ||
            ' | Tags: ' || threat_tags,
            '\n'
        ) || '

        Based on this real threat intelligence data, provide:
        1. Current threat landscape assessment
        2. Priority threat actor identification
        3. Attack vector analysis
        4. Defensive posture recommendations
        5. Proactive hunting opportunities

        Focus on actionable threat hunting and defensive strategies.'
    )
    FROM threat_summary
$$;

-- =====================================================
-- 6. STREAMLIT INTEGRATION FUNCTIONS
-- =====================================================

-- Function for specific incident investigation
CREATE OR REPLACE FUNCTION investigate_incident(incident_id_param STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
    WITH incident_context AS (
        SELECT 
            si.*,
            -- Get related user anomalies
            LISTAGG(DISTINCT mc.username, ', ') as related_users,
            -- Get related network events (simplified)
            COUNT(DISTINCT nsl.log_id) as related_network_events
        FROM SECURITY_INCIDENTS si
        LEFT JOIN ML_MODEL_COMPARISON mc 
            ON DATE(mc.analysis_date) = DATE(si.created_at)
            AND mc.risk_level IN ('CRITICAL', 'HIGH')
        LEFT JOIN NETWORK_SECURITY_LOGS nsl
            ON DATE(nsl.timestamp) = DATE(si.created_at)
            AND nsl.threat_category != 'legitimate'
        WHERE si.incident_id = incident_id_param
        GROUP BY si.incident_id, si.incident_type, si.severity, si.description, 
                 si.affected_systems, si.created_at, si.status, si.assigned_to, si.estimated_impact_score
    )
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        'Investigate this SPECIFIC incident from our system:

        Incident ID: ' || incident_id ||
        '\nType: ' || incident_type ||
        '\nSeverity: ' || severity ||
        '\nDescription: ' || description ||
        '\nAffected Systems: ' || ARRAY_TO_STRING(affected_systems, ', ') ||
        '\nCreated: ' || created_at ||
        '\nStatus: ' || status ||
        '\nRelated Users with Anomalies: ' || COALESCE(related_users, 'None') ||
        '\nRelated Network Events: ' || related_network_events ||

        '\n\nProvide detailed investigation guidance:
        1. Incident analysis and classification
        2. Potential attack vector assessment
        3. Evidence collection priorities
        4. Investigation timeline and steps
        5. Containment and remediation actions
        6. Related indicators to monitor

        Base recommendations on the specific incident details above.'
    )
    FROM incident_context
$$;

-- =====================================================
-- VALIDATION QUERIES WITH REAL DATA
-- =====================================================

-- Test queries that work with your actual table data:

-- 1. Test general chatbot with real data context
-- SELECT security_ai_chatbot('What are the current critical security threats I should be aware of?');

-- 2. Test recent incidents analysis
-- SELECT analyze_recent_incidents();

-- 3. Test user anomaly analysis with real ML data
-- SELECT analyze_user_anomalies();

-- 4. Test vulnerability prioritization
-- SELECT prioritize_vulnerabilities();

-- 5. Test threat landscape analysis
-- SELECT analyze_threat_landscape();

-- 6. Test specific incident investigation
-- SELECT investigate_incident('INC_001');

-- Note: Requires Snowflake account with Cortex AI access
-- Enable with: ALTER ACCOUNT SET ENABLE_CORTEX = TRUE;
