import cv2
import numpy as np
import logging

logger = logging.getLogger(__name__)

class MRIValidator:
    """
    Brain MRI Validator with user-friendly error messages.
    """
    
    def __init__(self):
        self.min_size = 100
        self.max_size = 4000
    
    def validate(self, image_bytes: bytes) -> dict:
        """
        Validates if the input image is a valid brain MRI.
        Returns simple, doctor-friendly messages.
        """
        try:
            # Decode image
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
            
            if img is None:
                return {"valid": False, "error": "Unable to read image. Please upload a valid file."}
            
            h, w = img.shape[:2]
            
            # Size check
            if h < self.min_size or w < self.min_size:
                return {"valid": False, "error": "Image too small. Please upload a higher resolution scan."}
            if h > self.max_size or w > self.max_size:
                return {"valid": False, "error": "Image too large. Please reduce the file size."}

            # Grayscale check
            if len(img.shape) == 3:
                b, g, r = cv2.split(img)
                diff_rg = np.mean(np.abs(r.astype("float") - g.astype("float")))
                diff_gb = np.mean(np.abs(g.astype("float") - b.astype("float")))
                
                if diff_rg > 8.0 or diff_gb > 8.0:
                    return {"valid": False, "error": "Please upload a valid brain MRI scan."}
                
                gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            else:
                gray = img.copy()
            
            gray_resized = cv2.resize(gray, (200, 200))
            
            # Background analysis
            edge_thickness = 20
            top = gray_resized[:edge_thickness, :].mean()
            bottom = gray_resized[-edge_thickness:, :].mean()
            left = gray_resized[:, :edge_thickness].mean()
            right = gray_resized[:, -edge_thickness:].mean()
            edge_mean = (top + bottom + left + right) / 4
            center = gray_resized[50:150, 50:150].mean()
            
            if edge_mean > 80:
                return {"valid": False, "error": "Not a valid brain MRI. Please upload an actual MRI scan."}
            
            if center < 30:
                return {"valid": False, "error": "Image too dark. Please upload a clear brain MRI."}
            
            # Brain content check
            hist = cv2.calcHist([gray_resized], [0], None, [256], [0, 256]).flatten()
            mid_range = hist[40:180].sum() / hist.sum()
            
            if mid_range < 0.25:
                return {"valid": False, "error": "No brain tissue visible. Please upload a valid MRI scan."}
            
            # Texture check
            blurred = cv2.GaussianBlur(gray_resized, (5, 5), 0)
            laplacian = cv2.Laplacian(blurred, cv2.CV_64F)
            variance = laplacian.var()
            
            if variance < 50:
                return {"valid": False, "error": "Image lacks detail. Please upload a clear MRI scan."}
            
            # Brain shape detection
            _, thresh = cv2.threshold(gray_resized, 30, 255, cv2.THRESH_BINARY)
            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            has_brain_shape = False
            for contour in contours:
                if cv2.contourArea(contour) > 5000:
                    perimeter = cv2.arcLength(contour, True)
                    if perimeter > 0:
                        circularity = 4 * np.pi * cv2.contourArea(contour) / (perimeter ** 2)
                        if 0.3 < circularity < 1.2:
                            has_brain_shape = True
                            break
            
            if not has_brain_shape:
                return {"valid": False, "error": "No brain structure found. Please upload a brain MRI image."}
            
            # Intensity check
            std_dev = gray_resized.std()
            if std_dev < 15:
                return {"valid": False, "error": "Image appears blank. Please upload a valid brain MRI."}
            if std_dev > 100:
                return {"valid": False, "error": "Image quality too low. Please upload a clearer scan."}
            
            return {
                "valid": True, 
                "message": "Valid brain MRI detected",
                "metadata": {
                    "edge_intensity": float(edge_mean),
                    "center_intensity": float(center),
                    "variance": float(variance),
                    "mid_range_ratio": float(mid_range),
                    "std_dev": float(std_dev)
                }
            }
            
        except Exception as e:
            logger.error(f"Validation error: {e}")
            return {"valid": False, "error": "Could not process image. Please try another file."}

validator = MRIValidator()
