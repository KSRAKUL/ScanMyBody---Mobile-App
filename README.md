<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-REST%20API-000000?style=for-the-badge&logo=flask&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Render](https://img.shields.io/badge/Render-Deployed-46E3B7?style=for-the-badge&logo=render&logoColor=white)

<br/>

# 🧠 ScanMyBody
### AI-Powered Brain Tumor Detection Mobile App

> **A full-stack cross-platform mobile application that connects to a cloud-deployed AI backend to detect and classify brain tumors from MRI scans — delivering real-time diagnosis with confidence scores directly on your phone.**

<br/>

[![GitHub stars](https://img.shields.io/github/stars/KSRAKUL/ScanMyBody---Mobile-App?style=social)](https://github.com/KSRAKUL/ScanMyBody---Mobile-App)
[![GitHub forks](https://img.shields.io/github/forks/KSRAKUL/ScanMyBody---Mobile-App?style=social)](https://github.com/KSRAKUL/ScanMyBody---Mobile-App/forks)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-KSRAKUL-0077B5?style=social&logo=linkedin)](https://www.linkedin.com/in/ksrakul)

</div>


## 🔍 Overview

**ScanMyBody** is a full-stack mobile application that brings AI-powered brain tumor detection to any Android or iOS device. The app allows users to upload an MRI scan image directly from their phone, which is then sent to a **cloud-deployed Python/Flask REST API** running a trained deep learning model. Within seconds, the app returns a **diagnosis with confidence score** — classifying the scan as Glioma, Meningioma, Pituitary Tumor, or No Tumor.

The backend leverages the same **Stacked Transfer Learning model** (EfficientNetB0 + MobileNetV3Small + NASNetMobile) trained in the companion research project, containerized with **Docker** and deployed on **Render** for reliable, scalable cloud inference.



## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 📸 **MRI Image Upload** | Upload brain MRI scans from Gallery or Camera |
| 🛡️ **Smart MRI Validation** | Automatically rejects non-MRI images with clear error messages |
| 🤖 **AI Inference** | Real-time classification via cloud-hosted deep learning model |
| 🏷️ **4-Class Detection** | Identifies Glioma · Meningioma · No Tumor · Pituitary |
| 📊 **Confidence Score** | Visual progress bar showing AI prediction probability |
| 🌡️ **Grad-CAM Heatmap** | Color-coded attention map (Low → Mild → High → Critical) |
| 🧠 **AI Explanation** | Tumor description, key characteristics & clinical recommendations |
| 📋 **Scan History** | Full history of past scans with MRI thumbnails & diagnosis tags |
| 👤 **User Profile** | Personalized profile with total scan count & settings |
| 📤 **Share & Export** | Share analysis report via WhatsApp, Gmail, and more |
| 💾 **Save to Gallery** | Download analysis report with heatmap overlay |
| ☁️ **Cloud Backend** | Flask REST API deployed on Render — always available |
| 🐳 **Dockerized** | Fully containerized backend for consistent deployment |
| 📱 **Cross-Platform** | Single codebase for Android & iOS via Flutter |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SCANMYBODY ARCHITECTURE                     │
│                                                                 │
│   📱 MOBILE APP (Flutter/Dart)                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  UI Layer           ViewModel Layer     Service Layer   │  │
│   │  • Splash Screen    • State Mgmt        • API Client    │  │
│   │  • Home Screen      • Image Picker      • HTTP Service  │  │
│   │  • Scan Screen      • Result Handler    • Error Handler │  │
│   │  • History Screen   • Profile Manager                   │  │
│   │  • Profile Screen                                       │  │
│   └────────────────────────┬────────────────────────────────┘  │
│                            │ HTTP POST (multipart/form-data)    │
│                            ▼                                    │
│   ☁️ CLOUD BACKEND (Render)                                     │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  🐳 Docker Container                                    │  │
│   │  ┌───────────────────────────────────────────────────┐  │  │
│   │  │  Flask REST API                                   │  │  │
│   │  │  • /predict endpoint                             │  │  │
│   │  │  • MRI validation                                │  │  │
│   │  │  • Image preprocessing (224×224)                 │  │  │
│   │  │  • Grad-CAM heatmap generation                   │  │  │
│   │  │  • JSON response (class + confidence + heatmap)  │  │  │
│   │  └───────────────────────────────────────────────────┘  │  │
│   │                      │                                   │  │
│   │  ┌───────────────────▼───────────────────────────────┐  │  │
│   │  │  Stacked Transfer Learning Model                  │  │  │
│   │  │  EfficientNetB0 + MobileNetV3Small + NASNetMobile │  │  │
│   │  │  → 4-Class Softmax Output (~87% Val Accuracy)     │  │  │
│   │  └───────────────────────────────────────────────────┘  │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │ JSON Response                      │
│                            ▼                                    │
│   📱 Diagnosis + Confidence + Heatmap displayed on mobile       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Mobile (Frontend)

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **HTTP Client** | http / dio |
| **Image Picker** | image_picker |
| **State Management** | Provider / setState |
| **UI** | Material Design 3 |

### Backend (API)

| Category | Technology |
|----------|-----------|
| **Language** | Python 3.8+ |
| **API Framework** | Flask |
| **Deep Learning** | TensorFlow / Keras |
| **Image Processing** | OpenCV / Pillow |
| **XAI** | Grad-CAM |
| **Containerization** | Docker |
| **Cloud Deployment** | Render |
| **Model** | Stacked Transfer Learning (EfficientNetB0 + MobileNetV3Small + NASNetMobile) |

---

## 📁 Project Structure

```
ScanMyBody---Mobile-App/
│
├── 📁 mobile/                         # Flutter mobile application
│   ├── 📁 lib/
│   │   ├── 📁 screens/
│   │   │   ├── splash_screen.dart      # App entry / onboarding
│   │   │   ├── home_screen.dart        # Dashboard · Quick Actions · Recent Scans
│   │   │   ├── scan_screen.dart        # MRI upload · Gallery & Camera
│   │   │   ├── result_screen.dart      # Diagnosis · Confidence · Heatmap
│   │   │   ├── history_screen.dart     # Scan history with MRI thumbnails
│   │   │   └── profile_screen.dart     # User profile · Settings
│   │   ├── 📁 services/
│   │   │   └── api_service.dart        # Flask API communication
│   │   ├── 📁 widgets/                 # Reusable UI components
│   │   ├── 📁 models/
│   │   │   └── prediction_result.dart  # Prediction data model
│   │   └── main.dart                   # App entry point
│   ├── 📁 android/                     # Android platform config
│   ├── 📁 ios/                         # iOS platform config
│   └── pubspec.yaml                    # Flutter dependencies
│
├── 📁 backend/                         # Python Flask API
│   ├── app.py                          # Flask app & /predict endpoint
│   ├── model_loader.py                 # Model loading & inference
│   ├── preprocessor.py                 # Image preprocessing pipeline
│   ├── gradcam.py                      # Grad-CAM heatmap generation
│   ├── requirements.txt                # Python dependencies
│   └── final_model.keras               # Trained stacked model weights
│
├── 🐳 Dockerfile                       # Docker container configuration
├── render.yaml                         # Render deployment configuration
├── .gitignore
└── 📄 README.md                        # Project documentation
```

---

## 🚀 Getting Started

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate       # Linux / macOS
venv\Scripts\activate          # Windows
pip install -r requirements.txt
python app.py
# API running at → http://localhost:5000
```

**requirements.txt**
```txt
flask>=2.3.0
tensorflow>=2.10.0
keras>=2.10.0
numpy>=1.23.0
opencv-python-headless>=4.6.0
Pillow>=9.2.0
gunicorn>=20.1.0
```

### Mobile App Setup

```bash
cd mobile
flutter pub get
# Set your API URL in lib/services/api_service.dart:
# const String baseUrl = 'https://your-render-url.onrender.com';
flutter run
flutter build apk --release
```

### Docker Setup

```bash
docker build -t scanmybody-backend .
docker run -p 5000:5000 scanmybody-backend
# API available at → http://localhost:5000
```

---

## 📡 API Reference

### `POST /predict`

**Request**
```
Content-Type: multipart/form-data
Body: { "image": <brain MRI image file> }
```

**Response**
```json
{
  "diagnosis": "Meningioma",
  "confidence": 100.0,
  "risk_level": "High Risk",
  "probabilities": {
    "glioma": 0.0,
    "meningioma": 100.0,
    "no_tumor": 0.0,
    "pituitary": 0.0
  },
  "heatmap": "<base64_encoded_heatmap_image>",
  "tumor_location": "central midline region",
  "status": "success"
}
```

**Status Codes**

| Code | Meaning |
|------|---------|
| `200` | Successful prediction |
| `400` | Invalid or non-MRI image |
| `500` | Internal server / model error |

---

## ☁️ Deployment

```yaml
# render.yaml
services:
  - type: web
    name: scanmybody-api
    env: docker
    plan: free
    dockerfilePath: ./Dockerfile
    envVars:
      - key: PORT
        value: 5000
```

**Steps:**
1. Push code to GitHub
2. Connect repo to [Render](https://render.com)
3. Render auto-detects `render.yaml` and deploys the Docker container
4. Update `baseUrl` in Flutter app with the live Render URL
5. Build and release the Flutter APK

---

## 🔬 How It Works

```
User opens ScanMyBody app (Splash Screen)
        │
        ▼
Home Dashboard → Tap "Start Scan" or "New Scan"
        │
        ▼
Select MRI from Gallery or Camera
        │
        ▼
App validates image → Non-MRI rejected with error dialog
        │
        ▼
POST /predict → Flask API on Render (multipart/form-data)
        │
        ▼
Backend: Resize 224×224 → Normalize → Model Inference
        │
        ▼
Stacked TL Model → 4-Class Softmax probabilities
        │
        ▼
Grad-CAM heatmap generated (Low→Mild→High→Critical)
        │
        ▼
JSON response → Mobile app
        │
        ▼
Analysis Report Screen:
  ✅ Diagnosis (e.g. Meningioma)
  📊 AI Confidence % + progress bar
  🌡️ Heatmap with tumor location info
  🧠 AI Explanation + Key Characteristics
  💡 Clinical Recommendations
  📤 Share / Save to Gallery
        │
        ▼
Scan saved to History with timestamp & diagnosis tag
```

---

## 🏷️ Classification Classes

| Class | Description | Risk Level |
|-------|-------------|------------|
| 🔴 **Glioma** | Malignant tumor from glial cells — most common primary brain tumor in adults | High |
| 🟡 **Meningioma** | Tumor from the meninges — typically benign, slow-growing | Moderate |
| 🟢 **No Tumor** | Healthy brain MRI — no tumor detected | Low |
| 🔵 **Pituitary** | Tumor in the pituitary gland — usually non-cancerous | Low–Moderate |

> ⚠️ **Medical Disclaimer:** ScanMyBody is intended for **research and educational purposes only**. It is not a substitute for professional medical diagnosis. Always consult a qualified neurologist or radiologist for clinical decisions.


## 🔗 Related Project

> **[🧠 Explainable AI for Brain Tumor Classification with Stacked Transfer Learning](https://github.com/KSRAKUL/Explainable-AI-for-Brain-Tumor-classification-with-Stacked-Transfer-Learning)**
> — Core AI research project with full model training pipeline, SHAP/Grad-CAM XAI analysis, confusion matrix results, and desktop GUI.

---

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Commit** your changes: `git commit -m 'Add feature'`
4. **Push** to the branch: `git push origin feature/your-feature`
5. **Open** a Pull Request

---

## 👨‍💻 Author

<div align="center">

**KSRAKUL**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ksrakul)
[![GitHub](https://img.shields.io/badge/GitHub-KSRAKUL-181717?style=for-the-badge&logo=github)](https://github.com/KSRAKUL)

*If this project helped you, please ⭐ star the repository on GitHub!*

---

**Made with ❤️ for accessible AI in Medical Imaging**

`Flutter` · `Python` · `Flask` · `Docker` · `Render` · `Deep Learning` · `Brain MRI` · `Healthcare AI`

</div>
