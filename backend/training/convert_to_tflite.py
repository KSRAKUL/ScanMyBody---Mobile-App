"""
Convert PyTorch model to TFLite for Flutter mobile deployment
Step 1: PyTorch -> ONNX (already done)
Step 2: ONNX -> TFLite using onnx2tf
"""

import os
import subprocess
import sys

MODEL_DIR = os.path.join(os.path.dirname(__file__), "../models")
ONNX_PATH = os.path.join(MODEL_DIR, "classifier.onnx")
TFLITE_PATH = os.path.join(MODEL_DIR, "classifier.tflite")

def install_package(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package, "-q"])

def convert_onnx_to_tflite():
    print("="*50)
    print("Converting ONNX to TFLite")
    print("="*50)
    
    # Install required packages
    print("\nInstalling onnx2tf...")
    try:
        install_package("onnx2tf")
        install_package("tensorflow")
        install_package("sng4onnx")
        install_package("onnx_graphsurgeon")
    except Exception as e:
        print(f"Package install warning: {e}")
    
    import onnx2tf
    
    print(f"\nInput ONNX: {ONNX_PATH}")
    print(f"Output TFLite: {TFLITE_PATH}")
    
    # Convert using onnx2tf
    onnx2tf.convert(
        input_onnx_file_path=ONNX_PATH,
        output_folder_path=MODEL_DIR,
        output_file_name="classifier",
        non_verbose=True,
    )
    
    # Find the generated tflite file
    for f in os.listdir(MODEL_DIR):
        if f.endswith('.tflite'):
            src = os.path.join(MODEL_DIR, f)
            if src != TFLITE_PATH:
                os.rename(src, TFLITE_PATH)
            break
    
    if os.path.exists(TFLITE_PATH):
        size_mb = os.path.getsize(TFLITE_PATH) / 1024 / 1024
        print(f"\n✓ TFLite model saved: {TFLITE_PATH}")
        print(f"  Size: {size_mb:.2f} MB")
        return True
    else:
        print("\n✗ TFLite conversion failed")
        return False

if __name__ == "__main__":
    if not os.path.exists(ONNX_PATH):
        print(f"ONNX model not found at {ONNX_PATH}")
        print("Please run the ONNX export first.")
    else:
        convert_onnx_to_tflite()
