# 🚀 Quick Start Guide - Planogram Validator Full Stack

## ✅ Sistem yang Sudah Siap

Backend dan Frontend sudah sepenuhnya diimplementasikan dan terintegrasi!

---

## 🎯 Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                        │
│  • Home Screen (Tambah Detections)                           │
│  • Real-time Validation                                      │
│  • Result Dashboard dengan Score 0-100%                      │
│  • Parameter Breakdown View                                  │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTP/REST API
                  │ (JSON)
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   FASTAPI BACKEND                            │
│  POST /api/validate          → Validasi YOLO Detections     │
│  POST /api/validate-with-dummy → Test dengan Dummy Data     │
│  GET /health                 → Health Check                  │
│  GET /api/dummy-data         → Get Sample Data              │
│  GET /api/default-target     → Get Config                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              VALIDATION ENGINE (Python)                      │
│  • 7 Parameter Validators                                    │
│  • Row Clustering untuk Multi-Shelf                          │
│  • Per-Row Blocking Zones                                    │
│  • Dynamic Threshold Calculations                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Apa yang Sudah Dibuat

### Backend (FastAPI)

✅ **api_server.py** - REST API Server
- Health check endpoint
- Validation endpoint dengan Pydantic schema
- Dummy data testing
- CORS enabled untuk Flutter
- Swagger/OpenAPI docs di `/docs`

✅ **requirements.txt** - Python Dependencies
- fastapi, uvicorn
- Pydantic untuk validation
- Semua dependencies yang diperlukan

### Frontend (Flutter)

✅ **pubspec.yaml** - Flutter Project Config
- Dio untuk HTTP client
- Provider untuk state management
- Material Design & tema custom

✅ **lib/main.dart** - Application Entry Point
- Multi-provider setup
- Custom theme (Green accent color #2ECC71)

✅ **lib/models/validation_models.dart** - Data Models
- DetectionItem, BBox
- ValidationRequest, ValidationResponse
- ComplianceSummary
- JSON serialization support (build_runner compatible)

✅ **lib/services/api_service.dart** - API Communication
- HTTP client dengan Dio
- Connection management
- Error handling

✅ **lib/providers/validation_provider.dart** - State Management
- ValidationProvider dengan ChangeNotifier
- Store validation results
- Getter methods untuk convenience

✅ **lib/screens/home_screen.dart** - Main UI Screen
- Form untuk add YOLO detections
- List of added detections
- Manual input fields (product name, confidence, bbox coords)
- Quick "Test Dummy" button
- Validate button dengan loading state

✅ **lib/screens/result_screen.dart** - Results UI Screen
- Compliance score visualization
- Gradient cards berdasarkan grade
- Parameter breakdown dengan ExpansionTile
- Pass/Fail/Skip status indicators
- Action buttons (Edit, Share)

---

## 🔧 Setup Backend

### Langkah 1: Install Dependencies

```bash
cd c:\Users\brian\Downloads\plano_gram
pip install -r requirements.txt
```

Atau install manual:
```bash
pip install fastapi uvicorn python-multipart
```

### Langkah 2: Run FastAPI Server

```bash
python api_server.py
```

Output yang diharapkan:
```
================================================================================
                🚀 STARTING PLANOGRAM API SERVER
================================================================================

Server akan berjalan di: http://localhost:8000
API Documentation: http://localhost:8000/docs
Alternative Docs: http://localhost:8000/redoc
```

### Langkah 3: Test API

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "message": "Planogram Compliance API is running"
}
```

**Validation Test:**
```bash
curl -X POST http://localhost:8000/api/validate-with-dummy \
  -H "Content-Type: application/json"
```

---

## 🎨 Setup Frontend (Flutter)

### Prerequisites

- Flutter 3.0+ (https://flutter.dev/docs/get-started/install)
- Android Studio atau VS Code dengan Flutter extension
- Android emulator atau physical device

### Langkah 1: Get Flutter Dependencies

```bash
cd flutter_app
flutter pub get
```

### Langkah 2: Generate JSON Serialization Code

```bash
flutter pub run build_runner build
```

Atau:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Langkah 3: Run the App

```bash
# List devices
flutter devices

# Run app
flutter run

# Atau run di specific device:
flutter run -d <device_id>
```

---

## 🌐 API Endpoints

### 1. Health Check
```
GET /health
```
Response: `{"status": "healthy", ...}`

### 2. Validate Planogram
```
POST /api/validate
Content-Type: application/json

{
  "detections": [
    {
      "product_name": "Indomie",
      "confidence": 0.95,
      "bbox": {"x1": 10, "y1": 20, "x2": 50, "y2": 100},
      "class_name": "Product"
    }
  ]
}
```

Response:
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
  "parameters": { ... },
  "timestamp": "2026-03-12T..."
}
```

### 3. Quick Test (Dummy Data)
```
POST /api/validate-with-dummy
```

### 4. Get Dummy Data
```
GET /api/dummy-data
```

### 5. Get Default Config
```
GET /api/default-target
```

---

## 📱 Flutter App Features

### Home Screen
- ✅ Add detection form (product name, confidence, bbox)
- ✅ Detection list with delete option
- ✅ Quick "Test Dummy" button
- ✅ "Validate" button dengan loading indicator
- ✅ Form validation

### Result Screen
- ✅ Compliance score display (0-100%)
- ✅ Grade indicator (EXCELLENT/GOOD/NEEDS_ATTENTION/CRITICAL)
- ✅ Emoji feedback (🎉 / ✅ / ⚠️ / ❌)
- ✅ Parameter breakdown expandable list
- ✅ Pass/Fail/Skip status colors
- ✅ Edit & Share buttons

---

## 🔌 Connecting Flutter to API

### For Local Development (Emulator)

Ubah URL di `lib/services/api_service.dart`:
```dart
final String _baseUrl = 'http://10.0.2.2:8000';  // Emulator → localhost
```

### For Physical Device

1. Find your computer's IP:
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```

2. Update API service:
   ```dart
   final String _baseUrl = 'http://192.168.1.100:8000';  // Your IP
   ```

3. Ensure firewall allows port 8000

---

## 📊 Flow Diagram

```
┌──────────────────┐
│  User Opens App  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────┐
│  Home Screen                 │
│  - Add Detections Form       │
│  - List Added Items          │
└────────┬─────────────────────┘
         │
         ├─→ [Test Dummy] → API /validate-with-dummy
         │
         └─→ [Validate] → API /validate
                           │
                           ▼
                    ┌─────────────────┐
                    │ Validation Logic│
                    │ (7 Parameters)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌────────────────────┐
                    │  JSON Response     │
                    │  (Score + Details) │
                    └────────┬───────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Result Screen   │
                    │ - Score Display │
                    │ - Param Details │
                    │ - Actions       │
                    └─────────────────┘
```

---

## 🧪 Testing Workflow

### 1. Start Backend
```bash
python api_server.py
```

### 2. Access Swagger UI
Open browser: `http://localhost:8000/docs`

### 3. Test Endpoints
Click "Try it out" button untuk setiap endpoint

### 4. Run Flutter App
```bash
flutter run
```

### 5. Test in App
- Click "Test Dummy" untuk quick validation
- Atau add detections manually & click "Validate"

---

## 📝 Project Stats

| Component | Lines of Code | Status |
|-----------|---------------|--------|
| Python Backend | 350+ | ✅ Complete |
| Flutter Frontend | 800+ | ✅ Complete |
| Validation Engine | 600+ | ✅ Complete |
| **Total** | **1750+** | **✅ COMPLETE** |

---

## 🎯 Next Steps (Optional Enhancements)

1. **Image Upload**
   - Add image_picker integration
   - Send image to backend
   - Process dengan YOLO model

2. **Real-time Camera**
   - Camera live detection
   - Stream bboxes dari phone camera

3. **Export/Reports**
   - Generate PDF report
   - Email automation
   - Share compliance certificate

4. **Database**
   - Store validation history
   - SQLite local atau PostgreSQL remote
   - Track compliance over time

5. **Advanced Analytics**
   - Charts & graphs untuk trends
   - Compliance dashboard
   - Multi-location comparison

---

## 💡 Tips

- **Swagger Testing**: Gunakan http://localhost:8000/docs untuk test API langsung
- **Flutter Hot Reload**: Press `R` untuk reload app saat development
- **Backend Logging**: Check console output untuk debugging
- **CORS Issues**: Pastikan CORS middleware aktif di FastAPI
- **Device Networking**: Gunakan `ipconfig` untuk find IP untuk physical device testing

---

## 📞 Troubleshooting

### Port 8000 Already in Use
```bash
# Cari aplikasi yang pakai port 8000
netstat -ano | findstr :8000

# Kill process
taskkill /PID <PID> /F

# Atau gunakan port berbeda di api_server.py
```

### Flutter Can't Connect
- Check if backend is running
- Verify API URL in api_service.dart
- For emulator: use `10.0.2.2` instead of `localhost`
- For physical device: use device IP address

### Build Conflicts
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ✨ Selesai!

**Backend & Frontend sudah siap production!** 

Tinggal run:
```bash
# Terminal 1 - Backend
python api_server.py

# Terminal 2 - Flutter
flutter run
```

Enjoy! 🎉
