# 🚀 Getting Started - Snowflake Cybersecurity AI Demo

## 📋 Prerequisites

### **Snowflake Requirements**
- Snowflake account with `ACCOUNTADMIN` privileges
- Streamlit in Snowflake enabled
- **Model Registry** access (included with Snowflake Notebooks)
- **Cortex AI** enabled for your account

### **Development Environment (Optional)**
- Python 3.8+ with packages: `scikit-learn`, `pandas`, `numpy`, `matplotlib`, `seaborn`
- Snowflake packages: `snowflake-snowpark-python`, `snowflake-ml-python>=1.1.0`

---

## ⚡ Quick Start (15 minutes)

### **Step 1: Database Setup**
Execute the SQL scripts in order:

```sql
-- 1. Create schema and tables
@01_cybersecurity_schema.sql

-- 2. Generate enhanced sample data (500+ users, 180+ days, seasonality)
@02_sample_data_generation.sql

-- 3. Create Native ML models and views
@03_ai_ml_models.sql

-- 4. Deploy real Snowpark ML models and UDFs
@04_snowpark_ml_deployment.sql

-- 5. (Optional) Model Registry integration
@05_model_registry_deployment.sql

-- 6. (Optional) Cortex AI integration
@06_cortex_ai_integration.sql

-- 7. (Optional) Cortex Analyst with semantic model
@07_cortex_analyst_integration.sql
```

⚠️ **Important Notes:**
- Native ML models require **90+ days** of training data
- Allow **5-10 minutes** for initial model training
- **Real Snowpark ML models** require the ML training notebook

---

### **Step 2: Train and Deploy ML Models**

#### **Option A: Snowflake Notebooks (Recommended) ✨**
1. **Upload notebook**: `notebooks/Cybersecurity_ML_Demo_Companion.ipynb` to Snowflake Notebooks
2. **Zero configuration**: Session automatically configured - no connection parameters needed!
3. **Run all cells**: Trains and registers models in Model Registry with enterprise features
4. **Validation**: Models automatically deployed as SQL UDFs

#### **Option B: Local Development (Optional)**
```bash
cd notebooks
pip install -r requirements.txt
# Modify notebook connection parameters
# Run: Cybersecurity_ML_Demo_Companion.ipynb
```

---

### **Step 3: Deploy Streamlit App**
1. Navigate to **Snowflake UI → Streamlit**
2. Create new Streamlit app
3. Upload `python/streamlit_cybersecurity_demo.py`
4. Set database context: `CYBERSECURITY_DEMO.SECURITY_AI`
5. Launch application

---

### **Step 4: (Optional) Deploy Cortex Analyst**
1. **Upload semantic model**:
   ```sql
   PUT file://semantic_models/cybersecurity_semantic_model.yaml @semantic_models;
   ```

2. **Enable Cortex Analyst** (requires admin):
   ```sql
   ALTER ACCOUNT SET ENABLE_CORTEX_ANALYST = TRUE;
   ```

3. **Create semantic model**:
   ```sql
   CREATE CORTEX SEARCH SERVICE cybersecurity_semantic_model
     FROM '@semantic_models/cybersecurity_semantic_model.yaml';
   ```

---

## ✅ Validation & Testing

### **Basic Functionality**
```sql
-- Test Native ML
SELECT * FROM NATIVE_ML_USER_BEHAVIOR LIMIT 5;

-- Test Snowpark ML (after notebook deployment)
SELECT * FROM SNOWPARK_ML_USER_CLUSTERS LIMIT 5;

-- Test ML Model Comparison
SELECT * FROM ML_MODEL_COMPARISON LIMIT 5;

-- Test Cortex AI (if deployed)
SELECT security_ai_chatbot('How many critical incidents this week?');

-- Test Cortex Analyst (if deployed)
SELECT ask_security_analyst('Show me security incident trends');
```

### **Performance Validation**
```sql
-- Check data volume
SELECT 
    'Authentication Logs' as data_source,
    COUNT(*) as record_count,
    MIN(timestamp) as earliest,
    MAX(timestamp) as latest
FROM USER_AUTHENTICATION_LOGS
UNION ALL
SELECT 
    'ML Anomalies',
    COUNT(*),
    MIN(analysis_date),
    MAX(analysis_date)
FROM ML_MODEL_COMPARISON;
```

### **ML Model Health Check**
```sql
-- Verify ML model deployment
SELECT * FROM ML_DEPLOYMENT_VALIDATION;
SELECT * FROM ML_MODEL_PERFORMANCE;

-- Check Model Registry (if used)
SHOW MODELS IN MODEL REGISTRY;
```

---

## 🎯 Demo Capabilities Overview

| **Capability** | **Technology** | **Status** |
|---------------|----------------|------------|
| **User Anomaly Detection** | Isolation Forest + K-means | ✅ Production |
| **Time-Series Analysis** | Snowflake Native ML | ✅ Production |
| **Risk Assessment** | Hybrid ML (4-tier system) | ✅ Production |
| **Model Comparison** | Ensemble Analytics | ✅ Production |
| **Threat Intelligence** | Real-time correlation | ✅ Production |
| **Vulnerability Management** | CVSS + Context ML | ✅ Production |
| **Fraud Detection** | Multi-factor analysis | ✅ Production |
| **Security Chatbot** | Cortex AI integration | ✅ Production |
| **Natural Language Analytics** | Cortex Analyst | ✅ Optional |

---

## 🔧 Configuration Options

### **Warehouse Sizing**
```sql
-- For demo (small data)
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'SMALL';

-- For production workloads
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'LARGE';
```

### **Performance Optimization**
```sql
-- Clustering for time-series queries
ALTER TABLE USER_AUTHENTICATION_LOGS 
CLUSTER BY (DATE(TIMESTAMP), USERNAME);

-- Search optimization for IP lookups
ALTER TABLE NETWORK_SECURITY_LOGS 
ADD SEARCH OPTIMIZATION ON EQUALITY(SOURCE_IP, DEST_IP);
```

### **Cost Optimization**
```sql
-- Auto-suspend compute
ALTER WAREHOUSE COMPUTE_WH SET 
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;
```

---

## 🛠️ Troubleshooting

### **Common Issues**

| **Issue** | **Solution** |
|-----------|-------------|
| **Permission Errors** | Ensure `ACCOUNTADMIN` role for setup |
| **Slow Queries** | Scale up warehouse: `WAREHOUSE_SIZE = 'LARGE'` |
| **Missing ML Data** | Run notebook: `Cybersecurity_ML_Demo_Companion.ipynb` |
| **Streamlit Errors** | Check database context: `CYBERSECURITY_DEMO.SECURITY_AI` |
| **Model Registry Issues** | Verify `snowflake-ml-python>=1.1.0` installed |

### **Data Validation**
```sql
-- Check sample data generation
SELECT 
    COUNT(*) as total_auth_logs,
    COUNT(DISTINCT username) as unique_users,
    DATEDIFF(day, MIN(timestamp), MAX(timestamp)) as days_of_data
FROM USER_AUTHENTICATION_LOGS;

-- Expected: 500+ users, 180+ days, 50K+ authentication logs
```

### **ML Model Debugging**
```sql
-- Check if models are training
SELECT SYSTEM$GET_ML_ANOMALY_DETECTOR_STATE('user_behavior_model');

-- Verify UDF deployment
SHOW FUNCTIONS LIKE '%isolation_forest%';
SHOW FUNCTIONS LIKE '%kmeans%';
```

---

## 📞 Support Resources

- **Snowflake Documentation**: [docs.snowflake.com](https://docs.snowflake.com)
- **Community Support**: [community.snowflake.com](https://community.snowflake.com)
- **ML Documentation**: [Snowflake ML Functions](https://docs.snowflake.com/en/user-guide/ml-functions.html)
- **Cortex AI**: [Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex.html)

---

## 🎯 Next Steps

1. **Complete Setup**: Follow steps 1-3 above
2. **Explore Demo**: Review [`docs/DEMO_GUIDE.md`](DEMO_GUIDE.md) for presentation guidance
3. **Customize**: See [`enhancement_roadmap.md`](../enhancement_roadmap.md) for enhancement options
4. **Extend**: Add your own data sources and ML models

**Ready to showcase Snowflake's cybersecurity capabilities!** 🚀
