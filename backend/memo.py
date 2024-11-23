import os

from mem0 import MemoryClient
from autogen import ConversableAgent

os.environ["OPENAI_API_KEY"] = "your-api-key-here"
os.environ["MEM0_API_KEY"] = "your-api-key-here"



agent = ConversableAgent(
    "chatbot",
    llm_config={"config_list": [{"model": "gpt-4o-mini", "api_key": os.environ.get("OPENAI_API_KEY")}]},
    code_execution_config=False,
    function_map=None,
    human_input_mode="NEVER",
)

memory = MemoryClient()




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

def handle_order_issue():
    try:
        # Initialize agents and memory
        customer_service_bot = ConversableAgent(
            "customer_service_bot",
            system_message="""You are a helpful customer service bot. Follow this conversation flow:
            1. First ask if there are any issues with received products
            2. If yes, ask for the order ID
            3. After getting order ID, analyze the issue and provide ONE of these decisions:
               - REFUND: If the product is damaged/defective and within return window
               - REPLACE: If the product is under warranty and fixable/replaceable
               - ESCALATE: If the situation requires human agent intervention
            Be polite and professional. Keep responses concise.""",
            llm_config={
                "config_list": [
                    {
                        "model": "gpt-4",  # Changed from gpt-4o-mini to gpt-4
                        "temperature": 0,
                        "api_key": os.environ.get("OPENAI_API_KEY"),
                        "timeout": 30
                    }
                ]
            },
            human_input_mode="NEVER",
        )

        memory = MemoryClient()
        conversation = []

        # Initial greeting
        initial_message = {
            "role": "assistant",
            "content": "Hello! I'm here to help you with any product issues. Have you experienced any problems with products you received from us?"
        }
        conversation.append(initial_message)
        print("\nBot:", initial_message["content"])

        # Get user's initial response
        user_response = input("You: ")
        conversation.append({"role": "user", "content": user_response})

        if any(word in user_response.lower() for word in ['yes', 'issue', 'problem', 'wrong']):
            # Ask for order ID
            order_query = {
                "role": "assistant",
                "content": "I'm sorry to hear that. Could you please provide your order ID so I can better assist you?"
            }
            conversation.append(order_query)
            print("\nBot:", order_query["content"])

            # Get order ID
            order_id = input("You: ")
            conversation.append({"role": "user", "content": order_id})

            # Ask for issue description
            issue_query = {
                "role": "assistant",
                "content": "Thank you. Could you please describe the issue you're experiencing with your product?"
            }
            conversation.append(issue_query)
            print("\nBot:", issue_query["content"])

            # Get issue description
            issue_description = input("You: ")
            conversation.append({"role": "user", "content": issue_description})

            # Analyze and provide decision
            decision_prompt = f"""
            Order ID: {order_id}
            Issue Description: {issue_description}
            
            Based on this information, provide ONE of these decisions:
            - REFUND: If the product is damaged/defective and within return window
            - REPLACE: If the product is under warranty and fixable/replaceable
            - ESCALATE: If the situation requires human agent intervention
            
            Include a brief explanation with your decision.
            """
            
            try:
                decision = get_bot_decision(customer_service_bot, decision_prompt)
                if decision:
                    final_response = {
                        "role": "assistant",
                        "content": decision["content"]
                    }
                else:
                    final_response = {
                        "role": "assistant",
                        "content": "I apologize, but I'm having trouble processing your request. Please try again or contact our support team."
                    }
                conversation.append(final_response)
                print("\nBot:", final_response["content"])
                
            except Exception as e:
                print(f"\nError processing request: {str(e)}")
                final_response = {
                    "role": "assistant",
                    "content": "I apologize, but I'm experiencing technical difficulties. Please try again later or contact our support team."
                }
                conversation.append(final_response)
                print("\nBot:", final_response["content"])
        else:
            # No issues reported
            closing_message = {
                "role": "assistant",
                "content": "I'm glad to hear you haven't experienced any issues. Is there anything else I can help you with?"
            }
            conversation.append(closing_message)
            print("\nBot:", closing_message["content"])

        # Store conversation in memory
        memory.add(messages=conversation, user_id="customer_service_bot")
        return conversation

    except Exception as e:
        print(f"\nAn error occurred: {str(e)}")
        return None

# Run the conversation
if __name__ == "__main__":
    handle_order_issue()