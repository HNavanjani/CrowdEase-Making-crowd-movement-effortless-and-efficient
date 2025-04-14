from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import bus
from app.routes.csv_preview import router as csv_preview_router 
from app.routes.data_cleaner import router as cleaner_router
from app.routes import predict
from app.routes import alerts
from app.routes import trip
from app.routes import live_buses
from app.routes import trip_updates
from app.routes import ors_route
from app.routes import ors_isochrone
from app.routes import ors_matrix


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(bus.router)
app.include_router(csv_preview_router)
app.include_router(cleaner_router)
app.include_router(predict.router)
app.include_router(alerts.router)
app.include_router(trip.router)
app.include_router(live_buses.router)
app.include_router(trip_updates.router)
app.include_router(ors_route.router)
app.include_router(ors_isochrone.router)
app.include_router(ors_matrix.router)

@app.get("/")
def root():
    return {"message": "CrowdEase API is running"}
