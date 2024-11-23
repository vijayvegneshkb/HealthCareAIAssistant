import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import autogen
from autogen import AssistantAgent, UserProxyAgent
from autogen.agentchat.contrib.retrieve_user_proxy_agent import RetrieveUserProxyAgent
from autogen.retrieve_utils import TEXT_FORMATS
import xml.etree.ElementTree as ET  # Import for parsing XML
import json
import chromadb
from pymongo import MongoClient
from datetime import datetime
import base64
from PIL import Image
from io import BytesIO

from autogen import ConversableAgent


import os
from dotenv import load_dotenv
import json

load_dotenv()

# Read and process OAI_CONFIG_LIST.json
with open('OAI_CONFIG_LIST.json', 'r') as f:
    config = json.load(f)
    config[0]['api_key'] = os.getenv('OPENAI_API_KEY')

os.environ["OPENAI_API_KEY"] = "your-api-key-here"

# Check if the XML file is accessible
if os.path.exists("../ProductCatelog.xml"):
    print("XML file is accessible.")
else:
    print("XML file not found.")

app = Flask(__name__)

# CORS configuration to allow requests from Flutter app
CORS(app)

# Load configuration for the assistant
config_list = autogen.config_list_from_json(env_or_file="OAI_CONFIG_LIST.json")

conversation_context = {}
order_contexts = {}

# Initialize AssistantAgent to handle general queries and greetings
healthassistant = AssistantAgent(
    name="healthassistant",
    system_message="You are a healthcare assistant. First provide a calming message for non-urgent symptoms "
                   "For medical symptoms, suggest medicines or medical kits(if applicable) with prices and images. All responses should be in JSON format. "
                   "Remind the user to consult a doctor for confirmation. Handle general queries normally"
                   "In the JSON, the calming message should be under the key 'message', medications as 'medicines' and reminder message as 'disclaimer'",
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

# Update classifier system message
classifier = AssistantAgent(
    name="classifier",
    system_message="You are a classifier. Classify input as either 'medical', 'greeting', 'order_issue', or 'general'. The output would be in JSON format with key 'classification'",
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

# Department classifier for medical queries
department_classifier = AssistantAgent(
    name="department_classifier",
    system_message="Classify the medical query into one of the following departments: 'Cardiology', 'Neurology', 'Dermatology', 'Orthopedics', 'General'. "
                   "Respond with JSON in the form {'department': 'Cardiology'}",
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

# Customer service bot
customer_service_bot = ConversableAgent(
    "customer_service_bot",
    system_message="""You are a helpful customer service bot. Follow these exact steps:
    1. If no order ID is provided in the message, ONLY ask for the order ID
    2. If an order ID is provided but no issue description, ONLY ask for the issue description
    3. If both order ID and issue description are provided, analyze and provide ONE of these decisions:
       - REFUND: If the product is damaged/defective and within return window
       - REPLACE: If the product is under warranty and fixable/replaceable
       - ESCALATE: If the situation requires human agent intervention
    Keep responses concise and handle one step at a time.""",
    llm_config={
        "config_list": [
            {
                "model": "gpt-4",
                "temperature": 0,
                "api_key": os.environ.get("OPENAI_API_KEY"),
                "timeout": 30
            }
        ]
    },
    human_input_mode="NEVER",
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
    human_input_mode="NEVER",
    system_message="Please say that the context is not relevant to medicine.",
    code_execution_config={
        "last_n_messages": 1,
        "work_dir": "tasks",
        "use_docker": False,
    },
)


# Define request structure and validation for Flask
def classify_intent(user_input, user_id=None):
    global conversation_context
    
    # Check if this is a follow-up to an order issue
    if user_id and user_id in conversation_context:
        if conversation_context[user_id] == "order_issue":
            return "order_issue"

    # If it's a potential order ID (numeric string)
    if user_input.strip().isdigit():
        return "order_issue"

    classification_prompt = (
        f"Classify the following input as either 'medical', 'greeting', 'order_issue', or 'general':\n\n"
        f"Input: {user_input}\n"
        "Please provide the classification in one word."
    )

    classification_response = healthassistant.initiate_chat(
        classifier, message=classification_prompt, max_turns=1, summary_method="last_msg"
    )

    summary = classification_response.summary
    clean_response = summary.strip().strip("```json").strip("```")
    
    try:
        response_json = json.loads(clean_response)
        classification = response_json.get("classification", "").lower()
        # Store the context if it's an order issue
        if classification == "order_issue" and user_id:
            conversation_context[user_id] = "order_issue"
        print(f"classification: {classification}")
    except json.JSONDecodeError:
        classification = "general"
    
    return classification


# Classify medical queries into departments
def classify_department(user_input):
    department_prompt = (
        f"Classify the following medical query into a department:\n\n"
        f"Input: {user_input}\n"
        "Please provide the department classification in the format {'department': 'Cardiology'}."
    )

    department_response = healthassistant.initiate_chat(
        department_classifier, message=department_prompt, max_turns=1, summary_method="last_msg"
    )
    
    summary = department_response.summary
    clean_response = summary.strip().strip("```json").strip("```")
    
    try:
        response_json = json.loads(clean_response)
        classification = response_json.get("department", "").lower()
    except json.JSONDecodeError:
        department = "General"
    
    return department



def get_bot_decision(customer_service_bot, prompt):
    try:
        user_proxy = ConversableAgent(
            "user_proxy",
            human_input_mode="NEVER",
            llm_config=False,
        )
        user_proxy.send(prompt, customer_service_bot, request_reply=True)
        response = customer_service_bot.last_message()
        if not response:
            raise ValueError("No response received from bot")
        return response
    except Exception as e:
        print(f"Error in get_bot_decision: {str(e)}")
        raise

def handle_order_issue(user_message, user_id="default_user", image_data=None):
    try:
        global order_contexts
        
        # Initialize context for new user if doesn't exist
        if user_id not in order_contexts:
            order_contexts[user_id] = {"order_id": None, "issue": None, "image": None}
            
        context = order_contexts[user_id]
        
        # If message is a number, treat it as order ID
        if user_message.strip().isdigit():
            context["order_id"] = user_message
            order_contexts[user_id] = context
            return {"message": "Thank you for providing the order ID. Could you please describe the issue you're experiencing? You can also upload an image of the problem if applicable."}
            
        # If we don't have an order ID yet
        if context["order_id"] is None:
            return {"message": "Could you please provide your order ID?"}
            
        # If we have order ID but no issue yet, store the issue and provide decision
        if context["issue"] is None:
            context["issue"] = user_message
            context["image"] = image_data
            
            # Create decision prompt with full context
            decision_prompt = f"""
            Order ID: {context["order_id"]}
            Issue Description: {context["issue"]}
            {"Image Analysis: An image was provided showing the product issue." if image_data else "No image provided."}
            
            Based on this information, provide ONE of these decisions:
            - REFUND: If the product is damaged/defective and within return window
            - REPLACE: If the product is under warranty and fixable/replaceable
            - ESCALATE: If the situation requires human agent intervention
            
            Include a brief explanation with your decision.
            """
            
            # Get decision from bot
            customer_service_bot = ConversableAgent(
                "customer_service_bot",
                system_message="You are a helpful customer service bot. Analyze the order issue, including any provided images, and provide ONE decision (REFUND/REPLACE/ESCALATE) with a brief explanation.",
                llm_config={
                    "config_list": [
                        {
                            "model": "gpt-4" if image_data else "gpt-4o-mini",
                            "temperature": 0,
                            "api_key": os.environ.get("OPENAI_API_KEY"),
                            "timeout": 30
                        }
                    ]
                },
                human_input_mode="NEVER",
            )
            
            user_proxy = ConversableAgent(
                "user_proxy",
                human_input_mode="NEVER",
                llm_config=False,
            )
            
            user_proxy.send(decision_prompt, customer_service_bot, request_reply=True)
            response = customer_service_bot.last_message()

            # Clear context after decision
            order_contexts[user_id] = {"order_id": None, "issue": None, "image": None}
            
            return {"message": response["content"]}
            
        return {"message": "I apologize, but I'm having trouble processing your request. Please try again."}

    except Exception as e:
        print(f"Error in handle_order_issue: {str(e)}")
        return {"message": "I apologize, but I'm having trouble processing your request. Please try again."}

            
            
            
def handle_user_query(user_input, user_id="default_user"):
    print("XYZ ")
    print(f"user_input: {user_input}")
    intent = classify_intent(user_input, user_id)
    print(f"intent: {intent}")

    if intent == "greeting":
        return {"message": "Hello! How can I assist you today with your health concerns?"}

    if intent == "medical":
        department = classify_department(user_input)
        print(f"Classified department: {department}")
    
        chat_result = ragproxyagent.initiate_chat(
            healthassistant, message=ragproxyagent.message_generator, problem=user_input, n_results=5
        )
        return chat_result
    
    if intent == "order_issue":
        return handle_order_issue(user_input, user_id)
    
    return {"message": "I may not have an answer to that, but I'd love to help with health-related questions, product recommendations, or wellness advice. Let me know how I can assist!"}


@app.route("/recommendation/", methods=["POST"])
def get_recommendation():
    try:
        data = request.get_json()
        input_message = data.get("message")
        user_id = data.get("user_id", "default_user")
        image_data = data.get("image")  # Get base64 image data if provided
        
        if not input_message:
            return jsonify({"error": "No message provided"}), 400
        
        print(f"Received message: {input_message}")
        intent = classify_intent(input_message, user_id)
        
        if intent == "order_issue":
            medicine_info = handle_order_issue(input_message, user_id, image_data)
        else:
            medicine_info = handle_user_query(input_message, user_id)
            
        print(f"Response information: {medicine_info}")
        
        if not medicine_info:
            return jsonify({"error": "No information found."}), 404
        
        return jsonify({"response": medicine_info})

    except Exception as e:
        print(f"Error occurred: {e}")
        return jsonify({"error": "Internal Server Error"}), 500
    

# Connect to MongoDB
mongo_client = MongoClient("mongodb://localhost:27017/")  # Replace with your MongoDB URI
db = mongo_client["HealthcareAssistant"]  # Database name
orders_collection = db["orders"]  # Collection name

@app.route("/submit_order/", methods=["POST"])
def submit_order():
    try:
        data = request.get_json()

        # Ensure all required fields are present
        required_fields = ["name", "address", "creditCardNumber", "medicine"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing field: {field}"}), 400

        # Prepare order document
        order_document = {
            "name": data["name"],
            "address": data["address"],
            "creditCardNumber": data["creditCardNumber"][-4:],  # Store only last 4 digits for security
            "medicine": data["medicine"],  # Includes name, price, and image details
            "orderNumber": datetime.now().strftime("%Y%m%d%H%M%S"),  # Generate a timestamp-based order number
            "timestamp": datetime.now(),  # Add a timestamp
        }

        # Insert order into MongoDB
        orders_collection.insert_one(order_document)

        return jsonify({"message": "Order submitted successfully", "orderNumber": order_document["orderNumber"]}), 201

    except Exception as e:
        print(f"Error occurred: {e}")
        return jsonify({"error": "Internal Server Error"}), 500

@app.route("/orders/", methods=["GET"])
def get_orders():
    try:
        orders = list(orders_collection.find({}, {"_id": 0}))  # Exclude MongoDB `_id` field
        return jsonify(orders), 200
    except Exception as e:
        print(f"Error occurred: {e}")
        return jsonify({"error": "Internal Server Error"}), 500


# To run this backend, use the following command:
# python app.py
if __name__ == "__main__":
    app.run(debug=True)
