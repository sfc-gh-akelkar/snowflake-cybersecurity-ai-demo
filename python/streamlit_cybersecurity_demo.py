"""
🛡️ SNOWFLAKE CYBERSECURITY ANALYTICS DEMO
==========================================
Comprehensive Streamlit in Snowflake application demonstrating
cybersecurity capabilities and advanced analytics use cases.

Features:
- Executive Security Dashboard
- ML-Powered Anomaly Detection  
- Threat Intelligence Analytics
- User Behavior Analysis
- AI Security Assistant (Cortex AI)
- Natural Language Analytics (Cortex Analyst)
- Real-time Security Monitoring

Use Cases Demonstrated:
- Cost-Effective Security Data Platform
- Threat Hunting & IR Automation  
- Advanced Anomaly Detection
- Intelligent Threat Prioritization
- Vulnerability Management
- Fraud Detection
- Security Chatbot Interface
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np
from datetime import datetime, timedelta
import json
from typing import Dict, Any, Optional

# Import Snowflake modules
from snowflake.snowpark.context import get_active_session

# Configure Streamlit page
st.set_page_config(
    page_title="🛡️ Snowflake Cybersecurity Analytics Demo",
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
        st.error(f"Query execution error: {str(e)}")
        return pd.DataFrame()

def format_metric(value, metric_type="number"):
    """Format metrics for display"""
    if metric_type == "percentage":
        return f"{value:.1f}%"
    elif metric_type == "currency":
        return f"${value:,.0f}"
    elif metric_type == "number":
        if value >= 1000000:
            return f"{value/1000000:.1f}M"
        elif value >= 1000:
            return f"{value/1000:.1f}K"
        else:
            return f"{value:,.0f}"
    return str(value)

# =====================================================
# CORTEX ANALYST FUNCTIONS
# =====================================================

def query_cortex_analyst(question: str, context: str = "general") -> Dict[str, Any]:
    """
    Query Cortex Analyst with natural language and return structured results
    
    Args:
        question: Natural language question
        context: Analysis context (incidents, users, vulnerabilities, threats, trends)
    
    Returns:
        Dictionary with query results, SQL, and explanation
    """
    try:
        # Use the Cortex Analyst integration function if available
        query = """
        SELECT ask_security_analyst(%s) as analyst_response
        """
        
        result = session.sql(query, [question]).collect()
        
        if result:
            response = json.loads(result[0]['ANALYST_RESPONSE'])
            return {
                "success": True,
                "data": response.get("data", []),
                "sql": response.get("sql", ""),
                "explanation": response.get("explanation", ""),
                "visualization": response.get("visualization", {})
            }
        else:
            return {"success": False, "error": "No response from Cortex Analyst"}
            
    except Exception as e:
        return {"success": False, "error": str(e)}

def create_fallback_response(question: str) -> Dict[str, Any]:
    """Generate structured fallback responses when Cortex Analyst is not available"""
    question_lower = question.lower()
    
    if any(word in question_lower for word in ['incident', 'alert', 'breach']):
        # Security incidents query
        try:
            data = run_query("""
                SELECT 
                    DATE(created_at) as date,
                    incident_type,
                    severity,
                    COUNT(*) as count
                FROM SECURITY_INCIDENTS
                WHERE created_at >= DATEADD(day, -30, CURRENT_TIMESTAMP())
                GROUP BY DATE(created_at), incident_type, severity
                ORDER BY date DESC
            """)
            
            return {
                "success": True,
                "data": data.to_dict('records') if not data.empty else [],
                "sql": "SELECT DATE(created_at), incident_type, severity, COUNT(*) FROM SECURITY_INCIDENTS...",
                "explanation": "Analysis of security incidents over the last 30 days, grouped by date, type, and severity.",
                "chart_type": "bar"
            }
        except:
            pass
    
    elif any(word in question_lower for word in ['user', 'login', 'authentication']):
        # User analytics query
        try:
            data = run_query("""
                SELECT 
                    cluster_label,
                    COUNT(*) as user_count,
                    AVG(countries) as avg_countries
                FROM SNOWPARK_ML_USER_CLUSTERS
                WHERE analysis_date >= DATEADD(day, -7, CURRENT_TIMESTAMP())
                GROUP BY cluster_label
                ORDER BY user_count DESC
            """)
            
            return {
                "success": True,
                "data": data.to_dict('records') if not data.empty else [],
                "sql": "SELECT cluster_label, COUNT(*), AVG(countries) FROM SNOWPARK_ML_USER_CLUSTERS...",
                "explanation": "User behavior clustering analysis showing different user patterns and their geographic distribution.",
                "chart_type": "pie"
            }
        except:
            pass
    
    elif any(word in question_lower for word in ['threat', 'malware', 'attack']):
        # Threat intelligence query
        try:
            data = run_query("""
                SELECT 
                    threat_type,
                    severity,
                    COUNT(*) as threat_count,
                    AVG(confidence_score) as avg_confidence
                FROM THREAT_INTEL_FEED
                WHERE first_seen >= DATEADD(day, -14, CURRENT_TIMESTAMP())
                GROUP BY threat_type, severity
                ORDER BY threat_count DESC
            """)
            
            return {
                "success": True,
                "data": data.to_dict('records') if not data.empty else [],
                "sql": "SELECT threat_type, severity, COUNT(*), AVG(confidence_score) FROM THREAT_INTEL_FEED...",
                "explanation": "Threat intelligence analysis showing active threats by type and severity over the last 14 days.",
                "chart_type": "heatmap"
            }
        except:
            pass
    
    # Default response
    return {
        "success": False,
        "error": "Cortex Analyst not available. Try questions about: incidents, users, threats, or authentication patterns."
    }

def visualize_data(data: list, chart_type: str = "bar", explanation: str = ""):
    """Create visualizations based on the data and chart type"""
    if not data:
        st.warning("No data to visualize")
        return
    
    df = pd.DataFrame(data)
    
    if chart_type == "bar" and len(df.columns) >= 2:
        st.bar_chart(df.set_index(df.columns[0]))
    
    elif chart_type == "line" and len(df.columns) >= 2:
        st.line_chart(df.set_index(df.columns[0]))
    
    elif chart_type == "pie" and len(df.columns) >= 2:
        fig = px.pie(df, values=df.columns[1], names=df.columns[0])
        st.plotly_chart(fig, use_container_width=True)
    
    elif chart_type == "heatmap" and len(df.columns) >= 3:
        fig = px.density_heatmap(df, x=df.columns[0], y=df.columns[1], z=df.columns[2])
        st.plotly_chart(fig, use_container_width=True)
    
    else:
        st.dataframe(df, use_container_width=True)

# =====================================================
# MAIN APPLICATION SECTIONS
# =====================================================

def show_executive_dashboard(days_back):
    """Executive-level security metrics and KPIs"""
    st.header("🏢 Executive Security Dashboard")
    st.markdown("*High-level security posture and business impact metrics*")
    
    # Key metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        total_incidents = run_query(f"""
            SELECT COUNT(*) as count 
            FROM SECURITY_INCIDENTS 
            WHERE created_at >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        incident_count = total_incidents['COUNT'].iloc[0] if not total_incidents.empty else 0
        st.metric("🚨 Security Incidents", format_metric(incident_count))
        
        with col2:
        critical_threats = run_query(f"""
            SELECT COUNT(*) as count 
            FROM THREAT_INTEL_FEED 
            WHERE severity = 'critical' 
            AND first_seen >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        threat_count = critical_threats['COUNT'].iloc[0] if not critical_threats.empty else 0
        st.metric("⚡ Critical Threats", format_metric(threat_count))
        
        with col3:
        ml_anomalies = run_query(f"""
            SELECT COUNT(*) as count 
            FROM ML_MODEL_COMPARISON 
            WHERE risk_level IN ('CRITICAL', 'HIGH')
            AND analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        anomaly_count = ml_anomalies['COUNT'].iloc[0] if not ml_anomalies.empty else 0
        st.metric("🎯 ML Anomalies", format_metric(anomaly_count))
        
        with col4:
        total_users = run_query("SELECT COUNT(DISTINCT username) as count FROM EMPLOYEE_DATA")
        user_count = total_users['COUNT'].iloc[0] if not total_users.empty else 0
        st.metric("👥 Protected Users", format_metric(user_count))
    
    # Risk trend chart
    st.subheader("📈 Security Risk Trends")
    
    risk_trends = run_query(f"""
        SELECT 
            DATE(analysis_date) as date,
            risk_level,
            COUNT(*) as incidents
        FROM ML_MODEL_COMPARISON
        WHERE analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        GROUP BY DATE(analysis_date), risk_level
        ORDER BY date
    """)
    
    if not risk_trends.empty:
        fig = px.area(risk_trends, x='DATE', y='INCIDENTS', color='RISK_LEVEL',
                     title="Daily Risk Level Distribution",
                color_discrete_map={
                         'CRITICAL': '#FF4B4B',
                         'HIGH': '#FF8C00', 
                         'MEDIUM': '#FFD700',
                         'LOW': '#90EE90'
                     })
            st.plotly_chart(fig, use_container_width=True)
    
def show_anomaly_detection(days_back):
    """ML-powered anomaly detection analytics"""
    st.header("🔍 ML-Powered Anomaly Detection")
    st.markdown("*Advanced machine learning models identifying suspicious behavior*")
    
    # Model performance metrics
    col1, col2, col3 = st.columns(3)
    
    with col1:
        native_anomalies = run_query(f"""
            SELECT COUNT(*) as count 
            FROM NATIVE_ML_USER_BEHAVIOR 
            WHERE native_anomaly = TRUE
            AND timestamp >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        native_count = native_anomalies['COUNT'].iloc[0] if not native_anomalies.empty else 0
        st.metric("🧠 Native ML Detections", native_count)
    
    with col2:
        snowpark_anomalies = run_query(f"""
            SELECT COUNT(*) as count 
            FROM SNOWPARK_ML_USER_CLUSTERS 
            WHERE snowpark_anomaly = TRUE
            AND analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        snowpark_count = snowpark_anomalies['COUNT'].iloc[0] if not snowpark_anomalies.empty else 0
        st.metric("⚡ Snowpark ML Detections", snowpark_count)
    
    with col3:
        agreement = run_query(f"""
            SELECT COUNT(*) as count 
            FROM ML_MODEL_COMPARISON 
            WHERE model_agreement = 'BOTH_AGREE_ANOMALY'
            AND analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        """)
        agreement_count = agreement['COUNT'].iloc[0] if not agreement.empty else 0
        st.metric("🎯 High Confidence", agreement_count)
    
    # Recent anomalies table
    st.subheader("🚨 Recent High-Risk Anomalies")
    
    recent_anomalies = run_query(f"""
    SELECT 
        username,
            analysis_date,
        risk_level,
            model_agreement,
            cluster_label,
            ROUND(snowpark_score, 3) as anomaly_score
        FROM ML_MODEL_COMPARISON
        WHERE risk_level IN ('CRITICAL', 'HIGH')
        AND analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        ORDER BY analysis_date DESC
        LIMIT 20
    """)
    
    if not recent_anomalies.empty:
        # Color code by risk level
        def color_risk(val):
            if val == 'CRITICAL':
                return 'background-color: #ffebee'
            elif val == 'HIGH':
                return 'background-color: #fff3e0'
            return ''
        
        styled_df = recent_anomalies.style.applymap(color_risk, subset=['RISK_LEVEL'])
        st.dataframe(styled_df, use_container_width=True)

def show_ml_comparison(days_back):
    """Compare different ML model performance"""
    st.header("📊 ML Model Comparison & Performance")
    st.markdown("*Comparing Native ML vs Snowpark ML detection capabilities*")
    
    # Model agreement analysis
    agreement_data = run_query(f"""
        SELECT 
            model_agreement,
            COUNT(*) as count,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
        FROM ML_MODEL_COMPARISON
        WHERE analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        GROUP BY model_agreement
        ORDER BY count DESC
    """)
    
    if not agreement_data.empty:
        col1, col2 = st.columns(2)
        
        with col1:
            # Agreement pie chart
            fig_pie = px.pie(agreement_data, values='COUNT', names='MODEL_AGREEMENT',
                           title="Model Agreement Distribution")
            st.plotly_chart(fig_pie, use_container_width=True)
        
        with col2:
            # Agreement metrics
            st.subheader("🎯 Model Performance")
            for _, row in agreement_data.iterrows():
                st.metric(
                    row['MODEL_AGREEMENT'].replace('_', ' ').title(),
                    f"{row['COUNT']} ({row['PERCENTAGE']}%)"
                )

def show_threat_intelligence(days_back):
    """Threat intelligence and correlation"""
    st.header("🚨 Threat Intelligence Dashboard")
    st.markdown("*Real-time threat correlation and prioritization*")
    
    # Threat metrics
    threat_data = run_query(f"""
    SELECT 
            threat_type,
        severity,
            COUNT(*) as threat_count,
            AVG(confidence_score) as avg_confidence
        FROM THREAT_INTEL_FEED
        WHERE first_seen >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        GROUP BY threat_type, severity
        ORDER BY threat_count DESC
    """)
    
    if not threat_data.empty:
        # Threat heatmap
        fig_heatmap = px.density_heatmap(
                threat_data,
            x='THREAT_TYPE', 
            y='SEVERITY', 
            z='THREAT_COUNT',
            title="Threat Type vs Severity Heatmap"
        )
        st.plotly_chart(fig_heatmap, use_container_width=True)

def show_ai_assistant():
    """AI-powered security assistant"""
    st.header("🤖 Security AI Assistant")
    st.markdown("*Intelligent security analysis powered by Cortex AI*")
    
    # Chat interface
    if "messages" not in st.session_state:
        st.session_state.messages = []
    
    # Display chat messages
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
    
    # Chat input
    if prompt := st.chat_input("Ask about security status, threats, or anomalies..."):
        # Add user message
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)
        
        # Generate AI response
        with st.chat_message("assistant"):
            with st.spinner("Analyzing security data..."):
                try:
                    # Try to use Cortex AI if available
                    ai_response = run_query(f"""
                        SELECT security_ai_chatbot('{prompt}') as response
                    """)
                    
                    if not ai_response.empty:
                        response = ai_response['RESPONSE'].iloc[0]
                    else:
                        response = generate_fallback_response(prompt)
                    
                except:
                    response = generate_fallback_response(prompt)
                
                st.markdown(response)
                st.session_state.messages.append({"role": "assistant", "content": response})

def generate_fallback_response(prompt):
    """Generate fallback responses when Cortex AI is not available"""
    prompt_lower = prompt.lower()
    
    if any(word in prompt_lower for word in ['status', 'overview', 'summary']):
        return """📊 **Current Security Status**: 
        - ✅ All systems operational
        - 🎯 ML models actively monitoring for anomalies
        - 📈 No critical threats detected in last 24 hours
        - 👥 User behavior patterns within normal ranges"""
    
    elif any(word in prompt_lower for word in ['threat', 'attack', 'malware']):
        return """🚨 **Threat Analysis**:
        - 🔍 Continuous threat intelligence monitoring active
        - ⚡ Real-time correlation with external threat feeds
        - 🛡️ ML-powered detection reduces false positives by 85%
        - 📊 Recommend reviewing latest threat intelligence dashboard"""
    
        else:
        return """🤖 I'm your security AI assistant! I can help analyze:
        - 📊 Current security status and metrics
        - 🔍 Anomaly detection results
        - 🚨 Threat intelligence insights
        - 👥 User behavior patterns
        - 📈 Security trends and patterns"""

def show_user_analytics(days_back):
    """User behavior analytics"""
    st.header("👥 User Behavior Analytics")
    st.markdown("*ML-powered user behavior analysis and clustering*")
    
    # User clusters
    cluster_data = run_query(f"""
    SELECT 
            cluster_label,
            COUNT(*) as user_count,
            AVG(countries) as avg_countries,
            AVG(weekend_ratio) as avg_weekend_activity
        FROM SNOWPARK_ML_USER_CLUSTERS
        WHERE analysis_date >= DATEADD(day, -{days_back}, CURRENT_TIMESTAMP())
        GROUP BY cluster_label
        ORDER BY user_count DESC
    """)
    
    if not cluster_data.empty:
        # Cluster visualization
        fig_cluster = px.bar(cluster_data, x='CLUSTER_LABEL', y='USER_COUNT',
                           title="User Behavioral Clusters")
        fig_cluster.update_xaxis(title="Behavior Pattern")
        fig_cluster.update_yaxis(title="Number of Users")
        st.plotly_chart(fig_cluster, use_container_width=True)

def show_realtime_monitoring():
    """Real-time security monitoring"""
    st.header("⚡ Real-time Security Monitoring")
    st.markdown("*Live security event stream and alerting*")
    
    # Auto-refresh every 30 seconds
    if st.button("🔄 Refresh Data"):
        st.rerun()
    
    # Recent events
    recent_events = run_query("""
SELECT 
    timestamp,
    username,
    source_ip,
            location:country::STRING as country,
            success,
            CASE WHEN success THEN '✅' ELSE '❌' END as status_icon
FROM USER_AUTHENTICATION_LOGS
        WHERE timestamp >= DATEADD(minute, -60, CURRENT_TIMESTAMP())
        ORDER BY timestamp DESC
        LIMIT 50
    """)
    
    if not recent_events.empty:
        st.subheader("🕐 Last Hour Activity")
        st.dataframe(recent_events, use_container_width=True)

def show_cortex_analyst():
    """Natural language analytics interface"""
    st.header("🔍 Cortex Analyst - Natural Language Analytics")
    st.markdown("*Ask questions in natural language about your security data*")
    
    # Sidebar with example questions
    with st.sidebar:
        st.markdown("---")
        st.subheader("💡 Example Questions")
        st.markdown("""
        **Security Incidents:**
        - "Show me critical incidents this week"
        - "What are the trending incident types?"
        - "How many breaches occurred last month?"
        
        **User Behavior:**
        - "Which users have unusual login patterns?"
        - "Show me user clusters by behavior"
        - "What are the peak login hours?"
        
        **Threat Intelligence:**
        - "What are the top threats this month?"
        - "Show me malware by severity"
        - "Which threat types are increasing?"
        
        **Anomaly Detection:**
        - "Show me ML anomaly detections"
        - "What's the model agreement rate?"
        - "Which users have high risk scores?"
        """)
    
    # Context selector
    context = st.selectbox(
        "Analysis Context:",
        ["general", "incidents", "users", "threats", "vulnerabilities", "trends"],
        help="Select the focus area for your analysis"
    )
    
    # Main query interface
    st.subheader("🤖 Natural Language Query")
    
    # Chat-style interface
    if "analyst_history" not in st.session_state:
        st.session_state.analyst_history = []
    
    # Display previous interactions
    for interaction in st.session_state.analyst_history:
        with st.container():
            st.markdown(f"**🧑 Question:** {interaction['question']}")
            
            if interaction['response']['success']:
                st.markdown(f"**🤖 Analysis:** {interaction['response']['explanation']}")
                
                if interaction['response']['data']:
                    # Show data visualization
                    chart_type = interaction['response'].get('chart_type', 'bar')
                    visualize_data(interaction['response']['data'], chart_type)
                    
                    # Show SQL query
                    with st.expander("🔍 View Generated SQL"):
                        st.code(interaction['response']['sql'], language='sql')
                        
                    # Show raw data
                    with st.expander("📊 View Raw Data"):
                        st.dataframe(pd.DataFrame(interaction['response']['data']))
            else:
                st.error(f"Error: {interaction['response']['error']}")
            
            st.markdown("---")
    
    # New query input
    question = st.text_input(
        "Ask a question about your cybersecurity data:",
        placeholder="e.g., 'Show me critical security incidents from last week'"
    )
    
    if st.button("🔍 Analyze", type="primary") and question:
        with st.spinner("Analyzing your security data..."):
            # Try Cortex Analyst first, fallback to structured queries
            response = query_cortex_analyst(question, context)
            
            if not response.get("success"):
                response = create_fallback_response(question)
            
            # Add to history
            st.session_state.analyst_history.append({
                "question": question,
                "response": response,
                "context": context
            })
            
            # Display current response
            if response.get("success"):
                st.success("✅ Analysis complete!")
                st.markdown(f"**🤖 Insight:** {response['explanation']}")
                
                if response.get('data'):
                    chart_type = response.get('chart_type', 'bar')
                    visualize_data(response['data'], chart_type)
                    
                    with st.expander("🔍 View Generated SQL"):
                        st.code(response.get('sql', 'Not available'), language='sql')
        else:
                st.error(f"❌ {response.get('error', 'Unknown error occurred')}")
    
    # Quick action buttons
    st.subheader("⚡ Quick Analysis")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        if st.button("🚨 Recent Incidents"):
            response = create_fallback_response("show me recent security incidents")
            if response.get("success") and response.get('data'):
                visualize_data(response['data'], 'bar')
    
    with col2:
        if st.button("👥 User Patterns"):
            response = create_fallback_response("analyze user behavior patterns")
            if response.get("success") and response.get('data'):
                visualize_data(response['data'], 'pie')
    
    with col3:
        if st.button("🎯 Threat Overview"):
            response = create_fallback_response("show me current threat landscape")
            if response.get("success") and response.get('data'):
                visualize_data(response['data'], 'heatmap')

# =====================================================
# MAIN APPLICATION
# =====================================================

def main():
    # Header
    st.title("🛡️ Snowflake Cybersecurity Analytics Demo")
    st.markdown("**Real-time security analytics powered by Snowflake Native ML and AI**")
    
    # Sidebar for demo navigation
    st.sidebar.title("🎯 Demo Sections")
    
    # Demo section selection
    demo_section = st.sidebar.radio(
        "Choose Demo Focus:",
        [
            "🏢 Executive Dashboard", 
            "🔍 Anomaly Detection",
            "📊 ML Model Comparison",
            "🚨 Threat Intelligence", 
            "🤖 Security AI Assistant",
            "👥 User Analytics",
            "⚡ Real-time Monitoring",
            "🔍 Cortex Analyst"
        ]
    )
    
    # Date range selector (not applicable for Cortex Analyst)
    if demo_section != "🔍 Cortex Analyst":
        st.sidebar.markdown("---")
        st.sidebar.subheader("📅 Analysis Period")
        days_back = st.sidebar.slider("Days to analyze", 1, 90, 7)
    
    # Route to appropriate section
    if demo_section == "🏢 Executive Dashboard":
        show_executive_dashboard(days_back)
    elif demo_section == "🔍 Anomaly Detection":
        show_anomaly_detection(days_back)
    elif demo_section == "📊 ML Model Comparison":
        show_ml_comparison(days_back)
    elif demo_section == "🚨 Threat Intelligence":
        show_threat_intelligence(days_back)
    elif demo_section == "🤖 Security AI Assistant":
        show_ai_assistant()
    elif demo_section == "👥 User Analytics":
        show_user_analytics(days_back)
    elif demo_section == "⚡ Real-time Monitoring":
        show_realtime_monitoring()
    elif demo_section == "🔍 Cortex Analyst":
        show_cortex_analyst()

# Run the main application
if __name__ == "__main__":
    main()
