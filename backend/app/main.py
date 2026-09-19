from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import health, profile, opportunities, swipes

app = FastAPI(
    title="Echelon API",
    description="Campus Opportunity Navigator for Virginia Tech",
    version="0.1.0",
)

# CORS — allow Expo dev server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health.router)
app.include_router(profile.router)
app.include_router(opportunities.router)
app.include_router(swipes.router)
