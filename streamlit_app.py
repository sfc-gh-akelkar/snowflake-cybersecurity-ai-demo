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

# Streamlit in Snowflake imports
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark import functions as F

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
    
    query = """
    SELECT 
        USERNAME,
        TIMESTAMP,
        CURRENT_COUNTRY,
        CURRENT_HOUR,
        ACTIVITY_COUNT,
        LINES_CHANGED,
        SENSITIVE_REPO_ACCESS,
        ANOMALY_SCORE,
        CLASSIFICATION,
        ANOMALY_INDICATORS
    FROM CYBERSECURITY_DEMO.SECURITY_AI.GITHUB_LOGIN_ANOMALY_DETECTION
    WHERE ANOMALY_SCORE > 0
    ORDER BY ANOMALY_SCORE DESC
    """
    
    try:
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading anomaly data: {str(e)}")
        # Fallback to sample data for demo purposes
        return pd.DataFrame({
            'USERNAME': ['john.smith', 'sarah.chen', 'john.smith'],
            'TIMESTAMP': pd.to_datetime(['2024-01-21 02:30:15', '2024-01-24 14:22:10', '2024-01-21 03:15:22']),
            'CURRENT_COUNTRY': ['CN', 'RU', 'CN'],
            'CURRENT_HOUR': [2, 14, 3],
            'ACTIVITY_COUNT': [15, 0, 12],
            'LINES_CHANGED': [5000, 0, 500],
            'SENSITIVE_REPO_ACCESS': [1, 0, 1],
            'ANOMALY_SCORE': [12.0, 7.0, 9.0],
            'CLASSIFICATION': ['HIGH_ANOMALY', 'MEDIUM_ANOMALY', 'HIGH_ANOMALY'],
            'ANOMALY_INDICATORS': [
                "unusual_hour, unusual_location, large_code_changes, sensitive_repo_access",
                "suspicious_location",
                "unusual_hour, unusual_location, sensitive_repo_access"
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
        return pd.DataFrame({
            'EVENT_TYPE': ['NETWORK_THREAT', 'USER_ANOMALY', 'CODE_THREAT'],
            'TIMESTAMP': pd.to_datetime(['2024-01-24 14:30:15', '2024-01-21 02:30:15', '2024-01-21 02:45:30']),
            'PRIMARY_ASSET': ['10.2.1.15', 'john.smith', 'john.smith'],
            'SECONDARY_ASSET': ['203.0.113.50', '203.0.113.25', 'company/core-payment-system'],
            'THREAT_CATEGORY': ['c2_communication', 'USER_COMPROMISE', 'CODE_MANIPULATION'],
            'CONFIDENCE_SCORE': [0.95, 0.85, 0.75],
            'RELATED_EVENTS': [3, 2, 2],
            'COMPOUND_THREAT_SCORE': [1.25, 1.05, 0.95],
            'CAMPAIGN_CLASSIFICATION': ['ADVANCED_PERSISTENT_THREAT', 'USER_COMPROMISE_CAMPAIGN', 'USER_COMPROMISE_CAMPAIGN']
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
        return pd.DataFrame({
            'CVE_ID': ['CVE-2023-4966', 'CVE-2023-46604', 'CVE-2023-44487'],
            'VULNERABILITY_NAME': ['Citrix NetScaler Buffer Overflow', 'Apache ActiveMQ RCE', 'HTTP/2 Rapid Reset Attack'],
            'CVSS_SCORE': [9.4, 10.0, 7.5],
            'HOSTNAME': ['prod-db-01', 'prod-api-01', 'prod-web-01'],
            'BUSINESS_CRITICALITY': ['critical', 'critical', 'critical'],
            'DATA_CLASSIFICATION': ['confidential', 'restricted', 'confidential'],
            'ENVIRONMENT': ['production', 'production', 'production'],
            'AI_RISK_SCORE': [10.15, 10.50, 8.75],
            'PRIORITY_CLASSIFICATION': ['CRITICAL', 'CRITICAL', 'HIGH'],
            'RECOMMENDED_ACTION': ['EMERGENCY_PATCH', 'EMERGENCY_PATCH', 'IMMEDIATE_PATCH'],
            'PATCH_URGENCY': ['OVERDUE', 'URGENT', 'URGENT']
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
        return pd.DataFrame({
            'EMPLOYEE_ID': ['EMP006', 'EMP007', 'EMP006'],
            'USERNAME': ['alex.turner', 'emily.davis', 'alex.turner'],
            'FULL_NAME': ['Alex Turner', 'Emily Davis', 'Alex Turner'],
            'TERMINATION_DATE': pd.to_datetime(['2024-01-15', '2024-01-20', '2024-01-15']),
            'RESOURCE': ['aws_console', 'jira', 'database_prod'],
            'VIOLATION_TIMESTAMP': pd.to_datetime(['2024-01-18 10:30:00', '2024-01-23 11:20:00', '2024-01-20 14:45:00']),
            'DAYS_OVERDUE': [3, 3, 5],
            'VIOLATION_SEVERITY': ['CRITICAL', 'MEDIUM', 'CRITICAL'],
            'COMPLIANCE_IMPACT_SCORE': [10.0, 5.0, 16.7],
            'SLA_STATUS': ['SLA_VIOLATION', 'SLA_VIOLATION', 'SLA_VIOLATION'],
            'REMEDIATION_ACTION': ['IMMEDIATE_DISABLE_ALL_ACCESS', 'DISABLE_ACCESS_WITHIN_24_HOURS', 'IMMEDIATE_DISABLE_ALL_ACCESS']
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
        return pd.DataFrame({
            'ALERT_ID': ['ALERT_001', 'ALERT_002', 'ALERT_003'],
            'TIMESTAMP': pd.to_datetime(['2024-01-24 14:35:00', '2024-01-23 08:50:00', '2024-01-22 16:20:00']),
            'SEVERITY': ['critical', 'high', 'medium'],
            'TITLE': ['Suspicious User Activity Detected', 'Persistent Port Scanning Detected', 'Terminated Employee Access Detected'],
            'AI_URGENCY_ASSESSMENT': ['HIGH_URGENCY', 'MEDIUM_URGENCY', 'MEDIUM_URGENCY'],
            'AI_THREAT_CLASSIFICATION': ['ACCOUNT_COMPROMISE', 'RECONNAISSANCE', 'ACCOUNT_COMPROMISE'],
            'AI_INVESTIGATION_PRIORITY_SCORE': [6.5, 5.0, 4.0],
            'AI_RECOMMENDED_ACTION': ['RESET_CREDENTIALS_AND_REVIEW_ACCESS_LOGS', 'VERIFY_FIREWALL_RULES_AND_BLOCK_SOURCE_IP', 'RESET_CREDENTIALS_AND_REVIEW_ACCESS_LOGS'],
            'EXTRACTED_IP_ADDRESSES': ["203.0.113.25", "45.33.32.156", "192.168.100.25"],
            'EXTRACTED_DATA_SIZES': ["", "", ""],
            'STATUS': ['investigating', 'resolved', 'resolved']
        })

def main():
    # Header
    st.markdown('<h1 class="main-header">🛡️ Snowflake Cybersecurity AI/ML Demo</h1>', unsafe_allow_html=True)
    st.markdown("**Showcasing AI-Powered Security Analytics in the Data Cloud**")
    
    # Sidebar
    with st.sidebar:
        st.title("🛡️ Security Data Cloud")
        st.markdown("---")
        
        # Demo navigation
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
            current_db = session.get_current_database()
            current_schema = session.get_current_schema()
            if current_db:
                st.info(f"📊 Database: {current_db}")
            if current_schema:
                st.info(f"🏛️ Schema: {current_schema}")
        except Exception as e:
            st.warning("⚠️ Using Demo Mode")
            st.caption("Fallback data loaded")
        
        # Time range
        time_range = st.selectbox(
            "Analysis Period",
            ["Last 24 Hours", "Last 7 Days", "Last 30 Days"],
            index=1
        )

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
        high_anomalies = len(anomaly_data[anomaly_data['ANOMALY_SCORE'] > 5]) if not anomaly_data.empty else 0
        st.metric("Anomalies Detected", high_anomalies, delta="+2")
    with col3:
        critical_anomalies = len(anomaly_data[anomaly_data['CLASSIFICATION'] == 'HIGH_ANOMALY']) if not anomaly_data.empty else 0
        st.metric("High-Risk Anomalies", critical_anomalies, delta="+1")
    with col4:
        st.metric("Avg Detection Time", "12 minutes", delta="-8 min")
    
    # Tabs for different views
    tab1, tab2, tab3 = st.tabs(["🚨 Active Anomalies", "📊 SQL Analytics", "🤖 ML Insights"])
    
    with tab1:
        st.subheader("GitHub Login Anomaly Detection Results")
        
        if not anomaly_data.empty:
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
            
            high_anomalies = anomaly_data[anomaly_data['ANOMALY_SCORE'] > 5]
            for _, row in high_anomalies.iterrows():
                indicators_text = str(row['ANOMALY_INDICATORS']) if row['ANOMALY_INDICATORS'] else ""
                alert_class = "critical-alert" if row['CLASSIFICATION'] == 'HIGH_ANOMALY' else "high-alert"
                
                st.markdown(f"""
                <div class="{alert_class}">
                    <strong>🚨 {row['USERNAME']}</strong> - Score: {row['ANOMALY_SCORE']}<br>
                    <strong>Time:</strong> {row['TIMESTAMP']}<br>
                    <strong>Location:</strong> {row['CURRENT_COUNTRY']} (Hour: {row['CURRENT_HOUR']})<br>
                    <strong>Activity:</strong> {row['ACTIVITY_COUNT']} GitHub actions, {row['LINES_CHANGED']} lines changed<br>
                    <strong>Risk Indicators:</strong> {indicators_text}
                </div>
                """, unsafe_allow_html=True)
        else:
            st.info("No anomaly data available. Please ensure the schema is set up correctly.")
        
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
FROM GITHUB_LOGIN_ANOMALY_DETECTION;
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
        campaigns = len(threat_data[threat_data['CAMPAIGN_CLASSIFICATION'] != 'ISOLATED_INCIDENT']) if not threat_data.empty else 0
        st.metric("Active Campaigns", campaigns, delta="+1")
    with col2:
        high_conf = len(threat_data[threat_data['CONFIDENCE_SCORE'] > 0.9]) if not threat_data.empty else 0
        st.metric("High Confidence Threats", high_conf, delta="+2")
    with col3:
        total_events = threat_data['RELATED_EVENTS'].sum() if not threat_data.empty else 0
        st.metric("Correlated Events", total_events, delta="+5")
    with col4:
        st.metric("Avg Response Time", "18 minutes", delta="-12 min")
    
    if not threat_data.empty:
        # Threat correlation timeline
        fig = px.scatter(
            threat_data,
            x='TIMESTAMP',
            y='COMPOUND_THREAT_SCORE',
            color='CAMPAIGN_CLASSIFICATION',
            size='RELATED_EVENTS',
            hover_data=['PRIMARY_ASSET', 'THREAT_CATEGORY'],
            title="Correlated Threat Events Timeline"
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # APT Detection
        apt_threats = threat_data[threat_data['CAMPAIGN_CLASSIFICATION'] == 'ADVANCED_PERSISTENT_THREAT']
        if not apt_threats.empty:
            apt_threat = apt_threats.iloc[0]
            st.markdown(f"""
            <div class="critical-alert">
            <h4>🚨 APT Campaign Detected</h4>
            <strong>Primary Asset:</strong> {apt_threat['PRIMARY_ASSET']}<br>
            <strong>Threat Score:</strong> {apt_threat['COMPOUND_THREAT_SCORE']}<br>
            <strong>Related Events:</strong> {apt_threat['RELATED_EVENTS']}<br>
            <strong>Confidence:</strong> {apt_threat['CONFIDENCE_SCORE'] * 100:.1f}%<br>
            </div>
            """, unsafe_allow_html=True)

def show_vulnerability_prioritization():
    st.markdown('<div class="use-case-header">⚠️ Use Case 3: AI-Powered Vulnerability Prioritization</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Prioritize vulnerability patching using AI that considers business context, not just CVSS scores. Reduce vulnerability backlog by 70%.
    </div>
    """, unsafe_allow_html=True)
    
    vuln_data = get_vulnerability_data()
    
    if not vuln_data.empty:
        # Comparison chart: CVSS vs AI Risk Score
        fig = make_subplots(
            rows=1, cols=2,
            subplot_titles=('Traditional CVSS Scoring', 'AI-Enhanced Risk Scoring')
        )
        
        fig.add_trace(
            go.Bar(x=vuln_data['CVE_ID'], y=vuln_data['CVSS_SCORE'], name='CVSS Score'),
            row=1, col=1
        )
        
        fig.add_trace(
            go.Bar(x=vuln_data['CVE_ID'], y=vuln_data['AI_RISK_SCORE'], name='AI Risk Score'),
            row=1, col=2
        )
        
        fig.update_layout(height=500, title_text="CVSS vs AI-Enhanced Risk Scoring")
        st.plotly_chart(fig, use_container_width=True)

def show_grc_compliance():
    st.markdown('<div class="use-case-header">📋 Use Case 4: Automated GRC & Compliance</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Automate compliance monitoring and evidence collection. Improve CIS Control 16 compliance from 60% to 95%.
    </div>
    """, unsafe_allow_html=True)
    
    compliance_data = get_compliance_data()
    
    if not compliance_data.empty:
        # Violation timeline
        fig = px.scatter(
            compliance_data,
            x='VIOLATION_TIMESTAMP',
            y='COMPLIANCE_IMPACT_SCORE',
            color='VIOLATION_SEVERITY',
            size='DAYS_OVERDUE',
            hover_data=['USERNAME', 'RESOURCE'],
            title="Access Control Violations Timeline"
        )
        st.plotly_chart(fig, use_container_width=True)

def show_ai_alert_triage():
    st.markdown('<div class="use-case-header">🤖 Use Case 5: AI-Powered Alert Triage</div>', unsafe_allow_html=True)
    
    st.markdown("""
    <div class="demo-callout">
    <strong>Business Value:</strong> Use Snowflake Cortex LLMs to automatically classify, prioritize, and enrich security alerts. Reduce alert fatigue by 60%.
    </div>
    """, unsafe_allow_html=True)
    
    alerts_data = get_ai_alerts_data()
    
    if not alerts_data.empty:
        # Alert priority matrix
        fig = px.scatter(
            alerts_data,
            x='TIMESTAMP',
            y='AI_INVESTIGATION_PRIORITY_SCORE',
            color='AI_THREAT_CLASSIFICATION',
            size='AI_INVESTIGATION_PRIORITY_SCORE',
            hover_data=['TITLE', 'AI_URGENCY_ASSESSMENT'],
            title="AI Alert Prioritization Timeline"
        )
        fig.add_hline(y=6, line_dash="dash", line_color="red", annotation_text="High Priority Threshold")
        st.plotly_chart(fig, use_container_width=True)
        
        st.markdown("**Cortex AI Functions Demo:**")
        st.code("""
-- Snowflake Cortex LLM functions for security alert analysis
SELECT 
    alert_id,
    SNOWFLAKE.CORTEX.SUMMARIZE(description) as ai_summary,
    SNOWFLAKE.CORTEX.SENTIMENT(description) as urgency,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        description, 
        'What IP addresses are mentioned?'
    ) as extracted_ips
FROM security_alerts;
        """, language='sql')

if __name__ == "__main__":
    main()