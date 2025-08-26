# =====================================================
# CORTEX ANALYST INTEGRATION FOR STREAMLIT
# Natural language cybersecurity analytics
# =====================================================

import streamlit as st
import pandas as pd
import json
from typing import Dict, Any, Optional

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
        # Use the Cortex Analyst integration function
        query = """
        SELECT cortex_security_assistant(%s, %s) as analyst_response
        """
        
        # Execute with your existing session
        result = session.sql(query, [question, context]).collect()
        
        if result:
            response = result[0]['ANALYST_RESPONSE']
            
            # Parse the Cortex Analyst response
            if isinstance(response, str):
                response = json.loads(response)
            
            return {
                'success': True,
                'sql_query': response.get('sql', ''),
                'results': response.get('results', []),
                'explanation': response.get('explanation', ''),
                'visualizations': response.get('visualizations', []),
                'raw_response': response
            }
        else:
            return {
                'success': False,
                'error': 'No response from Cortex Analyst'
            }
            
    except Exception as e:
        return {
            'success': False,
            'error': f'Cortex Analyst query failed: {str(e)}'
        }

def display_cortex_results(response: Dict[str, Any]) -> None:
    """
    Display Cortex Analyst results in Streamlit with rich formatting
    
    Args:
        response: Cortex Analyst response dictionary
    """
    if not response['success']:
        st.error(f"❌ {response['error']}")
        return
    
    # Display explanation
    if response.get('explanation'):
        st.markdown("### 🧠 Analysis")
        st.info(response['explanation'])
    
    # Display results
    if response.get('results'):
        st.markdown("### 📊 Results")
        
        results = response['results']
        if isinstance(results, list) and len(results) > 0:
            # Convert to DataFrame for better display
            df = pd.DataFrame(results)
            st.dataframe(df, use_container_width=True)
            
            # Auto-generate visualizations based on data
            display_auto_visualizations(df)
        else:
            st.write(results)
    
    # Display generated SQL (expandable)
    if response.get('sql_query'):
        with st.expander("🔍 Generated SQL Query"):
            st.code(response['sql_query'], language='sql')
    
    # Display visualizations if provided
    if response.get('visualizations'):
        st.markdown("### 📈 Visualizations")
        for viz in response['visualizations']:
            display_visualization(viz)

def display_auto_visualizations(df: pd.DataFrame) -> None:
    """
    Auto-generate appropriate visualizations based on data structure
    
    Args:
        df: Results DataFrame
    """
    if df.empty:
        return
    
    # Detect data patterns and create appropriate charts
    numeric_cols = df.select_dtypes(include=['number']).columns
    categorical_cols = df.select_dtypes(include=['object', 'category']).columns
    date_cols = [col for col in df.columns if 'date' in col.lower() or 'time' in col.lower()]
    
    # Time series chart
    if date_cols and numeric_cols.any():
        st.markdown("#### 📈 Trend Analysis")
        chart_data = df.set_index(date_cols[0]) if len(date_cols) > 0 else df
        st.line_chart(chart_data[numeric_cols])
    
    # Bar chart for categorical data
    elif categorical_cols.any() and numeric_cols.any():
        st.markdown("#### 📊 Distribution")
        chart_data = df.groupby(categorical_cols[0])[numeric_cols[0]].sum()
        st.bar_chart(chart_data)
    
    # Metric cards for single values
    elif len(df) == 1 and numeric_cols.any():
        st.markdown("#### 🎯 Key Metrics")
        cols = st.columns(len(numeric_cols))
        for i, col in enumerate(numeric_cols):
            with cols[i]:
                st.metric(
                    col.replace('_', ' ').title(),
                    f"{df[col].iloc[0]:,.0f}" if df[col].iloc[0] > 1 else f"{df[col].iloc[0]:.2f}"
                )

def display_visualization(viz_config: Dict[str, Any]) -> None:
    """
    Display a specific visualization configuration
    
    Args:
        viz_config: Visualization configuration from Cortex Analyst
    """
    viz_type = viz_config.get('type', 'table')
    data = viz_config.get('data', [])
    title = viz_config.get('title', 'Chart')
    
    st.markdown(f"#### {title}")
    
    if viz_type == 'bar_chart':
        st.bar_chart(pd.DataFrame(data))
    elif viz_type == 'line_chart':
        st.line_chart(pd.DataFrame(data))
    elif viz_type == 'area_chart':
        st.area_chart(pd.DataFrame(data))
    elif viz_type == 'scatter_chart':
        st.scatter_chart(pd.DataFrame(data))
    else:
        st.dataframe(pd.DataFrame(data))

def create_cortex_analyst_interface():
    """
    Create the main Cortex Analyst interface for cybersecurity analytics
    """
    st.title("🧠 Cortex Analyst - Cybersecurity Intelligence")
    st.markdown("**Ask natural language questions about your security data**")
    
    # Quick action buttons
    st.markdown("### 🚀 Quick Analytics")
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        if st.button("📊 Incident Dashboard"):
            response = query_cortex_analyst(
                "Show me a security incident dashboard with current critical incidents, trends, and status",
                "incidents"
            )
            display_cortex_results(response)
    
    with col2:
        if st.button("👥 User Risk Analysis"):
            response = query_cortex_analyst(
                "Analyze user risk levels and show high-risk users with behavioral anomalies",
                "users"
            )
            display_cortex_results(response)
    
    with col3:
        if st.button("🔍 Vulnerability Report"):
            response = query_cortex_analyst(
                "Create a vulnerability report showing critical CVEs and patching priorities",
                "vulnerabilities"
            )
            display_cortex_results(response)
    
    with col4:
        if st.button("🌍 Threat Landscape"):
            response = query_cortex_analyst(
                "Analyze current threat landscape with geographic and threat type analysis",
                "threats"
            )
            display_cortex_results(response)
    
    st.markdown("---")
    
    # Natural language query interface
    st.markdown("### 💬 Ask Anything About Your Security Data")
    
    # Context selector
    context_options = {
        "General Analytics": "general",
        "Incident Analysis": "incidents", 
        "User & Authentication": "users",
        "Vulnerability Management": "vulnerabilities",
        "Threat Intelligence": "threats",
        "Security Trends": "trends"
    }
    
    selected_context = st.selectbox(
        "Analysis Context",
        options=list(context_options.keys()),
        help="Select the type of analysis to optimize Cortex Analyst responses"
    )
    
    # Example questions based on context
    context_key = context_options[selected_context]
    example_questions = get_example_questions(context_key)
    
    st.markdown("#### 💡 Example Questions:")
    for question in example_questions[:3]:  # Show top 3 examples
        if st.button(f"📝 {question}", key=f"example_{question[:20]}"):
            response = query_cortex_analyst(question, context_key)
            display_cortex_results(response)
    
    # Manual question input
    user_question = st.text_area(
        "Your Question:",
        placeholder="e.g., How many critical incidents happened this week? Which users have unusual login patterns?",
        help="Ask any question about your cybersecurity data in natural language"
    )
    
    if st.button("🔍 Analyze", disabled=not user_question):
        with st.spinner("🧠 Cortex Analyst is analyzing your data..."):
            response = query_cortex_analyst(user_question, context_key)
            display_cortex_results(response)
    
    # Usage tips
    with st.expander("💡 Tips for Better Questions"):
        st.markdown("""
        **🎯 Effective Questions:**
        - "Show me critical incidents from the last week"
        - "Which users have the highest risk scores?"
        - "What vulnerabilities should we patch first?"
        - "How are our security metrics trending?"
        
        **📊 Analysis Types:**
        - **Incidents**: Focus on security events, severity, response
        - **Users**: Authentication, behavior, risk assessment
        - **Vulnerabilities**: CVEs, patching, asset exposure
        - **Threats**: Intelligence, geographic, threat types
        - **Trends**: Time-based analysis, performance metrics
        
        **🔍 Advanced Queries:**
        - Include time ranges: "last 30 days", "this quarter"
        - Specify departments: "Engineering team", "Finance users"
        - Request comparisons: "compare this month to last month"
        - Ask for recommendations: "what should we prioritize?"
        """)

def get_example_questions(context: str) -> list:
    """
    Get context-specific example questions
    
    Args:
        context: Analysis context
    
    Returns:
        List of example questions
    """
    examples = {
        "general": [
            "What's our overall security posture?",
            "Show me today's security summary",
            "What needs immediate attention?",
            "How are we performing against security KPIs?"
        ],
        "incidents": [
            "How many critical incidents this week?",
            "What are the most common incident types?",
            "Show incident resolution trends",
            "Which systems have the most security events?"
        ],
        "users": [
            "Which users have highest risk scores?",
            "Show login patterns by department",
            "Who has unusual authentication behavior?",
            "What are the top user security risks?"
        ],
        "vulnerabilities": [
            "What vulnerabilities should we patch first?",
            "Show CVSS distribution of open vulnerabilities",
            "Which assets have the most critical CVEs?",
            "How is our patching performance trending?"
        ],
        "threats": [
            "What threat types are we seeing most?",
            "Show threat intelligence by confidence level",
            "Which countries pose the highest threats?",
            "What are the emerging threat patterns?"
        ],
        "trends": [
            "How are security metrics trending?",
            "Show monthly incident patterns",
            "What's our authentication success rate trend?",
            "How is vulnerability management improving?"
        ]
    }
    
    return examples.get(context, examples["general"])

# =====================================================
# INTEGRATION WITH MAIN STREAMLIT APP
# =====================================================

def integrate_cortex_analyst_section():
    """
    Function to integrate Cortex Analyst into the main Streamlit app
    Add this to your main app's section handling
    """
    create_cortex_analyst_interface()

# Example usage in main app:
# elif current_section == "cortex_analyst":
#     integrate_cortex_analyst_section()
