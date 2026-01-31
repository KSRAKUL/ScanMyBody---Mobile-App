import cv2
import numpy as np
from PIL import Image
import torch
from torchvision import transforms

def preprocess_image(image: np.ndarray) -> np.ndarray:
    """
    Preprocesses image EXACTLY as training does.
    Training uses: Resize(224) -> ToTensor -> Normalize
    """
    # Convert BGR (OpenCV) to RGB (PIL/PyTorch expects)
    if len(image.shape) == 3 and image.shape[2] == 3:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    elif len(image.shape) == 2:
        # Grayscale - convert to 3-channel
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    
    # Resize to match training
    image = cv2.resize(image, (224, 224))
    
    # Convert to float32 and normalize to 0-1
    image = image.astype('float32') / 255.0
    
    return image


def preprocess_for_model(image: np.ndarray, device: torch.device) -> torch.Tensor:
    """
    Full preprocessing pipeline that matches training exactly.
    Returns tensor ready for model inference.
    """
    # Ensure RGB
    if len(image.shape) == 3 and image.shape[2] == 3:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    elif len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    
    # Convert to PIL for transforms (matches training)
    pil_image = Image.fromarray(image)
    
    # Exact same transforms as training
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])
    
    tensor = transform(pil_image).unsqueeze(0).to(device)
    return tensor
