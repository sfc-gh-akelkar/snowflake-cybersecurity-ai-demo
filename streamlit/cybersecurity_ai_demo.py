"""
Snowflake Cybersecurity AI/ML Demo - Streamlit in Snowflake
Interactive application showcasing AI/ML capabilities in cybersecurity
Designed to run natively within Snowflake's Streamlit environment
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import json
from datetime import datetime, timedelta
import time

# Streamlit in Snowflake imports
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark import functions as F
from snowflake.snowpark import types as T

# Page configuration
st.set_page_config(
    page_title="Snowflake Cybersecurity AI/ML Demo",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        color: #1E88E5;
        text-align: center;
        margin-bottom: 2rem;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
    }
    .use-case-header {
        background: linear-gradient(90deg, #1E88E5, #1976D2);
        color: white;
        padding: 1rem;
        border-radius: 10px;
        margin: 1rem 0;
        font-size: 1.5rem;
        font-weight: bold;
    }
    .metric-card {
        background: #f8f9fa;
        padding: 1.5rem;
        border-radius: 10px;
        border-left: 5px solid #1E88E5;
        margin: 1rem 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .critical-alert {
        background: #ffebee;
        border-left: 5px solid #f44336;
        padding: 1rem;
        margin: 1rem 0;
        border-radius: 5px;
    }
    .high-alert {
        background: #fff3e0;
        border-left: 5px solid #ff9800;
        padding: 1rem;
        margin: 1rem 0;
        border-radius: 5px;
    }
    .ai-insight {
        background: linear-gradient(45deg, #e3f2fd, #f3e5f5);
        border: 2px solid #9c27b0;
        border-radius: 10px;
        padding: 1rem;
        margin: 1rem 0;
    }
    .demo-callout {
        background: #e8f5e8;
        border: 2px solid #4caf50;
        border-radius: 10px;
        padding: 1rem;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# Initialize Snowflake session for Streamlit in Snowflake
@st.cache_resource
def get_snowflake_session():
    """Get the active Snowflake session for SiS"""
    return get_active_session()

# Data functions using real Snowflake queries
@st.cache_data(ttl=300)
def get_anomaly_data():
    """Get anomaly detection data from Snowflake"""
    session = get_snowflake_session()
    
    # Use the view we created in our schema
    query = """
    SELECT 
        USERNAME,
        TIMESTAMP,
        current_country,
        current_hour,
        activity_count,
        lines_changed,
        sensitive_repo_access,
        ANOMALY_SCORE,
        CLASSIFICATION,
        ANOMALY_INDICATORS
    FROM CYBERSECURITY_DEMO.SECURITY_AI.GITHUB_LOGIN_ANOMALY_DETECTION
    ORDER BY ANOMALY_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading anomaly data: {str(e)}")
        # Fallback to sample data for demo purposes
        return pd.DataFrame({
            'USERNAME': ['john.smith', 'sarah.chen', 'mike.rodriguez', 'john.smith', 'lisa.wang'],
            'TIMESTAMP': pd.to_datetime(['2024-01-21 02:30:15', '2024-01-24 14:22:10', '2024-01-23 16:45:30', '2024-01-21 03:15:22', '2024-01-22 09:30:00']),
            'CURRENT_COUNTRY': ['CN', 'RU', 'US', 'CN', 'US'],
            'CURRENT_HOUR': [2, 14, 16, 3, 9],
            'ACTIVITY_COUNT': [15, 0, 3, 12, 2],
            'LINES_CHANGED': [5000, 0, 150, 500, 80],
            'SENSITIVE_REPO_ACCESS': [1, 0, 0, 1, 0],
            'ANOMALY_SCORE': [12.0, 7.0, 1.0, 9.0, 0.0],
            'CLASSIFICATION': ['HIGH_ANOMALY', 'MEDIUM_ANOMALY', 'NORMAL', 'HIGH_ANOMALY', 'NORMAL'],
            'ANOMALY_INDICATORS': [
                "['unusual_hour', 'unusual_location', 'large_code_changes', 'sensitive_repo_access']",
                "['suspicious_location']",
                "[]",
                "['unusual_hour', 'unusual_location', 'sensitive_repo_access']",
                "[]"
            ]
        })

@st.cache_data(ttl=300)
def get_threat_data():
    """Get threat detection data from Snowflake"""
    session = get_snowflake_session()
    
    query = """
    SELECT 
        EVENT_TYPE,
        TIMESTAMP,
        PRIMARY_ASSET,
        SECONDARY_ASSET,
        THREAT_CATEGORY,
        CONFIDENCE_SCORE,
        RELATED_EVENTS,
        COMPOUND_THREAT_SCORE,
        CAMPAIGN_CLASSIFICATION
    FROM CYBERSECURITY_DEMO.SECURITY_AI.COMPREHENSIVE_THREAT_ANALYSIS
    ORDER BY COMPOUND_THREAT_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading threat data: {str(e)}")
        # Fallback to sample data
        return pd.DataFrame({
            'EVENT_TYPE': ['NETWORK_THREAT', 'USER_ANOMALY', 'CODE_THREAT', 'NETWORK_THREAT', 'USER_ANOMALY'],
            'TIMESTAMP': pd.to_datetime(['2024-01-24 14:30:15', '2024-01-21 02:30:15', '2024-01-21 02:45:30', '2024-01-23 08:45:22', '2024-01-24 14:22:10']),
            'PRIMARY_ASSET': ['10.2.1.15', 'john.smith', 'john.smith', '45.33.32.156', 'sarah.chen'],
            'SECONDARY_ASSET': ['203.0.113.50', '203.0.113.25', 'company/core-payment-system', '10.1.1.10', '203.0.113.50'],
            'THREAT_CATEGORY': ['c2_communication', 'USER_COMPROMISE', 'CODE_MANIPULATION', 'port_scan', 'USER_COMPROMISE'],
            'CONFIDENCE_SCORE': [0.95, 0.85, 0.75, 0.78, 0.85],
            'RELATED_EVENTS': [3, 2, 2, 0, 1],
            'COMPOUND_THREAT_SCORE': [1.25, 1.05, 0.95, 0.78, 0.95],
            'CAMPAIGN_CLASSIFICATION': ['ADVANCED_PERSISTENT_THREAT', 'USER_COMPROMISE_CAMPAIGN', 'USER_COMPROMISE_CAMPAIGN', 'ISOLATED_INCIDENT', 'COORDINATED_ATTACK']
        })

@st.cache_data(ttl=300)
def get_vulnerability_data():
    """Get vulnerability prioritization data from Snowflake"""
    session = get_snowflake_session()
    
    query = """
    SELECT 
        CVE_ID,
        VULNERABILITY_NAME,
        CVSS_SCORE,
        HOSTNAME,
        BUSINESS_CRITICALITY,
        DATA_CLASSIFICATION,
        ENVIRONMENT,
        AI_RISK_SCORE,
        PRIORITY_CLASSIFICATION,
        RECOMMENDED_ACTION,
        PATCH_URGENCY
    FROM CYBERSECURITY_DEMO.SECURITY_AI.AI_VULNERABILITY_PRIORITIZATION
    ORDER BY AI_RISK_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading vulnerability data: {str(e)}")
        # Fallback to sample data
        return pd.DataFrame({
            'CVE_ID': ['CVE-2023-4966', 'CVE-2023-46604', 'CVE-2023-44487', 'CVE-2023-36884', 'CVE-2023-32409'],
            'VULNERABILITY_NAME': ['Citrix NetScaler Buffer Overflow', 'Apache ActiveMQ RCE', 'HTTP/2 Rapid Reset Attack', 'Microsoft Office RCE', 'macOS Kernel Privilege Escalation'],
            'CVSS_SCORE': [9.4, 10.0, 7.5, 8.3, 7.8],
            'HOSTNAME': ['prod-db-01', 'prod-api-01', 'prod-web-01', 'DEV-JOHN-01', 'SEC-SARAH-01'],
            'BUSINESS_CRITICALITY': ['critical', 'critical', 'critical', 'high', 'high'],
            'DATA_CLASSIFICATION': ['confidential', 'restricted', 'confidential', 'internal', 'confidential'],
            'ENVIRONMENT': ['production', 'production', 'production', 'development', 'development'],
            'AI_RISK_SCORE': [10.15, 10.50, 8.75, 6.85, 6.90],
            'PRIORITY_CLASSIFICATION': ['CRITICAL', 'CRITICAL', 'HIGH', 'MEDIUM', 'MEDIUM'],
            'RECOMMENDED_ACTION': ['EMERGENCY_PATCH', 'EMERGENCY_PATCH', 'IMMEDIATE_PATCH', 'SCHEDULED_PATCH', 'SCHEDULED_PATCH'],
            'PATCH_URGENCY': ['OVERDUE', 'URGENT', 'URGENT', 'SCHEDULED', 'SCHEDULED']
        })

@st.cache_data(ttl=300)
def get_compliance_data():
    """Get GRC compliance data from Snowflake"""
    session = get_snowflake_session()
    
    query = """
    SELECT 
        EMPLOYEE_ID,
        USERNAME,
        FULL_NAME,
        TERMINATION_DATE,
        RESOURCE,
        VIOLATION_TIMESTAMP,
        DAYS_OVERDUE,
        VIOLATION_SEVERITY,
        COMPLIANCE_IMPACT_SCORE,
        SLA_STATUS,
        REMEDIATION_ACTION
    FROM CYBERSECURITY_DEMO.SECURITY_AI.CIS_CONTROL_16_MONITORING
    ORDER BY COMPLIANCE_IMPACT_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading compliance data: {str(e)}")
        # Fallback to sample data
        return pd.DataFrame({
            'EMPLOYEE_ID': ['EMP006', 'EMP007', 'EMP006', 'EMP007', 'EMP006'],
            'USERNAME': ['alex.turner', 'emily.davis', 'alex.turner', 'emily.davis', 'alex.turner'],
            'FULL_NAME': ['Alex Turner', 'Emily Davis', 'Alex Turner', 'Emily Davis', 'Alex Turner'],
            'TERMINATION_DATE': pd.to_datetime(['2024-01-15', '2024-01-20', '2024-01-15', '2024-01-20', '2024-01-15']),
            'RESOURCE': ['aws_console', 'jira', 'database_prod', 'aws_console', 'github'],
            'VIOLATION_TIMESTAMP': pd.to_datetime(['2024-01-18 10:30:00', '2024-01-23 11:20:00', '2024-01-20 14:45:00', '2024-01-24 16:30:00', '2024-01-22 09:15:00']),
            'DAYS_OVERDUE': [3, 3, 5, 4, 7],
            'VIOLATION_SEVERITY': ['CRITICAL', 'MEDIUM', 'CRITICAL', 'CRITICAL', 'HIGH'],
            'COMPLIANCE_IMPACT_SCORE': [10.0, 5.0, 16.7, 13.3, 15.5],
            'SLA_STATUS': ['SLA_VIOLATION', 'SLA_VIOLATION', 'SLA_VIOLATION', 'SLA_VIOLATION', 'SLA_VIOLATION'],
            'REMEDIATION_ACTION': ['IMMEDIATE_DISABLE_ALL_ACCESS', 'DISABLE_ACCESS_WITHIN_24_HOURS', 'IMMEDIATE_DISABLE_ALL_ACCESS', 'IMMEDIATE_DISABLE_ALL_ACCESS', 'DISABLE_ACCESS_WITHIN_4_HOURS']
        })

@st.cache_data(ttl=300)
def get_ai_alerts_data():
    """Get AI alert triage data from Snowflake"""
    session = get_snowflake_session()
    
    query = """
    SELECT 
        ALERT_ID,
        TIMESTAMP,
        SEVERITY,
        TITLE,
        AI_URGENCY_ASSESSMENT,
        AI_THREAT_CLASSIFICATION,
        AI_INVESTIGATION_PRIORITY_SCORE,
        AI_RECOMMENDED_ACTION,
        EXTRACTED_IP_ADDRESSES,
        EXTRACTED_DATA_SIZES,
        STATUS
    FROM CYBERSECURITY_DEMO.SECURITY_AI.AI_ENHANCED_ALERT_TRIAGE
    ORDER BY AI_INVESTIGATION_PRIORITY_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading AI alerts data: {str(e)}")
        # Fallback to sample data
        return pd.DataFrame({
            'ALERT_ID': ['ALERT_001', 'ALERT_002', 'ALERT_003', 'ALERT_004', 'ALERT_005'],
            'TIMESTAMP': pd.to_datetime(['2024-01-24 14:35:00', '2024-01-23 08:50:00', '2024-01-22 16:20:00', '2024-01-25 15:45:00', '2024-01-20 11:30:00']),
            'SEVERITY': ['critical', 'high', 'medium', 'high', 'critical'],
            'TITLE': ['Suspicious User Activity Detected', 'Persistent Port Scanning Detected', 'Terminated Employee Access Detected', 'Large Data Transfer to External Host', 'Potential Exploitation of CVE-2023-46604'],
            'AI_URGENCY_ASSESSMENT': ['HIGH_URGENCY', 'MEDIUM_URGENCY', 'MEDIUM_URGENCY', 'HIGH_URGENCY', 'HIGH_URGENCY'],
            'AI_THREAT_CLASSIFICATION': ['ACCOUNT_COMPROMISE', 'RECONNAISSANCE', 'ACCOUNT_COMPROMISE', 'DATA_EXFILTRATION', 'VULNERABILITY_EXPLOIT'],
            'AI_INVESTIGATION_PRIORITY_SCORE': [6.5, 5.0, 4.0, 5.5, 6.0],
            'AI_RECOMMENDED_ACTION': ['RESET_CREDENTIALS_AND_REVIEW_ACCESS_LOGS', 'VERIFY_FIREWALL_RULES_AND_BLOCK_SOURCE_IP', 'RESET_CREDENTIALS_AND_REVIEW_ACCESS_LOGS', 'INVESTIGATE_DATA_FLOW_AND_ISOLATE_AFFECTED_SYSTEMS', 'APPLY_PATCHES_AND_IMPLEMENT_WORKAROUNDS'],
            'EXTRACTED_IP_ADDRESSES': ["['203.0.113.25']", "['45.33.32.156']", "['192.168.100.25']", "['203.0.113.50']", "['198.51.100.45', '203.0.113.75']"],
            'EXTRACTED_DATA_SIZES': ["[]", "[]", "[]", "['25MB']", "[]"],
            'STATUS': ['investigating', 'resolved', 'resolved', 'investigating', 'new']
        })

def main():
    # Header
    st.markdown('<h1 class="main-header">🛡️ Snowflake Cybersecurity AI/ML Demo</h1>', unsafe_allow_html=True)
    st.markdown("**Showcasing AI-Powered Security Analytics in the Data Cloud**")
    
    # Sidebar
    with st.sidebar:
        st.image("https://logos-world.net/wp-content/uploads/2022/11/Snowflake-Logo.png", width=200)
        st.title("🛡️ Security Data Cloud")
        st.markdown("---")
        
        # Demo navigation
        demo_mode = st.selectbox(
            "Choose Demo Focus",
            ["Executive Overview", "Technical Deep Dive", "Use Case Comparison"]
        )
        
        use_case = st.selectbox(
            "Select AI/ML Use Case",
            [
                "🔍 Anomaly Detection",
                "🎯 Threat Detection & Response", 
                "⚠️ Vulnerability Prioritization",
                "📋 GRC & Compliance",
                "🤖 AI Alert Triage"
            ]
        )
        
        st.markdown("---")
        
        # Connection status
        try:
            session = get_snowflake_session()
            st.success("✅ Connected to Snowflake")
            st.info(f"📊 Current Database: {session.get_current_database()}")
            st.info(f"🏛️ Current Schema: {session.get_current_schema()}")
        except Exception as e:
            st.warning("⚠️ Using Demo Mode (Fallback Data)")
            st.caption(f"Error: {str(e)}")
        
        # Time range
        time_range = st.selectbox(
            "Analysis Period",
            ["Last 24 Hours", "Last 7 Days", "Last 30 Days"],
            index=1
        )
        
        if st.button("🔄 Refresh Data"):
            st.cache_data.clear()
            st.success("Data refreshed!")

    # Main content based on selected use case
    if "Anomaly Detection" in use_case:
        show_anomaly_detection()
    elif "Threat Detection" in use_case:
        show_threat_detection()
    elif "Vulnerability Prioritization" in use_case:
        show_vulnerability_prioritization()
    elif "GRC & Compliance" in use_case:
        show_grc_compliance()
    elif "AI Alert Triage" in use_case:
        show_ai_alert_triage()

def show_anomaly_detection():
    st.markdown('<div class="use-case-header">🔍 Use Case 1: AI-Powered Anomaly Detection</div>', unsafe_allow_html=True)
    
    # Value proposition
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Detect compromised accounts and insider threats using machine learning to identify deviations from normal user behavior patterns.
    </div>
    """, unsafe_allow_html=True)
    
    # Load data from Snowflake
    anomaly_data = get_anomaly_data()
    
    # Executive summary metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Users Analyzed", "250", delta="5 new")
    with col2:
        st.metric("Anomalies Detected", len(anomaly_data[anomaly_data['ANOMALY_SCORE'] > 5]), delta="+2")
    with col3:
        st.metric("High-Risk Anomalies", len(anomaly_data[anomaly_data['CLASSIFICATION'] == 'HIGH_ANOMALY']), delta="+1")
    with col4:
        st.metric("Avg Detection Time", "12 minutes", delta="-8 min")
    
    # Tabs for different views
    tab1, tab2, tab3 = st.tabs(["🚨 Active Anomalies", "📊 SQL Analytics", "🤖 ML Insights"])
    
    with tab1:
        st.subheader("GitHub Login Anomaly Detection Results")
        
        # Filter high anomalies
        high_anomalies = anomaly_data[anomaly_data['ANOMALY_SCORE'] > 5]
        
        if not high_anomalies.empty:
            # Anomaly timeline
            fig = px.scatter(
                anomaly_data,
                x='TIMESTAMP',
                y='ANOMALY_SCORE',
                color='CLASSIFICATION',
                size='LINES_CHANGED',
                hover_data=['USERNAME', 'CURRENT_COUNTRY', 'ACTIVITY_COUNT'],
                title="User Anomaly Detection Timeline",
                color_discrete_map={
                    'HIGH_ANOMALY': '#ff4444',
                    'MEDIUM_ANOMALY': '#ff8800', 
                    'LOW_ANOMALY': '#ffcc00',
                    'NORMAL': '#44ff44'
                }
            )
            fig.add_hline(y=8, line_dash="dash", line_color="red", annotation_text="High Risk Threshold")
            st.plotly_chart(fig, use_container_width=True)
            
            # Detailed anomaly breakdown
            st.subheader("High-Risk User Activities")
            
            for _, row in high_anomalies.iterrows():
                # Handle indicators that might be strings or arrays
                indicators = row['ANOMALY_INDICATORS']
                if isinstance(indicators, str):
                    # If it's a string representation of a list, try to eval it safely
                    try:
                        import ast
                        indicators = ast.literal_eval(indicators)
                    except:
                        indicators = []
                indicators_text = ", ".join([ind for ind in indicators if ind])
                
                alert_class = "critical-alert" if row['CLASSIFICATION'] == 'HIGH_ANOMALY' else "high-alert"
                
                st.markdown(f"""
                <div class="{alert_class}">
                    <strong>🚨 {row['USERNAME']}</strong> - Score: {row['ANOMALY_SCORE']}<br>
                    <strong>Time:</strong> {row['TIMESTAMP'].strftime('%Y-%m-%d %H:%M:%S')}<br>
                    <strong>Location:</strong> {row['CURRENT_COUNTRY']} (Hour: {row['CURRENT_HOUR']})<br>
                    <strong>Activity:</strong> {row['ACTIVITY_COUNT']} GitHub actions, {row['LINES_CHANGED']} lines changed<br>
                    <strong>Risk Indicators:</strong> {indicators_text}
                </div>
                """, unsafe_allow_html=True)
        
    with tab2:
        st.subheader("Advanced SQL Analytics")
        
        st.markdown("**Built-in Snowflake Anomaly Detection Function:**")
        st.code("""
-- Detect anomalous GitHub login patterns using built-in ML
SELECT 
    USERNAME,
    TIMESTAMP,
    daily_login_count,
    ANOMALY_DETECTION(daily_login_count) OVER (
        PARTITION BY USERNAME 
        ORDER BY login_date 
        ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
    ) as anomaly_result
FROM daily_user_logins
WHERE anomaly_result:is_anomaly = TRUE
ORDER BY anomaly_result:score DESC;
        """, language='sql')
        
        st.markdown("**Custom Anomaly Scoring Logic:**")
        st.code("""
-- Multi-factor anomaly scoring
SELECT 
    USERNAME,
    CASE 
        WHEN login_hour NOT IN (user_baseline_hours) THEN 5.0
        ELSE 0.0
    END +
    CASE 
        WHEN login_country NOT IN (user_typical_countries) THEN 7.0
        ELSE 0.0
    END +
    CASE 
        WHEN weekend_activity AND github_changes > 1000 THEN 4.0
        ELSE 0.0
    END as ANOMALY_SCORE
FROM user_activity_analysis;
        """, language='sql')
        
    with tab3:
        st.subheader("Machine Learning Insights")
        
        st.markdown("""
        <div class="ai-insight">
        <h4>🤖 AI Analysis</h4>
        <p><strong>Pattern Detected:</strong> User 'john.smith' shows classic signs of account compromise:</p>
        <ul>
            <li>Login from Beijing (CN) at 2:30 AM - Outside normal hours and location</li>
            <li>Massive GitHub activity (5,000+ lines changed) during compromise window</li>
            <li>Access to sensitive payment system repositories</li>
            <li>Creation of new repository with company source code</li>
        </ul>
        <p><strong>Confidence:</strong> 92% likelihood of compromise</p>
        <p><strong>Recommended Action:</strong> Immediate account lockdown and forensic investigation</p>
        </div>
        """, unsafe_allow_html=True)
        
        # Model performance metrics
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Model Performance**")
            perf_data = pd.DataFrame({
                'Metric': ['Accuracy', 'Precision', 'Recall', 'F1-Score'],
                'Score': [94.2, 89.1, 91.5, 90.3]
            })
            fig = px.bar(perf_data, x='Metric', y='Score', title="Anomaly Detection Model Performance")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.markdown("**Feature Importance**")
            feature_data = pd.DataFrame({
                'Feature': ['Geographic Location', 'Time of Day', 'Code Changes Volume', 'Repository Sensitivity', 'Login Frequency'],
                'Importance': [0.35, 0.25, 0.20, 0.15, 0.05]
            })
            fig = px.pie(feature_data, values='Importance', names='Feature', title="Model Feature Importance")
            st.plotly_chart(fig, use_container_width=True)

def show_threat_detection():
    st.markdown('<div class="use-case-header">🎯 Use Case 2: Threat Detection & Incident Response</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Correlate threats across network, user, and code repositories to identify coordinated attacks and compromised developers.
    </div>
    """, unsafe_allow_html=True)
    
    threat_data = get_threat_data()
    
    # Executive metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Active Campaigns", len(threat_data[threat_data['campaign_classification'] != 'ISOLATED_INCIDENT']), delta="+1")
    with col2:
        st.metric("High Confidence Threats", len(threat_data[threat_data['confidence_score'] > 0.9]), delta="+2")
    with col3:
        st.metric("Correlated Events", threat_data['related_events'].sum(), delta="+5")
    with col4:
        st.metric("Avg Response Time", "18 minutes", delta="-12 min")
    
    tab1, tab2, tab3 = st.tabs(["🎯 Threat Correlation", "👨‍💻 Compromised Developers", "📊 Campaign Analysis"])
    
    with tab1:
        st.subheader("Multi-Source Threat Correlation")
        
        # Threat correlation timeline
        fig = px.scatter(
            threat_data,
            x='timestamp',
            y='compound_threat_score',
            color='campaign_classification',
            size='related_events',
            hover_data=['primary_asset', 'threat_category'],
            title="Correlated Threat Events Timeline"
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Threat correlation matrix
        st.subheader("Advanced Persistent Threat (APT) Detection")
        
        apt_threat = threat_data[threat_data['campaign_classification'] == 'ADVANCED_PERSISTENT_THREAT'].iloc[0]
        
        st.markdown(f"""
        <div class="critical-alert">
        <h4>🚨 APT Campaign Detected</h4>
        <strong>Primary Asset:</strong> {apt_threat['primary_asset']}<br>
        <strong>Threat Score:</strong> {apt_threat['compound_threat_score']}<br>
        <strong>Related Events:</strong> {apt_threat['related_events']}<br>
        <strong>Confidence:</strong> {apt_threat['confidence_score'] * 100:.1f}%<br>
        
        <h5>Attack Timeline:</h5>
        <ol>
            <li><strong>Initial Compromise:</strong> Suspicious login from foreign IP</li>
            <li><strong>Lateral Movement:</strong> Network reconnaissance and C2 communication</li>
            <li><strong>Code Manipulation:</strong> Malicious changes to payment systems</li>
            <li><strong>Data Exfiltration:</strong> Large data transfers to external servers</li>
        </ol>
        </div>
        """, unsafe_allow_html=True)
        
    with tab2:
        st.subheader("Compromised Developer Detection")
        
        st.markdown("**Real-time Developer Risk Assessment:**")
        
        # Mock compromised developer data
        comp_dev_data = pd.DataFrame({
            'username': ['john.smith', 'alex.turner'],
            'compromise_risk_score': [14.0, 7.0],
            'suspicious_login_time': ['2024-01-21 02:30:15', '2024-01-22 10:15:30'],
            'github_activity_time': ['2024-01-21 02:45:30', '2024-01-22 10:30:45'],
            'lines_added': [5000, 150],
            'is_sensitive_repo': [True, False],
            'threat_intel_match': [True, False],
            'data_transferred': [25000000, 500000]
        })
        
        for _, dev in comp_dev_data.iterrows():
            risk_class = "critical-alert" if dev['compromise_risk_score'] > 10 else "high-alert"
            
            st.markdown(f"""
            <div class="{risk_class}">
            <strong>Developer:</strong> {dev['username']}<br>
            <strong>Risk Score:</strong> {dev['compromise_risk_score']}/20<br>
            <strong>Suspicious Login:</strong> {dev['suspicious_login_time']}<br>
            <strong>Code Changes:</strong> {dev['lines_added']} lines added<br>
            <strong>Sensitive Repo Access:</strong> {'Yes' if dev['is_sensitive_repo'] else 'No'}<br>
            <strong>Threat Intel Match:</strong> {'Yes' if dev['threat_intel_match'] else 'No'}<br>
            <strong>Data Transfer:</strong> {dev['data_transferred'] / 1024 / 1024:.1f} MB
            </div>
            """, unsafe_allow_html=True)
        
    with tab3:
        st.subheader("Campaign Analysis")
        
        # Campaign classification pie chart
        campaign_counts = threat_data['campaign_classification'].value_counts()
        fig = px.pie(
            values=campaign_counts.values,
            names=campaign_counts.index,
            title="Threat Campaign Classification"
        )
        st.plotly_chart(fig, use_container_width=True)
        
        st.markdown("**Complex Threat Hunting Query:**")
        st.code("""
-- Join security logs with GitHub data and threat intelligence
SELECT 
    u.USERNAME,
    u.SUSPICIOUS_LOGIN_TIME,
    g.REPOSITORY,
    g.LINES_ADDED,
    t.THREAT_TYPE,
    n.BYTES_OUT as data_transferred,
    -- Risk scoring
    (CASE WHEN u.risk_factors > 2 THEN 3.0 ELSE 0.0 END +
     CASE WHEN g.lines_added > 500 THEN 2.0 ELSE 0.0 END +
     CASE WHEN g.is_sensitive_repo THEN 3.0 ELSE 0.0 END +
     CASE WHEN t.confidence_level = 'high' THEN 4.0 ELSE 0.0 END) as compromise_score
FROM user_authentication_logs u
JOIN github_activity_logs g ON u.username = g.username
JOIN threat_intelligence t ON u.source_ip = t.ioc_value  
JOIN network_logs n ON u.source_ip = n.source_ip
WHERE u.risk_factors > 0
ORDER BY compromise_score DESC;
        """, language='sql')

def show_vulnerability_prioritization():
    st.markdown('<div class="use-case-header">⚠️ Use Case 3: AI-Powered Vulnerability Prioritization</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Prioritize vulnerability patching using AI that considers business context, not just CVSS scores. Reduce vulnerability backlog by 70%.
    </div>
    """, unsafe_allow_html=True)
    
    vuln_data = get_vulnerability_data()
    
    # Executive metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Vulnerabilities", len(vuln_data), delta="-15 (patched)")
    with col2:
        st.metric("Critical Priority", len(vuln_data[vuln_data['priority_classification'] == 'CRITICAL']), delta="+1")
    with col3:
        st.metric("Overdue Patches", len(vuln_data[vuln_data['patch_urgency'] == 'OVERDUE']), delta="-3")
    with col4:
        st.metric("Risk Reduction", "68%", delta="+5%")
    
    tab1, tab2, tab3 = st.tabs(["🎯 AI Risk Scoring", "📊 Business Context", "⚡ Patch Recommendations"])
    
    with tab1:
        st.subheader("AI-Enhanced Vulnerability Risk Scoring")
        
        # Comparison chart: CVSS vs AI Risk Score
        fig = make_subplots(
            rows=1, cols=2,
            subplot_titles=('Traditional CVSS Scoring', 'AI-Enhanced Risk Scoring'),
            specs=[[{"secondary_y": False}, {"secondary_y": False}]]
        )
        
        # CVSS scores
        fig.add_trace(
            go.Bar(
                x=vuln_data['cve_id'],
                y=vuln_data['cvss_score'],
                name='CVSS Score',
                marker_color='lightblue'
            ),
            row=1, col=1
        )
        
        # AI Risk scores
        fig.add_trace(
            go.Bar(
                x=vuln_data['cve_id'],
                y=vuln_data['ai_risk_score'],
                name='AI Risk Score',
                marker_color=vuln_data['priority_classification'].map({
                    'CRITICAL': 'red',
                    'HIGH': 'orange', 
                    'MEDIUM': 'yellow',
                    'LOW': 'green'
                })
            ),
            row=1, col=2
        )
        
        fig.update_layout(height=500, title_text="CVSS vs AI-Enhanced Risk Scoring")
        st.plotly_chart(fig, use_container_width=True)
        
        # Priority recommendations
        st.subheader("AI Prioritization Results")
        
        for _, vuln in vuln_data.iterrows():
            priority_color = {
                'CRITICAL': 'critical-alert',
                'HIGH': 'high-alert',
                'MEDIUM': 'metric-card',
                'LOW': 'metric-card'
            }.get(vuln['priority_classification'], 'metric-card')
            
            st.markdown(f"""
            <div class="{priority_color}">
            <strong>{vuln['cve_id']}</strong> - {vuln['vulnerability_name']}<br>
            <strong>Asset:</strong> {vuln['hostname']} ({vuln['business_criticality']} criticality)<br>
            <strong>Environment:</strong> {vuln['environment']} | <strong>Data:</strong> {vuln['data_classification']}<br>
            <strong>CVSS Score:</strong> {vuln['cvss_score']} → <strong>AI Risk Score:</strong> {vuln['ai_risk_score']:.2f}<br>
            <strong>Action:</strong> {vuln['recommended_action']} ({vuln['patch_urgency']})
            </div>
            """, unsafe_allow_html=True)
    
    with tab2:
        st.subheader("Business Context Integration")
        
        # Risk factor breakdown
        st.markdown("**AI Risk Calculation Factors:**")
        
        factors_data = pd.DataFrame({
            'Factor': ['CVSS Score (40%)', 'Business Criticality (25%)', 'Data Classification (15%)', 'Environment (10%)', 'Threat Intel (5%)', 'Network Exposure (3%)', 'User Access (2%)'],
            'Weight': [0.40, 0.25, 0.15, 0.10, 0.05, 0.03, 0.02]
        })
        
        fig = px.bar(
            factors_data,
            x='Factor',
            y='Weight',
            title="AI Risk Scoring Algorithm Weights"
        )
        fig.update_xaxes(tickangle=45)
        st.plotly_chart(fig, use_container_width=True)
        
        # Business impact analysis
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Asset Criticality Distribution**")
            criticality_counts = vuln_data['business_criticality'].value_counts()
            fig = px.pie(values=criticality_counts.values, names=criticality_counts.index)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.markdown("**Environment Distribution**")
            env_counts = vuln_data['environment'].value_counts()
            fig = px.pie(values=env_counts.values, names=env_counts.index)
            st.plotly_chart(fig, use_container_width=True)
    
    with tab3:
        st.subheader("Automated Patch Recommendations")
        
        st.markdown("**SQL-Based Risk Prioritization:**")
        st.code("""
-- AI-enhanced vulnerability prioritization
SELECT 
    CVE_ID,
    VULNERABILITY_NAME,
    -- Multi-factor AI risk calculation
    (CVSS_SCORE * 0.4) +
    (CASE business_criticality
        WHEN 'critical' THEN 10.0
        WHEN 'high' THEN 7.5
        WHEN 'medium' THEN 5.0
        ELSE 2.5
    END * 0.25) +
    (CASE data_classification
        WHEN 'restricted' THEN 10.0
        WHEN 'confidential' THEN 7.5
        ELSE 5.0
    END * 0.15) +
    (threat_intelligence_score * 0.05) as AI_RISK_SCORE,
    
    -- Automated recommendations
    CASE 
        WHEN ai_risk_score >= 9.0 AND patch_available THEN 'EMERGENCY_PATCH'
        WHEN ai_risk_score >= 7.0 THEN 'IMMEDIATE_PATCH'
        ELSE 'SCHEDULED_PATCH'
    END as recommended_action
FROM vulnerability_data v
JOIN asset_inventory a ON v.asset_id = a.asset_id
ORDER BY AI_RISK_SCORE DESC;
        """, language='sql')
        
        # Patch timeline recommendations
        st.markdown("**Recommended Patch Schedule:**")
        
        timeline_data = pd.DataFrame({
            'Priority': ['EMERGENCY_PATCH', 'IMMEDIATE_PATCH', 'SCHEDULED_PATCH'],
            'Count': [
                len(vuln_data[vuln_data['recommended_action'] == 'EMERGENCY_PATCH']),
                len(vuln_data[vuln_data['recommended_action'] == 'IMMEDIATE_PATCH']),
                len(vuln_data[vuln_data['recommended_action'] == 'SCHEDULED_PATCH'])
            ],
            'Timeline': ['< 24 hours', '< 72 hours', '< 30 days']
        })
        
        for _, row in timeline_data.iterrows():
            st.markdown(f"**{row['Priority']}:** {row['Count']} vulnerabilities - {row['Timeline']}")

def show_grc_compliance():
    st.markdown('<div class="use-case-header">📋 Use Case 4: Automated GRC & Compliance</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Automate compliance monitoring and evidence collection. Improve CIS Control 16 compliance from 60% to 95%.
    </div>
    """, unsafe_allow_html=True)
    
    compliance_data = get_compliance_data()
    
    # Executive metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Compliance Score", "73%", delta="+13%")
    with col2:
        st.metric("Active Violations", len(compliance_data), delta="-8")
    with col3:
        st.metric("Avg Resolution Time", "4.2 hours", delta="-18 hours")
    with col4:
        st.metric("Automated Checks", "95%", delta="+25%")
    
    tab1, tab2, tab3 = st.tabs(["🚨 CIS Control 16", "📊 Compliance Dashboard", "🤖 Automated Evidence"])
    
    with tab1:
        st.subheader("CIS Control 16: Account Monitoring and Control")
        
        st.markdown("**Real-time Violation Detection:**")
        
        # Violation timeline
        fig = px.scatter(
            compliance_data,
            x='violation_timestamp',
            y='compliance_impact_score',
            color='violation_severity',
            size='days_overdue',
            hover_data=['username', 'resource'],
            title="Access Control Violations Timeline",
            color_discrete_map={
                'CRITICAL': '#ff4444',
                'HIGH': '#ff8800',
                'MEDIUM': '#ffcc00',
                'LOW': '#44ff44'
            }
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Individual violations
        st.subheader("Active Compliance Violations")
        
        for _, violation in compliance_data.iterrows():
            severity_class = {
                'CRITICAL': 'critical-alert',
                'HIGH': 'high-alert',
                'MEDIUM': 'metric-card'
            }.get(violation['violation_severity'], 'metric-card')
            
            st.markdown(f"""
            <div class="{severity_class}">
            <strong>Employee:</strong> {violation['full_name']} ({violation['username']})<br>
            <strong>Terminated:</strong> {violation['termination_date'].strftime('%Y-%m-%d')}<br>
            <strong>Violation:</strong> Accessed {violation['resource']} on {violation['violation_timestamp'].strftime('%Y-%m-%d %H:%M')}<br>
            <strong>Days Overdue:</strong> {violation['days_overdue']} | <strong>Impact Score:</strong> {violation['compliance_impact_score']:.1f}<br>
            <strong>Action Required:</strong> {violation['remediation_action']}
            </div>
            """, unsafe_allow_html=True)
    
    with tab2:
        st.subheader("Compliance Monitoring Dashboard")
        
        # Compliance metrics
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Violation Severity Breakdown**")
            severity_counts = compliance_data['violation_severity'].value_counts()
            fig = px.pie(
                values=severity_counts.values,
                names=severity_counts.index,
                color_discrete_map={
                    'CRITICAL': '#ff4444',
                    'HIGH': '#ff8800',
                    'MEDIUM': '#ffcc00',
                    'LOW': '#44ff44'
                }
            )
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.markdown("**Resource Access Violations**")
            resource_counts = compliance_data['resource'].value_counts()
            fig = px.bar(x=resource_counts.index, y=resource_counts.values)
            st.plotly_chart(fig, use_container_width=True)
        
        # SLA compliance tracking
        st.markdown("**SLA Compliance Tracking**")
        sla_data = compliance_data['sla_status'].value_counts()
        
        for status, count in sla_data.items():
            color = {
                'WITHIN_SLA': '🟢',
                'SLA_WARNING': '🟡',
                'SLA_VIOLATION': '🔴'
            }.get(status, '⚪')
            st.markdown(f"{color} **{status}:** {count} violations")
    
    with tab3:
        st.subheader("Automated Evidence Collection")
        
        st.markdown("**Real-time Compliance Monitoring Query:**")
        st.code("""
-- Automated CIS Control 16 monitoring
WITH terminated_employees AS (
    SELECT employee_id, username, termination_date
    FROM employee_data 
    WHERE employment_status = 'terminated'
),
access_violations AS (
    SELECT 
        te.username,
        te.termination_date,
        ac.resource,
        ac.timestamp as violation_timestamp,
        DATEDIFF(day, te.termination_date, ac.timestamp) as days_overdue,
        -- Automated severity calculation
        CASE 
            WHEN ac.resource IN ('aws_console', 'database_prod') 
                AND DATEDIFF(day, te.termination_date, ac.timestamp) > 1 
                THEN 'CRITICAL'
            WHEN DATEDIFF(day, te.termination_date, ac.timestamp) > 7 
                THEN 'HIGH'
            ELSE 'MEDIUM'
        END as violation_severity
    FROM terminated_employees te
    JOIN access_control_logs ac ON te.username = ac.username
    WHERE ac.timestamp > te.termination_date
)
SELECT * FROM access_violations
ORDER BY days_overdue DESC;
        """, language='sql')
        
        # Automated compliance reporting
        st.markdown("**Automated Compliance Report:**")
        
        compliance_report = {
            'control_id': 'CIS_16',
            'control_description': 'Account Monitoring and Control',
            'compliance_score': 73.0,
            'total_terminated_employees': 8,
            'employees_with_violations': 2,
            'total_violations': 5,
            'evidence_sources': ['HR_SYSTEM', 'ACCESS_CONTROL_LOGS', 'AUTHENTICATION_LOGS'],
            'automated_checks': True,
            'last_audit': '2024-01-25',
            'next_audit_due': '2024-04-25'
        }
        
        st.json(compliance_report)

def show_ai_alert_triage():
    st.markdown('<div class="use-case-header">🤖 Use Case 5: AI-Powered Alert Triage</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Use Snowflake Cortex LLMs to automatically classify, prioritize, and enrich security alerts. Reduce alert fatigue by 60%.
    </div>
    """, unsafe_allow_html=True)
    
    alerts_data = get_ai_alerts_data()
    
    # Executive metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Alerts", len(alerts_data), delta="+8")
    with col2:
        st.metric("High Priority", len(alerts_data[alerts_data['ai_urgency_assessment'] == 'HIGH_URGENCY']), delta="+2")
    with col3:
        st.metric("Auto-Classified", "95%", delta="+15%")
    with col4:
        st.metric("Triage Time", "30 seconds", delta="-12 minutes")
    
    tab1, tab2, tab3 = st.tabs(["🧠 AI Triage", "📝 Text Analysis", "🎯 Recommendations"])
    
    with tab1:
        st.subheader("AI-Powered Alert Classification")
        
        # Alert priority matrix
        fig = px.scatter(
            alerts_data,
            x='timestamp',
            y='ai_investigation_priority_score',
            color='ai_threat_classification',
            size='ai_investigation_priority_score',
            hover_data=['title', 'ai_urgency_assessment'],
            title="AI Alert Prioritization Timeline"
        )
        fig.add_hline(y=6, line_dash="dash", line_color="red", annotation_text="High Priority Threshold")
        st.plotly_chart(fig, use_container_width=True)
        
        # AI-enhanced alert details
        st.subheader("AI-Enhanced Alert Analysis")
        
        for _, alert in alerts_data.iterrows():
            urgency_class = {
                'HIGH_URGENCY': 'critical-alert',
                'MEDIUM_URGENCY': 'high-alert',
                'LOW_URGENCY': 'metric-card'
            }.get(alert['ai_urgency_assessment'], 'metric-card')
            
            extracted_ips = ', '.join(alert['extracted_ip_addresses']) if alert['extracted_ip_addresses'] else 'None'
            extracted_sizes = ', '.join(alert['extracted_data_sizes']) if alert['extracted_data_sizes'] else 'None'
            
            st.markdown(f"""
            <div class="{urgency_class}">
            <strong>🚨 {alert['title']}</strong><br>
            <strong>AI Classification:</strong> {alert['ai_threat_classification']}<br>
            <strong>Urgency Assessment:</strong> {alert['ai_urgency_assessment']}<br>
            <strong>Priority Score:</strong> {alert['ai_investigation_priority_score']:.1f}/8.0<br>
            <strong>Extracted IPs:</strong> {extracted_ips}<br>
            <strong>Data Sizes:</strong> {extracted_sizes}<br>
            <strong>Recommended Action:</strong> {alert['ai_recommended_action']}<br>
            <strong>Status:</strong> {alert['status']}
            </div>
            """, unsafe_allow_html=True)
    
    with tab2:
        st.subheader("Cortex AI Text Analysis")
        
        st.markdown("**Natural Language Processing with Snowflake Cortex:**")
        
        # Mock Cortex analysis
        st.markdown("""
        <div class="ai-insight">
        <h4>🧠 Cortex AI Analysis</h4>
        <p><strong>Alert Text:</strong> "User john.smith exhibited highly unusual behavior pattern. Multiple failed login attempts from foreign IP address (203.0.113.25) followed by successful authentication and extensive GitHub activity..."</p>
        
        <p><strong>AI Extracted Entities:</strong></p>
        <ul>
            <li><strong>Users:</strong> john.smith</li>
            <li><strong>IP Addresses:</strong> 203.0.113.25</li>
            <li><strong>Systems:</strong> GitHub, authentication system</li>
            <li><strong>Actions:</strong> login attempts, code changes</li>
            <li><strong>Indicators:</strong> foreign IP, unusual behavior, extensive activity</li>
        </ul>
        
        <p><strong>Sentiment Analysis:</strong> High Urgency (95% confidence)</p>
        <p><strong>Threat Classification:</strong> Account Compromise (89% confidence)</p>
        </div>
        """, unsafe_allow_html=True)
        
        # Cortex functions demonstration
        st.markdown("**Cortex AI Functions:**")
        st.code("""
-- Snowflake Cortex LLM functions for security alert analysis
SELECT 
    alert_id,
    title,
    description,
    
    -- AI text summarization
    SNOWFLAKE.CORTEX.SUMMARIZE(description) as ai_summary,
    
    -- Sentiment analysis for urgency detection
    SNOWFLAKE.CORTEX.SENTIMENT(description) as urgency_sentiment,
    
    -- Entity extraction
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        description, 
        'What IP addresses are mentioned in this alert?'
    ) as extracted_ips,
    
    -- Threat classification
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        description,
        ['data_exfiltration', 'malware', 'account_compromise', 'network_attack']
    ) as threat_category,
    
    -- Investigation recommendations
    SNOWFLAKE.CORTEX.COMPLETE(
        'Based on this security alert, what should be the next investigation steps: ' 
        || description
    ) as investigation_steps
    
FROM security_alerts
WHERE timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY urgency_sentiment DESC;
        """, language='sql')
    
    with tab3:
        st.subheader("Automated Response Recommendations")
        
        # Recommendation engine
        st.markdown("**AI-Generated Investigation Playbooks:**")
        
        playbooks = {
            'ACCOUNT_COMPROMISE': {
                'steps': [
                    'Reset user credentials immediately',
                    'Review all recent user activities',
                    'Check for lateral movement indicators',
                    'Notify user and security team',
                    'Implement additional monitoring'
                ],
                'priority': 'HIGH',
                'estimated_time': '2-4 hours'
            },
            'DATA_EXFILTRATION': {
                'steps': [
                    'Isolate affected systems',
                    'Analyze data flow patterns',
                    'Identify exfiltrated data',
                    'Block external communications',
                    'Notify legal and compliance teams'
                ],
                'priority': 'CRITICAL',
                'estimated_time': '1-2 hours'
            },
            'RECONNAISSANCE': {
                'steps': [
                    'Block source IP addresses',
                    'Review firewall configurations',
                    'Monitor for follow-up attacks',
                    'Update threat intelligence',
                    'Enhance network monitoring'
                ],
                'priority': 'MEDIUM',
                'estimated_time': '30-60 minutes'
            }
        }
        
        for threat_type, playbook in playbooks.items():
            st.markdown(f"**{threat_type} Response Playbook:**")
            st.markdown(f"*Priority: {playbook['priority']} | Estimated Time: {playbook['estimated_time']}*")
            
            for i, step in enumerate(playbook['steps'], 1):
                st.markdown(f"{i}. {step}")
            
            st.markdown("---")
        
        # Performance metrics
        st.markdown("**AI Triage Performance Metrics:**")
        
        perf_metrics = pd.DataFrame({
            'Metric': ['Classification Accuracy', 'False Positive Rate', 'Time Savings', 'Analyst Productivity'],
            'Before AI': [65, 35, 0, 100],
            'With AI': [92, 8, 85, 240]
        })
        
        fig = px.bar(
            perf_metrics.melt(id_vars='Metric', var_name='Period', value_name='Value'),
            x='Metric',
            y='Value',
            color='Period',
            barmode='group',
            title="AI Impact on Alert Triage Performance"
        )
        fig.update_xaxes(tickangle=45)
        st.plotly_chart(fig, use_container_width=True)

if __name__ == "__main__":
    main()