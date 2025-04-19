# Working API connection test for OpenRouteService API
import openrouteservice
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Get the ORS API key
# Load .env locally only (skip on Render)
if not os.getenv("ORS_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

# Load API key from environment
ORS_API_KEY = os.getenv("ORS_API_KEY")

# Initialize ORS client
client = openrouteservice.Client(key=ORS_API_KEY)

# Sample coordinates in Sydney: [longitude, latitude]
coords = [
    [151.2093, -33.8688],  # Sydney CBD
    [151.2069, -33.8731]   # Town Hall
]

# Request route directions
route = client.directions(
    coordinates=coords,
    profile='driving-car',
    format='json'
)

summary = route['routes'][0]['summary']
print(f"Distance: {summary['distance']} meters")
print(f"Duration: {summary['duration']/60:.2f} minutes")

