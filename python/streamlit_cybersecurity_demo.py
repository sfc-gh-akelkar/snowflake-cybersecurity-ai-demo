"""
🛡️ SNOWFLAKE CYBERSECURITY AI/ML DEMO
=====================================
Comprehensive Streamlit in Snowflake application demonstrating
cybersecurity capabilities and AI/ML use cases.

Use Cases Demonstrated:
- Cost-Effective Security Data Platform
- Threat Hunting & IR Automation  
- AI/ML Anomaly Detection
- Threat Prioritization
- Vulnerability Management
- Fraud Detection
- Security Chatbot with LLM
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np
from datetime import datetime, timedelta
import json

# Import Snowflake modules
from snowflake.snowpark.context import get_active_session

# Configure Streamlit page
st.set_page_config(
    page_title="🛡️ Snowflake Cybersecurity AI/ML Demo",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Get Snowflake session
session = get_active_session()

# =====================================================
# UTILITY FUNCTIONS
# =====================================================

@st.cache_data(ttl=300)  # Cache for 5 minutes
def run_query(query):
    """Execute SQL query and return results as DataFrame"""
    try:
        result = session.sql(query).to_pandas()
        return result
    except Exception as e:
        st.error(f"Query error: {str(e)}")
        return pd.DataFrame()

def create_metric_card(title, value, delta=None, delta_color="normal"):
    """Create a styled metric card"""
    delta_html = ""
    if delta:
        color = "green" if delta_color == "good" else "red" if delta_color == "bad" else "gray"
        delta_html = f'<span style="color: {color}; font-size: 14px;">({delta})</span>'
    
    st.markdown(f"""
    <div style="
        background: linear-gradient(90deg, #1f1f2e 0%, #2d2d44 100%);
        padding: 1rem;
        border-radius: 10px;
        border: 1px solid #444;
        text-align: center;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    ">
        <h3 style="color: #fff; margin: 0; font-size: 2rem;">{value}</h3>
        <p style="color: #aaa; margin: 0.5rem 0 0 0; font-size: 14px;">{title} {delta_html}</p>
    </div>
    """, unsafe_allow_html=True)

# =====================================================
# SIDEBAR NAVIGATION
# =====================================================

st.sidebar.title("🛡️ Cybersecurity Demo")
st.sidebar.markdown("**Snowflake AI/ML Platform**")

demo_sections = {
    "🏠 Executive Dashboard": "dashboard",
    "🔍 Anomaly Detection": "anomaly",
    "⚠️ Threat Prioritization": "threats", 
    "🔓 Vulnerability Management": "vulnerabilities",
    "💰 Fraud Detection": "fraud",
    "🕵️ Insider Threat Detection": "insider",
    "🔎 Threat Hunting": "hunting",
    "🤖 Security Chatbot": "chatbot",
    "📊 Cost & Performance": "performance"
}

selected_section = st.sidebar.selectbox("Select Demo Section", list(demo_sections.keys()))
current_section = demo_sections[selected_section]

# Database info
st.sidebar.markdown("---")
st.sidebar.info("""
**Database:** CYBERSECURITY_DEMO  
**Schema:** SECURITY_AI  
**Compute:** Auto-scaling  
**Storage:** Pay-per-use
""")

# =====================================================
# MAIN APPLICATION CONTENT
# =====================================================

if current_section == "dashboard":
    st.title("🏠 Executive Security Dashboard")
    st.markdown("**Real-time cybersecurity metrics powered by Snowflake AI/ML**")
    
    # Get dashboard summary data
    summary_data = run_query("SELECT * FROM SECURITY_DASHBOARD_SUMMARY")
    
    if not summary_data.empty:
        summary = summary_data.iloc[0]
        
        # Top metrics row
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            create_metric_card(
                "Critical Anomalies", 
                summary.get('CRITICAL_LOGIN_ANOMALIES', 0), 
                "+2 from yesterday", 
                "bad"
            )
        
        with col2:
            create_metric_card(
                "P0 Incidents", 
                summary.get('P0_INCIDENTS', 0),
                "Requires immediate action",
                "bad"
            )
        
        with col3:
            create_metric_card(
                "Critical Vulns", 
                summary.get('CRITICAL_VULNS', 0),
                "Patch immediately",
                "bad"
            )
        
        with col4:
            create_metric_card(
                "Fraud Detected", 
                f"${summary.get('SUSPICIOUS_TRANSACTION_AMOUNT', 0):,.0f}",
                "Blocked transactions",
                "good"
            )
        
        with col5:
            create_metric_card(
                "Threat Intel Hits", 
                summary.get('THREAT_INTEL_MATCHES_TODAY', 0),
                "Known bad actors",
                "bad"
            )
    
    st.markdown("---")
    
    # Charts row
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("🚨 Anomaly Detection Overview")
        
        anomaly_data = run_query("""
        SELECT 
            risk_level,
            COUNT(*) as count,
            DATE(timestamp) as date
        FROM LOGIN_ANOMALY_DETECTION 
        WHERE timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        GROUP BY risk_level, DATE(timestamp)
        ORDER BY date DESC
        """)
        
        if not anomaly_data.empty:
            fig = px.bar(
                anomaly_data, 
                x='DATE', 
                y='COUNT', 
                color='RISK_LEVEL',
                color_discrete_map={
                    'CRITICAL': '#ff4444',
                    'HIGH': '#ff8800', 
                    'MEDIUM': '#ffcc00',
                    'LOW': '#88cc88'
                },
                title="Anomalies by Risk Level (Last 7 Days)"
            )
            fig.update_layout(height=400, showlegend=True)
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("💰 Fraud Detection Trends")
        
        fraud_data = run_query("""
        SELECT 
            DATE(timestamp) as date,
            fraud_classification,
            COUNT(*) as transaction_count,
            SUM(amount) as total_amount
        FROM FRAUD_DETECTION_SCORING
        WHERE timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        GROUP BY DATE(timestamp), fraud_classification
        ORDER BY date DESC
        """)
        
        if not fraud_data.empty:
            fig = px.line(
                fraud_data,
                x='DATE',
                y='TOTAL_AMOUNT', 
                color='FRAUD_CLASSIFICATION',
                title="Fraud Detection by Amount (Last 7 Days)",
                color_discrete_map={
                    'HIGH_RISK': '#ff4444',
                    'MEDIUM_RISK': '#ffcc00',
                    'LOW_RISK': '#88cc88',
                    'NORMAL': '#4488cc'
                }
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)

elif current_section == "anomaly":
    st.title("🔍 AI-Powered Anomaly Detection")
    st.markdown("**Machine learning models detecting suspicious user behavior patterns**")
    
    # Filter controls
    col1, col2, col3 = st.columns(3)
    with col1:
        risk_filter = st.selectbox("Risk Level", ["All", "CRITICAL", "HIGH", "MEDIUM", "LOW"])
    with col2:
        days_back = st.slider("Days to analyze", 1, 30, 7)
    with col3:
        user_filter = st.text_input("Filter by user (optional)")
    
    # Build query with filters
    where_conditions = [f"timestamp >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())"]
    if risk_filter != "All":
        where_conditions.append(f"risk_level = '{risk_filter}'")
    if user_filter:
        where_conditions.append(f"username ILIKE '%{user_filter}%'")
    
    where_clause = " AND ".join(where_conditions)
    
    anomaly_query = f"""
    SELECT 
        username,
        timestamp,
        current_country as country,
        current_hour as hour,
        anomaly_score,
        risk_level,
        anomaly_indicators,
        source_ip,
        threat_intel_match
    FROM LOGIN_ANOMALY_DETECTION 
    WHERE {where_clause}
    ORDER BY anomaly_score DESC, timestamp DESC
    """
    
    anomaly_data = run_query(anomaly_query)
    
    if not anomaly_data.empty:
        # Summary metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Total Anomalies", len(anomaly_data))
        with col2:
            st.metric("Avg Anomaly Score", f"{anomaly_data['ANOMALY_SCORE'].mean():.2f}")
        with col3:
            critical_count = len(anomaly_data[anomaly_data['RISK_LEVEL'] == 'CRITICAL'])
            st.metric("Critical Risk", critical_count, delta=f"{critical_count/len(anomaly_data)*100:.1f}%")
        with col4:
            threat_intel_hits = anomaly_data['THREAT_INTEL_MATCH'].sum()
            st.metric("Threat Intel Matches", threat_intel_hits)
        
        # Risk Level Distribution
        st.subheader("📊 Risk Level Distribution")
        risk_counts = anomaly_data['RISK_LEVEL'].value_counts()
        
        risk_cols = st.columns(len(risk_counts))
        colors = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🟢'}
        
        for i, (risk_level, count) in enumerate(risk_counts.items()):
            with risk_cols[i]:
                percentage = (count / len(anomaly_data)) * 100
                st.metric(
                    label=f"{colors.get(risk_level, '⚪')} {risk_level}",
                    value=count,
                    delta=f"{percentage:.1f}%"
                )
        
        # Visualization
        col1, col2 = st.columns(2)
        
        with col1:
            # Anomaly score line chart (SiS-compatible)
            fig = px.line(
                anomaly_data.sort_values('TIMESTAMP'),
                x='TIMESTAMP',
                y='ANOMALY_SCORE',
                color='RISK_LEVEL',
                title="Anomaly Scores Over Time",
                color_discrete_map={
                    'CRITICAL': '#ff4444',
                    'HIGH': '#ff8800',
                    'MEDIUM': '#ffcc00', 
                    'LOW': '#88cc88'
                },
                markers=True
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Geographic distribution (Native Streamlit - 100% SiS compatible)
            st.subheader("🌍 Anomalies by Country")
            country_counts = anomaly_data['COUNTRY'].value_counts()
            
            # Use native Streamlit bar chart (most reliable in SiS)
            st.bar_chart(country_counts, height=400)
        
        # Detailed table
        st.subheader("🔍 Detailed Anomaly Analysis")
        
        # Format the data for display
        display_data = anomaly_data.copy()
        display_data['TIMESTAMP'] = pd.to_datetime(display_data['TIMESTAMP']).dt.strftime('%Y-%m-%d %H:%M')
        display_data['ANOMALY_INDICATORS'] = display_data['ANOMALY_INDICATORS'].apply(
            lambda x: ', '.join(eval(x)) if x and x != '[]' else 'None'
        )
        
        st.dataframe(
            display_data,
            column_config={
                "RISK_LEVEL": st.column_config.SelectboxColumn(
                    "Risk Level",
                    options=["CRITICAL", "HIGH", "MEDIUM", "LOW"],
                ),
                "ANOMALY_SCORE": st.column_config.ProgressColumn(
                    "Anomaly Score",
                    min_value=0,
                    max_value=20,
                ),
            },
            use_container_width=True
        )
    else:
        st.info("No anomalies found for the selected criteria.")

elif current_section == "threats":
    st.title("⚠️ AI-Driven Threat Prioritization")
    st.markdown("**Machine learning algorithms ranking threats by impact and context**")
    
    # Get threat prioritization data
    threat_data = run_query("""
    SELECT 
        incident_id,
        title,
        severity,
        status,
        created_at,
        ml_priority_score,
        priority_classification,
        asset_criticality_score,
        threat_intel_matches,
        estimated_impact_score,
        affected_systems
    FROM THREAT_PRIORITIZATION_SCORING
    ORDER BY ml_priority_score DESC, created_at DESC
    """)
    
    if not threat_data.empty:
        # Summary metrics
        col1, col2, col3, col4 = st.columns(4)
        
        p0_count = len(threat_data[threat_data['PRIORITY_CLASSIFICATION'] == 'P0_CRITICAL'])
        p1_count = len(threat_data[threat_data['PRIORITY_CLASSIFICATION'] == 'P1_HIGH'])
        open_incidents = len(threat_data[threat_data['STATUS'] == 'open'])
        avg_priority = threat_data['ML_PRIORITY_SCORE'].mean()
        
        with col1:
            st.metric("P0 Critical", p0_count, delta="Immediate action required")
        with col2:
            st.metric("P1 High", p1_count, delta="High priority")
        with col3:
            st.metric("Open Incidents", open_incidents)
        with col4:
            st.metric("Avg ML Score", f"{avg_priority:.1f}/100")
        
        # Priority distribution chart
        col1, col2 = st.columns(2)
        
        with col1:
            priority_counts = threat_data['PRIORITY_CLASSIFICATION'].value_counts()
            fig = px.bar(
                x=priority_counts.index,
                y=priority_counts.values,
                color=priority_counts.index,
                title="Threat Priority Distribution",
                color_discrete_map={
                    'P0_CRITICAL': '#ff4444',
                    'P1_HIGH': '#ff8800',
                    'P2_MEDIUM': '#ffcc00',
                    'P3_LOW': '#88cc88'
                }
            )
            fig.update_layout(height=400, showlegend=False)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # ML Score vs Time
            fig = px.scatter(
                threat_data,
                x='CREATED_AT',
                y='ML_PRIORITY_SCORE',
                color='PRIORITY_CLASSIFICATION',
                size='THREAT_INTEL_MATCHES',
                hover_data=['TITLE', 'SEVERITY'],
                title="ML Priority Scores Timeline",
                color_discrete_map={
                    'P0_CRITICAL': '#ff4444',
                    'P1_HIGH': '#ff8800', 
                    'P2_MEDIUM': '#ffcc00',
                    'P3_LOW': '#88cc88'
                }
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        # Detailed threat analysis
        st.subheader("🎯 Prioritized Threat Queue")
        
        # Format for display
        display_threats = threat_data.copy()
        display_threats['CREATED_AT'] = pd.to_datetime(display_threats['CREATED_AT']).dt.strftime('%Y-%m-%d %H:%M')
        display_threats['AFFECTED_SYSTEMS'] = display_threats['AFFECTED_SYSTEMS'].apply(
            lambda x: ', '.join(eval(x)) if x and isinstance(x, str) else 'Unknown'
        )
        
        st.dataframe(
            display_threats,
            column_config={
                "ML_PRIORITY_SCORE": st.column_config.ProgressColumn(
                    "ML Priority Score",
                    min_value=0,
                    max_value=100,
                ),
                "PRIORITY_CLASSIFICATION": st.column_config.SelectboxColumn(
                    "Priority",
                    options=["P0_CRITICAL", "P1_HIGH", "P2_MEDIUM", "P3_LOW"],
                ),
                "STATUS": st.column_config.SelectboxColumn(
                    "Status",
                    options=["open", "investigating", "resolved", "closed"],
                ),
            },
            use_container_width=True
        )

elif current_section == "vulnerabilities":
    st.title("🔓 AI-Enhanced Vulnerability Management")
    st.markdown("**Smart vulnerability prioritization using CVSS, context, and threat intelligence**")
    
    # Get vulnerability data
    vuln_data = run_query("""
    SELECT 
        vuln_id,
        asset_name,
        cve_id,
        cvss_score,
        severity,
        status,
        enhanced_priority_score,
        ai_recommendation,
        exploit_availability_score,
        asset_exposure_score,
        threat_intel_mentions,
        first_detected,
        age_multiplier
    FROM VULNERABILITY_PRIORITIZATION
    ORDER BY enhanced_priority_score DESC
    """)
    
    if not vuln_data.empty:
        # Summary metrics
        col1, col2, col3, col4 = st.columns(4)
        
        patch_immediately = len(vuln_data[vuln_data['AI_RECOMMENDATION'] == 'PATCH_IMMEDIATELY'])
        critical_vulns = len(vuln_data[vuln_data['SEVERITY'] == 'critical'])
        open_vulns = len(vuln_data[vuln_data['STATUS'] == 'open'])
        avg_cvss = vuln_data['CVSS_SCORE'].mean()
        
        with col1:
            st.metric("Patch Immediately", patch_immediately, delta="Critical priority")
        with col2:
            st.metric("Critical Vulns", critical_vulns)
        with col3:
            st.metric("Open Vulns", open_vulns)
        with col4:
            st.metric("Avg CVSS Score", f"{avg_cvss:.1f}/10")
        
        # Visualizations
        col1, col2 = st.columns(2)
        
        with col1:
            # CVSS vs AI Priority Score
            fig = px.scatter(
                vuln_data,
                x='CVSS_SCORE',
                y='ENHANCED_PRIORITY_SCORE',
                color='AI_RECOMMENDATION',
                size='THREAT_INTEL_MENTIONS',
                hover_data=['CVE_ID', 'ASSET_NAME'],
                title="CVSS Score vs AI Priority Score",
                color_discrete_map={
                    'PATCH_IMMEDIATELY': '#ff4444',
                    'PATCH_THIS_WEEK': '#ff8800',
                    'PATCH_THIS_MONTH': '#ffcc00',
                    'PATCH_NEXT_CYCLE': '#88cc88'
                }
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Recommendation distribution
            rec_counts = vuln_data['AI_RECOMMENDATION'].value_counts()
            fig = px.pie(
                values=rec_counts.values,
                names=rec_counts.index,
                title="AI Patch Recommendations"
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        # Detailed vulnerability table
        st.subheader("🔍 Vulnerability Analysis")
        
        display_vulns = vuln_data.copy()
        display_vulns['FIRST_DETECTED'] = pd.to_datetime(display_vulns['FIRST_DETECTED']).dt.strftime('%Y-%m-%d')
        
        st.dataframe(
            display_vulns,
            column_config={
                "ENHANCED_PRIORITY_SCORE": st.column_config.ProgressColumn(
                    "AI Priority Score",
                    min_value=0,
                    max_value=100,
                ),
                "CVSS_SCORE": st.column_config.ProgressColumn(
                    "CVSS Score",
                    min_value=0,
                    max_value=10,
                ),
                "AI_RECOMMENDATION": st.column_config.SelectboxColumn(
                    "AI Recommendation",
                    options=["PATCH_IMMEDIATELY", "PATCH_THIS_WEEK", "PATCH_THIS_MONTH", "PATCH_NEXT_CYCLE"],
                ),
                "STATUS": st.column_config.SelectboxColumn(
                    "Status",
                    options=["open", "patched", "accepted_risk"],
                ),
            },
            use_container_width=True
        )

elif current_section == "fraud":
    st.title("💰 Machine Learning Fraud Detection")
    st.markdown("**Real-time transaction analysis using advanced ML algorithms**")
    
    # Get fraud detection data
    fraud_data = run_query("""
    SELECT 
        transaction_id,
        timestamp,
        user_id,
        transaction_type,
        amount,
        currency,
        location,
        ml_fraud_score,
        fraud_classification,
        transactions_last_hour,
        amount_last_24h,
        prev_country
    FROM FRAUD_DETECTION_SCORING
    WHERE timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    ORDER BY ml_fraud_score DESC, timestamp DESC
    """)
    
    if not fraud_data.empty:
        # Extract location country for analysis
        fraud_data['COUNTRY'] = fraud_data['LOCATION'].apply(
            lambda x: json.loads(x)['country'] if x else 'Unknown'
        )
        
        # Summary metrics
        col1, col2, col3, col4 = st.columns(4)
        
        high_risk_count = len(fraud_data[fraud_data['FRAUD_CLASSIFICATION'] == 'HIGH_RISK'])
        total_suspicious_amount = fraud_data[
            fraud_data['FRAUD_CLASSIFICATION'].isin(['HIGH_RISK', 'MEDIUM_RISK'])
        ]['AMOUNT'].sum()
        avg_fraud_score = fraud_data['ML_FRAUD_SCORE'].mean()
        unique_users = fraud_data['USER_ID'].nunique()
        
        with col1:
            st.metric("High Risk Transactions", high_risk_count)
        with col2:
            st.metric("Suspicious Amount", f"${total_suspicious_amount:,.2f}")
        with col3:
            st.metric("Avg Fraud Score", f"{avg_fraud_score:.3f}")
        with col4:
            st.metric("Affected Users", unique_users)
        
        # Visualizations
        col1, col2 = st.columns(2)
        
        with col1:
            # Fraud score distribution
            fig = px.histogram(
                fraud_data,
                x='ML_FRAUD_SCORE',
                color='FRAUD_CLASSIFICATION',
                title="Fraud Score Distribution",
                nbins=20,
                color_discrete_map={
                    'HIGH_RISK': '#ff4444',
                    'MEDIUM_RISK': '#ffcc00',
                    'LOW_RISK': '#88cc88',
                    'NORMAL': '#4488cc'
                }
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Geographic fraud distribution
            country_fraud = fraud_data.groupby('COUNTRY').agg({
                'ML_FRAUD_SCORE': 'mean',
                'AMOUNT': 'sum'
            }).reset_index()
            
            fig = px.scatter(
                country_fraud,
                x='ML_FRAUD_SCORE',
                y='AMOUNT',
                size='AMOUNT',
                hover_data=['COUNTRY'],
                title="Fraud Risk by Country"
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        # Transaction timeline
        st.subheader("📈 Fraud Detection Timeline")
        
        # Group by hour for timeline
        fraud_timeline = fraud_data.groupby([
            pd.to_datetime(fraud_data['TIMESTAMP']).dt.floor('H'),
            'FRAUD_CLASSIFICATION'
        ]).size().reset_index(name='count')
        fraud_timeline.columns = ['hour', 'classification', 'count']
        
        fig = px.line(
            fraud_timeline,
            x='hour',
            y='count',
            color='classification',
            title="Fraud Detection Over Time",
            color_discrete_map={
                'HIGH_RISK': '#ff4444',
                'MEDIUM_RISK': '#ffcc00',
                'LOW_RISK': '#88cc88',
                'NORMAL': '#4488cc'
            }
        )
        fig.update_layout(height=400)
        st.plotly_chart(fig, use_container_width=True)
        
        # Detailed transactions
        st.subheader("💳 Transaction Analysis")
        
        # Filter for high/medium risk only
        risk_filter = st.selectbox(
            "Filter by Risk Level",
            ["All", "HIGH_RISK", "MEDIUM_RISK", "LOW_RISK", "NORMAL"]
        )
        
        if risk_filter != "All":
            display_data = fraud_data[fraud_data['FRAUD_CLASSIFICATION'] == risk_filter]
        else:
            display_data = fraud_data
        
        display_data_formatted = display_data.copy()
        display_data_formatted['TIMESTAMP'] = pd.to_datetime(
            display_data_formatted['TIMESTAMP']
        ).dt.strftime('%Y-%m-%d %H:%M')
        
        st.dataframe(
            display_data_formatted[[
                'TRANSACTION_ID', 'TIMESTAMP', 'USER_ID', 'TRANSACTION_TYPE',
                'AMOUNT', 'COUNTRY', 'ML_FRAUD_SCORE', 'FRAUD_CLASSIFICATION'
            ]],
            column_config={
                "ML_FRAUD_SCORE": st.column_config.ProgressColumn(
                    "Fraud Score",
                    min_value=0,
                    max_value=1,
                ),
                "AMOUNT": st.column_config.NumberColumn(
                    "Amount",
                    format="$%.2f"
                ),
                "FRAUD_CLASSIFICATION": st.column_config.SelectboxColumn(
                    "Risk Level",
                    options=["HIGH_RISK", "MEDIUM_RISK", "LOW_RISK", "NORMAL"],
                ),
            },
            use_container_width=True
        )

elif current_section == "insider":
    st.title("🕵️ Insider Threat Detection")
    st.markdown("**Behavioral analytics to identify potential insider threats**")
    
    # Get insider threat data
    insider_data = run_query("""
    SELECT 
        username,
        department,
        status,
        login_anomalies_30d,
        total_data_accessed_30d,
        avg_daily_data_access,
        off_hours_activity_30d,
        insider_threat_score,
        insider_threat_classification
    FROM INSIDER_THREAT_DETECTION
    ORDER BY insider_threat_score DESC
    """)
    
    if not insider_data.empty:
        # Summary metrics
        col1, col2, col3, col4 = st.columns(4)
        
        high_risk_users = len(insider_data[insider_data['INSIDER_THREAT_CLASSIFICATION'] == 'HIGH_RISK'])
        terminated_users = len(insider_data[insider_data['STATUS'] == 'terminated'])
        avg_threat_score = insider_data['INSIDER_THREAT_SCORE'].mean()
        total_anomalies = insider_data['LOGIN_ANOMALIES_30D'].sum()
        
        with col1:
            st.metric("High Risk Users", high_risk_users, delta="Requires investigation")
        with col2:
            st.metric("Terminated Users", terminated_users, delta="Access monitoring")
        with col3:
            st.metric("Avg Threat Score", f"{avg_threat_score:.1f}/100")
        with col4:
            st.metric("Login Anomalies (30d)", total_anomalies)
        
        # Visualizations
        col1, col2 = st.columns(2)
        
        with col1:
            # Risk distribution by department
            dept_risk = insider_data.groupby(['DEPARTMENT', 'INSIDER_THREAT_CLASSIFICATION']).size().reset_index(name='count')
            fig = px.bar(
                dept_risk,
                x='DEPARTMENT',
                y='count',
                color='INSIDER_THREAT_CLASSIFICATION',
                title="Insider Threat Risk by Department",
                color_discrete_map={
                    'HIGH_RISK': '#ff4444',
                    'MEDIUM_RISK': '#ffcc00',
                    'LOW_RISK': '#88cc88',
                    'NORMAL': '#4488cc'
                }
            )
            fig.update_layout(height=400)
            fig.update_xaxes(tickangle=45)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Scatter plot: Data access vs Off-hours activity
            fig = px.scatter(
                insider_data,
                x='OFF_HOURS_ACTIVITY_30D',
                y='TOTAL_DATA_ACCESSED_30D',
                color='INSIDER_THREAT_CLASSIFICATION',
                size='INSIDER_THREAT_SCORE',
                hover_data=['USERNAME', 'DEPARTMENT'],
                title="Data Access vs Off-Hours Activity",
                color_discrete_map={
                    'HIGH_RISK': '#ff4444',
                    'MEDIUM_RISK': '#ffcc00',
                    'LOW_RISK': '#88cc88',
                    'NORMAL': '#4488cc'
                }
            )
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
        
        # Risk factors analysis
        st.subheader("🔍 Risk Factors Analysis")
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            # Login anomalies distribution
            fig = px.histogram(
                insider_data,
                x='LOGIN_ANOMALIES_30D',
                title="Login Anomalies Distribution",
                nbins=10
            )
            fig.update_layout(height=300)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Off-hours activity
            fig = px.histogram(
                insider_data,
                x='OFF_HOURS_ACTIVITY_30D',
                title="Off-Hours Activity Distribution",
                nbins=10
            )
            fig.update_layout(height=300)
            st.plotly_chart(fig, use_container_width=True)
        
        with col3:
            # Threat score distribution
            fig = px.histogram(
                insider_data,
                x='INSIDER_THREAT_SCORE',
                color='INSIDER_THREAT_CLASSIFICATION',
                title="Threat Score Distribution",
                nbins=10,
                color_discrete_map={
                    'HIGH_RISK': '#ff4444',
                    'MEDIUM_RISK': '#ffcc00',
                    'LOW_RISK': '#88cc88',
                    'NORMAL': '#4488cc'
                }
            )
            fig.update_layout(height=300)
            st.plotly_chart(fig, use_container_width=True)
        
        # Detailed user analysis
        st.subheader("👥 User Risk Assessment")
        
        # Filter controls
        col1, col2 = st.columns(2)
        with col1:
            dept_filter = st.selectbox(
                "Filter by Department",
                ["All"] + list(insider_data['DEPARTMENT'].unique())
            )
        with col2:
            risk_filter = st.selectbox(
                "Filter by Risk Level",
                ["All", "HIGH_RISK", "MEDIUM_RISK", "LOW_RISK", "NORMAL"]
            )
        
        # Apply filters
        filtered_data = insider_data.copy()
        if dept_filter != "All":
            filtered_data = filtered_data[filtered_data['DEPARTMENT'] == dept_filter]
        if risk_filter != "All":
            filtered_data = filtered_data[filtered_data['INSIDER_THREAT_CLASSIFICATION'] == risk_filter]
        
        st.dataframe(
            filtered_data,
            column_config={
                "INSIDER_THREAT_SCORE": st.column_config.ProgressColumn(
                    "Threat Score",
                    min_value=0,
                    max_value=100,
                ),
                "INSIDER_THREAT_CLASSIFICATION": st.column_config.SelectboxColumn(
                    "Risk Level",
                    options=["HIGH_RISK", "MEDIUM_RISK", "LOW_RISK", "NORMAL"],
                ),
                "STATUS": st.column_config.SelectboxColumn(
                    "Status",
                    options=["active", "terminated", "suspended"],
                ),
                "TOTAL_DATA_ACCESSED_30D": st.column_config.NumberColumn(
                    "Data Accessed (30d)",
                    format="%d bytes"
                ),
            },
            use_container_width=True
        )

elif current_section == "hunting":
    st.title("🔎 Threat Hunting & Investigation")
    st.markdown("**High-performance search and analysis of security logs**")
    
    # Search interface
    st.subheader("🕵️ Threat Hunting Query Interface")
    
    col1, col2 = st.columns([3, 1])
    with col1:
        search_query = st.text_area(
            "Enter your threat hunting SQL query:",
            value="""-- Example: Search for suspicious network activities
SELECT 
    timestamp,
    source_ip,
    dest_ip,
    protocol,
    bytes_transferred,
    threat_category,
    severity
FROM NETWORK_SECURITY_LOGS
WHERE threat_category != 'legitimate'
    AND timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY severity DESC, timestamp DESC
LIMIT 100;""",
            height=200
        )
    
    with col2:
        st.markdown("**Quick Searches:**")
        if st.button("🔍 Threat Intel Matches"):
            search_query = """
SELECT 
    ual.timestamp,
    ual.username,
    ual.source_ip,
    ti.indicator_value,
    ti.threat_type,
    ti.description
FROM USER_AUTHENTICATION_LOGS ual
JOIN THREAT_INTEL_FEED ti ON ual.source_ip = ti.indicator_value
WHERE ual.timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY ual.timestamp DESC;
"""
        
        if st.button("🚨 Failed Logins"):
            search_query = """
SELECT 
    timestamp,
    username,
    source_ip,
    failure_reason,
    location:country::STRING as country
FROM USER_AUTHENTICATION_LOGS
WHERE success = FALSE
    AND timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY timestamp DESC;
"""
        
        if st.button("📁 Large Data Access"):
            search_query = """
SELECT 
    timestamp,
    username,
    resource_name,
    action,
    bytes_accessed,
    data_classification
FROM DATA_ACCESS_LOGS
WHERE bytes_accessed > 50000000
    AND timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY bytes_accessed DESC;
"""
    
    # Execute search
    if st.button("🔍 Execute Search", type="primary"):
        if search_query.strip():
            with st.spinner("Executing threat hunting query..."):
                try:
                    search_results = run_query(search_query)
                    
                    if not search_results.empty:
                        st.success(f"Found {len(search_results)} results")
                        
                        # Display results
                        st.subheader("📊 Search Results")
                        st.dataframe(search_results, use_container_width=True)
                        
                        # Download option
                        csv = search_results.to_csv(index=False)
                        st.download_button(
                            label="📥 Download Results as CSV",
                            data=csv,
                            file_name=f"threat_hunt_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                            mime="text/csv"
                        )
                    else:
                        st.info("No results found for the given query.")
                        
                except Exception as e:
                    st.error(f"Query execution failed: {str(e)}")
        else:
            st.warning("Please enter a query to execute.")
    
    # Pre-built threat hunting queries
    st.subheader("📚 Pre-built Threat Hunting Queries")
    
    hunting_queries = {
        "Lateral Movement Detection": """
-- Detect potential lateral movement
SELECT 
    ual.timestamp,
    ual.username,
    ual.source_ip,
    dal.resource_name,
    dal.action,
    COUNT(*) OVER (PARTITION BY ual.username ORDER BY ual.timestamp RANGE BETWEEN INTERVAL '1 HOUR' PRECEDING AND CURRENT ROW) as activities_last_hour
FROM USER_AUTHENTICATION_LOGS ual
JOIN DATA_ACCESS_LOGS dal ON ual.username = dal.username 
    AND dal.timestamp BETWEEN ual.timestamp AND DATEADD(hour, 1, ual.timestamp)
WHERE ual.timestamp >= DATEADD(day, -3, CURRENT_TIMESTAMP())
    AND dal.data_classification IN ('confidential', 'restricted')
ORDER BY activities_last_hour DESC, ual.timestamp DESC;
""",
        
        "Data Exfiltration Indicators": """
-- Identify potential data exfiltration
SELECT 
    dal.username,
    DATE(dal.timestamp) as date,
    SUM(dal.bytes_accessed) as total_bytes,
    COUNT(DISTINCT dal.resource_name) as unique_resources,
    COUNT(*) as access_count,
    STRING_AGG(DISTINCT dal.data_classification, ', ') as data_types
FROM DATA_ACCESS_LOGS dal
WHERE dal.timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY dal.username, DATE(dal.timestamp)
HAVING SUM(dal.bytes_accessed) > 100000000 -- >100MB
    OR COUNT(*) > 50 -- >50 accesses per day
ORDER BY total_bytes DESC;
""",
        
        "Compromised Account Indicators": """
-- Detect potentially compromised accounts
SELECT 
    ual.username,
    COUNT(DISTINCT ual.location:country::STRING) as countries,
    COUNT(DISTINCT ual.source_ip) as unique_ips,
    COUNT(*) as total_logins,
    MIN(ual.timestamp) as first_login,
    MAX(ual.timestamp) as last_login,
    SUM(CASE WHEN ual.location:country::STRING != 'US' THEN 1 ELSE 0 END) as foreign_logins
FROM USER_AUTHENTICATION_LOGS ual
WHERE ual.timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND ual.success = TRUE
GROUP BY ual.username
HAVING COUNT(DISTINCT ual.location:country::STRING) > 2
    OR COUNT(DISTINCT ual.source_ip) > 10
ORDER BY foreign_logins DESC, countries DESC;
"""
    }
    
    selected_query = st.selectbox("Select a pre-built query:", list(hunting_queries.keys()))
    
    if st.button("📋 Load Query"):
        st.code(hunting_queries[selected_query], language="sql")
    
    # Performance metrics
    st.subheader("⚡ Performance Metrics")
    
    perf_col1, perf_col2, perf_col3, perf_col4 = st.columns(4)
    
    with perf_col1:
        st.metric("Search Performance", "< 2 seconds", delta="99.9% queries")
    with perf_col2:
        st.metric("Data Retention", "7 years", delta="Full fidelity")
    with perf_col3:
        st.metric("Storage Cost", "$0.02/GB/month", delta="80% savings")
    with perf_col4:
        st.metric("Compute Cost", "Pay-per-use", delta="No idle charges")

elif current_section == "chatbot":
    st.title("🤖 Security Chatbot")
    st.markdown("**AI-powered security assistant for natural language queries**")
    
    # Initialize chat history
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []
    
    # Chat interface
    st.subheader("💬 Ask the Security AI")
    
    # Sample questions
    st.markdown("**Try asking questions like:**")
    sample_questions = [
        "Show me all critical security incidents from today",
        "What are the top 5 vulnerabilities I should patch first?",
        "Which users have the highest insider threat scores?",
        "Find all login attempts from Russia or China",
        "Show me suspicious financial transactions above $5000",
        "What network security events happened in the last hour?"
    ]
    
    for i, question in enumerate(sample_questions):
        if st.button(f"💡 {question}", key=f"sample_{i}"):
            st.session_state.user_input = question
    
    # Chat input
    user_input = st.text_input("Ask a security question:", key="chat_input")
    
    if st.button("Send", type="primary") or user_input:
        if user_input:
            # Add user message to history
            st.session_state.chat_history.append({"role": "user", "content": user_input})
            
            # Generate AI response (simplified - in real implementation would use LLM)
            ai_response = generate_ai_response(user_input)
            
            # Add AI response to history
            st.session_state.chat_history.append({"role": "assistant", "content": ai_response})
            
            # Clear input
            st.session_state.chat_input = ""
    
    # Display chat history
    st.subheader("💬 Conversation History")
    
    for message in st.session_state.chat_history:
        if message["role"] == "user":
            st.markdown(f"**🧑 You:** {message['content']}")
        else:
            st.markdown(f"**🤖 Security AI:** {message['content']}")
    
    # Clear chat button
    if st.button("🗑️ Clear Chat History"):
        st.session_state.chat_history = []
        st.experimental_rerun()

elif current_section == "performance":
    st.title("📊 Cost & Performance Analytics")
    st.markdown("**Demonstrating Snowflake's cost-effective, scalable security platform**")
    
    # Cost comparison
    st.subheader("💰 Cost Comparison: Traditional SIEM vs Snowflake")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("**Traditional SIEM**")
        st.error("**❌ Expensive & Limited**")
        st.markdown("""
        - **$50,000+** per TB/year
        - **90-day** retention typical
        - **Ingest fees** for all data
        - **Limited** search capabilities
        - **Proprietary** query language
        - **Fixed** compute resources
        """)
    
    with col2:
        st.markdown("**Snowflake Security Platform**")
        st.success("**✅ Cost-Effective & Scalable**")
        st.markdown("""
        - **$240** per TB/year storage
        - **7+ years** retention affordable
        - **No ingest tax** - pay for storage only
        - **SQL-based** high-performance search
        - **Standard SQL** - no vendor lock-in
        - **Auto-scaling** compute
        """)
    
    # Performance metrics
    st.subheader("⚡ Performance Benchmarks")
    
    # Create sample performance data
    performance_data = pd.DataFrame({
        'Query Type': ['Threat Hunting', 'Anomaly Detection', 'Fraud Analysis', 'Compliance Reporting'],
        'Traditional SIEM': [45, 30, 60, 120],  # seconds
        'Snowflake': [2, 1, 3, 8],  # seconds
        'Data Volume (GB)': [100, 50, 200, 500]
    })
    
    fig = px.bar(
        performance_data,
        x='Query Type',
        y=['Traditional SIEM', 'Snowflake'],
        title="Query Performance Comparison (seconds)",
        barmode='group'
    )
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)
    
    # Storage costs over time
    st.subheader("📈 Storage Cost Projection")
    
    # Calculate storage growth and costs
    months = list(range(1, 37))  # 3 years
    data_tb = [i * 0.5 for i in months]  # 0.5 TB growth per month
    
    traditional_cost = [tb * 50000 / 12 for tb in data_tb]  # $50k per TB/year
    snowflake_cost = [tb * 240 / 12 for tb in data_tb]  # $240 per TB/year
    
    cost_df = pd.DataFrame({
        'Month': months,
        'Traditional SIEM': traditional_cost,
        'Snowflake': snowflake_cost,
        'Data Volume (TB)': data_tb
    })
    
    fig = px.line(
        cost_df,
        x='Month',
        y=['Traditional SIEM', 'Snowflake'],
        title="Monthly Storage Cost Comparison",
        labels={'value': 'Monthly Cost ($)', 'variable': 'Platform'}
    )
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)
    
    # ROI calculation
    st.subheader("💵 Return on Investment")
    
    col1, col2, col3, col4 = st.columns(4)
    
    total_savings_3yr = sum(traditional_cost) - sum(snowflake_cost)
    
    with col1:
        st.metric("3-Year Savings", f"${total_savings_3yr:,.0f}")
    with col2:
        st.metric("Cost Reduction", "99.5%")
    with col3:
        st.metric("Performance Gain", "20x faster")
    with col4:
        st.metric("Retention Increase", "28x longer")
    
    # Marketplace value proposition
    st.subheader("🏪 Snowflake Marketplace Value")
    
    marketplace_benefits = [
        {"Feature": "Threat Intelligence Feeds", "Value": "No integration costs", "Benefit": "$50k+ saved"},
        {"Feature": "Security Applications", "Value": "Native deployment", "Benefit": "Weeks → Hours"},
        {"Feature": "Partner Ecosystem", "Value": "200+ security vendors", "Benefit": "Best-of-breed choice"},
        {"Feature": "Data Sharing", "Value": "Secure collaboration", "Benefit": "Real-time intel sharing"}
    ]
    
    marketplace_df = pd.DataFrame(marketplace_benefits)
    st.dataframe(marketplace_df, use_container_width=True)

# =====================================================
# HELPER FUNCTIONS
# =====================================================

def generate_ai_response(user_question):
    """Generate AI response for chatbot (simplified implementation)"""
    
    question_lower = user_question.lower()
    
    if "critical" in question_lower and "incident" in question_lower:
        return """I found the current critical security incidents:

**P0 Critical Incidents:**
1. **Suspicious Login from Threat Actor IP** - User john.smith logged in from known APT29 infrastructure
2. **Ransomware Indicators Detected** - Multiple file encryption activities on file server

**Recommended Actions:**
- Immediately isolate affected systems
- Reset user credentials
- Activate incident response team

Would you like me to show the detailed incident analysis?"""
    
    elif "vulnerabilit" in question_lower and ("top" in question_lower or "patch" in question_lower):
        return """Here are the top 5 vulnerabilities requiring immediate attention:

**Patch Immediately:**
1. **CVE-2021-44228** (Log4j) - CVSS 10.0 - web-server-01
2. **CVE-2022-22965** (Spring) - CVSS 9.8 - api-server-01
3. **CVE-2021-26855** (Exchange) - CVSS 7.2 - backup-server-01

**AI Recommendations:**
- These vulnerabilities have known exploits in the wild
- Assets are internet-facing with high exposure
- Patch deployment estimated: 2-4 hours

Would you like me to generate patch deployment scripts?"""
    
    elif "insider threat" in question_lower:
        return """Users with highest insider threat scores:

**High Risk (Score > 70):**
1. **james.wilson** (Score: 100) - Terminated employee with recent access attempts
2. **alex.brown** (Score: 45) - Unusual data access patterns, off-hours activity

**Key Risk Factors:**
- Terminated employee access attempts
- Large data downloads outside business hours
- Multiple login anomalies

**Recommended Actions:**
- Disable access for terminated employees
- Review data access permissions
- Monitor off-hours activities

Need more details on any specific user?"""
    
    elif any(country in question_lower for country in ["russia", "china", "ru", "cn"]):
        return """Found login attempts from Russia and China:

**Recent Foreign Login Attempts:**
- **john.smith** - 203.0.113.45 (Russia) - 2 hours ago ⚠️ **THREAT INTEL MATCH**
- **sarah.chen** - Multiple IPs (Russia) - Last 24 hours
- **alex.brown** - 185.220.100.240 (China) - Failed attempts

**Threat Intelligence Correlation:**
- IPs match known APT infrastructure
- Unusual access patterns detected
- Recommended: Immediate credential reset

Would you like me to show the detailed forensic timeline?"""
    
    elif "transaction" in question_lower and ("suspicious" in question_lower or "5000" in question_lower):
        return """Suspicious financial transactions above $5000:

**High Risk Transactions:**
1. **$9,999.99** - User_1234 to crypto exchange (Russia) - Fraud Score: 0.95
2. **$15,000.00** - User_9999 luxury goods (Miami) - New device - Fraud Score: 0.92
3. **$5,000.00** - User_5678 ATM withdrawal (China) - Fraud Score: 0.88

**Risk Indicators:**
- Foreign transaction locations
- Unusual amounts for user patterns
- New/unknown device fingerprints

**Actions Taken:**
- Transactions flagged for review
- Account holders notified
- Additional verification required

Need details on any specific transaction?"""
    
    elif "network" in question_lower and ("hour" in question_lower or "last" in question_lower):
        return """Network security events from the last hour:

**Threat Events Detected:**
1. **Blocked C2 Communication** - 192.168.1.100 → 203.0.113.45 (APT infrastructure)
2. **Botnet Activity** - 192.168.1.150 → 185.220.100.240 (Emotet C2)
3. **Data Exfiltration** - Large transfer 10.0.0.45 → external IP

**Actions Taken:**
- Malicious traffic blocked by firewall
- Affected systems isolated
- Security team notified

**Status:** 🔴 Active monitoring in progress

Would you like me to show the network flow analysis?"""
    
    else:
        return f"""I understand you're asking about: "{user_question}"

I can help you with:
- 🚨 Security incidents and alerts
- 🔓 Vulnerability management
- 🕵️ Threat hunting queries  
- 💰 Fraud detection analysis
- 👥 Insider threat assessment
- 🌐 Network security events

Please try rephrasing your question or ask about any of these security topics. For complex analysis, I can also generate SQL queries to investigate your security data.

What specific security information would you like me to help you find?"""

# =====================================================
# FOOTER
# =====================================================

st.markdown("---")
st.markdown("""
<div style="text-align: center; color: #666; padding: 20px;">
    <p>🛡️ <strong>Snowflake Cybersecurity AI/ML Demo</strong></p>
    <p>Powered by Snowflake's Native App Platform | Real-time ML Analytics | Cost-Effective Security Data Lake</p>
    <p><em>Demonstrating: Anomaly Detection • Threat Prioritization • Vulnerability Management • Fraud Detection • Security Chatbot</em></p>
</div>
""", unsafe_allow_html=True)
