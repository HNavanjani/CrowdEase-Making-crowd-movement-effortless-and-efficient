from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import bus
from app.routes.routes import router as route_router 

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(bus.router)
app.include_router(route_router)

@app.get("/")
def root():
    return {"message": "CrowdEase API is running"}
