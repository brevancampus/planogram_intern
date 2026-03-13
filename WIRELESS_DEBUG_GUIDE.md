# 📱 Panduan Wireless Debugging Flutter

## Setup Konfigurasi

- **PC (Development Machine)**: `192.168.0.121`
- **Device (Android Phone)**: `192.168.0.132`
- **Backend API**: `http://192.168.0.121:8000`
- **Flutter App**: Sudah dikonfigurasi untuk wireless!

---

## ✅ Step 1: Pastikan Device Siap untuk Wireless Debugging

Di **HP Android** kamu:

1. Buka **Settings → Developer Options** (tekan 7x di Build Number jika belum aktif)
2. Aktifkan **"USB Debugging"**
3. Aktifkan **"Wireless debugging"** (Android 11+)
4. Catat **IP + Port** yang ditampilkan (contoh: `192.168.0.132:45055`)

---

## ✅ Step 2: Hubungkan Device via Wireless ADB

**Opsi A: Pairing Pertama Kali (Wireless)**

Di **PowerShell** (PC kamu):

```powershell
$env:PATH = "C:\Users\brian\AppData\Local\Android\sdk\platform-tools;$env:PATH"

# Jika diminta pairan code & PIN, lihat di device → Wireless debugging
adb pair 192.168.0.132:45055 <PAIRING_CODE>

# Tunggu hingga berhasil, lalu connect:
adb connect 192.168.0.132:45055
```

**Opsi B: Device Sudah Pernah Dipair**

```powershell
$env:PATH = "C:\Users\brian\AppData\Local\Android\sdk\platform-tools;$env:PATH"
adb connect 192.168.0.132:45055
```

**Cek Status:**
```powershell
adb devices
```

Output yang benar:
```
List of devices attached
192.168.0.132:45055     device
```

---

## ⚠️ Troubleshooting: Jika Device Tidak Terdeteksi

### Masalah 1: "A connection attempt failed"
```powershell
# Pastikan device aktif dan wireless debugging ON
# Coba test konektivitas:
ping 192.168.0.132

# Jika pingable tapi adb tidak konek, restart wireless debugging:
# Di device: Settings → Developer Options → Wireless debugging → OFF, lalu ON lagi
```

### Masalah 2: Device Offine
```powershell
# Kill & restart adb daemon:
adb kill-server
adb devices
# Tunggu beberapa detik, lalu retry connect
```

### Masalah 3: "Multiple adb instances connected"
```powershell
# Disconnect yang kecil sebelumnya:
adb disconnect 192.168.0.132:45055

# Atau disconnect semua:
adb disconnect

# Coba lagi:
adb connect 192.168.0.132:45055
```

---

## ✅ Step 3: Verifikasi Backend Berjalan

**Pastikan API running di PC:**

```powershell
cd C:\Users\brian\Downloads\plano_gram

# Terminal 1: Jalankan backend
python api_server.py
# Harus melihat: "Uvicorn running on http://0.0.0.0:8000"

# Terminal 2: Test endpoint dari PC
Invoke-WebRequest -Uri "http://192.168.0.121:8000/health" -UseBasicParsing
# Status: 200 OK ✓
```

---

## ✅ Step 4: Run Flutter di Device

**Terminal 3** (di folder `flutter_app`):

```powershell
cd C:\Users\brian\Downloads\plano_gram\flutter_app

# Verify device terdeteksi:
flutter devices
# Output: device harus muncul dengan status "connected"

# Jalankan app:
flutter run
```

---

## 🎯 Testing di Device

Setelah app launched:

1. **Klik "Test Dummy Data"** button
2. Lihat apakah API respond dengan compliance score
3. Jika ada error, check:
   - Backend still running di PC
   - Network connectivity
   - Device bisa ping `192.168.0.121`

---

## 📊 Network Topology

```
┌──────────────────────────┐
│  PC (192.168.0.121)      │
│  ├─ Backend: 8000        │
│  └─ ADB Server           │
└────────────┬─────────────┘
             │ WiFi Network (192.168.0.x)
             │
┌────────────▼─────────────┐
│ Device (192.168.0.132)   │
│  ├─ ADB Daemon: 45055    │
│  └─ Flutter App          │
│     └─ HTTP → PC:8000    │
└──────────────────────────┘
```

---

## 🔧 Konfigurasi yang Sudah Diupdate

✅ **Flutter API Service** (`api_service.dart`):
```dart
ApiService({String baseUrl = 'http://192.168.0.121:8000'})
```

Jika mau ganti IP kemudian:
```dart
ApiService(baseUrl: 'http://192.168.0.121:8000')
// atau pass saat main.dart initialize
```

---

## 📋 Quick Checklist

- [ ] Device WiFi debugging aktif (Settings → Developer Options → Wireless debugging)
- [ ] ADB paired & connected: `adb devices` shows device
- [ ] Backend running: `python api_server.py` 
- [ ] PC firewall allows port 8000 (or disable for testing)
- [ ] Device bisa ping PC: `adb shell ping 192.168.0.121`
- [ ] Flutter app launched: `flutter run`
- [ ] Test "Dummy Data" button works
- [ ] Lihat compliance score: ✅ DONE!

---

## 💡 Tips

- **Keep screen on**: Device mungkin sleep → tap screen saat app loading
- **Use Logcat**: Lihat logs real-time:
  ```powershell
  adb logcat | grep flutter
  ```
- **Enable Developer Mode**: Jangan forget Settings → Developer Options
- **Airplane Mode**: WiFi debugging tidak jalan di airplane mode

---

## 🚀 Next Steps

Setelah device connected:

1. Coba "Test Dummy Data" - harus melihat hasil validasi
2. Tambah detections manual via form
3. Lihat real-time scoring
4. Build APK release untuk production:
   ```powershell
   flutter build apk --release
   ```

---

**Good luck! 🎉**

Jika ada masalah, cek:
1. Network connectivity: `ping 192.168.0.132`
2. ADB status: `adb devices`
3. Backend status: Buka terminal tempat `api_server.py` running
4. Log app: `flutter run` output di PowerShell
