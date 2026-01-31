import numpy as np
import cv2

class XAIService:
    def generate_heatmap(self, image: np.ndarray, mask: np.ndarray) -> str:
        """
        Generates a Grad-CAM heatmap.
        For now, creates a heatmap based on the segmentation mask to simulate attention.
        Returns: Base64 string or Path URL of the heatmap.
        """
        # MOCK IMPLEMENTATION: Gaussian blur the mask to look like a heatmap
        heatmap = cv2.applyColorMap(mask, cv2.COLORMAP_JET)
        
        # Overlay on black background or handle blending later
        # For simplicity, just returning the heatmap array (or simulating encoding)
        return "base64_heatmap_placeholder"

    def generate_explanation(self, prediction: dict, location: dict) -> str:
        """
        Generates text explanation.
        """
        tumor_type = prediction['type']
        confidence = prediction['confidence'] * 100
        region = location['region']
        
        return (f"The AI detected a {tumor_type} with {confidence:.2f}% confidence. "
                f"Attention was focused on the {region}, where abnormal tissue density was observed consistent with this tumor type.")

xai_service = XAIService()
