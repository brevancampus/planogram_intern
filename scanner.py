"""
SCANNER - YOLO WRAPPER
File wrapper untuk Ultralytics YOLOv8.
Bertanggung jawab untuk:
1. Load model .pt
2. Membaca file gambar
3. Menjalankan deteksi
4. Mengkonversi output ke format List[Dict] sesuai contract
"""

import sys
from pathlib import Path
from typing import List, Dict, Optional

# Coba import ultralytics YOLO
try:
    from ultralytics import YOLO
except ImportError:
    raise ImportError(
        "Ultralytics YOLO tidak terinstall. "
        "Silakan jalankan: pip install ultralytics"
    )


class YOLOScanner:
    """Wrapper untuk YOLO deteksi dengan konversi format output."""
    
    def __init__(self, model_path: str, conf_threshold: float = 0.5):
        """
        Inisialisasi scanner dengan model YOLO.
        
        Args:
            model_path: Path ke file model .pt (e.g., 'best (1).pt')
            conf_threshold: Confidence minimum untuk deteksi (default 0.5)
        
        Raises:
            FileNotFoundError: Jika file model tidak ditemukan
        """
        model_file = Path(model_path)
        
        if not model_file.exists():
            raise FileNotFoundError(
                f"Model YOLO tidak ditemukan di: {model_path}\n"
                f"Absolute path: {model_file.absolute()}"
            )
        
        try:
            self.model = YOLO(model_path)
            self.conf_threshold = conf_threshold
            print(f"✓ Model YOLO berhasil dimuat: {model_path}")
        except Exception as e:
            raise RuntimeError(f"Gagal load model YOLO: {str(e)}")
    
    def scan_image(self, image_path: str, save_annotated: bool = True) -> List[Dict]:
        """
        Scan gambar dan kembalikan hasil deteksi dalam format standard.
        
        Args:
            image_path: Path ke file gambar
            save_annotated: Jika True, simpan gambar dengan bounding box
        
        Returns:
            List of detection dictionaries dengan format:
            [{
                "product_name": str (nama class dari YOLO),
                "confidence": float,
                "bbox": (x1, y1, x2, y2),  # left-top & right-bottom
                "class_name": str  # class name dari model YOLO
            }, ...]
        
        Raises:
            FileNotFoundError: Jika image_path tidak ada
            RuntimeError: Jika deteksi gagal
        """
        image_file = Path(image_path)
        
        if not image_file.exists():
            raise FileNotFoundError(
                f"File gambar tidak ditemukan di: {image_path}\n"
                f"Absolute path: {image_file.absolute()}"
            )
        
        try:
            # Jalankan deteksi
            results = self.model.predict(
                source=image_path,
                conf=self.conf_threshold,
                save=save_annotated,  # Simpan gambar dengan box
                verbose=False
            )
            
            # Convert hasil ke format standard
            detections = self._convert_results(results)
            
            print(f"✓ Deteksi berhasil: {len(detections)} objek terdeteksi")
            
            return detections
            
        except Exception as e:
            raise RuntimeError(
                f"Gagal mendeteksi gambar {image_path}: {str(e)}"
            )
    
    def _convert_results(self, results) -> List[Dict]:
        """
        Convert Ultralytics YOLO results ke format standard.
        
        YOLO results berisi:
        - results[0].boxes: Semua bounding boxes
        - results[0].boxes.xyxy: Koordinat (x1, y1, x2, y2)
        - results[0].boxes.conf: Confidence scores
        - results[0].boxes.cls: Class indices
        - results[0].names: Dict mapping class_id ke class_name
        
        Args:
            results: Output dari model.predict()
        
        Returns:
            List of detection dicts
        """
        detections: List[Dict] = []
        
        if not results or len(results) == 0:
            return detections
        
        result = results[0]  # Hanya 1 image per scan dalam MVP
        
        # Ekstrak info dari boxes
        boxes = result.boxes
        names = result.names  # Dict: {class_id: class_name}
        
        for i in range(len(boxes)):
            # Ambil koordinat (x1, y1, x2, y2)
            xyxy = boxes.xyxy[i].cpu().numpy()  # Convert tensor to numpy
            x1, y1, x2, y2 = float(xyxy[0]), float(xyxy[1]), float(xyxy[2]), float(xyxy[3])
            
            # Ambil confidence
            conf = float(boxes.conf[i].cpu().item())
            
            # Ambil class
            cls_idx = int(boxes.cls[i].cpu().item())
            class_name = names[cls_idx]
            
            # Format output
            detection = {
                "product_name": class_name,
                "confidence": conf,
                "bbox": (x1, y1, x2, y2),
                "class_name": class_name
            }
            
            detections.append(detection)
        
        return detections


def scan_with_yolo(
    image_path: str,
    model_path: str = "best (1).pt",
    conf_threshold: float = 0.5
) -> List[Dict]:
    """
    Wrapper fungsi untuk scan gambar dengan YOLO.
    
    Args:
        image_path: Path ke gambar
        model_path: Path ke model .pt (default: best (1).pt)
        conf_threshold: Confidence threshold (default: 0.5)
    
    Returns:
        List of detections
    
    Raises:
        FileNotFoundError, RuntimeError
    """
    scanner = YOLOScanner(model_path, conf_threshold)
    return scanner.scan_image(image_path)
