from fastapi import APIRouter, UploadFile, File, HTTPException
import cv2
import numpy as np
from backend.services.validator import validator
from backend.services.preprocessing import preprocess_image
from backend.services.inference import inference_service
from backend.services.xai import xai_service
from backend.services.anatomy import locate_tumor

router = APIRouter()

@router.post("/analyze")
async def analyze_mri(file: UploadFile = File(...)):
    # 1. Read Bytes
    contents = await file.read()
    
    # 2. Strict Validation
    validation = validator.validate(contents)
    if not validation["valid"]:
        raise HTTPException(status_code=400, detail=validation["error"])
        
    try:
        # Decode for processing
        nparr = np.frombuffer(contents, np.uint8)
        original_image = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
        
        # 3. Preprocessing (for display/mask only)
        processed = preprocess_image(original_image)
        
        # 4. Inference (uses RAW image - applies its own transforms)
        classification = inference_service.classify_tumor(original_image)
        mask = inference_service.segment_tumor(processed)
        
        # 5. GradCAM Visualization (shows WHERE tumor is detected)
        class_idx = classification.get("class_index", 0)
        gradcam_result = inference_service.generate_visualization(original_image, class_idx)
        
        # 6. Anatomical Localization
        location = locate_tumor(mask)
        
        # 7. XAI Generation (text explanation)
        heatmap = xai_service.generate_heatmap(original_image, mask)
        explanation = xai_service.generate_explanation(classification, location)
        
        # Build response with GradCAM
        return {
            "status": "success",
            "validation": validation,
            "classification": classification,
            "segmentation": {
                "mask_base64": "dummy_base64_mask",
                "has_tumor": classification["type"].lower() != "notumor"
            },
            "anatomy": location,
            "xai": {
                "heatmap_base64": heatmap,
                "explanation": explanation
            },
            "gradcam": {
                "heatmap_base64": gradcam_result.get("heatmap"),
                "tumor_location": gradcam_result.get("location", "Analysis pending"),
                "intensity": gradcam_result.get("intensity", 0),
                "available": gradcam_result.get("success", False)
            }
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@router.get("/health")
def health_check():
    return {"status": "ok"}
