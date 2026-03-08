import cv2
import numpy as np
from PIL import Image
import torch
from torchvision import transforms

def get_inference_transform():
    """
    Returns the exact transform pipeline used for model inference.
    """
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

def preprocess_for_inference(image: np.ndarray, device: torch.device) -> torch.Tensor:
    """
    Unified preprocessing for model inference.
    Handles BGR/Grayscale to RGB and applies standard transforms.
    """
    # Convert to RGB
    if len(image.shape) == 3 and image.shape[2] == 3:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    elif len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    
    pil_image = Image.fromarray(image)
    transform = get_inference_transform()
    
    return transform(pil_image).unsqueeze(0).to(device)

def preprocess_for_display(image: np.ndarray) -> np.ndarray:
    """
    Simple resize and color conversion for internal visualization/masking.
    """
    if len(image.shape) == 3 and image.shape[2] == 3:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    elif len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    
    return cv2.resize(image, (224, 224))
