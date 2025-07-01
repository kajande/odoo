import requests

# Replace with your actual bearer token or auth credentials if needed
AUTH_TOKEN = "your-auth-token"  # Optional
URL = "http://localhost:8069/ordo/partners"

headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    # Uncomment if authentication is required
    # "Authorization": f"Bearer {AUTH_TOKEN}",
}

def fetch_partners():
    try:
        response = requests.get(URL, headers=headers)
        response.raise_for_status()
        data = response.json()
        print("Partners:")
        for partner in data:
            print(f"- {partner['name']} ({partner['email']})")
    except requests.exceptions.RequestException as e:
        print("Error:", e)

if __name__ == "__main__":
    fetch_partners()
