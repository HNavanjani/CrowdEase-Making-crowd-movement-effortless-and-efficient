from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import bus

# Initialize FastAPI application instance
app = FastAPI()

# Enable CORS for all origins and headers
# This allows frontend apps (e.g., Flutter) to access the API without restrictions during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register bus-related API routes
app.include_router(bus.router)

# Root endpoint for health check or base URL message
# Useful for confirming the API is up and running
@app.get("/")
def root():
    return {"message": "CrowdEase API is running"}
