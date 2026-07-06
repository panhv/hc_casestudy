"""

Start:
    streamlit run chatbot_streamlit.py
"""

import streamlit as st

from chatbot_app import answer_question


st.set_page_config(
    page_title="HolidayCheck Media Chatbot",
    page_icon="💬",
    layout="wide",
)

st.title("💬 HolidayCheck Business Analyst Media Case Study-Chatbot")
st.write(
    "Stelle Fragen zu monatlicher Performance, Anomalien, Segmenten, Volatilität "
    "oder Business-Empfehlungen."
)

with st.expander("Beispielfragen anzeigen"):
    st.markdown(
        """
        - Zeig mir die monatliche Performance pro Hotel
        - Welche Hotels haben steigende Kosten und sinkende Leads?
        - Zeig mir die Top 5 Anomalien pro Jahr
        - Welche Hotels haben die höchste Volatilität?
        - Welche zusätzlichen Daten sollten wir anfordern?
        - Soll der Kunde das Werbebudget erhöhen?
        """
    )

if "messages" not in st.session_state:
    st.session_state.messages = [
        {
            "role": "assistant",
            "content": "Hallo! Ich kann dir Fragen zur Business Analyst Case Study beantworten. Frage mich zum Beispiel nach Anomalien, Segmenten oder einer Budget-Empfehlung.",
        }
    ]

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

question = st.chat_input("Deine Frage ...")

if question:
    st.session_state.messages.append({"role": "user", "content": question})

    with st.chat_message("user"):
        st.markdown(question)

    with st.chat_message("assistant"):
        try:
            response = answer_question(question)
            st.markdown(response.answer)
            st.session_state.messages.append({"role": "assistant", "content": response.answer})
        except Exception as exc:
            error_message = f"Es ist ein Fehler aufgetreten: {exc}"
            st.error(error_message)
            st.session_state.messages.append({"role": "assistant", "content": error_message})
