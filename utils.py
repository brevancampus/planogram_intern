"""
DEPARTEMEN PERKAKAS MATEMATIKA
File berisi fungsi-fungsi dasar (helper) yang dipakai berulang kali.
Ini adalah tempat untuk rumus-rumus kecil dengan type hinting lengkap.
"""

import math
from typing import List, Tuple, Optional


# Type Aliases
BBox = Tuple[float, float, float, float]  # (x1, y1, x2, y2)


# ============================================================================
# KOORDINAT & GEOMETRI DASAR
# ============================================================================

def hitung_center(x1: float, x2: float) -> float:
    """
    Menghitung koordinat titik tengah (center) dari dua koordinat X atau Y.
    
    Rumus: x_center = (x1 + x2) / 2
    
    Args:
        x1: Koordinat awal
        x2: Koordinat akhir
    
    Returns:
        Koordinat titik tengah
    
    Example:
        >>> hitung_center(10, 50)
        30.0
    """
    return (x1 + x2) / 2.0


def hitung_center_point(bbox: BBox) -> Tuple[float, float]:
    """
    Menghitung titik pusat (center point) dari bounding box.
    
    Args:
        bbox: Tuple (x1, y1, x2, y2)
    
    Returns:
        Tuple (x_center, y_center)
    """
    x1, y1, x2, y2 = bbox
    return (hitung_center(x1, x2), hitung_center(y1, y2))


def hitung_lebar_produk(x1: float, x2: float) -> float:
    """
    Menghitung lebar bounding box produk.
    
    Args:
        x1: Koordinat X1 (kiri)
        x2: Koordinat X2 (kanan)
    
    Returns:
        Lebar bounding box
    
    Example:
        >>> hitung_lebar_produk(10, 50)
        40.0
    """
    return x2 - x1


def hitung_tinggi_produk(y1: float, y2: float) -> float:
    """
    Menghitung tinggi bounding box produk.
    
    Args:
        y1: Koordinat Y1 (atas)
        y2: Koordinat Y2 (bawah)
    
    Returns:
        Tinggi bounding box
    """
    return y2 - y1


def hitung_area_produk(x1: float, y1: float, x2: float, y2: float) -> float:
    """
    Menghitung luas bounding box produk.
    
    Args:
        x1, y1, x2, y2: Koordinat bounding box
    
    Returns:
        Luas bounding box
    """
    lebar = hitung_lebar_produk(x1, x2)
    tinggi = hitung_tinggi_produk(y1, y2)
    return lebar * tinggi


# ============================================================================
# JARAK & EUCLIDEAN (PYTHAGORAS)
# ============================================================================

def hitung_jarak_euclidean(x1: float, y1: float, x2: float, y2: float) -> float:
    """
    Menghitung jarak antara dua titik menggunakan rumus Euclidean/Pythagoras.
    
    Rumus: d = sqrt((x2 - x1)² + (y2 - y1)²)
    
    Args:
        x1: Koordinat X titik awal
        y1: Koordinat Y titik awal
        x2: Koordinat X titik akhir
        y2: Koordinat Y titik akhir
    
    Returns:
        Jarak Euclidean antara kedua titik
    
    Example:
        >>> hitung_jarak_euclidean(0, 0, 3, 4)
        5.0
    """
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


# Alias untuk kompatibilitas backward
def hitung_jarak_posm(x1: float, y1: float, x2: float, y2: float) -> float:
    """Alias dari hitung_jarak_euclidean untuk backward compatibility."""
    return hitung_jarak_euclidean(x1, y1, x2, y2)


def hitung_gap(x2_kiri: float, x1_kanan: float) -> float:
    """
    Menghitung selisih jarak (gap) antara tepi kanan produk kiri dan tepi kiri produk kanan.
    Digunakan untuk deteksi VOID (celah kosong).
    
    Rumus: gap = x1_kanan - x2_kiri
    - Jika gap positif = ada celah
    - Jika gap negatif = produk overlap
    
    Args:
        x2_kiri: Koordinat X2 (tepi kanan) produk sebelah kiri
        x1_kanan: Koordinat X1 (tepi kiri) produk sebelah kanan
    
    Returns:
        Selisih jarak (gap). Positif = celah, Negatif = overlap
    
    Example:
        >>> hitung_gap(50, 60)
        10.0  # Ada celah 10 pixel
        
        >>> hitung_gap(50, 45)
        -5.0  # Ada overlap 5 pixel
    """
    return x1_kanan - x2_kiri


# ============================================================================
# STATISTIK & AGREGASI
# ============================================================================

def hitung_persentase_sos(jumlah_pixel_produk: float, total_pixel: float) -> float:
    """
    Menghitung persentase SOS (Share of Shelf) dari satu produk.
    
    Rumus: SOS% = (jumlah_pixel_produk / total_pixel) * 100
    
    Args:
        jumlah_pixel_produk: Jumlah pixel lebar produk yang terdeteksi
        total_pixel: Total pixel rak yang tersedia
    
    Returns:
        Persentase SOS
    
    Example:
        >>> hitung_persentase_sos(50, 200)
        25.0  # 25% dari total rak
    """
    if total_pixel == 0:
        return 0.0
    return (jumlah_pixel_produk / total_pixel) * 100.0


def hitung_median_lebar(bboxes: List[BBox]) -> float:
    """
    Menghitung median lebar dari list bounding boxes.
    Digunakan untuk threshold Void Detection.
    
    Args:
        bboxes: List of (x1, y1, x2, y2) tuples
    
    Returns:
        Median lebar bounding boxes
    """
    if not bboxes:
        return 0.0
    
    widths = [hitung_lebar_produk(bbox[0], bbox[2]) for bbox in bboxes]
    widths_sorted = sorted(widths)
    n = len(widths_sorted)
    
    if n % 2 == 1:
        return widths_sorted[n // 2]
    else:
        return (widths_sorted[n // 2 - 1] + widths_sorted[n // 2]) / 2.0


# ============================================================================
# ZONA & BLOCKING (UNTUK PRICE TAG & POSM)
# ============================================================================

def apakah_x_dalam_zona(x: float, x_min: float, x_max: float, padding: float = 0.0) -> bool:
    """
    Mengecek apakah koordinat X berada dalam zona/range tertentu.
    
    Args:
        x: Koordinat X yang akan dicek
        x_min: Batas kiri zona
        x_max: Batas kanan zona
        padding: Padding tambahan di kedua sisi zona (opsional)
    
    Returns:
        True jika X berada dalam zona, False sebaliknya
    """
    return (x_min - padding) <= x <= (x_max + padding)


def apakah_y_di_bawah(y_awal: float, y_target: float) -> bool:
    """
    Mengecek apakah titik Y berada di bawah Y awal (pixel meningkat ke bawah).
    
    Args:
        y_awal: Koordinat Y referensi (produk)
        y_target: Koordinat Y yang dicek (price tag)
    
    Returns:
        True jika y_target > y_awal (lebih ke bawah)
    """
    return y_target > y_awal


def hitung_blocking_zone(bboxes: List[BBox], product_names: List[str], target_product: str) -> Optional[Tuple[float, float]]:
    """
    Menghitung zona blocking horizontal untuk produk yang sejenis dan berjejer.
    Blocking zone = (min_x1, max_x2) dari semua produk sejenis yang bersentuhan.
    
    Args:
        bboxes: List of (x1, y1, x2, y2) tuples
        product_names: List nama produk sesuai order bboxes
        target_product: Nama produk target
    
    Returns:
        Tuple (x_min, x_max) dari zona blocking, atau None jika tidak ada
    
    Example:
        Jika ada Indomie1(10-50), Indomie2(60-100), Indomie3(110-150)
        Return: (10, 150)
    """
    # Filter indices dari produk yang sesuai nama
    indices = [i for i, name in enumerate(product_names) if name == target_product]
    
    if not indices:
        return None
    
    # Urutkan berdasarkan x1 (dari kiri ke kanan)
    sorted_indices = sorted(indices, key=lambda i: bboxes[i][0])
    
    # Ambil x1 minimal dan x2 maksimal
    x_min = min(bboxes[i][0] for i in sorted_indices)
    x_max = max(bboxes[i][2] for i in sorted_indices)
    
    return (x_min, x_max)


# ============================================================================
# BOUNDING BOX GEOMETRY
# ============================================================================

def bbox_distance(bbox1: BBox, bbox2: BBox) -> float:
    """
    Menghitung jarak terdekat antara dua bounding box (dari center).
    
    Args:
        bbox1: Tuple (x1, y1, x2, y2)
        bbox2: Tuple (x1, y1, x2, y2)
    
    Returns:
        Jarak Euclidean antara center kedua bbox
    """
    x_center1, y_center1 = hitung_center_point(bbox1)
    x_center2, y_center2 = hitung_center_point(bbox2)
    
    return hitung_jarak_euclidean(x_center1, y_center1, x_center2, y_center2)


def apakah_bbox_overlap(bbox1: BBox, bbox2: BBox) -> bool:
    """
    Mengecek apakah dua bounding box saling overlap.
    
    Args:
        bbox1, bbox2: Tuple (x1, y1, x2, y2)
    
    Returns:
        True jika ada overlap, False sebaliknya
    """
    x1a, y1a, x2a, y2a = bbox1
    x1b, y1b, x2b, y2b = bbox2
    
    # Overlap terjadi jika:
    # x_interval overlap AND y_interval overlap
    x_overlap = not (x2a < x1b or x2b < x1a)
    y_overlap = not (y2a < y1b or y2b < y1a)
    
    return x_overlap and y_overlap
