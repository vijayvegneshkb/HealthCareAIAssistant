import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import autogen
from autogen import AssistantAgent, UserProxyAgent
from autogen.agentchat.contrib.retrieve_user_proxy_agent import RetrieveUserProxyAgent
from autogen.retrieve_utils import TEXT_FORMATS
from fastapi.middleware.cors import CORSMiddleware
import xml.etree.ElementTree as ET  # Import for parsing XML
import json
import chromadb

# Check if the XML file is accessible
if os.path.exists("../ProductCatelog.xml"):
    print("XML file is accessible.")
else:
    print("XML file not found.")

app = FastAPI()

# CORS configuration to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load configuration for the assistant
config_list = autogen.config_list_from_json(env_or_file="OAI_CONFIG_LIST.json")

# Initialize AssistantAgent to handle general queries and greetings
healthassistant = AssistantAgent(
    name="healthassistant",
    system_message="You are a healthcare assistant. First provide a calming message for non-urgent symptoms "
                   "For medical symptoms, suggest medicines or medical kits(if applicable) with prices and images. All responses should be in JSON format. "
                   "Remind the user to consult a doctor for confirmation. Handle general queries normally"
                   "In the JSON, the calming message should be under the key 'message', medications as 'medicines' and remineder message as 'disclaimer'",
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

classifier = AssistantAgent(
    name="classifier",
    system_message="You are a classifier. The output would be in JSON format" ,
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

corpus_file = "../ProductCatelog.xml"

ragproxyagent = RetrieveUserProxyAgent(
    name="RetrieveMedicineProxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10,
    retrieve_config={
        "task": "code",
        "docs_path": corpus_file,
        "chunk_token_size": 2000,
        "model": config_list[0]["model"],
        "client": chromadb.PersistentClient(path="/tmp/chromadb"),
        "get_or_create": True,
        "embedding_model": "all-MiniLM-L6-v2",
    },
    code_execution_config=False,
)


# Initialize UserProxyAgent
user_proxy = UserProxyAgent(
    name="UserProxy",
    human_input_mode="NEVER",  # Automated user interaction
    system_message="""
    Please say that the context is not relevant to medicine.
    """,
    code_execution_config={
        "last_n_messages": 1,
        "work_dir": "tasks",
        "use_docker": False,
    },
)

critic = AssistantAgent(
    name="Critic",
    llm_config={"config_list": config_list},
    system_message="""
    You are a critic. Your task is to review healthcare advice for harmful or incorrect information, ensuring it follows medical guidelines.
    """,
)

# Define the trigger for nested chat: after the assistant's response, the critic provides feedback
def reflection_message(recipient, messages, sender, config):
    return f"Reflect on and provide critique on the following medical advice:\n\n{recipient.chat_messages_for_summary(sender)[-1]['content']}"

# Define request structure for FastAPI
class QueryRequest(BaseModel):
    message: str  # The user's medical symptom description


# Function to classify the user input dynamically using UserProxyAgent
def classify_intent(user_input):
    # Ask the UserProxyAgent (LLM) to classify the input
    classification_prompt = (
        f"Classify the following input as either 'medical', 'greeting', or 'general':\n\n"
        f"Input: {user_input}\n"
        "Please provide the classification in one word."
    )

    # Call the assistant (or user proxy) to generate the classification
    classification_response = user_proxy.initiate_chat(
        classifier, message=classification_prompt, max_turns=1, summary_method="last_msg"
    )
    print(f"classification_response: {classification_response}")

    summary = classification_response.summary

    print(f"summary: {summary}")

    clean_response = summary.strip().strip("```json").strip("```")
    
    # Parse the cleaned JSON response
    try:
        response_json = json.loads(clean_response)
        classification = response_json.get("classification", "").lower()
        print(f"classification: {classification}")
    except json.JSONDecodeError:
        # Handle case where the response isn't valid JSON
        classification = "general"
    
    return classification

def handle_user_query(user_input):
    # Classify the intent dynamically
    print("XYZ ")
    print(f"user_input: {user_input}")
    intent = classify_intent(user_input)
    print(f"intent: {intent}")

    if intent == "greeting":
        return {"message": "Hello! How can I assist you today with your health concerns?"}

    if intent == "medical":
        # Route medical queries to RetrieveUserProxyAgent for symptom analysis
        chat_result = ragproxyagent.initiate_chat(
            healthassistant, message=ragproxyagent.message_generator, problem=user_input, n_results=5
        )
        return chat_result
    
    return {"message": "I may not have an answer to that, but I'd love to help with health-related questions, product recommendations, or wellness advice. Let me know how I can assist!"}



@app.post("/recommendation/")
async def get_recommendation(request: QueryRequest):
    try:

        input_message = request.message
        print(f"Received message: {input_message}")

        medicine_info = handle_user_query(input_message)

        print(f"Medicine information retrieved: {medicine_info}")

        # Directly return the fetched medicine information
        if not medicine_info:
            raise ValueError("No medicine information found.")
        
        return {"response": medicine_info}

    except Exception as e:
        print(f"Error occurred: {e}")  # Consider logging the full error in production
        raise HTTPException(status_code=500, detail="Internal Server Error")

# To run this backend, use the following command:
# uvicorn app:app --reload
