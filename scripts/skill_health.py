import requests

# Define the endpoint to check skill health
SKILL_HEALTH_ENDPOINT = "https://api.example.com/skill-health"

def check_skill_health():
    try:
        response = requests.get(SKILL_HEALTH_ENDPOINT)
        response.raise_for_status()
        health_data = response.json()

        # Process health data as needed
        print("Skill health data:", health_data)
    except requests.exceptions.RequestException as e:
        print("Error checking skill health:", e)

if __name__ == "__main__":
    check_skill_health()