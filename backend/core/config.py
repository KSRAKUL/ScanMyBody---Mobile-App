import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Brain Tumor Detection"
    API_V1_STR: str = "/api/v1"
    
    # Model Paths - relative to backend folder
    MODEL_DIR: str = os.path.join(os.path.dirname(__file__), "../models")
    CLASSIFIER_PATH: str = os.path.join(MODEL_DIR, "classifier_real.pth")
    CLASSES_PATH: str = os.path.join(MODEL_DIR, "classes.txt")
    
    # Validation Rules
    ALLOWED_EXTENSIONS: set = {"jpg", "jpeg", "png", "dicom"}
    
    class Config:
        case_sensitive = True

settings = Settings()
