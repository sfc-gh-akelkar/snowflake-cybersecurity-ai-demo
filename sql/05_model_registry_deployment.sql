-- =====================================================
-- SNOWFLAKE MODEL REGISTRY INTEGRATION
-- Enhanced ML deployment using Snowflake Model Registry
-- Replaces manual UDF creation with Registry-managed models
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. MODEL REGISTRY VIEWS AND FUNCTIONS
-- =====================================================

-- Create view to show registered models
CREATE OR REPLACE VIEW MODEL_REGISTRY_OVERVIEW AS
SELECT 
    'Model Registry Status' as status,
    'Use: SHOW MODELS IN MODEL REGISTRY' as instruction,
    'Benefits: Versioning, Metadata, Governance' as benefits;

-- =====================================================
-- 2. ENHANCED SNOWPARK ML VIEWS WITH REGISTRY MODELS
-- =====================================================

-- Updated view to use Model Registry deployed UDFs
CREATE OR REPLACE VIEW SNOWPARK_ML_USER_CLUSTERS_REGISTRY AS
WITH user_features AS (
    SELECT 
        username,
        AVG(EXTRACT(HOUR FROM timestamp)) as avg_login_hour,
        COALESCE(STDDEV(EXTRACT(HOUR FROM timestamp)), 0) as stddev_login_hour,
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
    HAVING COUNT(*) >= 5  -- Minimum activity for meaningful ML analysis
)
SELECT 
    'SNOWPARK_ML_REGISTRY' as model_type,
    'USER_CLUSTERING_REGISTRY' as model_subtype,
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
    
    -- MODEL REGISTRY DEPLOYED UDF CALLS
    -- These UDFs are automatically created by the Model Registry
    CYBERSECURITY_ISOLATION_FOREST_PREDICT(
        avg_login_hour, stddev_login_hour, unique_ips, 
        countries, weekend_ratio, offhours_ratio
    ) as isolation_forest_score,
    
    CYBERSECURITY_KMEANS_PREDICT(
        avg_login_hour, countries, weekend_ratio, 
        offhours_ratio, unique_ips
    ) as user_cluster,
    
    -- Enhanced anomaly detection logic
    CASE 
        WHEN CYBERSECURITY_ISOLATION_FOREST_PREDICT(
            avg_login_hour, stddev_login_hour, unique_ips, 
            countries, weekend_ratio, offhours_ratio
        ) < -0.3 THEN TRUE
        ELSE FALSE
    END as snowpark_anomaly,
    
    -- Cluster interpretation
    CASE CYBERSECURITY_KMEANS_PREDICT(
        avg_login_hour, countries, weekend_ratio, 
        offhours_ratio, unique_ips
    )
        WHEN 0 THEN 'BUSINESS_HOURS_REGULAR'
        WHEN 1 THEN 'INTERNATIONAL_ACCESS'
        WHEN 2 THEN 'WEEKEND_WORKER'
        WHEN 3 THEN 'OFF_HOURS_FREQUENT'
        WHEN 4 THEN 'MULTI_LOCATION_USER'
        ELSE 'HIGH_ACTIVITY_USER'
    END as cluster_label
FROM user_features;

-- =====================================================
-- 3. MODEL REGISTRY METADATA QUERIES
-- =====================================================

-- View to show model registry metadata
CREATE OR REPLACE VIEW MODEL_REGISTRY_METADATA AS
WITH model_info AS (
    SELECT 
        'cybersecurity_isolation_forest' as model_name,
        'Anomaly Detection' as model_type,
        'Production-ready Isolation Forest for cybersecurity anomaly detection' as description,
        'sklearn.ensemble.IsolationForest' as algorithm,
        '0.1 contamination, 100 estimators' as parameters
    
    UNION ALL
    
    SELECT 
        'cybersecurity_kmeans_clustering' as model_name,
        'Clustering' as model_type,
        'User behavior clustering for cybersecurity analysis' as description,
        'sklearn.cluster.KMeans' as algorithm,
        '6 clusters, 10 init' as parameters
        
    UNION ALL
    
    SELECT 
        'cybersecurity_isolation_scaler' as model_name,
        'Preprocessor' as model_type,
        'Feature scaling for Isolation Forest model' as description,
        'sklearn.preprocessing.StandardScaler' as algorithm,
        'Standard scaling with mean=0, std=1' as parameters
        
    UNION ALL
    
    SELECT 
        'cybersecurity_kmeans_scaler' as model_name,
        'Preprocessor' as model_type,
        'Feature scaling for K-means clustering' as description,
        'sklearn.preprocessing.StandardScaler' as algorithm,
        'Standard scaling with mean=0, std=1' as parameters
)
SELECT 
    model_name,
    model_type,
    description,
    algorithm,
    parameters,
    'Use SHOW MODELS IN MODEL REGISTRY for full details' as registry_query
FROM model_info;

-- =====================================================
-- 4. ENHANCED ML MODEL COMPARISON WITH REGISTRY
-- =====================================================

-- Enhanced ML comparison using Registry models
CREATE OR REPLACE VIEW ML_MODEL_COMPARISON_REGISTRY AS
WITH recent_logins_with_threat_intel AS (
    SELECT 
        ual.username,
        DATE(ual.timestamp) as analysis_date,
        EXTRACT(HOUR FROM ual.timestamp) as current_hour,
        ual.location:country::STRING as current_country,
        ual.source_ip,
        -- Check if IP is in threat intel
        CASE WHEN ti.INDICATOR_VALUE IS NOT NULL THEN 1 ELSE 0 END as threat_intel_match,
        -- Create anomaly indicators array for compatibility
        ARRAY_CONSTRUCT_COMPACT(
            CASE WHEN ti.INDICATOR_VALUE IS NOT NULL THEN 'threat_intel_match' END
        ) as anomaly_indicators
    FROM USER_AUTHENTICATION_LOGS ual
    LEFT JOIN THREAT_INTEL_FEED ti ON ual.SOURCE_IP = ti.INDICATOR_VALUE AND ti.INDICATOR_TYPE = 'ip'
    WHERE ual.TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP())
      AND ual.SUCCESS = TRUE
)
SELECT 
    COALESCE(n.username, s.username, rl.username) as username,
    COALESCE(DATE(n.timestamp), DATE(s.timestamp), rl.analysis_date) as analysis_date,
    
    -- Native ML results
    n.native_confidence,
    n.native_anomaly,
    n.ml_risk_level as native_risk_level,
    n.expected_daily_logins,
    n.daily_logins as actual_daily_logins,
    
    -- MODEL REGISTRY Snowpark ML results
    s.isolation_forest_score as snowpark_score,
    s.snowpark_anomaly,
    s.user_cluster,
    s.cluster_label,
    
    -- Threat Intelligence enrichment
    rl.current_hour,
    rl.current_country,
    rl.source_ip,
    rl.threat_intel_match,
    rl.anomaly_indicators,
    
    -- Agreement analysis between real models
    CASE 
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE THEN 'BOTH_AGREE_ANOMALY'
        WHEN n.native_anomaly = FALSE AND s.snowpark_anomaly = FALSE THEN 'BOTH_AGREE_NORMAL'
        WHEN n.native_anomaly = TRUE AND s.snowpark_anomaly = FALSE THEN 'NATIVE_ONLY'
        WHEN n.native_anomaly = FALSE AND s.snowpark_anomaly = TRUE THEN 'SNOWPARK_ONLY'
        WHEN n.native_anomaly IS NULL AND s.snowpark_anomaly IS NOT NULL THEN 'SNOWPARK_ONLY'
        WHEN n.native_anomaly IS NOT NULL AND s.snowpark_anomaly IS NULL THEN 'NATIVE_ONLY'
        ELSE 'NO_DATA'
    END as model_agreement,
    
    -- Enhanced risk assessment using Registry models
    CASE 
        -- CRITICAL: Both models strongly agree it's an anomaly
        WHEN (n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE) 
             AND (n.native_confidence >= 0.8 OR ABS(s.isolation_forest_score) >= 0.6) THEN 'CRITICAL'
        
        -- HIGH: One model has very high confidence OR both models agree with moderate confidence
        WHEN (n.native_confidence >= 0.9) 
             OR (ABS(s.isolation_forest_score) >= 0.7)
             OR (n.native_anomaly = TRUE AND s.snowpark_anomaly = TRUE) THEN 'HIGH'
        
        -- MEDIUM: Single model detects with moderate confidence
        WHEN (n.native_anomaly = TRUE AND n.native_confidence >= 0.6)
             OR (s.snowpark_anomaly = TRUE AND ABS(s.isolation_forest_score) >= 0.4) THEN 'MEDIUM'
        
        -- LOW: Everything else (normal behavior or very weak signals)
        ELSE 'LOW'
    END as risk_level,
    
    -- Registry model metadata
    'MODEL_REGISTRY_V2' as ml_engine_version
    
FROM NATIVE_ML_USER_BEHAVIOR n
FULL OUTER JOIN SNOWPARK_ML_USER_CLUSTERS_REGISTRY s 
    ON n.username = s.username AND DATE(n.timestamp) = DATE(s.timestamp)
FULL OUTER JOIN recent_logins_with_threat_intel rl
    ON COALESCE(n.username, s.username) = rl.username 
    AND COALESCE(DATE(n.timestamp), DATE(s.timestamp)) = rl.analysis_date
WHERE COALESCE(DATE(n.timestamp), DATE(s.timestamp), rl.analysis_date) >= DATEADD(day, -7, CURRENT_TIMESTAMP());

-- =====================================================
-- 5. MODEL REGISTRY VALIDATION QUERIES
-- =====================================================

-- Query to validate Model Registry deployment
CREATE OR REPLACE VIEW MODEL_REGISTRY_VALIDATION AS
SELECT 
    'Model Registry Integration Status' as validation_type,
    'Run these queries to validate your Model Registry setup:' as instructions,
    
    ARRAY_CONSTRUCT(
        'SHOW MODELS IN MODEL REGISTRY',
        'SELECT * FROM MODEL_REGISTRY_METADATA',
        'SELECT * FROM SNOWPARK_ML_USER_CLUSTERS_REGISTRY LIMIT 5',
        'SELECT * FROM ML_MODEL_COMPARISON_REGISTRY LIMIT 5'
    ) as validation_queries,
    
    'Models should be deployed as UDFs: CYBERSECURITY_ISOLATION_FOREST_PREDICT, CYBERSECURITY_KMEANS_PREDICT' as expected_udfs;

-- =====================================================
-- DEPLOYMENT VALIDATION QUERIES
-- =====================================================

-- Test Model Registry UDF availability
-- Run these queries after training models:

-- 1. Check Model Registry models
-- SHOW MODELS IN MODEL REGISTRY;

-- 2. Test Isolation Forest UDF
-- SELECT CYBERSECURITY_ISOLATION_FOREST_PREDICT(14.5, 2.1, 3, 2, 0.1, 0.2) as anomaly_score;

-- 3. Test K-means UDF  
-- SELECT CYBERSECURITY_KMEANS_PREDICT(14.5, 2, 0.1, 0.2, 3) as user_cluster;

-- 4. Validate full pipeline
-- SELECT * FROM ML_MODEL_COMPARISON_REGISTRY LIMIT 10;

-- Note: UDF names may vary based on your Model Registry deployment
-- Use SHOW USER FUNCTIONS to see all available UDFs
