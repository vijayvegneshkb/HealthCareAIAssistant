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

# Initialize the healthcare assistant (AssistantAgent)
healthassistant = AssistantAgent(
    name="HealthcareAssistant",
    system_message="You are a healthcare assistant. First give a one line 'message' regarding the symptom that would not make the user panic regarding the health condition. Then suggest the medicines and the prices along with the images for the symptom given by user. Give the response in a json format. Then give a 'disclaimer' saying that the recommendation is done by a AI, for better clarification please consult a doctor",
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
    code_execution_config={
        "last_n_messages": 1,
        "work_dir": "tasks",
        "use_docker": False,
    },
)

# Define request structure for FastAPI
class QueryRequest(BaseModel):
    message: str  # The user's medical symptom description

@app.post("/recommendation/")
async def get_recommendation(request: QueryRequest):
    try:
        input_message = request.message
        print(f"Received message: {input_message}")

        # Fetch medicine information based on the user's symptoms from the XML file
        # medicine_info = retrieve_proxy.initiate_chat(
        #     recipient=healthassistant,
        #     message=input_message,
        #     max_turns=1,
        #     summary_method="last_msg",
        # )
        healthassistant.reset()

   # qa_problem = questions[i]
        medicine_info = ragproxyagent.initiate_chat(
            healthassistant, message=ragproxyagent.message_generator, problem=input_message, n_results=5
        )

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
