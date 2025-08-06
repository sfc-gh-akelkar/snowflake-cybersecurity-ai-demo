-- =====================================================
-- SNOWFLAKE CYBERSECURITY AI/ML USE CASES
-- SQL implementations showcasing AI/ML capabilities
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- USE CASE 1: ANOMALY DETECTION
-- Built-in anomaly detection using SQL
-- =====================================================

-- 1A. GitHub Login Anomaly Detection (Simplified)
CREATE OR REPLACE VIEW GITHUB_LOGIN_ANOMALY_DETECTION AS
WITH user_baseline AS (
    -- Establish baseline login patterns for each user (simplified)
    SELECT 
        USERNAME,
        COLLECT_LIST(DISTINCT EXTRACT(HOUR FROM TIMESTAMP)) as typical_hours,
        COLLECT_LIST(DISTINCT LOCATION:country::STRING) as typical_countries
    FROM USER_AUTHENTICATION_LOGS 
    WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND SUCCESS = TRUE
        AND LOCATION:country::STRING IS NOT NULL
    GROUP BY USERNAME
),
recent_activity AS (
    -- Analyze recent login activity (simplified)
    SELECT 
        u.USERNAME,
        u.TIMESTAMP,
        COALESCE(u.LOCATION:country::STRING, 'Unknown') as current_country,
        EXTRACT(HOUR FROM u.TIMESTAMP) as current_hour,
        EXTRACT(DOW FROM u.TIMESTAMP) as current_dow,
        -- GitHub activity correlation (with null handling)
        COALESCE(g.activity_count, 0) as activity_count,
        COALESCE(g.lines_changed, 0) as lines_changed,
        COALESCE(g.sensitive_repo_access, 0) as sensitive_repo_access
    FROM USER_AUTHENTICATION_LOGS u
    LEFT JOIN (
        SELECT 
            USERNAME,
            DATE_TRUNC('hour', TIMESTAMP) as activity_hour,
            COUNT(*) as activity_count,
            SUM(LINES_ADDED + LINES_DELETED) as lines_changed,
            MAX(CASE WHEN IS_SENSITIVE_REPO THEN 1 ELSE 0 END) as sensitive_repo_access
        FROM GITHUB_ACTIVITY_LOGS
        WHERE TIMESTAMP >= DATEADD(day, -1, CURRENT_TIMESTAMP())
        GROUP BY USERNAME, DATE_TRUNC('hour', TIMESTAMP)
    ) g ON u.USERNAME = g.USERNAME AND DATE_TRUNC('hour', u.TIMESTAMP) = g.activity_hour
    WHERE u.TIMESTAMP >= DATEADD(day, -1, CURRENT_TIMESTAMP())
        AND u.SUCCESS = TRUE
)
SELECT 
    r.USERNAME,
    r.TIMESTAMP,
    r.current_country,
    r.current_hour,
    r.activity_count,
    r.lines_changed,
    r.sensitive_repo_access,
    -- Simplified anomaly scoring
    (CASE 
        WHEN NOT ARRAY_CONTAINS(r.current_hour::VARIANT, ub.typical_hours) THEN 5.0
        ELSE 0.0
    END +
    CASE 
        WHEN NOT ARRAY_CONTAINS(r.current_country::VARIANT, ub.typical_countries) THEN 7.0
        ELSE 0.0
    END +
    CASE 
        WHEN r.current_dow IN (0, 6) AND r.activity_count > 5 THEN 4.0
        ELSE 0.0
    END +
    CASE 
        WHEN r.lines_changed > 1000 THEN 3.0
        ELSE 0.0
    END +
    CASE 
        WHEN r.sensitive_repo_access = 1 THEN 2.0
        ELSE 0.0
    END) as ANOMALY_SCORE,
    
    -- Simplified classification
    CASE 
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(r.current_hour::VARIANT, ub.typical_hours) THEN 5.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(r.current_country::VARIANT, ub.typical_countries) THEN 7.0 ELSE 0.0 END +
              CASE WHEN r.current_dow IN (0, 6) AND r.activity_count > 5 THEN 4.0 ELSE 0.0 END +
              CASE WHEN r.lines_changed > 1000 THEN 3.0 ELSE 0.0 END +
              CASE WHEN r.sensitive_repo_access = 1 THEN 2.0 ELSE 0.0 END) >= 8.0 THEN 'HIGH_ANOMALY'
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(r.current_hour::VARIANT, ub.typical_hours) THEN 5.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(r.current_country::VARIANT, ub.typical_countries) THEN 7.0 ELSE 0.0 END +
              CASE WHEN r.current_dow IN (0, 6) AND r.activity_count > 5 THEN 4.0 ELSE 0.0 END +
              CASE WHEN r.lines_changed > 1000 THEN 3.0 ELSE 0.0 END +
              CASE WHEN r.sensitive_repo_access = 1 THEN 2.0 ELSE 0.0 END) >= 5.0 THEN 'MEDIUM_ANOMALY'
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(r.current_hour::VARIANT, ub.typical_hours) THEN 5.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(r.current_country::VARIANT, ub.typical_countries) THEN 7.0 ELSE 0.0 END +
              CASE WHEN r.current_dow IN (0, 6) AND r.activity_count > 5 THEN 4.0 ELSE 0.0 END +
              CASE WHEN r.lines_changed > 1000 THEN 3.0 ELSE 0.0 END +
              CASE WHEN r.sensitive_repo_access = 1 THEN 2.0 ELSE 0.0 END) >= 2.0 THEN 'LOW_ANOMALY'
        ELSE 'NORMAL'
    END as CLASSIFICATION,
    
    -- Simplified anomaly indicators (as string to avoid array issues)
    CONCAT_WS(', ',
        CASE WHEN NOT ARRAY_CONTAINS(r.current_hour::VARIANT, ub.typical_hours) THEN 'unusual_hour' END,
        CASE WHEN NOT ARRAY_CONTAINS(r.current_country::VARIANT, ub.typical_countries) THEN 'unusual_location' END,
        CASE WHEN r.current_dow IN (0, 6) AND r.activity_count > 5 THEN 'weekend_activity' END,
        CASE WHEN r.lines_changed > 1000 THEN 'large_code_changes' END,
        CASE WHEN r.sensitive_repo_access = 1 THEN 'sensitive_repo_access' END
    ) as ANOMALY_INDICATORS
FROM recent_activity r
LEFT JOIN user_baseline ub ON r.USERNAME = ub.USERNAME
ORDER BY ANOMALY_SCORE DESC;

-- 1B. Statistical Anomaly Detection for Login Counts
CREATE OR REPLACE VIEW LOGIN_COUNT_ANOMALY_DETECTION AS
WITH daily_logins AS (
    SELECT 
        USERNAME,
        DATE_TRUNC('day', TIMESTAMP) as login_date,
        COUNT(*) as daily_login_count
    FROM USER_AUTHENTICATION_LOGS 
    WHERE SUCCESS = TRUE
        AND TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    GROUP BY USERNAME, DATE_TRUNC('day', TIMESTAMP)
),
user_baselines AS (
    SELECT 
        USERNAME,
        AVG(daily_login_count) as avg_logins,
        STDDEV(daily_login_count) as stddev_logins,
        COUNT(*) as days_observed
    FROM daily_logins
    GROUP BY USERNAME
),
anomaly_detection AS (
    SELECT 
        dl.USERNAME,
        dl.login_date,
        dl.daily_login_count,
        ub.avg_logins,
        ub.stddev_logins,
        -- Calculate z-score (number of standard deviations from mean)
        CASE 
            WHEN ub.stddev_logins > 0 THEN 
                ABS(dl.daily_login_count - ub.avg_logins) / ub.stddev_logins
            ELSE 0
        END as z_score,
        -- Define bounds (mean ± 2 standard deviations)
        ub.avg_logins - (2 * COALESCE(ub.stddev_logins, 0)) as expected_lower,
        ub.avg_logins + (2 * COALESCE(ub.stddev_logins, 0)) as expected_upper
    FROM daily_logins dl
    JOIN user_baselines ub ON dl.USERNAME = ub.USERNAME
)
SELECT 
    USERNAME,
    login_date,
    daily_login_count,
    -- Anomaly if z-score > 2 (outside 2 standard deviations)
    CASE WHEN z_score > 2 THEN TRUE ELSE FALSE END as is_anomaly,
    z_score as anomaly_score,
    expected_lower,
    expected_upper,
    CASE 
        WHEN z_score > 2 AND daily_login_count > expected_upper THEN 'EXCESSIVE_LOGINS'
        WHEN z_score > 2 AND daily_login_count < expected_lower THEN 'INSUFFICIENT_LOGINS'
        ELSE 'NORMAL'
    END as anomaly_type
FROM anomaly_detection
WHERE login_date >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY USERNAME, login_date DESC;

-- =====================================================
-- USE CASE 2: THREAT DETECTION & INCIDENT RESPONSE (TDIR)
-- Complex analytics across multiple datasets
-- =====================================================

-- 2A. Comprehensive Threat Correlation Analysis
CREATE OR REPLACE VIEW COMPREHENSIVE_THREAT_ANALYSIS AS
WITH threat_timeline AS (
    -- Correlate threats across multiple data sources
    SELECT 
        'NETWORK_THREAT' as event_type,
        n.TIMESTAMP,
        n.SOURCE_IP as primary_asset,
        n.DEST_IP as secondary_asset,
        n.THREAT_TYPE as threat_category,
        n.CONFIDENCE_SCORE,
        t.IOC_VALUE,
        t.THREAT_TYPE as ioc_threat_type,
        t.MITRE_TECHNIQUES,
        NULL as username,
        NULL as affected_repo
    FROM NETWORK_SECURITY_LOGS n
    JOIN THREAT_INTELLIGENCE t ON n.DEST_IP = t.IOC_VALUE
    WHERE n.THREAT_DETECTED = TRUE
        AND t.EXPIRY_DATE > CURRENT_TIMESTAMP()
        AND n.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    
    UNION ALL
    
    -- User-based threats
    SELECT 
        'USER_ANOMALY' as event_type,
        u.TIMESTAMP,
        u.USERNAME as primary_asset,
        u.SOURCE_IP as secondary_asset,
        'USER_COMPROMISE' as threat_category,
        0.85 as confidence_score,
        u.SOURCE_IP as ioc_value,
        'suspicious_activity' as ioc_threat_type,
        NULL as mitre_techniques,
        u.USERNAME,
        NULL as affected_repo
    FROM USER_AUTHENTICATION_LOGS u
    WHERE ARRAY_SIZE(u.RISK_FACTORS) > 2
        AND u.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    
    UNION ALL
    
    -- GitHub-based threats
    SELECT 
        'CODE_THREAT' as event_type,
        g.TIMESTAMP,
        g.USERNAME as primary_asset,
        g.REPOSITORY as secondary_asset,
        'CODE_MANIPULATION' as threat_category,
        0.75 as confidence_score,
        g.SOURCE_IP as ioc_value,
        'malicious_code' as ioc_threat_type,
        NULL as mitre_techniques,
        g.USERNAME,
        g.REPOSITORY as affected_repo
    FROM GITHUB_ACTIVITY_LOGS g
    WHERE (g.LINES_ADDED > 1000 OR g.IS_SENSITIVE_REPO = TRUE)
        AND EXTRACT(HOUR FROM g.TIMESTAMP) NOT BETWEEN 8 AND 18
        AND g.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
),
correlated_threats AS (
    -- Identify related threats within time windows
    SELECT 
        t1.*,
        COUNT(t2.event_type) as related_events,
        ARRAY_AGG(DISTINCT t2.event_type) as related_event_types,
        MIN(t2.TIMESTAMP) as first_related_event,
        MAX(t2.TIMESTAMP) as last_related_event
    FROM threat_timeline t1
    LEFT JOIN threat_timeline t2 ON (
        t1.primary_asset = t2.primary_asset 
        OR t1.secondary_asset = t2.secondary_asset
        OR t1.username = t2.username
    )
    AND t2.TIMESTAMP BETWEEN DATEADD(hour, -2, t1.TIMESTAMP) AND DATEADD(hour, 2, t1.TIMESTAMP)
    AND t1.TIMESTAMP != t2.TIMESTAMP
    GROUP BY t1.event_type, t1.TIMESTAMP, t1.primary_asset, t1.secondary_asset, 
             t1.threat_category, t1.confidence_score, t1.ioc_value, t1.ioc_threat_type, 
             t1.mitre_techniques, t1.username, t1.affected_repo
)
SELECT 
    *,
    -- Calculate compound threat score
    CASE 
        WHEN related_events >= 3 THEN confidence_score + 0.3
        WHEN related_events >= 2 THEN confidence_score + 0.2
        WHEN related_events >= 1 THEN confidence_score + 0.1
        ELSE confidence_score
    END as compound_threat_score,
    
    -- Threat campaign classification
    CASE 
        WHEN related_events >= 3 AND ARRAY_CONTAINS('USER_ANOMALY'::VARIANT, related_event_types) 
             AND ARRAY_CONTAINS('CODE_THREAT'::VARIANT, related_event_types) THEN 'ADVANCED_PERSISTENT_THREAT'
        WHEN related_events >= 2 AND threat_category = 'c2_communication' THEN 'COMMAND_CONTROL_CAMPAIGN'
        WHEN related_events >= 2 AND username IS NOT NULL THEN 'USER_COMPROMISE_CAMPAIGN'
        WHEN related_events >= 1 THEN 'COORDINATED_ATTACK'
        ELSE 'ISOLATED_INCIDENT'
    END as campaign_classification
FROM correlated_threats
ORDER BY compound_threat_score DESC, TIMESTAMP DESC;

-- 2B. Compromised Developer Detection
CREATE OR REPLACE VIEW COMPROMISED_DEVELOPER_DETECTION AS
SELECT 
    u.USERNAME,
    u.TIMESTAMP as suspicious_login_time,
    u.SOURCE_IP as suspicious_ip,
    u.LOCATION:country::STRING as login_country,
    
    -- GitHub activity correlation
    g.TIMESTAMP as github_activity_time,
    g.ACTION as github_action,
    g.REPOSITORY,
    g.LINES_ADDED,
    g.LINES_DELETED,
    g.COMMIT_MESSAGE,
    g.IS_SENSITIVE_REPO,
    
    -- Threat intelligence correlation
    t.IOC_VALUE,
    t.THREAT_TYPE,
    t.CONFIDENCE_LEVEL,
    
    -- Network activity correlation
    n.BYTES_OUT as data_transferred,
    n.DEST_IP as communication_target,
    
    -- Risk scoring
    (
        CASE WHEN ARRAY_SIZE(u.RISK_FACTORS) > 2 THEN 3.0 ELSE 0.0 END +
        CASE WHEN g.LINES_ADDED > 500 THEN 2.0 ELSE 0.0 END +
        CASE WHEN g.IS_SENSITIVE_REPO = TRUE THEN 3.0 ELSE 0.0 END +
        CASE WHEN t.CONFIDENCE_LEVEL = 'high' THEN 4.0 ELSE 0.0 END +
        CASE WHEN n.BYTES_OUT > 10000000 THEN 2.0 ELSE 0.0 END
    ) as compromise_risk_score,
    
    -- Evidence indicators
    ARRAY_CONSTRUCT(
        CASE WHEN ARRAY_SIZE(u.RISK_FACTORS) > 2 THEN 'suspicious_login_pattern' END,
        CASE WHEN g.LINES_ADDED > 500 THEN 'large_code_changes' END,
        CASE WHEN g.IS_SENSITIVE_REPO = TRUE THEN 'sensitive_repository_access' END,
        CASE WHEN t.CONFIDENCE_LEVEL = 'high' THEN 'threat_intelligence_match' END,
        CASE WHEN n.BYTES_OUT > 10000000 THEN 'large_data_transfer' END
    ) as compromise_indicators
    
FROM USER_AUTHENTICATION_LOGS u
JOIN GITHUB_ACTIVITY_LOGS g ON u.USERNAME = g.USERNAME
    AND g.TIMESTAMP BETWEEN u.TIMESTAMP AND DATEADD(hour, 4, u.TIMESTAMP)
LEFT JOIN THREAT_INTELLIGENCE t ON u.SOURCE_IP = t.IOC_VALUE
LEFT JOIN NETWORK_SECURITY_LOGS n ON u.SOURCE_IP = n.SOURCE_IP
    AND n.TIMESTAMP BETWEEN u.TIMESTAMP AND DATEADD(hour, 4, u.TIMESTAMP)
WHERE ARRAY_SIZE(u.RISK_FACTORS) > 0
    AND u.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY compromise_risk_score DESC;

-- =====================================================
-- USE CASE 3: VULNERABILITY PRIORITIZATION
-- AI-enhanced risk scoring based on business context
-- =====================================================

-- 3A. AI-Powered Vulnerability Risk Scoring
CREATE OR REPLACE VIEW AI_VULNERABILITY_PRIORITIZATION AS
WITH vulnerability_context AS (
    SELECT 
        v.VULN_ID,
        v.CVE_ID,
        v.VULNERABILITY_NAME,
        v.CVSS_SCORE,
        v.EXPLOITABILITY_SCORE,
        v.IMPACT_SCORE,
        v.PATCH_AVAILABLE,
        v.DISCOVERY_DATE,
        
        -- Asset context
        a.HOSTNAME,
        a.BUSINESS_CRITICALITY,
        a.DATA_CLASSIFICATION,
        a.ENVIRONMENT,
        a.COMPLIANCE_SCOPE,
        
        -- Threat context
        COUNT(t.IOC_ID) as related_threats,
        MAX(t.CONFIDENCE_LEVEL) as max_threat_confidence,
        
        -- Network exposure
        COUNT(DISTINCT n.DEST_IP) as network_connections,
        SUM(n.BYTES_OUT) as total_data_transfer,
        
        -- User access patterns
        COUNT(DISTINCT ac.USERNAME) as users_with_access,
        MAX(CASE WHEN ac.PRIVILEGE_LEVEL = 'admin' THEN 1 ELSE 0 END) as has_admin_access
        
    FROM VULNERABILITY_DATA v
    JOIN ASSET_INVENTORY a ON v.ASSET_ID = a.ASSET_ID
    LEFT JOIN THREAT_INTELLIGENCE t ON a.IP_ADDRESS = t.IOC_VALUE
    LEFT JOIN NETWORK_SECURITY_LOGS n ON a.IP_ADDRESS = n.SOURCE_IP
        AND n.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    LEFT JOIN ACCESS_CONTROL_LOGS ac ON a.HOSTNAME LIKE '%' || SPLIT_PART(ac.RESOURCE, '_', -1) || '%'
        AND ac.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND ac.SUCCESS = TRUE
    WHERE v.STATUS = 'open'
    GROUP BY v.VULN_ID, v.CVE_ID, v.VULNERABILITY_NAME, v.CVSS_SCORE, v.EXPLOITABILITY_SCORE, 
             v.IMPACT_SCORE, v.PATCH_AVAILABLE, v.DISCOVERY_DATE, a.HOSTNAME, 
             a.BUSINESS_CRITICALITY, a.DATA_CLASSIFICATION, a.ENVIRONMENT, a.COMPLIANCE_SCOPE
),
ai_risk_calculation AS (
    SELECT 
        *,
        -- AI-enhanced risk score calculation
        (
            -- Base CVSS score (40% weight)
            (CVSS_SCORE * 0.4) +
            
            -- Business criticality multiplier (25% weight)
            (CASE BUSINESS_CRITICALITY
                WHEN 'critical' THEN 10.0
                WHEN 'high' THEN 7.5
                WHEN 'medium' THEN 5.0
                WHEN 'low' THEN 2.5
                ELSE 1.0
            END * 0.25) +
            
            -- Data classification impact (15% weight)
            (CASE DATA_CLASSIFICATION
                WHEN 'restricted' THEN 10.0
                WHEN 'confidential' THEN 7.5
                WHEN 'internal' THEN 5.0
                WHEN 'public' THEN 2.5
                ELSE 1.0
            END * 0.15) +
            
            -- Environment criticality (10% weight)
            (CASE ENVIRONMENT
                WHEN 'production' THEN 10.0
                WHEN 'staging' THEN 6.0
                WHEN 'development' THEN 3.0
                ELSE 1.0
            END * 0.1) +
            
            -- Threat intelligence correlation (5% weight)
            (CASE 
                WHEN related_threats > 0 AND max_threat_confidence = 'high' THEN 10.0
                WHEN related_threats > 0 AND max_threat_confidence = 'medium' THEN 6.0
                WHEN related_threats > 0 THEN 3.0
                ELSE 0.0
            END * 0.05) +
            
            -- Network exposure factor (3% weight)
            (CASE 
                WHEN network_connections > 100 THEN 10.0
                WHEN network_connections > 50 THEN 7.0
                WHEN network_connections > 10 THEN 4.0
                ELSE 1.0
            END * 0.03) +
            
            -- User access risk (2% weight)
            (CASE 
                WHEN has_admin_access = 1 AND users_with_access > 5 THEN 10.0
                WHEN has_admin_access = 1 THEN 7.0
                WHEN users_with_access > 10 THEN 5.0
                ELSE 1.0
            END * 0.02)
        ) as ai_risk_score,
        
        -- Patch urgency calculation
        CASE 
            WHEN PATCH_AVAILABLE = TRUE AND DATEDIFF(day, DISCOVERY_DATE, CURRENT_TIMESTAMP()) > 30 THEN 'OVERDUE'
            WHEN PATCH_AVAILABLE = TRUE AND DATEDIFF(day, DISCOVERY_DATE, CURRENT_TIMESTAMP()) > 7 THEN 'URGENT'
            WHEN PATCH_AVAILABLE = TRUE THEN 'SCHEDULED'
            ELSE 'NO_PATCH_AVAILABLE'
        END as patch_urgency
    FROM vulnerability_context
)
SELECT 
    *,
    -- Final prioritization
    CASE 
        WHEN ai_risk_score >= 9.0 THEN 'CRITICAL'
        WHEN ai_risk_score >= 7.0 THEN 'HIGH'
        WHEN ai_risk_score >= 5.0 THEN 'MEDIUM'
        WHEN ai_risk_score >= 3.0 THEN 'LOW'
        ELSE 'INFO'
    END as priority_classification,
    
    -- Recommended actions
    CASE 
        WHEN ai_risk_score >= 9.0 AND patch_urgency = 'OVERDUE' THEN 'EMERGENCY_PATCH'
        WHEN ai_risk_score >= 7.0 AND PATCH_AVAILABLE = TRUE THEN 'IMMEDIATE_PATCH'
        WHEN ai_risk_score >= 5.0 AND PATCH_AVAILABLE = TRUE THEN 'SCHEDULED_PATCH'
        WHEN ai_risk_score >= 7.0 AND PATCH_AVAILABLE = FALSE THEN 'IMPLEMENT_WORKAROUND'
        ELSE 'MONITOR'
    END as recommended_action,
    
    -- Business justification
    'Risk Score: ' || ROUND(ai_risk_score, 2) || 
    ' | Asset Criticality: ' || BUSINESS_CRITICALITY || 
    ' | Data: ' || DATA_CLASSIFICATION || 
    ' | Environment: ' || ENVIRONMENT ||
    CASE WHEN related_threats > 0 THEN ' | Active Threats: ' || related_threats ELSE '' END ||
    CASE WHEN patch_urgency = 'OVERDUE' THEN ' | PATCH OVERDUE' ELSE '' END as business_justification
    
FROM ai_risk_calculation
ORDER BY ai_risk_score DESC, CVSS_SCORE DESC;

-- =====================================================
-- USE CASE 4: GRC (GOVERNANCE, RISK, AND COMPLIANCE)
-- Automated compliance monitoring and reporting
-- =====================================================

-- 4A. CIS Control 16 Automated Monitoring
CREATE OR REPLACE VIEW CIS_CONTROL_16_MONITORING AS
WITH terminated_employees AS (
    SELECT 
        EMPLOYEE_ID,
        USERNAME,
        FULL_NAME,
        TERMINATION_DATE,
        DATEDIFF(day, TERMINATION_DATE, CURRENT_TIMESTAMP()) as days_since_termination
    FROM EMPLOYEE_DATA 
    WHERE EMPLOYMENT_STATUS = 'terminated'
        AND TERMINATION_DATE >= DATEADD(day, -90, CURRENT_TIMESTAMP()) -- Check last 90 days
),
access_violations AS (
    SELECT 
        te.EMPLOYEE_ID,
        te.USERNAME,
        te.FULL_NAME,
        te.TERMINATION_DATE,
        te.days_since_termination,
        
        ac.RESOURCE,
        ac.TIMESTAMP as violation_timestamp,
        ac.SUCCESS,
        ac.SESSION_DURATION_MINUTES,
        
        DATEDIFF(day, te.TERMINATION_DATE, ac.TIMESTAMP) as days_overdue,
        
        -- Severity calculation
        CASE 
            WHEN ac.RESOURCE IN ('aws_console', 'database_prod') AND DATEDIFF(day, te.TERMINATION_DATE, ac.TIMESTAMP) > 1 THEN 'CRITICAL'
            WHEN DATEDIFF(day, te.TERMINATION_DATE, ac.TIMESTAMP) > 7 THEN 'HIGH'
            WHEN DATEDIFF(day, te.TERMINATION_DATE, ac.TIMESTAMP) > 3 THEN 'MEDIUM'
            ELSE 'LOW'
        END as violation_severity,
        
        -- Compliance score impact
        CASE 
            WHEN ac.RESOURCE IN ('aws_console', 'database_prod') THEN 10.0
            WHEN ac.RESOURCE = 'github' THEN 7.0
            WHEN ac.RESOURCE = 'jira' THEN 5.0
            ELSE 3.0
        END * LEAST(DATEDIFF(day, te.TERMINATION_DATE, ac.TIMESTAMP), 30) / 30.0 as compliance_impact_score
        
    FROM terminated_employees te
    JOIN ACCESS_CONTROL_LOGS ac ON te.USERNAME = ac.USERNAME
    WHERE ac.TIMESTAMP > te.TERMINATION_DATE
        AND ac.SUCCESS = TRUE
),
compliance_summary AS (
    SELECT 
        COUNT(DISTINCT EMPLOYEE_ID) as total_terminated_employees,
        COUNT(DISTINCT CASE WHEN days_overdue > 0 THEN EMPLOYEE_ID END) as employees_with_violations,
        COUNT(*) as total_violations,
        AVG(days_overdue) as avg_days_overdue,
        SUM(compliance_impact_score) as total_compliance_impact,
        MAX(days_overdue) as max_days_overdue
    FROM access_violations
)
SELECT 
    -- Individual violations
    av.*,
    
    -- Remediation priority
    ROW_NUMBER() OVER (ORDER BY compliance_impact_score DESC, days_overdue DESC) as remediation_priority,
    
    -- SLA compliance
    CASE 
        WHEN days_overdue <= 1 THEN 'WITHIN_SLA'
        WHEN days_overdue <= 3 THEN 'SLA_WARNING'
        ELSE 'SLA_VIOLATION'
    END as sla_status,
    
    -- Automated remediation recommendation
    CASE 
        WHEN violation_severity = 'CRITICAL' THEN 'IMMEDIATE_DISABLE_ALL_ACCESS'
        WHEN violation_severity = 'HIGH' THEN 'DISABLE_ACCESS_WITHIN_4_HOURS'
        WHEN violation_severity = 'MEDIUM' THEN 'DISABLE_ACCESS_WITHIN_24_HOURS'
        ELSE 'DISABLE_ACCESS_NEXT_BUSINESS_DAY'
    END as remediation_action,
    
    -- Compliance metrics from summary
    cs.total_terminated_employees,
    cs.employees_with_violations,
    cs.total_violations,
    ROUND((cs.total_terminated_employees - cs.employees_with_violations) * 100.0 / cs.total_terminated_employees, 2) as compliance_percentage
    
FROM access_violations av
CROSS JOIN compliance_summary cs
ORDER BY remediation_priority;

-- 4B. Automated Evidence Collection for Compliance
CREATE OR REPLACE VIEW COMPLIANCE_EVIDENCE_COLLECTION AS
SELECT 
    'CIS_16_ACCOUNT_MONITORING' as control_id,
    'Account Monitoring and Control' as control_description,
    CURRENT_TIMESTAMP() as evidence_collection_date,
    
    -- Evidence metrics
    COUNT(DISTINCT e.EMPLOYEE_ID) as total_employees_monitored,
    COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END) as terminated_employees_count,
    COUNT(DISTINCT CASE WHEN cv.EMPLOYEE_ID IS NOT NULL THEN cv.EMPLOYEE_ID END) as employees_with_violations,
    COUNT(cv.violation_timestamp) as total_access_violations,
    
    -- Compliance scoring
    ROUND(
        (COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END) - 
         COUNT(DISTINCT CASE WHEN cv.EMPLOYEE_ID IS NOT NULL THEN cv.EMPLOYEE_ID END)) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END), 0), 2
    ) as compliance_score_percentage,
    
    -- Evidence details
    OBJECT_CONSTRUCT(
        'monitoring_period', 'Last 90 days',
        'data_sources', ['HR_SYSTEM', 'ACCESS_CONTROL_LOGS', 'AUTHENTICATION_LOGS'],
        'automated_checks', TRUE,
        'manual_verification', FALSE,
        'last_audit_date', CURRENT_DATE(),
        'next_audit_due', DATEADD(month, 3, CURRENT_DATE())
    ) as evidence_metadata,
    
    -- Automated compliance status
    CASE 
        WHEN ROUND((COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END) - 
                   COUNT(DISTINCT CASE WHEN cv.EMPLOYEE_ID IS NOT NULL THEN cv.EMPLOYEE_ID END)) * 100.0 /
                  NULLIF(COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END), 0), 2) >= 95 THEN 'COMPLIANT'
        WHEN ROUND((COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END) - 
                   COUNT(DISTINCT CASE WHEN cv.EMPLOYEE_ID IS NOT NULL THEN cv.EMPLOYEE_ID END)) * 100.0 /
                  NULLIF(COUNT(DISTINCT CASE WHEN e.EMPLOYMENT_STATUS = 'terminated' THEN e.EMPLOYEE_ID END), 0), 2) >= 85 THEN 'MOSTLY_COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END as compliance_status
    
FROM EMPLOYEE_DATA e
LEFT JOIN CIS_CONTROL_16_MONITORING cv ON e.EMPLOYEE_ID = cv.EMPLOYEE_ID
WHERE e.TERMINATION_DATE >= DATEADD(day, -90, CURRENT_TIMESTAMP()) OR e.EMPLOYMENT_STATUS = 'active';

-- =====================================================
-- USE CASE 5: AI ENRICHMENTS WITH CORTEX
-- Text analysis and enrichment using Snowflake Cortex
-- =====================================================

-- 5A. Security Alert Triage with AI Text Analysis
-- Note: These functions require Snowflake Cortex to be enabled
CREATE OR REPLACE VIEW AI_ENHANCED_ALERT_TRIAGE AS
SELECT 
    ALERT_ID,
    TIMESTAMP,
    ALERT_TYPE,
    SEVERITY,
    TITLE,
    DESCRIPTION,
    
    -- AI-powered text analysis (Cortex functions)
    -- Note: Replace with actual Cortex functions when available
    CASE 
        WHEN CONTAINS(UPPER(DESCRIPTION), 'IMMEDIATELY') OR CONTAINS(UPPER(DESCRIPTION), 'URGENT') OR CONTAINS(UPPER(DESCRIPTION), 'CRITICAL') THEN 'HIGH_URGENCY'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'SHOULD') OR CONTAINS(UPPER(DESCRIPTION), 'RECOMMEND') THEN 'MEDIUM_URGENCY'
        ELSE 'LOW_URGENCY'
    END as ai_urgency_assessment,
    
    -- Extract key entities from description
    REGEXP_SUBSTR_ALL(DESCRIPTION, '\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b') as extracted_ip_addresses,
    REGEXP_SUBSTR_ALL(DESCRIPTION, '\\b[A-Za-z0-9]+\\.[A-Za-z0-9]+\\.[A-Za-z]{2,}\\b') as extracted_domains,
    REGEXP_SUBSTR_ALL(DESCRIPTION, '\\bCVE-[0-9]{4}-[0-9]+\\b') as extracted_cves,
    
    -- Threat classification based on content
    CASE 
        WHEN CONTAINS(UPPER(DESCRIPTION), 'EXFILTRATION') OR CONTAINS(UPPER(DESCRIPTION), 'DATA TRANSFER') THEN 'DATA_EXFILTRATION'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'COMMAND') AND CONTAINS(UPPER(DESCRIPTION), 'CONTROL') THEN 'C2_COMMUNICATION'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'SCANNING') OR CONTAINS(UPPER(DESCRIPTION), 'RECONNAISSANCE') THEN 'RECONNAISSANCE'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'MALWARE') OR CONTAINS(UPPER(DESCRIPTION), 'TROJAN') THEN 'MALWARE'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'COMPROMISE') OR CONTAINS(UPPER(DESCRIPTION), 'SUSPICIOUS') THEN 'ACCOUNT_COMPROMISE'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'VULNERABILITY') OR CONTAINS(UPPER(DESCRIPTION), 'EXPLOIT') THEN 'VULNERABILITY_EXPLOIT'
        ELSE 'GENERAL_SECURITY'
    END as ai_threat_classification,
    
    -- Extract key metrics/numbers
    REGEXP_SUBSTR_ALL(DESCRIPTION, '\\b[0-9]+(?:MB|GB|TB)\\b') as extracted_data_sizes,
    REGEXP_SUBSTR_ALL(DESCRIPTION, '\\b[0-9]+\\s*(?:minutes?|hours?|days?)\\b') as extracted_time_periods,
    
    -- Generate investigation priorities
    (
        CASE SEVERITY
            WHEN 'critical' THEN 4.0
            WHEN 'high' THEN 3.0
            WHEN 'medium' THEN 2.0
            WHEN 'low' THEN 1.0
            ELSE 0.5
        END +
        CASE 
            WHEN CONTAINS(UPPER(DESCRIPTION), 'IMMEDIATELY') OR CONTAINS(UPPER(DESCRIPTION), 'URGENT') THEN 2.0
            WHEN CONTAINS(UPPER(DESCRIPTION), 'SHOULD') OR CONTAINS(UPPER(DESCRIPTION), 'RECOMMEND') THEN 1.0
            ELSE 0.0
        END +
        CASE 
            WHEN ARRAY_SIZE(REGEXP_SUBSTR_ALL(DESCRIPTION, '\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b')) > 0 THEN 1.0
            ELSE 0.0
        END +
        CASE 
            WHEN AUTOMATED_RESPONSE = TRUE THEN 0.5
            ELSE 0.0
        END
    ) as ai_investigation_priority_score,
    
    -- Recommended next actions
    CASE 
        WHEN CONTAINS(UPPER(DESCRIPTION), 'EXFILTRATION') THEN 'INVESTIGATE_DATA_FLOW_AND_ISOLATE_AFFECTED_SYSTEMS'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'SCANNING') THEN 'VERIFY_FIREWALL_RULES_AND_BLOCK_SOURCE_IP'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'COMPROMISE') THEN 'RESET_CREDENTIALS_AND_REVIEW_ACCESS_LOGS'
        WHEN CONTAINS(UPPER(DESCRIPTION), 'VULNERABILITY') THEN 'APPLY_PATCHES_AND_IMPLEMENT_WORKAROUNDS'
        ELSE 'STANDARD_INVESTIGATION_PROTOCOL'
    END as ai_recommended_action,
    
    STATUS,
    ASSIGNED_TO,
    FALSE_POSITIVE
    
FROM SECURITY_ALERTS
WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY ai_investigation_priority_score DESC, TIMESTAMP DESC;

-- 5B. Automated Threat Intelligence Enrichment
CREATE OR REPLACE VIEW AUTOMATED_THREAT_ENRICHMENT AS
SELECT 
    t.IOC_ID,
    t.IOC_VALUE,
    t.IOC_TYPE,
    t.THREAT_TYPE,
    t.CONFIDENCE_LEVEL,
    t.DESCRIPTION,
    
    -- Enrich with network activity
    COUNT(DISTINCT n.LOG_ID) as network_matches,
    COUNT(DISTINCT n.SOURCE_IP) as affected_internal_ips,
    SUM(n.BYTES_OUT) as total_data_transferred,
    MAX(n.TIMESTAMP) as last_network_activity,
    
    -- Enrich with user activity
    COUNT(DISTINCT u.USERNAME) as affected_users,
    MAX(u.TIMESTAMP) as last_user_activity,
    
    -- Generate enriched context
    OBJECT_CONSTRUCT(
        'network_activity', OBJECT_CONSTRUCT(
            'total_connections', COUNT(DISTINCT n.LOG_ID),
            'data_transferred_mb', ROUND(SUM(n.BYTES_OUT) / 1024 / 1024, 2),
            'unique_internal_sources', COUNT(DISTINCT n.SOURCE_IP)
        ),
        'user_impact', OBJECT_CONSTRUCT(
            'affected_user_count', COUNT(DISTINCT u.USERNAME),
            'authentication_attempts', COUNT(u.LOG_ID)
        ),
        'threat_assessment', OBJECT_CONSTRUCT(
            'activity_level', CASE 
                WHEN COUNT(DISTINCT n.LOG_ID) > 10 THEN 'HIGH'
                WHEN COUNT(DISTINCT n.LOG_ID) > 3 THEN 'MEDIUM'
                WHEN COUNT(DISTINCT n.LOG_ID) > 0 THEN 'LOW'
                ELSE 'NONE'
            END,
            'impact_scope', CASE 
                WHEN COUNT(DISTINCT u.USERNAME) > 5 THEN 'WIDESPREAD'
                WHEN COUNT(DISTINCT u.USERNAME) > 1 THEN 'MODERATE'
                WHEN COUNT(DISTINCT u.USERNAME) = 1 THEN 'LIMITED'
                ELSE 'NO_USER_IMPACT'
            END
        )
    ) as enrichment_data,
    
    -- Calculate dynamic threat score
    (
        CASE t.CONFIDENCE_LEVEL
            WHEN 'high' THEN 4.0
            WHEN 'medium' THEN 2.5
            WHEN 'low' THEN 1.0
            ELSE 0.5
        END +
        CASE 
            WHEN COUNT(DISTINCT n.LOG_ID) > 10 THEN 3.0
            WHEN COUNT(DISTINCT n.LOG_ID) > 3 THEN 2.0
            WHEN COUNT(DISTINCT n.LOG_ID) > 0 THEN 1.0
            ELSE 0.0
        END +
        CASE 
            WHEN COUNT(DISTINCT u.USERNAME) > 5 THEN 2.0
            WHEN COUNT(DISTINCT u.USERNAME) > 1 THEN 1.5
            WHEN COUNT(DISTINCT u.USERNAME) = 1 THEN 1.0
            ELSE 0.0
        END
    ) as dynamic_threat_score,
    
    -- Action recommendations
    CASE 
        WHEN COUNT(DISTINCT n.LOG_ID) > 10 AND COUNT(DISTINCT u.USERNAME) > 3 THEN 'IMMEDIATE_CONTAINMENT_REQUIRED'
        WHEN COUNT(DISTINCT n.LOG_ID) > 5 OR COUNT(DISTINCT u.USERNAME) > 1 THEN 'ENHANCED_MONITORING_RECOMMENDED'
        WHEN COUNT(DISTINCT n.LOG_ID) > 0 OR COUNT(DISTINCT u.USERNAME) > 0 THEN 'INVESTIGATE_AND_MONITOR'
        ELSE 'PREVENTIVE_BLOCKING'
    END as recommended_action
    
FROM THREAT_INTELLIGENCE t
LEFT JOIN NETWORK_SECURITY_LOGS n ON t.IOC_VALUE = n.DEST_IP
    AND n.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
LEFT JOIN USER_AUTHENTICATION_LOGS u ON t.IOC_VALUE = u.SOURCE_IP
    AND u.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
WHERE t.EXPIRY_DATE > CURRENT_TIMESTAMP()
GROUP BY t.IOC_ID, t.IOC_VALUE, t.IOC_TYPE, t.THREAT_TYPE, t.CONFIDENCE_LEVEL, t.DESCRIPTION
ORDER BY dynamic_threat_score DESC;

COMMIT;