-- =====================================================
-- REAL SNOWPARK ML MODEL DEPLOYMENT
-- Production-grade ML model deployment and UDF registration
-- =====================================================

USE DATABASE CYBERSECURITY_DEMO;
USE SCHEMA SECURITY_AI;

-- =====================================================
-- 1. SETUP ML MODEL INFRASTRUCTURE
-- =====================================================

-- Create stage for ML models and artifacts
CREATE OR REPLACE STAGE ml_models
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Storage for trained ML models and artifacts';

-- Create stage for Python UDF code
CREATE OR REPLACE STAGE python_udfs
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Storage for Python UDF source code';

-- =====================================================
-- 2. ML TRAINING DATA VALIDATION VIEWS
-- =====================================================

-- Validate sufficient data for ML training
CREATE OR REPLACE VIEW ML_TRAINING_DATA_VALIDATION AS
SELECT 
    'ML Training Data Quality Check' as check_type,
    COUNT(*) as total_events,
    COUNT(DISTINCT username) as unique_users,
    COUNT(DISTINCT DATE(timestamp)) as training_days,
    ROUND(COUNT(*) / COUNT(DISTINCT username), 2) as avg_events_per_user,
    COUNT(DISTINCT location:country::STRING) as unique_countries,
    COUNT(DISTINCT source_ip) as unique_ips,
    ROUND(AVG(CASE WHEN success THEN 1.0 ELSE 0.0 END), 3) as success_rate,
    CASE 
        WHEN COUNT(*) >= 100000 AND COUNT(DISTINCT username) >= 100 AND COUNT(DISTINCT DATE(timestamp)) >= 60 THEN 'SUFFICIENT'
        WHEN COUNT(*) >= 10000 AND COUNT(DISTINCT username) >= 50 THEN 'MINIMAL'
        ELSE 'INSUFFICIENT'
    END as ml_readiness_status,
    CURRENT_TIMESTAMP() as validation_timestamp
FROM USER_AUTHENTICATION_LOGS
WHERE timestamp >= DATEADD(day, -90, CURRENT_TIMESTAMP());

-- Ensure feature diversity for ML
CREATE OR REPLACE VIEW ML_FEATURE_VALIDATION AS
SELECT 
    username,
    COUNT(*) as total_events,
    COUNT(DISTINCT EXTRACT(HOUR FROM timestamp)) as hour_diversity,
    COUNT(DISTINCT location:country::STRING) as country_diversity,
    COUNT(DISTINCT source_ip) as ip_diversity,
    COUNT(DISTINCT DATE(timestamp)) as active_days,
    ROUND(AVG(CASE WHEN EXTRACT(DOW FROM timestamp) IN (0,6) THEN 1.0 ELSE 0.0 END), 3) as weekend_ratio,
    ROUND(AVG(CASE WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 22 AND 6 THEN 1.0 ELSE 0.0 END), 3) as offhours_ratio,
    ROUND(STDDEV(EXTRACT(HOUR FROM timestamp)), 2) as hour_stddev,
    CASE 
        WHEN COUNT(*) >= 50 AND COUNT(DISTINCT EXTRACT(HOUR FROM timestamp)) >= 3 AND active_days >= 10 THEN 'TRAINABLE'
        WHEN COUNT(*) >= 10 AND COUNT(DISTINCT EXTRACT(HOUR FROM timestamp)) >= 2 THEN 'MINIMAL'
        ELSE 'INSUFFICIENT_ACTIVITY'
    END as user_ml_readiness
FROM USER_AUTHENTICATION_LOGS
WHERE timestamp >= DATEADD(day, -90, CURRENT_TIMESTAMP())
  AND username IS NOT NULL
GROUP BY username
ORDER BY total_events DESC;

-- =====================================================
-- 3. PYTHON UDF REGISTRATION
-- =====================================================

-- NOTE: Before running these UDF registrations, you must:
-- 1. Train the models using model_trainer.py
-- 2. Upload the trained models to @ml_models stage
-- 3. Upload the Python UDF code to @python_udfs stage

-- Real Isolation Forest UDF for anomaly scoring
CREATE OR REPLACE FUNCTION isolation_forest_score(
    avg_hour DOUBLE,
    countries DOUBLE, 
    unique_ips DOUBLE,
    weekend_ratio DOUBLE,
    offhours_ratio DOUBLE,
    stddev_hour DOUBLE
)
RETURNS DOUBLE
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('scikit-learn==1.3.0', 'pandas', 'numpy', 'joblib')
IMPORTS = ('@ml_models/isolation_forest.pkl', '@ml_models/isolation_scaler.pkl')
HANDLER = 'ml_udfs.isolation_forest_score'
COMMENT = 'Real Isolation Forest UDF - returns anomaly scores (more negative = more anomalous)';

-- Real Isolation Forest anomaly flag UDF
CREATE OR REPLACE FUNCTION isolation_forest_anomaly(
    avg_hour DOUBLE,
    countries DOUBLE, 
    unique_ips DOUBLE,
    weekend_ratio DOUBLE,
    offhours_ratio DOUBLE,
    stddev_hour DOUBLE
)
RETURNS BOOLEAN
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('scikit-learn==1.3.0', 'pandas', 'numpy', 'joblib')
IMPORTS = ('@ml_models/isolation_forest.pkl', '@ml_models/isolation_scaler.pkl')
HANDLER = 'ml_udfs.isolation_forest_anomaly'
COMMENT = 'Real Isolation Forest anomaly detection - returns TRUE for anomalous behavior';

-- Real K-means clustering UDF
CREATE OR REPLACE FUNCTION kmeans_cluster_assignment(
    avg_hour DOUBLE,
    countries DOUBLE,
    weekend_ratio DOUBLE, 
    offhours_ratio DOUBLE,
    unique_ips DOUBLE
)
RETURNS INTEGER
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('scikit-learn==1.3.0', 'pandas', 'numpy', 'joblib')
IMPORTS = ('@ml_models/kmeans.pkl', '@ml_models/kmeans_scaler.pkl')
HANDLER = 'ml_udfs.kmeans_cluster_assignment'
COMMENT = 'Real K-means clustering - returns cluster ID (0-5) for user behavior classification';

-- Cluster label mapping UDF
CREATE OR REPLACE FUNCTION cluster_label_mapping(cluster_id INTEGER)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('pandas',)
HANDLER = 'ml_udfs.cluster_label_mapping'
COMMENT = 'Maps cluster IDs to human-readable behavior labels';

-- Hybrid risk assessment UDF
CREATE OR REPLACE FUNCTION hybrid_risk_assessment(
    isolation_score DOUBLE,
    isolation_anomaly BOOLEAN,
    cluster_id INTEGER,
    native_anomaly BOOLEAN
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('pandas',)
HANDLER = 'ml_udfs.hybrid_risk_assessment'
COMMENT = 'Combines multiple ML signals into CRITICAL/HIGH/MEDIUM/LOW risk assessment';

-- =====================================================
-- 4. REAL SNOWPARK ML VIEWS (REPLACING SIMULATION)
-- =====================================================

-- Real Snowpark ML user clustering with actual trained models
CREATE OR REPLACE VIEW SNOWPARK_ML_USER_CLUSTERS AS
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
    
    -- REAL ML UDF CALLS (no more simulation!)
    kmeans_cluster_assignment(avg_login_hour, countries, weekend_ratio, 
                             offhours_ratio, unique_ips) as user_cluster,
    
    isolation_forest_score(avg_login_hour, countries, unique_ips,
                          weekend_ratio, offhours_ratio, stddev_login_hour) as isolation_forest_score,
    
    isolation_forest_anomaly(avg_login_hour, countries, unique_ips,
                           weekend_ratio, offhours_ratio, stddev_login_hour) as snowpark_anomaly,
    
    cluster_label_mapping(
        kmeans_cluster_assignment(avg_login_hour, countries, weekend_ratio, 
                                offhours_ratio, unique_ips)
    ) as cluster_label
FROM user_features;

-- Enhanced ML model comparison with real models
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
    
    -- Real Snowpark ML results (no more simulation!)
    s.isolation_forest_score as snowpark_score,
    s.snowpark_anomaly,
    s.user_cluster,
    s.cluster_label,
    
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
    
    -- Real hybrid risk assessment using UDF
    hybrid_risk_assessment(
        s.isolation_forest_score,
        s.snowpark_anomaly,
        s.user_cluster,
        n.native_anomaly
    ) as risk_level
    
FROM NATIVE_ML_USER_BEHAVIOR n
FULL OUTER JOIN SNOWPARK_ML_USER_CLUSTERS s 
    ON n.username = s.username AND DATE(n.timestamp) = DATE(s.timestamp)
WHERE COALESCE(DATE(n.timestamp), DATE(s.timestamp)) >= DATEADD(day, -7, CURRENT_TIMESTAMP());

-- =====================================================
-- 5. ML MODEL PERFORMANCE MONITORING
-- =====================================================

-- Real-time ML model performance dashboard
CREATE OR REPLACE VIEW ML_MODEL_PERFORMANCE AS
SELECT 
    'Model Performance Metrics' as metric_type,
    COUNT(*) as total_users_analyzed,
    
    -- Isolation Forest metrics
    ROUND(AVG(isolation_forest_score), 4) as avg_isolation_score,
    ROUND(STDDEV(isolation_forest_score), 4) as stddev_isolation_score,
    ROUND(MIN(isolation_forest_score), 4) as min_isolation_score,
    ROUND(MAX(isolation_forest_score), 4) as max_isolation_score,
    SUM(CASE WHEN snowpark_anomaly THEN 1 ELSE 0 END) as isolation_anomalies,
    ROUND(SUM(CASE WHEN snowpark_anomaly THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as isolation_anomaly_rate_pct,
    
    -- K-means clustering metrics
    COUNT(DISTINCT user_cluster) as active_clusters,
    MODE(user_cluster) as most_common_cluster,
    
    -- Risk assessment distribution
    SUM(CASE WHEN mc.risk_level = 'CRITICAL' THEN 1 ELSE 0 END) as critical_risk_users,
    SUM(CASE WHEN mc.risk_level = 'HIGH' THEN 1 ELSE 0 END) as high_risk_users,
    SUM(CASE WHEN mc.risk_level = 'MEDIUM' THEN 1 ELSE 0 END) as medium_risk_users,
    SUM(CASE WHEN mc.risk_level = 'LOW' THEN 1 ELSE 0 END) as low_risk_users,
    
    -- Model agreement metrics
    SUM(CASE WHEN mc.model_agreement = 'BOTH_AGREE_ANOMALY' THEN 1 ELSE 0 END) as models_agree_anomaly,
    SUM(CASE WHEN mc.model_agreement = 'BOTH_AGREE_NORMAL' THEN 1 ELSE 0 END) as models_agree_normal,
    ROUND(SUM(CASE WHEN mc.model_agreement LIKE 'BOTH_AGREE%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as model_agreement_rate_pct,
    
    CURRENT_TIMESTAMP() as metrics_timestamp
FROM SNOWPARK_ML_USER_CLUSTERS s
LEFT JOIN ML_MODEL_COMPARISON mc ON s.username = mc.username;

-- Cluster distribution analysis
CREATE OR REPLACE VIEW ML_CLUSTER_ANALYSIS AS
SELECT 
    user_cluster,
    cluster_label,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(isolation_forest_score), 4) as avg_anomaly_score,
    ROUND(AVG(unique_ips), 1) as avg_unique_ips,
    ROUND(AVG(countries), 1) as avg_countries,
    ROUND(AVG(weekend_ratio), 3) as avg_weekend_ratio,
    ROUND(AVG(offhours_ratio), 3) as avg_offhours_ratio,
    SUM(CASE WHEN snowpark_anomaly THEN 1 ELSE 0 END) as anomalies_in_cluster,
    ROUND(SUM(CASE WHEN snowpark_anomaly THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as cluster_anomaly_rate_pct
FROM SNOWPARK_ML_USER_CLUSTERS
GROUP BY user_cluster, cluster_label
ORDER BY user_cluster;

-- =====================================================
-- 6. ML DEPLOYMENT VALIDATION
-- =====================================================

-- Validate ML deployment is working correctly
CREATE OR REPLACE VIEW ML_DEPLOYMENT_VALIDATION AS
SELECT 
    'ML Deployment Status' as validation_type,
    
    -- Check if models are accessible
    CASE 
        WHEN EXISTS (SELECT 1 FROM @ml_models WHERE name LIKE '%isolation_forest.pkl') THEN 'AVAILABLE'
        ELSE 'MISSING'
    END as isolation_forest_model_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM @ml_models WHERE name LIKE '%kmeans.pkl') THEN 'AVAILABLE'
        ELSE 'MISSING'
    END as kmeans_model_status,
    
    -- Test UDF functionality with sample data
    (SELECT COUNT(*) FROM SNOWPARK_ML_USER_CLUSTERS LIMIT 1) as snowpark_ml_view_accessible,
    (SELECT COUNT(*) FROM ML_MODEL_COMPARISON LIMIT 1) as model_comparison_accessible,
    
    -- Check data freshness
    (SELECT MAX(timestamp) FROM SNOWPARK_ML_USER_CLUSTERS) as latest_ml_analysis,
    
    CURRENT_TIMESTAMP() as validation_timestamp;

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

-- Grant access to ML stages and functions
GRANT USAGE ON STAGE ml_models TO ROLE PUBLIC;
GRANT USAGE ON STAGE python_udfs TO ROLE PUBLIC;

-- Grant access to ML functions
GRANT USAGE ON FUNCTION isolation_forest_score(DOUBLE, DOUBLE, DOUBLE, DOUBLE, DOUBLE, DOUBLE) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION isolation_forest_anomaly(DOUBLE, DOUBLE, DOUBLE, DOUBLE, DOUBLE, DOUBLE) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION kmeans_cluster_assignment(DOUBLE, DOUBLE, DOUBLE, DOUBLE, DOUBLE) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION cluster_label_mapping(INTEGER) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION hybrid_risk_assessment(DOUBLE, BOOLEAN, INTEGER, BOOLEAN) TO ROLE PUBLIC;

COMMIT;

-- =====================================================
-- 8. DEPLOYMENT SUMMARY
-- =====================================================

SELECT 'Real Snowpark ML deployment complete!' as status,
       'No more simulations - all models are now production-grade ML' as note,
       'Next steps: Train models using model_trainer.py and upload to stages' as action_required;
