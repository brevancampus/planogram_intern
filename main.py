"""
SANG MANDOR - File Utama Program
Alur:
1. Load model YOLO dan scan gambar via scanner.py
2. Ambil data YOLO dari scanner
3. Validasi dengan rules_engine.py
4. Print laporan hasil ke terminal
"""

import sys
from pathlib import Path
from typing import List, Dict

# Imports
from data_dummy import PLANOGRAM_TARGET, YOLO_DETECTION_DUMMY
from scanner import scan_with_yolo
from rules_engine import PlanogramValidator


# ============================================================================
# CONFIGURATION
# ============================================================================

MODEL_PATH = "best (1).pt"  # Path ke model YOLO
IMAGE_PATH = "data/foto_rak_test.jpg"  # Path ke gambar yang akan di-scan
USE_DUMMY_DATA = True  # Jika True, gunakan dummy data (untuk testing tanpa gambar)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def print_header() -> None:
    """Print header laporan."""
    print("\n" + "=" * 80)
    print(" " * 20 + "LAPORAN KEPATUHAN PLANOGRAM")
    print("=" * 80 + "\n")


def print_parameter_1_sos(result: Dict) -> None:
    """Print hasil Parameter 1: SOS"""
    print("┌─ Parameter 1: SOS (Share of Shelf)")
    status = result.get("status", "UNKNOWN")
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    details = result.get("details", {})
    for product_name, info in details.items():
        symbol = info["status"]
        actual = info["actual"]
        target = info["target"]
        print(f"│  {symbol} {product_name}: {actual}% (target: {target}%)")
    
    print("│  Total pixel lebar: " + str(result.get("total_pixel", 0)))
    print("└")


def print_parameter_2_7_facing_oos(result: Dict) -> None:
    """Print hasil Parameter 2 & 7: Facing & OOS"""
    print("┌─ Parameter 2 & 7: Facing & OOS")
    facing_status = result.get("facing_status", "UNKNOWN")
    oos_status = result.get("oos_status", "UNKNOWN")
    
    facing_sym = "✓" if facing_status == "PASS" else "✗"
    oos_sym = "✓" if oos_status == "PASS" else "✗"
    
    print(f"│  {facing_sym} FACING: {facing_status}")
    print(f"│  {oos_sym} OOS: {oos_status}")
    print(f"│")
    
    # Facing details
    print(f"│  FACING DETAILS:")
    facing_details = result.get("facing_details", {})
    for product_name, info in facing_details.items():
        symbol = info["status"]
        actual = info["actual"]
        target = info["target"]
        print(f"│    {symbol} {product_name}: {actual} (target: {target})")
    
    # OOS details
    oos_details = result.get("oos_details", [])
    if oos_details:
        print(f"│")
        print(f"│  OOS VIOLATIONS:")
        for item in oos_details:
            print(f"│    ✗ {item['product']}: {item['reason']}")
    
    # Understock
    understock = result.get("understock_details", [])
    if understock:
        print(f"│")
        print(f"│  UNDERSTOCK WARNINGS:")
        for item in understock:
            print(f"│    ⚠ {item['product']}: {item['actual']} (min: {item['minimum']})")
    
    print("└")


def print_parameter_3b_eye_level(result: Dict) -> None:
    """Print hasil Parameter 3B: Eye Level Compliance"""
    print("┌─ Parameter 3B: Eye Level Compliance")
    status = result.get("status", "UNKNOWN")
    
    if status == "SKIP":
        reason = result.get("reason", "N/A")
        print(f"│  Status: - SKIP ({reason})")
        print("└")
        return
    
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    shelf_height = result.get("shelf_height", 0)
    zone_range = result.get("zone_range", (0, 0))
    
    print(f"│  Shelf Height: {shelf_height}px")
    print(f"│  Eye Level Zone: {zone_range[0]}px - {zone_range[1]}px (34%-66%)")
    print(f"│")
    
    details = result.get("details", {})
    if details:
        print(f"│  PLACEMENT ANALYSIS:")
        for product_name, info in details.items():
            symbol = info["status"]
            y_center = info["y_center"]
            placement = info.get("placement", "Dalam zone")
            print(f"│    {symbol} {product_name}: y_center={y_center}px → {placement}")
    else:
        print(f"│  Tidak ada produk yang require eye level")
    
    print("└")


def print_parameter_3_sequence(result: Dict) -> None:
    """Print hasil Parameter 3: Sequence (dengan Row Clustering)"""
    print("┌─ Parameter 3: Sequence (Urutan Produk per Rak)")
    status = result.get("status", "UNKNOWN")
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    # Informasi clustering
    y_threshold = result.get("y_threshold", 0)
    median_height = result.get("median_product_height", 0)
    print(f"│  Y_THRESHOLD (clustering): {y_threshold}px (median_height: {median_height}px)")
    print(f"│")
    
    # Row details
    if result.get("status") == "SKIP":
        reason = result.get("reason", "N/A")
        print(f"│  {reason}")
        print("└")
        return
    
    row_details = result.get("row_details", {})
    if row_details:
        print(f"│  ANALISIS PER RAK:")
        for rak_name, rak_info in row_details.items():
            symbol = rak_info["status"]
            actual = " → ".join(rak_info["actual"])
            target = " → ".join(rak_info["target"])
            
            print(f"│")
            print(f"│    {symbol} {rak_name}:")
            print(f"│       Actual:  {actual}")
            print(f"│       Target:  {target}")
    
    print("└")


def print_parameter_4_price_tag(result: Dict) -> None:
    """Print hasil Parameter 4: Price Tag"""
    print("┌─ Parameter 4: Price Tag (dengan Product Blocking)")
    status = result.get("status", "UNKNOWN")
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    details = result.get("details", {})
    if not details:
        print(f"│  {result.get('reason', 'N/A')}")
    else:
        for product_name, info in details.items():
            symbol = info["status"]
            if symbol == "✓":
                print(f"│  {symbol} {product_name}: Found {info.get('found_count', 0)} tags")
            else:
                print(f"│  {symbol} {product_name}: {info.get('reason', 'N/A')}")
            
            if "blocking_zone" in info:
                zone = info["blocking_zone"]
                print(f"│      Blocking Zone: X [{zone[0]:.0f} - {zone[1]:.0f}]")
    
    print(f"│  Total tags detected: {result.get('total_tags', 0)}")
    print("└")


def print_parameter_5_void(result: Dict) -> None:
    """Print hasil Parameter 5: Void Detection"""
    print("┌─ Parameter 5: Void Detection")
    status = result.get("status", "UNKNOWN")
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL" if status == "FAIL" else "- SKIP"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    reason = result.get("reason", "")
    if reason:
        print(f"│  {reason}")
    else:
        median = result.get("median_width", 0)
        print(f"│  Median lebar produk: {median:.1f}px")
        
        violations = result.get("violations", [])
        if violations:
            print(f"│")
            for v in violations:
                print(f"│  ✗ {v['between']}: {v['gap']:.1f}px gap (median: {v['median_width']:.1f}px)")
        else:
            print(f"│  Tidak ada void yang signifikan")
    
    print("└")


def print_parameter_6_posm(result: Dict) -> None:
    """Print hasil Parameter 6: POSM"""
    print("┌─ Parameter 6: POSM (Point of Sale Material)")
    status = result.get("status", "UNKNOWN")
    status_sym = "✓ PASS" if status == "PASS" else "✗ FAIL"
    print(f"│  Status: {status_sym}")
    print(f"│")
    
    reason = result.get("reason", "")
    if reason:
        print(f"│  {reason}")
    else:
        details = result.get("details", {})
        for product_name, info in details.items():
            symbol = info["status"]
            if symbol == "✓":
                print(f"│  {symbol} {product_name}: Found {info.get('posm_found', 0)} POSM")
            else:
                print(f"│  {symbol} {product_name}: {info.get('reason', 'N/A')}")
    
    print(f"│  Total POSM detected: {result.get('total_posm_detected', 0)}")
    print("└")


def print_summary(summary: Dict) -> None:
    """Print ringkasan score keseluruhan."""
    print("\n" + "=" * 80)
    print(" " * 30 + "RINGKASAN HASIL")
    print("=" * 80 + "\n")
    
    pass_count = summary.get("pass_count", 0)
    fail_count = summary.get("fail_count", 0)
    total = summary.get("total_params", 0)
    score = summary.get("compliance_score", 0)
    
    print(f"Parameter PASS: {pass_count}/{total}")
    print(f"Parameter FAIL: {fail_count}/{total}")
    
    if score == 100:
        status_text = "🎉 EXCELLENT!"
    elif score >= 80:
        status_text = "✓ GOOD"
    elif score >= 50:
        status_text = "⚠ NEEDS ATTENTION"
    else:
        status_text = "✗ CRITICAL"
    
    print(f"\n📊 COMPLIANCE SCORE: {score}% {status_text}\n")
    print("=" * 80 + "\n")


# ============================================================================
# MAIN PROGRAM
# ============================================================================

def main() -> int:
    """
    Main program flow.
    
    Returns:
        Exit code (0 = success, 1 = error)
    """
    print_header()
    
    # Step 1: Load data
    print("[1] Loading data YOLO...\n")
    
    if USE_DUMMY_DATA:
        print("    Mode: DUMMY DATA (untuk testing)")
        yolo_data = YOLO_DETECTION_DUMMY
        print(f"    → {len(yolo_data)} detections loaded dari data_dummy")
    else:
        print(f"    Mode: LIVE SCAN dengan model: {MODEL_PATH}")
        print(f"    Image path: {IMAGE_PATH}\n")
        
        try:
            yolo_data = scan_with_yolo(IMAGE_PATH, MODEL_PATH)
        except FileNotFoundError as e:
            print(f"\n❌ ERROR: {e}")
            return 1
        except RuntimeError as e:
            print(f"\n❌ ERROR: {e}")
            return 1
    
    print()
    
    # Step 2: Validate
    print("[2] Menjalankan validasi planogram...\n")
    
    try:
        validator = PlanogramValidator(yolo_data, PLANOGRAM_TARGET)
        results = validator.validate_all()
        summary = validator.get_summary()
    except Exception as e:
        print(f"\n❌ ERROR saat validasi: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    # Step 3: Print hasil detail
    print("[3] Menampilkan hasil detail...\n")
    
    if "sos" in results:
        print_parameter_1_sos(results["sos"])
    
    if "facing_oos" in results:
        print_parameter_2_7_facing_oos(results["facing_oos"])
    
    if "eye_level" in results:
        print_parameter_3b_eye_level(results["eye_level"])
    
    if "sequence" in results:
        print_parameter_3_sequence(results["sequence"])
    
    if "price_tag" in results:
        print_parameter_4_price_tag(results["price_tag"])
    
    if "void" in results:
        print_parameter_5_void(results["void"])
    
    if "posm" in results:
        print_parameter_6_posm(results["posm"])
    
    # Step 4: Print summary
    print_summary(summary)
    
    print("[✓] Program selesai!\n")
    
    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)

