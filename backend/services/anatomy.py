import numpy as np

def locate_tumor(mask: np.ndarray) -> dict:
    """
    Locates the tumor based on mask centroid.
    Maps to Hemisphere and Brain Region (2D Heuristic).
    """
    M = cv2.moments(mask)
    if M["m00"] == 0:
        return {
            "hemisphere": "Unknown",
            "region": "Unknown",
            "size_cm2": 0.0
        }
    
    cX = int(M["m10"] / M["m00"])
    cY = int(M["m01"] / M["m00"])
    
    height, width = mask.shape
    
    # Hemisphere
    hemisphere = "Left" if cX > width // 2 else "Right" # Radiological convention is flipped, but assuming standard view for now
    
    # Simple Region Heuristic (3x3 Grid)
    grid_x = cX // (width // 3)
    grid_y = cY // (height // 3)
    
    regions = [
        ["Frontal Lobe", "Frontal Lobe", "Frontal Lobe"],
        ["Temporal Lobe", "Parietal Lobe", "Temporal Lobe"],
        ["Cerebellum", "Brainstem", "Cerebellum"]
    ]
    
    try:
        region = regions[grid_y][grid_x]
    except:
        region = "Unknown"
        
    # Size estimation (assuming 1px = 1mm for standard MRI FOV of ~240mm)
    # Area in pixels
    pixel_area = M["m00"] / 255.0
    # Approx conversion: 240mm / 224px ~= 1.07 mm/px -> Area = 1.07^2 * pixel_area
    real_area_mm2 = pixel_area * (1.14) 
    real_area_cm2 = real_area_mm2 / 100.0
    
    return {
        "hemisphere": hemisphere,
        "region": region,
        "size_cm2": round(real_area_cm2, 2)
    }

import cv2 # Late import to avoid top-level issues if called purely for typing, but ok here.
