import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.core.config import settings
from backend.api.endpoints import router as api_router

app = FastAPI(
    title="Brain Tumor Detection API",
    description="Medical-grade AI API for Brain Tumor Detection (Classification + Segmentation + XAI)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Configuration
origins = [
    "*", # Allow all for mobile dev
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def health_check():
    return {
        "status": "online",
        "service": "Brain Tumor Detection AI",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    # Use PORT env var for Render, fallback to 8000 for local dev
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("backend.main:app", host="0.0.0.0", port=port, reload=False)
