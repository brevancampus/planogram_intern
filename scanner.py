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
            model_path: Path ke file model .pt (e.g., 'best.pt')
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
    model_path: str = r"C:\Users\brian\Downloads\plano_gram\models\best.pt",
    conf_threshold: float = 0.5
) -> List[Dict]:
    """
    Wrapper fungsi untuk scan gambar dengan YOLO.
    
    Args:
        image_path: Path ke gambar
        model_path: Path ke model .pt (default: best.pt)
        conf_threshold: Confidence threshold (default: 0.5)
    
    Returns:
        List of detections
    
    Raises:
        FileNotFoundError, RuntimeError
    """
    scanner = YOLOScanner(model_path, conf_threshold)
    return scanner.scan_image(image_path)


def scan_multiple_images_with_stitching(
    image_paths: List[str],
    model_path: str = r"C:\Users\brian\Downloads\plano_gram\models\best.pt",
    conf_threshold: float = 0.5
) -> List[Dict]:
    """
    Scan multiple images (e.g., Left, Center, Right shelf photos) with X-coordinate stitching.
    
    Fixes coordinate reset bug by adding X-offset to each image's detections based on
    the cumulative width of all previous images. This ensures Left-to-Right sequence logic works.
    
    Args:
        image_paths: List of image file paths to process in order (L→C→R)
        model_path: Path to YOLO model .pt file
        conf_threshold: Confidence threshold for detections (default 0.5)
    
    Returns:
        List of all detections with stitched X-coordinates
    
    Raises:
        FileNotFoundError: If image or model not found
        RuntimeError: If detection fails
    """
    import cv2
    
    scanner = YOLOScanner(model_path, conf_threshold)
    all_detections: List[Dict] = []
    current_x_offset = 0
    
    for image_idx, image_path in enumerate(image_paths):
        try:
            # Step 1: Read image to get width
            image = cv2.imread(image_path)
            if image is None:
                raise FileNotFoundError(f"Failed to read image: {image_path}")
            
            image_height, image_width = image.shape[:2]
            
            print(f"\n[{image_idx + 1}/{len(image_paths)}] Processing: {Path(image_path).name}")
            print(f"  Dimensions: {image_width}x{image_height}px | X-offset: {current_x_offset}px")
            
            # Step 2: Run YOLO detection
            results = scanner.model.predict(
                source=image_path,
                conf=scanner.conf_threshold,
                save=False,
                verbose=False
            )
            
            # Step 3: Convert results to standard format
            detections = scanner._convert_results(results)
            
            # Step 4: Apply X-offset to all detections for coordinate stitching
            for detection in detections:
                x1, y1, x2, y2 = detection["bbox"]
                
                # Shift X-coordinates by cumulative offset
                detection["bbox"] = (
                    x1 + current_x_offset,
                    y1,
                    x2 + current_x_offset,
                    y2
                )
                
                # Add metadata for debugging
                detection["photo_index"] = image_idx
                detection["photo_source"] = Path(image_path).name
                detection["x_offset_applied"] = current_x_offset
            
            all_detections.extend(detections)
            
            print(f"  ✓ {len(detections)} objects detected")
            
            # Step 5: Update offset for next image
            current_x_offset += image_width
            
        except FileNotFoundError as e:
            print(f"  ✗ File not found: {str(e)}")
            raise
        except Exception as e:
            print(f"  ✗ Error processing image: {str(e)}")
            raise RuntimeError(f"Multi-photo scan failed at image {image_idx + 1}: {str(e)}")
    
    print(f"\n{'='*70}")
    print(f"✓ MULTI-PHOTO AUDIT COMPLETE")
    print(f"  Total detections: {len(all_detections)}")
    print(f"  Stitched width: {current_x_offset}px across {len(image_paths)} photos")
    print(f"{'='*70}\n")
    
    return all_detections


# Test model classes
model = YOLO(r'C:\Users\brian\Downloads\plano_gram\models\best.pt')
print("📊 MODEL CLASSES:")
for class_id, class_name in model.names.items():
    print(f"  {class_id}: {class_name}")
