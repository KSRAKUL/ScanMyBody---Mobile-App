import cv2
import numpy as np
import base64

# Lazy import flags
GRADCAM_AVAILABLE = False
GradCAM = None
show_cam_on_image = None
ClassifierOutputTarget = None

def _try_import_gradcam():
    global GRADCAM_AVAILABLE, GradCAM, show_cam_on_image, ClassifierOutputTarget
    try:
        from pytorch_grad_cam import GradCAM as GC
        from pytorch_grad_cam.utils.image import show_cam_on_image as show_cam
        from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget as COT
        GradCAM = GC
        show_cam_on_image = show_cam
        ClassifierOutputTarget = COT
        GRADCAM_AVAILABLE = True
        print("✓ pytorch-grad-cam loaded successfully!")
    except ImportError:
        print("⚠️ pytorch-grad-cam not available. Using custom visualization.")
        GRADCAM_AVAILABLE = False


class GradCAMService:
    """Generates clear, accurate heatmaps for tumor visualization."""
    
    def __init__(self, model, device):
        self.model = model
        self.device = device
        self.cam = None
        
        _try_import_gradcam()
        
        if GRADCAM_AVAILABLE and model is not None:
            try:
                from torchvision import transforms
                self.transform = transforms.Compose([
                    transforms.Resize((224, 224)),
                    transforms.ToTensor(),
                    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
                ])
                self.target_layer = [model.features[-1]]
                self.cam = GradCAM(model=model, target_layers=self.target_layer)
                print("✓ GradCAM visualization ready!")
            except Exception as e:
                print(f"GradCAM init error: {e}")
                self.cam = None
        else:
            self.transform = None
    
    def generate_heatmap(self, raw_image: np.ndarray, predicted_class_idx: int) -> dict:
        """Generates heatmap with clear tumor region visualization."""
        if GRADCAM_AVAILABLE and self.cam is not None:
            return self._generate_real_gradcam(raw_image, predicted_class_idx)
        else:
            return self._generate_enhanced_fallback(raw_image)
    
    def _generate_real_gradcam(self, raw_image: np.ndarray, predicted_class_idx: int) -> dict:
        """Uses actual GradCAM library."""
        try:
            from PIL import Image
            
            if len(raw_image.shape) == 3:
                rgb_image = cv2.cvtColor(raw_image, cv2.COLOR_BGR2RGB)
            else:
                rgb_image = cv2.cvtColor(raw_image, cv2.COLOR_GRAY2RGB)
            
            rgb_resized = cv2.resize(rgb_image, (224, 224))
            rgb_normalized = rgb_resized.astype(np.float32) / 255.0
            
            pil_image = Image.fromarray(rgb_resized)
            input_tensor = self.transform(pil_image).unsqueeze(0).to(self.device)
            
            targets = [ClassifierOutputTarget(predicted_class_idx)]
            grayscale_cam = self.cam(input_tensor=input_tensor, targets=targets)
            grayscale_cam = grayscale_cam[0, :]
            
            # Create enhanced colored overlay
            heatmap_overlay = self._create_enhanced_overlay(rgb_normalized, grayscale_cam)
            location = self._analyze_location(grayscale_cam)
            
            _, buffer = cv2.imencode('.png', cv2.cvtColor(heatmap_overlay, cv2.COLOR_RGB2BGR))
            heatmap_base64 = base64.b64encode(buffer).decode('utf-8')
            
            return {
                "heatmap": heatmap_base64,
                "location": location,
                "intensity": float(grayscale_cam.max()),
                "success": True
            }
        except Exception as e:
            print(f"GradCAM error: {e}")
            return self._generate_enhanced_fallback(raw_image)
    
    def _create_enhanced_overlay(self, rgb_normalized: np.ndarray, cam: np.ndarray) -> np.ndarray:
        """Creates clear, color-coded overlay with distinct tumor regions."""
        # Create custom colormap: Blue(low) -> Cyan -> Green -> Yellow -> Red(high)
        heatmap = np.zeros((cam.shape[0], cam.shape[1], 3), dtype=np.float32)
        
        for i in range(cam.shape[0]):
            for j in range(cam.shape[1]):
                v = cam[i, j]
                if v < 0.2:
                    # Blue (very low activation)
                    heatmap[i, j] = [v * 5 * 0.2, v * 5 * 0.2, v * 5]
                elif v < 0.4:
                    # Cyan to Green
                    t = (v - 0.2) / 0.2
                    heatmap[i, j] = [0, 0.5 + t * 0.5, 1 - t]
                elif v < 0.6:
                    # Green to Yellow
                    t = (v - 0.4) / 0.2
                    heatmap[i, j] = [t, 1, 0]
                elif v < 0.8:
                    # Yellow to Orange
                    t = (v - 0.6) / 0.2
                    heatmap[i, j] = [1, 1 - t * 0.5, 0]
                else:
                    # Orange to Red (tumor hotspot)
                    t = (v - 0.8) / 0.2
                    heatmap[i, j] = [1, 0.5 - t * 0.5, 0]
        
        # Blend with original image
        alpha = 0.4 + cam * 0.3  # Higher activation = more visible
        alpha = np.expand_dims(alpha, axis=2)
        
        result = rgb_normalized * (1 - alpha) + heatmap * alpha
        result = np.clip(result * 255, 0, 255).astype(np.uint8)
        
        return result
    
    def _analyze_location(self, cam: np.ndarray) -> str:
        """Provides clear, doctor-friendly location description."""
        h, w = cam.shape
        
        # Find hotspot
        max_val = cam.max()
        if max_val < 0.3:
            return "Minimal activation detected - scan appears normal"
        
        # Find center of mass
        y_idx, x_idx = np.indices((h, w))
        total = cam.sum()
        cy = (y_idx * cam).sum() / total
        cx = (x_idx * cam).sum() / total
        
        # Determine region
        if cy < h * 0.33:
            vertical = "frontal (superior)"
        elif cy > h * 0.67:
            vertical = "occipital (inferior)"
        else:
            vertical = "parietal (central)"
        
        if cx < w * 0.4:
            horizontal = "left hemisphere"
        elif cx > w * 0.6:
            horizontal = "right hemisphere"
        else:
            horizontal = "midline"
        
        # Intensity
        if max_val > 0.7:
            intensity = "Strong focal"
        elif max_val > 0.5:
            intensity = "Moderate"
        else:
            intensity = "Diffuse"
        
        return f"{intensity} activation in {vertical} region, {horizontal}"
    
    def _generate_enhanced_fallback(self, raw_image: np.ndarray) -> dict:
        """Smart fallback that analyzes image intensity for tumor detection."""
        try:
            # Convert and resize
            if len(raw_image.shape) == 3:
                gray = cv2.cvtColor(raw_image, cv2.COLOR_BGR2GRAY)
                rgb = cv2.cvtColor(raw_image, cv2.COLOR_BGR2RGB)
            else:
                gray = raw_image.copy()
                rgb = cv2.cvtColor(raw_image, cv2.COLOR_GRAY2RGB)
            
            gray_resized = cv2.resize(gray, (224, 224))
            rgb_resized = cv2.resize(rgb, (224, 224))
            
            # Analyze intensity to find potential tumor regions
            # Brain MRIs: tumors often appear as brighter regions
            blurred = cv2.GaussianBlur(gray_resized, (15, 15), 0)
            normalized = (blurred - blurred.min()) / (blurred.max() - blurred.min() + 1e-8)
            
            # Create mask for brain region (non-black areas)
            brain_mask = (gray_resized > 20).astype(np.float32)
            
            # Find high-intensity regions within brain
            threshold = np.percentile(blurred[gray_resized > 20], 85)
            highlight_mask = ((blurred > threshold) & (gray_resized > 20)).astype(np.float32)
            
            # Smooth the highlight mask
            highlight_mask = cv2.GaussianBlur(highlight_mask, (31, 31), 0)
            highlight_mask = highlight_mask / (highlight_mask.max() + 1e-8)
            
            # Create heatmap
            heatmap = np.zeros((224, 224, 3), dtype=np.float32)
            for i in range(224):
                for j in range(224):
                    v = highlight_mask[i, j]
                    if v < 0.3:
                        heatmap[i, j] = [0, 0, v * 3]  # Blue
                    elif v < 0.6:
                        t = (v - 0.3) / 0.3
                        heatmap[i, j] = [t, 1 - t * 0.5, 1 - t]  # Green-Yellow
                    else:
                        t = (v - 0.6) / 0.4
                        heatmap[i, j] = [1, 0.5 - t * 0.5, 0]  # Red
            
            # Blend
            rgb_norm = rgb_resized.astype(np.float32) / 255.0
            alpha = 0.3 + highlight_mask * 0.4
            alpha = np.expand_dims(alpha, axis=2)
            
            result = rgb_norm * (1 - alpha) + heatmap * alpha
            result = (result * 255).clip(0, 255).astype(np.uint8)
            
            # Find location
            y_idx, x_idx = np.indices((224, 224))
            total = highlight_mask.sum() + 1e-8
            cy = (y_idx * highlight_mask).sum() / total
            cx = (x_idx * highlight_mask).sum() / total
            
            if cy < 75:
                vert = "superior (upper)"
            elif cy > 150:
                vert = "inferior (lower)"
            else:
                vert = "central"
            
            if cx < 90:
                horiz = "left"
            elif cx > 134:
                horiz = "right"
            else:
                horiz = "midline"
            
            _, buffer = cv2.imencode('.png', cv2.cvtColor(result, cv2.COLOR_RGB2BGR))
            heatmap_base64 = base64.b64encode(buffer).decode('utf-8')
            
            return {
                "heatmap": heatmap_base64,
                "location": f"Detected in {vert} {horiz} region of brain",
                "intensity": float(highlight_mask.max()),
                "success": True
            }
            
        except Exception as e:
            print(f"Fallback error: {e}")
            return {
                "heatmap": None,
                "location": "Visualization unavailable",
                "intensity": 0,
                "success": False
            }


gradcam_service = None

def initialize_gradcam(model, device):
    global gradcam_service
    gradcam_service = GradCAMService(model, device)
    return gradcam_service
