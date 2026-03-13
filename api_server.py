"""
FASTAPI BACKEND - REST API untuk Planogram Validation System
Menghubungkan sistem validasi dengan frontend (Flutter)
"""

from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
import json
from pathlib import Path
import tempfile
import shutil
from datetime import datetime

# Import sistem validasi lokal
from data_dummy import PLANOGRAM_TARGET, YOLO_DETECTION_DUMMY
from rules_engine import PlanogramValidator

# Optional: Import YOLO scanner jika tersedia
try:
    from scanner import YOLOScanner
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False
    print("[WARN] YOLOScanner tidak tersedia - Multi-photo audit disabled")


# ============================================================================
# PYDANTIC MODELS (Request/Response Schema)
# ============================================================================

class BBox(BaseModel):
    """Bounding box model"""
    x1: float
    y1: float
    x2: float
    y2: float
    
    def to_tuple(self) -> tuple:
        """Convert to tuple format"""
        return (self.x1, self.y1, self.x2, self.y2)


class DetectionItem(BaseModel):
    """Single YOLO detection item"""
    product_name: str
    confidence: float
    bbox: BBox
    class_name: str  # "Product", "Price_Tag", "POSM"


class ValidationRequest(BaseModel):
    """Request body untuk validation endpoint"""
    detections: List[DetectionItem]
    planogram_target: Optional[Dict] = None  # Optional, gunakan default jika tidak ada


class ParameterResult(BaseModel):
    """Individual parameter validation result"""
    status: str  # "PASS", "FAIL", "SKIP"
    parameter: str
    details: Optional[Dict] = None


class ComplianceSummary(BaseModel):
    """Summary hasil validasi"""
    pass_count: int
    fail_count: int
    skip_count: int
    total_params: int
    compliance_score: float
    grade: str  # "EXCELLENT", "GOOD", "NEEDS_ATTENTION", "CRITICAL"


class ValidationResponse(BaseModel):
    """Response body untuk validation endpoint"""
    status: str  # "success" atau "error"
    summary: ComplianceSummary
    parameters: Dict[str, Dict]  # Detailed results per parameter
    timestamp: str


class AuditPhotoResult(BaseModel):
    """Single photo audit result"""
    photo_index: int
    filename: str
    detections_count: int
    status: str  # "success" atau "error"
    error_message: Optional[str] = None


class MultiPhotoAuditResponse(BaseModel):
    """Response untuk multi-photo audit endpoint"""
    status: str  # "success" atau "error"
    total_photos: int
    photos_processed: int
    photos_failed: int
    total_detections: int
    photo_results: List[AuditPhotoResult]
    summary: ComplianceSummary
    parameters: Dict[str, Dict]
    timestamp: str
    notes: str = "Hasil kombinasi dari semua foto"


# ============================================================================
# FASTAPI APP INITIALIZATION
# ============================================================================

app = FastAPI(
    title="Planogram Compliance API",
    description="REST API untuk validasi kepatuhan planogram menggunakan YOLO detections",
    version="1.0.0"
)

# Enable CORS untuk Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Production: specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def detection_items_to_dict(detections: List[DetectionItem]) -> List[Dict]:
    """Convert Pydantic DetectionItem list to dict format yang dibutuhkan validator"""
    result = []
    for det in detections:
        result.append({
            "product_name": det.product_name,
            "confidence": det.confidence,
            "bbox": det.bbox.to_tuple(),  # Convert BBox ke tuple
            "class_name": det.class_name
        })
    return result


def get_compliance_grade(score: float) -> str:
    """Determine compliance grade based on score"""
    if score == 100:
        return "EXCELLENT"
    elif score >= 80:
        return "GOOD"
    elif score >= 50:
        return "NEEDS_ATTENTION"
    else:
        return "CRITICAL"


# ============================================================================
# HEALTH CHECK ENDPOINT
# ============================================================================

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "Planogram Compliance API is running"
    }


# ============================================================================
# MAIN VALIDATION ENDPOINT
# ============================================================================

@app.post("/api/validate", response_model=ValidationResponse)
async def validate_planogram(request: ValidationRequest):
    """
    Main validation endpoint.
    
    Menerima YOLO detections dan menjalankan full planogram validation.
    
    Example request:
    ```json
    {
      "detections": [
        {
          "product_name": "Indomie",
          "confidence": 0.95,
          "bbox": {"x1": 10, "y1": 20, "x2": 50, "y2": 100},
          "class_name": "Product"
        },
        ...
      ]
    }
    ```
    """
    try:
        # Konversi request ke format dict yang dibutuhkan validator
        detections_dict = detection_items_to_dict(request.detections)
        
        # Gunakan planogram target dari request atau fallback ke default
        target = request.planogram_target or PLANOGRAM_TARGET
        
        # Run validation
        validator = PlanogramValidator(detections_dict, target)
        results = validator.validate_all()
        summary = validator.get_summary()
        
        # Hitung grade
        score = summary.get("compliance_score", 0)
        grade = get_compliance_grade(score)
        
        # Build response
        response = ValidationResponse(
            status="success",
            summary=ComplianceSummary(
                pass_count=summary["pass_count"],
                fail_count=summary["fail_count"],
                skip_count=summary["skip_count"],
                total_params=summary["total_params"],
                compliance_score=score,
                grade=grade
            ),
            parameters=results,
            timestamp="2026-03-12T00:00:00Z"
        )
        
        return response
    
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Validation error: {str(e)}"
        )


# ============================================================================
# HELPER ENDPOINTS
# ============================================================================

@app.get("/api/dummy-data")
def get_dummy_data():
    """Get dummy YOLO detection data untuk testing"""
    return {
        "detections": YOLO_DETECTION_DUMMY,
        "target": PLANOGRAM_TARGET
    }


@app.post("/api/validate-with-dummy")
async def validate_with_dummy():
    """Shortcut endpoint: Run validation dengan dummy data"""
    try:
        validator = PlanogramValidator(YOLO_DETECTION_DUMMY, PLANOGRAM_TARGET)
        results = validator.validate_all()
        summary = validator.get_summary()
        
        score = summary.get("compliance_score", 0)
        grade = get_compliance_grade(score)
        
        response = ValidationResponse(
            status="success",
            summary=ComplianceSummary(
                pass_count=summary["pass_count"],
                fail_count=summary["fail_count"],
                skip_count=summary["skip_count"],
                total_params=summary["total_params"],
                compliance_score=score,
                grade=grade
            ),
            parameters=results,
            timestamp="2026-03-12T00:00:00Z"
        )
        
        return response
    
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Validation error: {str(e)}"
        )


@app.get("/api/default-target")
def get_default_target():
    """Get default planogram target configuration"""
    return PLANOGRAM_TARGET


# ============================================================================
# MULTI-PHOTO AUDIT ENDPOINT
# ============================================================================

@app.post("/api/audit-multiple", response_model=MultiPhotoAuditResponse)
async def audit_multiple_photos(files: List[UploadFile] = File(...)):
    """
    Multi-Photo Shelf Audit Endpoint.
    
    Menerima beberapa foto rak, menjalankan YOLO pada masing-masing,
    dan menggabungkan hasil untuk skor compliance keseluruhan.
    
    Flow:
    1. User upload N foto (kiri, tengah, kanan, dst)
    2. Backend YOLO scan setiap foto individually
    3. Combine all detections
    4. Run PlanogramValidator on combined detections
    5. Return summary + per-parameter results
    
    Args:
        files: List[UploadFile] - Foto-foto rak yang akan diaudit
    
    Returns:
        MultiPhotoAuditResponse dengan:
        - total_photos: Jumlah foto yang diterima
        - photos_processed: Berhasil di-process
        - photos_failed: Gagal di-process
        - total_detections: Total deteksi dari semua foto
        - photo_results: Status per-photo
        - summary & parameters: Hasil validasi kombinasi
    """
    if not files or len(files) == 0:
        raise HTTPException(
            status_code=400,
            detail="Minimal 1 foto diperlukan untuk audit"
        )
    
    if len(files) > 10:
        raise HTTPException(
            status_code=400,
            detail="Maksimal 10 foto per audit"
        )
    
    # Create temp directory untuk store uploaded files
    temp_dir = tempfile.mkdtemp(prefix="audit_")
    
    try:
        all_detections: List[Dict] = []
        photo_results: List[AuditPhotoResult] = []
        photos_processed = 0
        photos_failed = 0
        
        print(f"\n{'='*80}")
        print(f"[API] MULTI-PHOTO AUDIT: {len(files)} foto diterima") # BENAR
        print(f"{'='*80}\n")
        
        # ====================================================================
        # STEP 1: Scan setiap foto
        # ====================================================================
        for idx, file in enumerate(files):
            print(f"[{idx+1}/{len(files)}] Processing: {file.filename}")
            
            try:
                # Validasi file type
                if not file.filename.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tiff')):
                    raise ValueError(f"Unsupported image format: {file.filename}")
                
                # Save uploaded file temporarily
                file_path = Path(temp_dir) / file.filename
                with open(file_path, "wb") as f:
                    content = await file.read()
                    f.write(content)
                
                # Run YOLO detection
                if not YOLO_AVAILABLE:
                    raise RuntimeError(
                        "YOLO scanner tidak tersedia. Install ultralytics: pip install ultralytics"
                    )
                
                # Initialize YOLO scanner (jika belum ada global instance)
                # NOTE: Untuk production, gunakan singleton pattern
                scanner = YOLOScanner(model_path="best.pt", conf_threshold=0.5)
                detections = scanner.scan_image(str(file_path), save_annotated=False)
                
                # Append ke all_detections
                all_detections.extend(detections)
                
                photo_results.append(AuditPhotoResult(
                    photo_index=idx + 1,
                    filename=file.filename,
                    detections_count=len(detections),
                    status="success",
                    error_message=None
                ))
                
                photos_processed += 1
                print(f"  [OK] Success: {len(detections)} detections")
                
            except Exception as e:
                print(f"  [ERROR] Error: {str(e)}")
                
                photo_results.append(AuditPhotoResult(
                    photo_index=idx + 1,
                    filename=file.filename,
                    detections_count=0,
                    status="error",
                    error_message=str(e)
                ))
                
                photos_failed += 1
        
        # ====================================================================
        # STEP 2: Check jika ada detections
        # ====================================================================
        if len(all_detections) == 0:
            raise HTTPException(
                status_code=400,
                detail=f"Tidak ada objek terdeteksi dari {photos_processed} foto yang diproses"
            )
        
        print(f"\n{'='*70}")
        print(f"[OK] Total Detections: {len(all_detections)} dari {photos_processed} foto")
        print(f"{'='*70}\n")
        
        # ====================================================================
        # STEP 3: Validate kombinasi detections
        # ====================================================================
        print("Running Compliance Validation...\n")
        
        validator = PlanogramValidator(all_detections, PLANOGRAM_TARGET)
        results = validator.validate_all()
        summary = validator.get_summary()
        
        score = summary.get("compliance_score", 0)
        grade = get_compliance_grade(score)
        
        print(f"Compliance Score: {score:.1f}% - Grade: {grade}\n")
        
        # ====================================================================
        # STEP 4: Build response
        # ====================================================================
        response = MultiPhotoAuditResponse(
            status="success",
            total_photos=len(files),
            photos_processed=photos_processed,
            photos_failed=photos_failed,
            total_detections=len(all_detections),
            photo_results=photo_results,
            summary=ComplianceSummary(
                pass_count=summary["pass_count"],
                fail_count=summary["fail_count"],
                skip_count=summary["skip_count"],
                total_params=summary["total_params"],
                compliance_score=score,
                grade=grade
            ),
            parameters=results,
            timestamp=datetime.now().isoformat(),
            notes=f"Coordinate stitching: {photos_processed} foto, {len(all_detections)} total detections"
        )
        
        return response
        
    except HTTPException:
        raise
    
    except Exception as e:
        print(f"\n[FAILED] ERROR: {str(e)}\n")
        raise HTTPException(
            status_code=500,
            detail=f"Multi-photo audit error: {str(e)}"
        )
    
    finally:
        # Cleanup temp directory
        try:
            shutil.rmtree(temp_dir)
        except Exception as e:
            print(f"[WARN] Warning: Gagal cleanup temp dir: {e}")


# ============================================================================
# RUN SERVER
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    print("\n" + "="*80)
    print(" "*20 + "STARTING PLANOGRAM API SERVER")
    print("="*80)
    print("\nServer akan berjalan di: http://localhost:8000")
    print("API Documentation: http://localhost:8000/docs")
    print("Alternative Docs: http://localhost:8000/redoc")
    print("\n" + "="*80 + "\n")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
