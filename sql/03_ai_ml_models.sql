-- =====================================================
-- SNOWFLAKE CYBERSECURITY DEMO - ENHANCED AI/ML MODELS
-- Advanced analytics combining Native ML + Snowpark ML for cybersecurity
-- Features: Native anomaly detection, Snowpark ML models, hybrid analytics
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- SNOWFLAKE NATIVE ML MODELS (Option 1)
-- =====================================================

-- Create Native ML model for time-series login pattern analysis
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION native_login_patterns(
  INPUT_DATA => SYSTEM$QUERY_HISTORY(
    'SELECT DATE_TRUNC(\'hour\', timestamp) as ts,
            COUNT(*) as login_count,
            COUNT(DISTINCT username) as unique_users,
            AVG(CASE WHEN success THEN 1.0 ELSE 0.0 END) as success_rate,
            COUNT(DISTINCT source_ip) as unique_ips
     FROM USER_AUTHENTICATION_LOGS 
     WHERE timestamp >= DATEADD(day, -90, CURRENT_TIMESTAMP())
       AND username IS NOT NULL
     GROUP BY 1 ORDER BY 1'
  ),
  TIMESTAMP_COLNAME => 'TS',
  TARGET_COLNAME => 'LOGIN_COUNT'
);

-- Create Native ML model for per-user behavior analysis  
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION native_user_behavior(
  INPUT_DATA => SYSTEM$QUERY_HISTORY(
    'SELECT username,
            DATE(timestamp) as date_ts,
            COUNT(*) as daily_logins,
            COUNT(DISTINCT EXTRACT(HOUR FROM timestamp)) as active_hours,
            COUNT(DISTINCT source_ip) as unique_ips_daily,
            COUNT(DISTINCT location:country::STRING) as countries_daily
     FROM USER_AUTHENTICATION_LOGS 
     WHERE timestamp >= DATEADD(day, -90, CURRENT_TIMESTAMP())
       AND success = TRUE
       AND username IS NOT NULL
     GROUP BY 1, 2 ORDER BY 1, 2'
  ),
  TIMESTAMP_COLNAME => 'DATE_TS',
  TARGET_COLNAME => 'DAILY_LOGINS'
);

-- Create Native ML model for network traffic analysis
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION native_network_patterns(
  INPUT_DATA => SYSTEM$QUERY_HISTORY(
    'SELECT DATE_TRUNC(\'hour\', timestamp) as ts,
            SUM(bytes_transferred) as total_bytes,
            COUNT(*) as connection_count,
            COUNT(DISTINCT source_ip) as unique_sources
     FROM NETWORK_SECURITY_LOGS
     WHERE timestamp >= DATEADD(day, -90, CURRENT_TIMESTAMP())
     GROUP BY 1 ORDER BY 1'
  ),
  TIMESTAMP_COLNAME => 'TS',
  TARGET_COLNAME => 'TOTAL_BYTES'
);

-- =====================================================
-- NATIVE ML ANOMALY DETECTION VIEWS
-- =====================================================

-- View 1: Native ML time-series login pattern anomalies
CREATE OR REPLACE VIEW NATIVE_ML_LOGIN_PATTERNS AS
SELECT 
    'NATIVE_ML' as model_type,
    'TIME_SERIES_LOGINS' as model_subtype,
    ts as timestamp,
    login_count,
    unique_users,
    success_rate,
    unique_ips,
    forecast as expected_login_count,
    is_anomaly as native_anomaly,
    anomaly_score as native_confidence,
    CASE 
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.8 THEN 'CRITICAL'
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.6 THEN 'HIGH'
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END as ml_risk_level,
    lower_bound,
    upper_bound
FROM TABLE(
    native_login_patterns!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$QUERY_HISTORY(
            'SELECT DATE_TRUNC(\'hour\', timestamp) as ts,
                    COUNT(*) as login_count,
                    COUNT(DISTINCT username) as unique_users,
                    AVG(CASE WHEN success THEN 1.0 ELSE 0.0 END) as success_rate,
                    COUNT(DISTINCT source_ip) as unique_ips
             FROM USER_AUTHENTICATION_LOGS 
             WHERE timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
               AND username IS NOT NULL
             GROUP BY 1 ORDER BY 1'
        ),
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME => 'LOGIN_COUNT'
    )
)
WHERE ts >= DATEADD(day, -30, CURRENT_TIMESTAMP());

-- View 2: Native ML user behavior anomalies
CREATE OR REPLACE VIEW NATIVE_ML_USER_BEHAVIOR AS  
SELECT 
    'NATIVE_ML' as model_type,
    'USER_BEHAVIOR' as model_subtype,
    username,
    date_ts as timestamp,
    daily_logins,
    active_hours,
    unique_ips_daily,
    countries_daily,
    forecast as expected_daily_logins,
    is_anomaly as native_anomaly,
    anomaly_score as native_confidence,
    CASE 
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.8 THEN 'CRITICAL'
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.6 THEN 'HIGH' 
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END as ml_risk_level,
    lower_bound,
    upper_bound
FROM TABLE(
    native_user_behavior!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$QUERY_HISTORY(
            'SELECT username,
                    DATE(timestamp) as date_ts,
                    COUNT(*) as daily_logins,
                    COUNT(DISTINCT EXTRACT(HOUR FROM timestamp)) as active_hours,
                    COUNT(DISTINCT source_ip) as unique_ips_daily,
                    COUNT(DISTINCT location:country::STRING) as countries_daily
             FROM USER_AUTHENTICATION_LOGS 
             WHERE timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
               AND success = TRUE
               AND username IS NOT NULL
             GROUP BY 1, 2 ORDER BY 1, 2'
        ),
        TIMESTAMP_COLNAME => 'DATE_TS',
        TARGET_COLNAME => 'DAILY_LOGINS'
    )
)
WHERE date_ts >= DATEADD(day, -30, CURRENT_TIMESTAMP());

-- View 3: Native ML network traffic anomalies
CREATE OR REPLACE VIEW NATIVE_ML_NETWORK_PATTERNS AS
SELECT 
    'NATIVE_ML' as model_type,
    'NETWORK_TRAFFIC' as model_subtype,
    ts as timestamp,
    total_bytes,
    connection_count,
    unique_sources,
    forecast as expected_bytes,
    is_anomaly as native_anomaly,
    anomaly_score as native_confidence,
    CASE 
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.8 THEN 'CRITICAL'
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.6 THEN 'HIGH'
        WHEN is_anomaly = TRUE AND anomaly_score >= 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END as ml_risk_level,
    lower_bound,
    upper_bound
FROM TABLE(
    native_network_patterns!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$QUERY_HISTORY(
            'SELECT DATE_TRUNC(\'hour\', timestamp) as ts,
                    SUM(bytes_transferred) as total_bytes,
                    COUNT(*) as connection_count,
                    COUNT(DISTINCT source_ip) as unique_sources
             FROM NETWORK_SECURITY_LOGS
             WHERE timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
             GROUP BY 1 ORDER BY 1'
        ),
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME => 'TOTAL_BYTES'
    )
)
WHERE ts >= DATEADD(day, -30, CURRENT_TIMESTAMP());

-- =====================================================
-- SNOWPARK ML PLACEHOLDER VIEWS (Option 2)
-- Note: These require Snowpark ML models to be trained and deployed as UDFs
-- =====================================================

-- Placeholder view for Snowpark ML user clustering results
CREATE OR REPLACE VIEW SNOWPARK_ML_USER_CLUSTERS AS
WITH user_features AS (
    SELECT 
        username,
        AVG(EXTRACT(HOUR FROM timestamp)) as avg_login_hour,
        STDDEV(EXTRACT(HOUR FROM timestamp)) as stddev_login_hour,
        COUNT(*) as total_logins,
        COUNT(DISTINCT DATE(timestamp)) as active_days,
        COUNT(DISTINCT source_ip) as unique_ips,
        COUNT(DISTINCT location:country::STRING) as countries,
        AVG(CASE WHEN EXTRACT(DOW FROM timestamp) IN (0,6) THEN 1.0 ELSE 0.0 END) as weekend_ratio,
        AVG(CASE WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 22 AND 6 THEN 1.0 ELSE 0.0 END) as offhours_ratio
    FROM USER_AUTHENTICATION_LOGS
    WHERE timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
      AND username IS NOT NULL
      AND success = TRUE
    GROUP BY username
)
SELECT 
    'SNOWPARK_ML' as model_type,
    'USER_CLUSTERING' as model_subtype,
    username,
    CURRENT_TIMESTAMP() as timestamp,
    avg_login_hour,
    stddev_login_hour,
    total_logins,
    active_days,
    unique_ips,
    countries,
    weekend_ratio,
    offhours_ratio,
    -- Simulated clustering results (would be replaced by actual UDF calls)
    CASE 
        WHEN countries > 3 AND offhours_ratio > 0.3 AND unique_ips > 10 THEN 0
        WHEN avg_login_hour BETWEEN 8 AND 18 AND weekend_ratio < 0.1 AND countries <= 2 THEN 1
        WHEN weekend_ratio > 0.4 AND avg_login_hour NOT BETWEEN 8 AND 18 THEN 2
        WHEN offhours_ratio > 0.5 THEN 3
        WHEN countries > 2 AND unique_ips > 5 THEN 4
        ELSE 5
    END as user_cluster,
    -- Simulated anomaly scores (would be replaced by actual Isolation Forest UDF)
    CASE 
        WHEN countries > 3 AND offhours_ratio > 0.3 AND unique_ips > 10 THEN -0.6
        WHEN countries > 2 AND unique_ips > 5 THEN -0.4
        WHEN offhours_ratio > 0.5 THEN -0.3
        WHEN stddev_login_hour > 4 THEN -0.2
        ELSE UNIFORM(-0.1, 0.1, RANDOM())
    END as isolation_forest_score,
    CASE 
        WHEN countries > 3 AND offhours_ratio > 0.3 AND unique_ips > 10 THEN TRUE
        WHEN countries > 2 AND unique_ips > 5 THEN TRUE
        ELSE FALSE
    END as snowpark_anomaly,
    CASE 
        WHEN countries > 3 AND offhours_ratio > 0.3 AND unique_ips > 10 THEN 'HIGH_RISK_TRAVELER'
        WHEN avg_login_hour BETWEEN 8 AND 18 AND weekend_ratio < 0.1 AND countries <= 2 THEN 'REGULAR_BUSINESS_USER'
        WHEN weekend_ratio > 0.4 AND avg_login_hour NOT BETWEEN 8 AND 18 THEN 'WEEKEND_USER'
        WHEN offhours_ratio > 0.5 THEN 'NIGHT_SHIFT_USER'
        WHEN countries > 2 AND unique_ips > 5 THEN 'MULTI_LOCATION_USER'
        ELSE 'STANDARD_USER'
    END as cluster_label
FROM user_features;

-- =====================================================
-- HYBRID ML ANALYSIS VIEWS (Combining Both Approaches)
-- =====================================================

-- Combined ML model comparison and agreement analysis
CREATE OR REPLACE VIEW ML_MODEL_COMPARISON AS
SELECT 
    COALESCE(n.username, s.username) as username,
    COALESCE(DATE(n.timestamp), DATE(s.timestamp)) as analysis_date,
    
    -- Native ML results
    n.native_confidence,
    n.native_anomaly,
    n.ml_risk_level as native_risk_level,
    n.expected_daily_logins,
    n.daily_logins as actual_daily_logins,
    
    -- Snowpark ML results  
    s.isolation_forest_score as snowpark_score,
    s.snowpark_anomaly,
    s.user_cluster,
    s.cluster_label,
    
    -- Agreement analysis
    CASE 
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE THEN 'BOTH_AGREE_ANOMALY'
        WHEN n.native_anomaly = FALSE AND s.snowpark_anomaly = FALSE THEN 'BOTH_AGREE_NORMAL'
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = FALSE THEN 'NATIVE_ONLY'
        WHEN n.native_anomaly = FALSE AND s.snowpark_anomaly = TRUE THEN 'SNOWPARK_ONLY'
        WHEN n.native_anomaly IS NULL AND s.snowpark_anomaly IS NOT NULL THEN 'SNOWPARK_ONLY'
        WHEN n.native_anomaly IS NOT NULL AND s.snowpark_anomaly IS NULL THEN 'NATIVE_ONLY'
        ELSE 'NO_DATA'
    END as model_agreement,
    
    -- Combined confidence score using both models
    CASE 
        WHEN n.native_confidence IS NOT NULL AND s.isolation_forest_score IS NOT NULL THEN
            (n.native_confidence + ABS(s.isolation_forest_score)) / 2
        WHEN n.native_confidence IS NOT NULL THEN n.native_confidence
        WHEN s.isolation_forest_score IS NOT NULL THEN ABS(s.isolation_forest_score)
        ELSE 0.5
    END as hybrid_confidence,
    
    -- Enhanced risk assessment combining both models
    CASE 
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE AND n.native_confidence >= 0.8 THEN 'CRITICAL_ML_CONFIRMED'
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE THEN 'HIGH_ML_CONFIRMED'
        WHEN n.native_anomaly = TRUE AND n.native_confidence >= 0.8 THEN 'CRITICAL_NATIVE_ML'
        WHEN s.snowpark_anomaly = TRUE AND ABS(s.isolation_forest_score) >= 0.5 THEN 'HIGH_SNOWPARK_ML'
        WHEN n.native_anomaly = TRUE OR s.snowpark_anomaly = TRUE THEN 'MEDIUM_ML_DETECTED'
        ELSE 'LOW_OR_NORMAL'
    END as hybrid_risk_assessment
    
FROM NATIVE_ML_USER_BEHAVIOR n
FULL OUTER JOIN SNOWPARK_ML_USER_CLUSTERS s 
    ON n.username = s.username AND DATE(n.timestamp) = DATE(s.timestamp)
WHERE COALESCE(DATE(n.timestamp), DATE(s.timestamp)) >= DATEADD(day, -7, CURRENT_TIMESTAMP());

-- =====================================================
-- 1. ENHANCED ANOMALY DETECTION (Original + ML Enhanced)
-- =====================================================

-- User behavior baseline (normal patterns)
CREATE OR REPLACE VIEW USER_BEHAVIOR_BASELINE AS
SELECT 
    USERNAME,
    EXTRACT(HOUR FROM TIMESTAMP) as login_hour,
    EXTRACT(DOW FROM TIMESTAMP) as login_dow,
    LOCATION:country::STRING as country,
    COUNT(*) as frequency
FROM USER_AUTHENTICATION_LOGS
WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    AND SUCCESS = TRUE
    AND USERNAME IS NOT NULL
GROUP BY USERNAME, EXTRACT(HOUR FROM TIMESTAMP), EXTRACT(DOW FROM TIMESTAMP), LOCATION:country::STRING;

-- Real-time anomaly detection using statistical analysis
CREATE OR REPLACE VIEW LOGIN_ANOMALY_DETECTION AS
WITH user_stats AS (
    SELECT 
        USERNAME,
        ARRAY_AGG(DISTINCT EXTRACT(HOUR FROM TIMESTAMP)) as typical_hours,
        ARRAY_AGG(DISTINCT LOCATION:country::STRING) as typical_countries
    FROM USER_AUTHENTICATION_LOGS
    WHERE TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND SUCCESS = TRUE
    GROUP BY USERNAME
),
recent_logins AS (
    SELECT 
        ual.*,
        EXTRACT(HOUR FROM ual.TIMESTAMP) as current_hour,
        EXTRACT(DOW FROM ual.TIMESTAMP) as current_dow,
        ual.LOCATION:country::STRING as current_country,
        -- Check if IP is in threat intel
        CASE WHEN ti.INDICATOR_VALUE IS NOT NULL THEN 1 ELSE 0 END as threat_intel_match
    FROM USER_AUTHENTICATION_LOGS ual
    LEFT JOIN THREAT_INTEL_FEED ti ON ual.SOURCE_IP = ti.INDICATOR_VALUE AND ti.INDICATOR_TYPE = 'ip'
    WHERE ual.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
)
SELECT 
    rl.*,
    -- Anomaly scoring
    (CASE WHEN NOT ARRAY_CONTAINS(rl.current_hour::VARIANT, us.typical_hours) THEN 3.0 ELSE 0.0 END +
     CASE WHEN NOT ARRAY_CONTAINS(rl.current_country::VARIANT, us.typical_countries) THEN 5.0 ELSE 0.0 END +
     CASE WHEN rl.threat_intel_match = 1 THEN 8.0 ELSE 0.0 END +
     CASE WHEN rl.current_dow IN (0, 6) AND rl.current_hour BETWEEN 22 AND 6 THEN 2.0 ELSE 0.0 END +
     CASE WHEN ed.STATUS = 'terminated' THEN 10.0 ELSE 0.0 END) as anomaly_score,
    
    -- Risk classification
    CASE 
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(rl.current_hour::VARIANT, us.typical_hours) THEN 3.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(rl.current_country::VARIANT, us.typical_countries) THEN 5.0 ELSE 0.0 END +
              CASE WHEN rl.threat_intel_match = 1 THEN 8.0 ELSE 0.0 END +
              CASE WHEN rl.current_dow IN (0, 6) AND rl.current_hour BETWEEN 22 AND 6 THEN 2.0 ELSE 0.0 END +
              CASE WHEN ed.STATUS = 'terminated' THEN 10.0 ELSE 0.0 END) >= 8.0 THEN 'CRITICAL'
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(rl.current_hour::VARIANT, us.typical_hours) THEN 3.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(rl.current_country::VARIANT, us.typical_countries) THEN 5.0 ELSE 0.0 END +
              CASE WHEN rl.threat_intel_match = 1 THEN 8.0 ELSE 0.0 END +
              CASE WHEN rl.current_dow IN (0, 6) AND rl.current_hour BETWEEN 22 AND 6 THEN 2.0 ELSE 0.0 END +
              CASE WHEN ed.STATUS = 'terminated' THEN 10.0 ELSE 0.0 END) >= 5.0 THEN 'HIGH'
        WHEN (CASE WHEN NOT ARRAY_CONTAINS(rl.current_hour::VARIANT, us.typical_hours) THEN 3.0 ELSE 0.0 END +
              CASE WHEN NOT ARRAY_CONTAINS(rl.current_country::VARIANT, us.typical_countries) THEN 5.0 ELSE 0.0 END +
              CASE WHEN rl.threat_intel_match = 1 THEN 8.0 ELSE 0.0 END +
              CASE WHEN rl.current_dow IN (0, 6) AND rl.current_hour BETWEEN 22 AND 6 THEN 2.0 ELSE 0.0 END +
              CASE WHEN ed.STATUS = 'terminated' THEN 10.0 ELSE 0.0 END) >= 2.0 THEN 'MEDIUM'
        ELSE 'LOW'
    END as risk_level,
    
    -- Anomaly indicators
    ARRAY_CONSTRUCT_COMPACT(
        CASE WHEN NOT ARRAY_CONTAINS(rl.current_hour::VARIANT, us.typical_hours) THEN 'unusual_time' END,
        CASE WHEN NOT ARRAY_CONTAINS(rl.current_country::VARIANT, us.typical_countries) THEN 'unusual_location' END,
        CASE WHEN rl.threat_intel_match = 1 THEN 'threat_intel_match' END,
        CASE WHEN rl.current_dow IN (0, 6) AND rl.current_hour BETWEEN 22 AND 6 THEN 'off_hours' END,
        CASE WHEN ed.STATUS = 'terminated' THEN 'terminated_employee' END
    ) as anomaly_indicators
    
FROM recent_logins rl
LEFT JOIN user_stats us ON rl.USERNAME = us.USERNAME
LEFT JOIN EMPLOYEE_DATA ed ON rl.USERNAME = ed.USERNAME;

-- =====================================================
-- 2. THREAT PRIORITIZATION using ML scoring
-- =====================================================

CREATE OR REPLACE VIEW THREAT_PRIORITIZATION_SCORING AS
WITH threat_context AS (
    SELECT 
        si.*,
        -- Asset criticality score
        CASE 
            WHEN ARRAY_CONTAINS('database-server-01'::VARIANT, si.AFFECTED_SYSTEMS) THEN 10
            WHEN ARRAY_CONTAINS('web-server-01'::VARIANT, si.AFFECTED_SYSTEMS) THEN 8
            WHEN ARRAY_CONTAINS('file-server-01'::VARIANT, si.AFFECTED_SYSTEMS) THEN 6
            ELSE 4
        END as asset_criticality_score,
        
        -- Threat intel correlation (simplified for demo)
        2 as threat_intel_matches,
        
        -- Historical impact analysis
        CASE 
            WHEN si.SEVERITY = 'critical' THEN 10
            WHEN si.SEVERITY = 'high' THEN 7
            WHEN si.SEVERITY = 'medium' THEN 4
            ELSE 2
        END as severity_multiplier,
        
        -- Time criticality (recency)
        CASE 
            WHEN si.CREATED_AT >= DATEADD(hour, -4, CURRENT_TIMESTAMP()) THEN 3.0
            WHEN si.CREATED_AT >= DATEADD(hour, -24, CURRENT_TIMESTAMP()) THEN 2.0
            WHEN si.CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP()) THEN 1.0
            ELSE 0.5
        END as time_decay_factor
    FROM SECURITY_INCIDENTS si
)
SELECT 
    *,
    -- ML-based priority score (0-100)
    LEAST(100, 
        (asset_criticality_score * 0.3 + 
         threat_intel_matches * 2.0 + 
         severity_multiplier * 0.4 + 
         COALESCE(ESTIMATED_IMPACT_SCORE, 5) * 0.2) * time_decay_factor
    ) as ml_priority_score,
    
    -- Priority classification
    CASE 
        WHEN LEAST(100, 
            (asset_criticality_score * 0.3 + 
             threat_intel_matches * 2.0 + 
             severity_multiplier * 0.4 + 
             COALESCE(ESTIMATED_IMPACT_SCORE, 5) * 0.2) * time_decay_factor
        ) >= 80 THEN 'P0_CRITICAL'
        WHEN LEAST(100, 
            (asset_criticality_score * 0.3 + 
             threat_intel_matches * 2.0 + 
             severity_multiplier * 0.4 + 
             COALESCE(ESTIMATED_IMPACT_SCORE, 5) * 0.2) * time_decay_factor
        ) >= 60 THEN 'P1_HIGH'
        WHEN LEAST(100, 
            (asset_criticality_score * 0.3 + 
             threat_intel_matches * 2.0 + 
             severity_multiplier * 0.4 + 
             COALESCE(ESTIMATED_IMPACT_SCORE, 5) * 0.2) * time_decay_factor
        ) >= 40 THEN 'P2_MEDIUM'
        ELSE 'P3_LOW'
    END as priority_classification
FROM threat_context;

-- =====================================================
-- 3. VULNERABILITY PRIORITIZATION with CVSS and Context
-- =====================================================

CREATE OR REPLACE VIEW VULNERABILITY_PRIORITIZATION AS
WITH vuln_context AS (
    SELECT 
        vs.*,
        -- Asset exposure calculation
        CASE 
            WHEN vs.ASSET_NAME LIKE '%web-server%' THEN 10 -- Internet-facing
            WHEN vs.ASSET_NAME LIKE '%database%' THEN 9    -- Critical data
            WHEN vs.ASSET_NAME LIKE '%file-server%' THEN 7 -- Internal file storage
            WHEN vs.ASSET_NAME LIKE '%laptop%' THEN 5      -- Endpoint
            ELSE 6
        END as asset_exposure_score,
        
        -- Exploit availability (simulated)
        CASE 
            WHEN vs.CVE_ID IN ('CVE-2021-44228', 'CVE-2021-34527') THEN 10 -- Known exploits
            WHEN vs.CVSS_SCORE >= 9.0 THEN 8
            WHEN vs.CVSS_SCORE >= 7.0 THEN 6
            ELSE 3
        END as exploit_availability_score,
        
        -- Age factor (older = higher risk)
        CASE 
            WHEN DATEDIFF(day, vs.FIRST_DETECTED, CURRENT_DATE()) > 60 THEN 3.0
            WHEN DATEDIFF(day, vs.FIRST_DETECTED, CURRENT_DATE()) > 30 THEN 2.0
            WHEN DATEDIFF(day, vs.FIRST_DETECTED, CURRENT_DATE()) > 7 THEN 1.5
            ELSE 1.0
        END as age_multiplier,
        
        -- Threat intel correlation (simplified for demo)
        1 as threat_intel_mentions
    FROM VULNERABILITY_SCANS vs
)
SELECT 
    *,
    -- Enhanced priority score
    LEAST(100, 
        (vs.CVSS_SCORE * 0.4 + 
         asset_exposure_score * 0.25 + 
         exploit_availability_score * 0.2 + 
         threat_intel_mentions * 0.15) * age_multiplier
    ) as enhanced_priority_score,
    
    -- AI-based recommendation
    CASE 
        WHEN LEAST(100, 
            (vs.CVSS_SCORE * 0.4 + 
             asset_exposure_score * 0.25 + 
             exploit_availability_score * 0.2 + 
             threat_intel_mentions * 0.15) * age_multiplier
        ) >= 85 THEN 'PATCH_IMMEDIATELY'
        WHEN LEAST(100, 
            (vs.CVSS_SCORE * 0.4 + 
             asset_exposure_score * 0.25 + 
             exploit_availability_score * 0.2 + 
             threat_intel_mentions * 0.15) * age_multiplier
        ) >= 70 THEN 'PATCH_THIS_WEEK'
        WHEN LEAST(100, 
            (vs.CVSS_SCORE * 0.4 + 
             asset_exposure_score * 0.25 + 
             exploit_availability_score * 0.2 + 
             threat_intel_mentions * 0.15) * age_multiplier
        ) >= 50 THEN 'PATCH_THIS_MONTH'
        ELSE 'PATCH_NEXT_CYCLE'
    END as ai_recommendation
FROM vuln_context vs;

-- =====================================================
-- 4. FRAUD DETECTION SCORING
-- =====================================================

CREATE OR REPLACE VIEW FRAUD_DETECTION_SCORING AS
WITH transaction_features AS (
    SELECT 
        ft.*,
        -- Velocity features
        COUNT(*) OVER (
            PARTITION BY ft.USER_ID 
            ORDER BY ft.TIMESTAMP 
            RANGE BETWEEN INTERVAL '1 HOUR' PRECEDING AND CURRENT ROW
        ) as transactions_last_hour,
        
        SUM(ft.AMOUNT) OVER (
            PARTITION BY ft.USER_ID 
            ORDER BY ft.TIMESTAMP 
            RANGE BETWEEN INTERVAL '24 HOUR' PRECEDING AND CURRENT ROW
        ) as amount_last_24h,
        
        -- Location features
        LAG(ft.LOCATION:country::STRING) OVER (
            PARTITION BY ft.USER_ID ORDER BY ft.TIMESTAMP
        ) as prev_country,
        
        -- Time features
        EXTRACT(HOUR FROM ft.TIMESTAMP) as transaction_hour,
        EXTRACT(DOW FROM ft.TIMESTAMP) as transaction_dow,
        
        -- Historical user behavior
        AVG(ft.AMOUNT) OVER (
            PARTITION BY ft.USER_ID 
            ORDER BY ft.TIMESTAMP 
            ROWS BETWEEN 100 PRECEDING AND 1 PRECEDING
        ) as avg_historical_amount
    FROM FINANCIAL_TRANSACTIONS ft
)
SELECT 
    *,
    -- ML fraud score calculation
    LEAST(1.0, GREATEST(0.0,
        -- Base risk factors
        (CASE WHEN transactions_last_hour > 5 THEN 0.3 ELSE 0.0 END) +
        (CASE WHEN amount_last_24h > 10000 THEN 0.25 ELSE 0.0 END) +
        (CASE WHEN LOCATION:country::STRING != 'US' THEN 0.2 ELSE 0.0 END) +
        (CASE WHEN prev_country != LOCATION:country::STRING AND prev_country IS NOT NULL THEN 0.15 ELSE 0.0 END) +
        (CASE WHEN transaction_hour BETWEEN 23 AND 5 THEN 0.1 ELSE 0.0 END) +
        (CASE WHEN AMOUNT > (avg_historical_amount * 10) THEN 0.2 ELSE 0.0 END) +
        (CASE WHEN DEVICE_FINGERPRINT = 'FP_UNKNOWN' OR DEVICE_FINGERPRINT LIKE '%SUSPICIOUS%' THEN 0.15 ELSE 0.0 END)
    )) as ml_fraud_score,
    
    -- Fraud classification
    CASE 
        WHEN LEAST(1.0, GREATEST(0.0,
            (CASE WHEN transactions_last_hour > 5 THEN 0.3 ELSE 0.0 END) +
            (CASE WHEN amount_last_24h > 10000 THEN 0.25 ELSE 0.0 END) +
            (CASE WHEN LOCATION:country::STRING != 'US' THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN prev_country != LOCATION:country::STRING AND prev_country IS NOT NULL THEN 0.15 ELSE 0.0 END) +
            (CASE WHEN transaction_hour BETWEEN 23 AND 5 THEN 0.1 ELSE 0.0 END) +
            (CASE WHEN AMOUNT > (avg_historical_amount * 10) THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN DEVICE_FINGERPRINT = 'FP_UNKNOWN' OR DEVICE_FINGERPRINT LIKE '%SUSPICIOUS%' THEN 0.15 ELSE 0.0 END)
        )) >= 0.8 THEN 'HIGH_RISK'
        WHEN LEAST(1.0, GREATEST(0.0,
            (CASE WHEN transactions_last_hour > 5 THEN 0.3 ELSE 0.0 END) +
            (CASE WHEN amount_last_24h > 10000 THEN 0.25 ELSE 0.0 END) +
            (CASE WHEN LOCATION:country::STRING != 'US' THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN prev_country != LOCATION:country::STRING AND prev_country IS NOT NULL THEN 0.15 ELSE 0.0 END) +
            (CASE WHEN transaction_hour BETWEEN 23 AND 5 THEN 0.1 ELSE 0.0 END) +
            (CASE WHEN AMOUNT > (avg_historical_amount * 10) THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN DEVICE_FINGERPRINT = 'FP_UNKNOWN' OR DEVICE_FINGERPRINT LIKE '%SUSPICIOUS%' THEN 0.15 ELSE 0.0 END)
        )) >= 0.5 THEN 'MEDIUM_RISK'
        WHEN LEAST(1.0, GREATEST(0.0,
            (CASE WHEN transactions_last_hour > 5 THEN 0.3 ELSE 0.0 END) +
            (CASE WHEN amount_last_24h > 10000 THEN 0.25 ELSE 0.0 END) +
            (CASE WHEN LOCATION:country::STRING != 'US' THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN prev_country != LOCATION:country::STRING AND prev_country IS NOT NULL THEN 0.15 ELSE 0.0 END) +
            (CASE WHEN transaction_hour BETWEEN 23 AND 5 THEN 0.1 ELSE 0.0 END) +
            (CASE WHEN AMOUNT > (avg_historical_amount * 10) THEN 0.2 ELSE 0.0 END) +
            (CASE WHEN DEVICE_FINGERPRINT = 'FP_UNKNOWN' OR DEVICE_FINGERPRINT LIKE '%SUSPICIOUS%' THEN 0.15 ELSE 0.0 END)
        )) >= 0.3 THEN 'LOW_RISK'
        ELSE 'NORMAL'
    END as fraud_classification
FROM transaction_features;

-- =====================================================
-- 5. ROOT CAUSE ANALYSIS - Anomaly Correlation
-- =====================================================

CREATE OR REPLACE VIEW ROOT_CAUSE_ANALYSIS AS
WITH incident_timeline AS (
    SELECT 
        si.INCIDENT_ID,
        si.CREATED_AT,
        si.SEVERITY,
        si.AFFECTED_SYSTEMS,
        -- Network events around incident time - simplified
        5 as network_events_2h_before,
        
        -- Login anomalies around incident time - simplified
        2 as login_anomalies_2h_before,
        
        -- Vulnerability context - simplified
        1 as open_vulns_on_affected_systems,
        
        -- Data access patterns - simplified
        3 as large_data_access_4h_before
         
    FROM SECURITY_INCIDENTS si
)
SELECT 
    *,
    -- Root cause likelihood scoring
    CASE 
        WHEN open_vulns_on_affected_systems > 0 AND network_events_2h_before > 5 THEN 'LIKELY_EXPLOITATION'
        WHEN login_anomalies_2h_before > 0 AND large_data_access_4h_before > 0 THEN 'LIKELY_INSIDER_THREAT'
        WHEN network_events_2h_before > 10 THEN 'LIKELY_EXTERNAL_ATTACK'
        WHEN large_data_access_4h_before > 0 THEN 'LIKELY_DATA_EXFILTRATION'
        ELSE 'REQUIRES_INVESTIGATION'
    END as likely_root_cause,
    
    -- Confidence score
    CASE 
        WHEN (open_vulns_on_affected_systems + network_events_2h_before + login_anomalies_2h_before) > 5 THEN 'HIGH_CONFIDENCE'
        WHEN (open_vulns_on_affected_systems + network_events_2h_before + login_anomalies_2h_before) > 2 THEN 'MEDIUM_CONFIDENCE'
        ELSE 'LOW_CONFIDENCE'
    END as confidence_level
FROM incident_timeline;

-- =====================================================
-- 6. INSIDER THREAT DETECTION
-- =====================================================

CREATE OR REPLACE VIEW INSIDER_THREAT_DETECTION AS
WITH user_risk_factors AS (
    SELECT 
        ed.USERNAME,
        ed.DEPARTMENT,
        ed.STATUS,
        -- Behavioral anomalies
        (SELECT COUNT(*) FROM LOGIN_ANOMALY_DETECTION lad 
         WHERE lad.USERNAME = ed.USERNAME 
         AND lad.TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
         AND lad.risk_level IN ('HIGH', 'CRITICAL')) as login_anomalies_30d,
        
        -- Unusual data access
        (SELECT SUM(dal.BYTES_ACCESSED) FROM DATA_ACCESS_LOGS dal 
         WHERE dal.USERNAME = ed.USERNAME 
         AND dal.TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())) as total_data_accessed_30d,
        
        -- Average baseline data access (simplified for demo)
        (SELECT AVG(dal2.BYTES_ACCESSED) FROM DATA_ACCESS_LOGS dal2 
         WHERE dal2.USERNAME = ed.USERNAME 
         AND dal2.TIMESTAMP BETWEEN DATEADD(day, -90, CURRENT_TIMESTAMP()) AND DATEADD(day, -30, CURRENT_TIMESTAMP())) as avg_daily_data_access,
        
        -- Off-hours activity
        (SELECT COUNT(*) FROM DATA_ACCESS_LOGS dal3
         WHERE dal3.USERNAME = ed.USERNAME
         AND dal3.TIMESTAMP >= DATEADD(day, -30, CURRENT_TIMESTAMP())
         AND (EXTRACT(HOUR FROM dal3.TIMESTAMP) < 7 OR EXTRACT(HOUR FROM dal3.TIMESTAMP) > 19)) as off_hours_activity_30d
         
    FROM EMPLOYEE_DATA ed
)
SELECT 
    *,
    -- Insider threat risk score
    LEAST(100, 
        (CASE WHEN STATUS = 'terminated' THEN 50 ELSE 0 END) +
        (login_anomalies_30d * 5) +
        (CASE WHEN total_data_accessed_30d > (avg_daily_data_access * 30 * 3) THEN 20 ELSE 0 END) +
        (off_hours_activity_30d * 2)
    ) as insider_threat_score,
    
    -- Risk classification
    CASE 
        WHEN LEAST(100, 
            (CASE WHEN STATUS = 'terminated' THEN 50 ELSE 0 END) +
            (login_anomalies_30d * 5) +
            (CASE WHEN total_data_accessed_30d > (avg_daily_data_access * 30 * 3) THEN 20 ELSE 0 END) +
            (off_hours_activity_30d * 2)
        ) >= 70 THEN 'HIGH_RISK'
        WHEN LEAST(100, 
            (CASE WHEN STATUS = 'terminated' THEN 50 ELSE 0 END) +
            (login_anomalies_30d * 5) +
            (CASE WHEN total_data_accessed_30d > (avg_daily_data_access * 30 * 3) THEN 20 ELSE 0 END) +
            (off_hours_activity_30d * 2)
        ) >= 40 THEN 'MEDIUM_RISK'
        WHEN LEAST(100, 
            (CASE WHEN STATUS = 'terminated' THEN 50 ELSE 0 END) +
            (login_anomalies_30d * 5) +
            (CASE WHEN total_data_accessed_30d > (avg_daily_data_access * 30 * 3) THEN 20 ELSE 0 END) +
            (off_hours_activity_30d * 2)
        ) >= 20 THEN 'LOW_RISK'
        ELSE 'NORMAL'
    END as insider_threat_classification
FROM user_risk_factors;

-- =====================================================
-- SECURITY SUMMARY DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW SECURITY_DASHBOARD_SUMMARY AS
SELECT 
    -- Current timestamp
    CURRENT_TIMESTAMP() as dashboard_updated_at,
    
    -- Anomaly detection metrics
    (SELECT COUNT(*) FROM LOGIN_ANOMALY_DETECTION WHERE risk_level = 'CRITICAL') as critical_login_anomalies,
    (SELECT COUNT(*) FROM LOGIN_ANOMALY_DETECTION WHERE risk_level = 'HIGH') as high_risk_login_anomalies,
    
    -- Threat prioritization
    (SELECT COUNT(*) FROM THREAT_PRIORITIZATION_SCORING WHERE priority_classification = 'P0_CRITICAL') as p0_incidents,
    (SELECT COUNT(*) FROM THREAT_PRIORITIZATION_SCORING WHERE priority_classification = 'P1_HIGH') as p1_incidents,
    
    -- Vulnerability metrics
    (SELECT COUNT(*) FROM VULNERABILITY_PRIORITIZATION WHERE ai_recommendation = 'PATCH_IMMEDIATELY') as critical_vulns,
    (SELECT COUNT(*) FROM VULNERABILITY_PRIORITIZATION WHERE STATUS = 'open') as total_open_vulns,
    
    -- Fraud detection
    (SELECT COUNT(*) FROM FRAUD_DETECTION_SCORING WHERE fraud_classification = 'HIGH_RISK') as high_risk_transactions,
    (SELECT SUM(AMOUNT) FROM FRAUD_DETECTION_SCORING WHERE fraud_classification IN ('HIGH_RISK', 'MEDIUM_RISK')) as suspicious_transaction_amount,
    
    -- Insider threats
    (SELECT COUNT(*) FROM INSIDER_THREAT_DETECTION WHERE insider_threat_classification = 'HIGH_RISK') as high_risk_insiders,
    
    -- Threat intel matches
    (SELECT COUNT(*) FROM LOGIN_ANOMALY_DETECTION WHERE ARRAY_CONTAINS('threat_intel_match'::VARIANT, anomaly_indicators)) as threat_intel_matches_today;

COMMIT;
