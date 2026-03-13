# Planogram Validator - Full Stack Application

Aplikasi full-stack untuk validasi kepatuhan planogram rak retail menggunakan YOLO detections dengan backend FastAPI dan frontend Flutter.

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Backend Setup (FastAPI)](#backend-setup-fastapi)
- [Frontend Setup (Flutter)](#frontend-setup-flutter)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)

---

## 📁 Project Structure

```
plano_gram/
├── api_server.py              # FastAPI backend server
├── rules_engine.py            # Validation logic
├── data_dummy.py              # Target config & dummy data
├── scanner.py                 # YOLO wrapper
├── utils.py                   # Math utilities
├── main.py                    # CLI version
├── requirements.txt           # Python dependencies
└── flutter_app/
    ├── pubspec.yaml           # Flutter dependencies
    ├── lib/
    │   ├── main.dart          # App entry point
    │   ├── models/
    │   │   └── validation_models.dart
    │   ├── services/
    │   │   └── api_service.dart
    │   ├── providers/
    │   │   └── validation_provider.dart
    │   └── screens/
    │       ├── home_screen.dart
    │       └── result_screen.dart
    └── android/
```

---

## 🔧 Backend Setup (FastAPI)

### Prerequisites

- Python 3.9+
- pip (Python package manager)
- FastAPI & Uvicorn

### Installation

1. **Navigate to project directory:**
   ```bash
   cd c:\Users\brian\Downloads\plano_gram
   ```

2. **Create virtual environment (optional but recommended):**
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   ```

3. **Install FastAPI dependencies:**
   ```bash
   pip install fastapi uvicorn python-multipart
   ```

4. **Or install all Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

### Running the Backend

```bash
python api_server.py
```

Output:
```
================================================================================
                🚀 STARTING PLANOGRAM API SERVER
================================================================================

Server akan berjalan di: http://localhost:8000
API Documentation: http://localhost:8000/docs
Alternative Docs: http://localhost:8000/redoc

================================================================================
```

**Access the API:**
- Main API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## 🎨 Frontend Setup (Flutter)

### Prerequisites

- Flutter SDK (3.0.0 or later)
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

### Installation

1. **Navigate to Flutter app directory:**
   ```bash
   cd c:\Users\brian\Downloads\plano_gram\flutter_app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate JSON serialization code:**
   ```bash
   flutter pub run build_runner build
   ```

### Running the Frontend

1. **Start emulator or connect device:**
   ```bash
   # List available devices
   flutter devices
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

   Or with specific device:
   ```bash
   flutter run -d <device_id>
   ```

---

## 🚀 Running the Application

### Step 1: Start Backend Server

```bash
cd plano_gram
python api_server.py
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 2: Configure API URL in Flutter (If Needed)

If using physical device or different host:

**Open `lib/services/api_service.dart` and modify:**

```dart
// For local development (emulator)
final String _baseUrl = 'http://10.0.2.2:8000';

// For physical device on same network
final String _baseUrl = 'http://192.168.x.x:8000';
```

### Step 3: Run Flutter App

```bash
cd flutter_app
flutter run
```

---

## 📡 API Documentation

### Health Check

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "message": "Planogram Compliance API is running"
}
```

### Validate Planogram

**Endpoint:** `POST /api/validate`

**Request Body:**
```json
{
  "detections": [
    {
      "product_name": "Indomie",
      "confidence": 0.95,
      "bbox": {
        "x1": 10,
        "y1": 20,
        "x2": 50,
        "y2": 100
      },
      "class_name": "Product"
    }
  ],
  "planogram_target": null
}
```

**Response:**
```json
{
  "status": "success",
  "summary": {
    "pass_count": 6,
    "fail_count": 1,
    "skip_count": 0,
    "total_params": 7,
    "compliance_score": 85.7,
    "grade": "GOOD"
  },
  "parameters": {
    "sos": {...},
    "sequence": {...},
    ...
  },
  "timestamp": "2026-03-12T00:00:00Z"
}
```

### Quick Test with Dummy Data

**Endpoint:** `POST /api/validate-with-dummy`

No request body needed. Will run validation on built-in dummy data.

### Get Dummy Data

**Endpoint:** `GET /api/dummy-data`

Returns example YOLO detections and target configuration.

### Get Default Target

**Endpoint:** `GET /api/default-target`

Returns default planogram target configuration.

---

## 🛠️ Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Change port in api_server.py
uvicorn.run(app, host="0.0.0.0", port=8001)
```

**Import errors:**
```bash
pip install --upgrade -r requirements.txt
```

### Flutter Issues

**Dependencies not found:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Can't connect to API:**
- Check backend is running on correct port
- Check API URL in `api_service.dart`
- For emulator: use `http://10.0.2.2:8000` instead of `localhost`
- For physical device: use actual IP address of development machine

**Build issues:**
```bash
flutter pub cache repair
flutter pub get
flutter clean
flutter run
```

---

## 📝 Features

### Backend (FastAPI)
- ✅ RESTful API endpoints
- ✅ Pydantic request/response validation
- ✅ CORS enabled for Flutter
- ✅ Swagger/OpenAPI documentation
- ✅ Dummy data testing endpoint
- ✅ Error handling

### Frontend (Flutter)
- ✅ Material Design UI
- ✅ Add/remove detection items
- ✅ Real-time form validation
- ✅ Compliance score visualization
- ✅ Parameter detail breakdown
- ✅ Dark mode support
- ✅ State management with Provider

---

## 🔜 Future Enhancements

- [ ] Image upload & YOLO integration
- [ ] Real-time camera detection
- [ ] Export/PDF report generation
- [ ] Historical data tracking
- [ ] Multi-language support
- [ ] Offline mode with local DB
- [ ] IoT integration for automated monitoring

---

## 📄 License

This project is part of the Planogram Compliance System.

---

## 📧 Support

For issues or questions, refer to the API documentation at `http://localhost:8000/docs`
