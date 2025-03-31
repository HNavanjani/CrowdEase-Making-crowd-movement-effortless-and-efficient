def get_bus_positions():
    from datetime import datetime

    if not TFNSW_API_KEY:
        return {"error": "API key not found. Check .env file."}

    url = 'https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses'
    headers = {'Authorization': f"apikey {TFNSW_API_KEY}"}
    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        return {
            "error": "Failed to fetch data",
            "status": response.status_code,
            "message": response.text[:300]
        }

    feed = gtfs_realtime_pb2.FeedMessage()
    feed.ParseFromString(response.content)

    buses = []
    for entity in feed.entity[:5]:
        if entity.HasField('vehicle'):
            v = entity.vehicle
            buses.append({
                "trip_id": v.trip.trip_id,
                "label": v.vehicle.label or v.vehicle.id,
                "lat": v.position.latitude,
                "lon": v.position.longitude,
                "bearing": getattr(v.position, "bearing", None),
                "last_updated": datetime.utcfromtimestamp(v.timestamp).isoformat() + "Z" if v.HasField("timestamp") else "N/A"
            })

    return {"buses": buses}
