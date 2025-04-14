from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import bus
from app.routes.routes import router as route_router
from app.routes.csv_preview import router as csv_preview_router 
from app.routes.data_cleaner import router as cleaner_router
from app.routes import predict

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
app.include_router(csv_preview_router)
app.include_router(cleaner_router)
app.include_router(predict.router)

@app.get("/")
def root():
    return {"message": "CrowdEase API is running"}
