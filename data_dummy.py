"""
DEPARTEMEN DATA
File untuk menyimpan target Planogram dan referensi data.
Tidak ada rumus di sini - hanya penyimpanan data statis.

Data Format Contract:
YOLO Output dari scanner.py harus dalam format List[Dict]:
[{
  "product_name": str,
  "confidence": float,
  "bbox": (x1, y1, x2, y2),  # left-top & right-bottom
  "class_name": str  # e.g., "Product", "Price_Tag", "POSM"
}, ...]
"""

from typing import Dict, List


# ============================================================================
# TARGET PLANOGRAM (Kunci Jawaban) - DEFINISI PER RAK
# ============================================================================

PLANOGRAM_TARGET: Dict = {
    "toko_id": "TOKO001",
    "rak_id": "RAK_MINUMAN_01",
    "lokasi_gambar": "data/foto_rak_test.jpg",
    
    # ========================================================================
    # Parameter 1: SOS (Share of Shelf) - Proporsi pixel produk per SKU
    # ========================================================================
    "sos_target": {
        "Indomie": 25.0,      # % dari total pixel lebar rak
        "Aqua": 50.0,         # % dari total pixel lebar rak
        "Sprite": 25.0        # % dari total pixel lebar rak
    },
    
    # ========================================================================
    # Parameter 1: Category Mapping - Grouping produk berdasarkan kategori
    # ========================================================================
    "category_mapping": {
        "Indomie": "Mie Instan",     # Mapping produk ke kategori
        "Aqua": "Minuman",            # Mapping produk ke kategori
        "Sprite": "Minuman"           # Mapping produk ke kategori
    },
    
    # ========================================================================
    # Parameter 2: Facing & OOS
    # ========================================================================
    "facing_target": {
        "Indomie": 1,         # Minimal 1 facing
        "Aqua": 2,            # Minimal 2 facing
        "Sprite": 1           # Minimal 1 facing
    },
    
    "min_quantity": {
        "Indomie": 1,
        "Aqua": 2,
        "Sprite": 1
    },
    
    # ========================================================================
    # Parameter 3: Sequence (Urutan Produk - Row Clustering per Tingkat Rak)
    # Format: List of Lists (2D Array) - [ [Row1_produk1, Row1_produk2, ...], 
    #                                       [Row2_produk1, Row2_produk2, ...], ... ]
    # ========================================================================
    "sequence_target": [["Indomie", "Aqua"], ["Aqua", "Sprite"]],
    
    # ========================================================================
    # Parameter 4: Price Tag dengan Product Blocking
    # ========================================================================
    "price_tag_required": {
        "Indomie": True,
        "Aqua": True,
        "Sprite": True
    },
    
    # ========================================================================
    # Parameter 3B: Eye Level Compliance
    # Zona eye level: 34% - 66% dari tinggi rak (area konsumen ideal)
    # ========================================================================
    "eye_level_required": {
        "Indomie": True,      # Produk premium harus di eye level
        "Aqua": True,         # Produk utama harus di eye level
        "Sprite": False       # Optional di eye level
    },
    
    # ========================================================================
    # Parameter 5: Void Detection (menggunakan median lebar)
    # ========================================================================
    # Tidak ada hardcoded - threshold dihitung dari median lebar produk
    
    # ========================================================================
    # Parameter 6: POSM (Point of Sale Material) - Floating detection
    # ========================================================================
    "posm_required": {
        "Indomie": False,     # Optional
        "Aqua": False,
        "Sprite": False
    },
    
    # ========================================================================
    # Parameter 7: OOS (Out of Stock)
    # ========================================================================
    # Implisit dalam facing_target dan quantity check
}


# ============================================================================
# DUMMY DATA YOLO DETECTION (UNTUK TESTING)
# ============================================================================

YOLO_DETECTION_DUMMY: List[Dict] = [
    # Products - Row 1 (Rak Atas): y1=20, y2=100
    {
        "product_name": "Indomie",
        "confidence": 0.95,
        "bbox": (10, 20, 50, 100),
        "class_name": "Product"
    },
    {
        "product_name": "Aqua",
        "confidence": 0.92,
        "bbox": (55, 20, 95, 100),
        "class_name": "Product"
    },
    # Products - Row 2 (Rak Bawah): y1=110, y2=190
    {
        "product_name": "Aqua",
        "confidence": 0.89,
        "bbox": (10, 110, 50, 190),
        "class_name": "Product"
    },
    {
        "product_name": "Sprite",
        "confidence": 0.88,
        "bbox": (55, 110, 95, 190),
        "class_name": "Product"
    },
    # Price Tags - Row 1
    {
        "product_name": "Price_Tag",
        "confidence": 0.87,
        "bbox": (15, 105, 45, 115),
        "class_name": "Price_Tag"
    },
    {
        "product_name": "Price_Tag",
        "confidence": 0.86,
        "bbox": (60, 105, 90, 115),
        "class_name": "Price_Tag"
    },
    # Price Tags - Row 2
    {
        "product_name": "Price_Tag",
        "confidence": 0.85,
        "bbox": (15, 195, 45, 205),
        "class_name": "Price_Tag"
    },
    {
        "product_name": "Price_Tag",
        "confidence": 0.84,
        "bbox": (60, 195, 90, 205),
        "class_name": "Price_Tag"
    },
]
