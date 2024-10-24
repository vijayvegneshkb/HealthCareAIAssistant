import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import autogen
from autogen import AssistantAgent, UserProxyAgent
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS configuration to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load configuration for the assistant (assuming OAI_CONFIG_LIST.json is properly set)
config_list = autogen.config_list_from_json(env_or_file="OAI_CONFIG_LIST.json")

# Initialize the healthcare assistant (AssistantAgent)
healthassistant = AssistantAgent(
    name="HealthcareAssistant",
    llm_config={"config_list": config_list},
    system_message="""
    You are a healthcare assistant who will suggest medicines based on the symptoms the user describes.
    Recommend suitable medicines, and inform the user that this is just a recommendation.
    Always suggest that they consult a doctor if necessary.
    """,
)

# Initialize UserProxyAgent (to simulate user inputs without manual intervention)
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

# API route for handling product recommendation requests
@app.post("/recommendation/")
async def get_recommendation(request: QueryRequest):
    try:
        input_message = request.message
        print(f"Received message: {input_message}")

        # Use the user_proxy to initiate a conversation with the health assistant
        response = user_proxy.initiate_chat(
            recipient=healthassistant,
            message=input_message,
            max_turns=1,  # One interaction for now
            summary_method="last_msg",  # Capture only the last message
        )

        print(f"Response from assistant: {response}")  # Log the assistant's response

        # Check if the response is empty or invalid
        if not response or (isinstance(response, list) and len(response) == 0):
            raise ValueError("Received empty or invalid response from assistant.")
        
        # Return the valid response
        return {"response": response}

    except Exception as e:
        print(f"Error occurred: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

# To run this backend, use the following command:
# uvicorn app:app --reload
