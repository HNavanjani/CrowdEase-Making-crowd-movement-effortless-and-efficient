# Working API connection test for Transport for NSW API 
import requests
from google.transit import gtfs_realtime_pb2
from dotenv import load_dotenv
import os

# Load variables from .env file
load_dotenv()

# Get the API key from environment variables
TFNSW_API_KEY = os.getenv('TFNSW_API_KEY')

# API endpoint for bus positions
url = 'https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses'
headers = {'Authorization': f'apikey {TFNSW_API_KEY}'}

# Make the request
response = requests.get(url, headers=headers)

# Parse the GTFS-Realtime protobuf response
feed = gtfs_realtime_pb2.FeedMessage()
feed.ParseFromString(response.content)

# Print details of first 5 vehicles
for entity in feed.entity[:5]:
    if entity.HasField('vehicle'):
        vehicle = entity.vehicle
        print(f"Trip ID: {vehicle.trip.trip_id}")
        print(f"Vehicle Label: {vehicle.vehicle.label}")
        print(f"Latitude: {vehicle.position.latitude}")
        print(f"Longitude: {vehicle.position.longitude}")
        print("-" * 30)
