"""
RULES ENGINE - DEPARTEMEN LOGIKA BISNIS
File utama yang mengeksekusi 6 parameter validasi planogram.
Meminjam alat dari utils.py dan menerapkannya ke data YOLO.
"""

from typing import List, Dict, Tuple, Optional
from collections import defaultdict
from utils import (
    hitung_center_point,
    hitung_lebar_produk,
    hitung_jarak_euclidean,
    hitung_gap,
    hitung_persentase_sos,
    hitung_median_lebar,
    hitung_blocking_zone,
    apakah_x_dalam_zona,
    apakah_y_di_bawah,
    bbox_distance
)


class PlanogramValidator:
    """Validator utama untuk mengecek kepatuhan planogram dengan 6 parameter."""
    
    def __init__(self, yolo_detections: List[Dict], planogram_target: Dict):
        """
        Inisialisasi validator.
        
        Args:
            yolo_detections: List of detection dicts dari scanner
            planogram_target: Dictionary target planogram dari data_dummy
        """
        self.yolo_detections = yolo_detections
        self.target = planogram_target
        self.results = {}
        
        # Pisahkan detections menjadi Product, Price_Tag, dan POSM
        self._organize_detections()
    
    def _organize_detections(self) -> None:
        """Pisahkan detections berdasarkan class_name."""
        self.products = []
        self.price_tags = []
        self.posm_list = []
        
        for detection in self.yolo_detections:
            class_name = detection.get("class_name", "")
            
            if class_name == "Product":
                self.products.append(detection)
            elif class_name == "Price_Tag":
                self.price_tags.append(detection)
            elif class_name == "POSM":
                self.posm_list.append(detection)
    
    def _cluster_into_rows(self, products: List[Dict]) -> List[List[Dict]]:
        """
        Private method untuk row clustering (mengelompokkan produk per baris berdasarkan Y-coordinate).

        Logika:
        1. Hitung y_center, x_center untuk setiap produk
        2. Hitung Y_THRESHOLD = 0.5 * median_height
        3. Urutkan produk berdasarkan y_center (atas → bawah)
        4. Clustering: jika selisih y_center < Y_THRESHOLD, masuk baris sama
        5. Dalam setiap baris, urutkan berdasarkan x_center (kiri → kanan)
        6. Return List of Lists (2D array)

        Args:
            products: List of product detection dicts

        Returns:
            List[List[Dict]]: Products grouped by rows, sorted left-to-right within each row
        """
        if not products:
            return []

        # Step 1: Hitung y_center, x_center, tinggi untuk semua produk
        products_with_coords = []
        heights = []

        for product in products:
            x1, y1, x2, y2 = product["bbox"]
            x_center = (x1 + x2) / 2.0
            y_center = (y1 + y2) / 2.0
            height = y2 - y1
            heights.append(height)

            products_with_coords.append({
                "product": product,
                "x_center": x_center,
                "y_center": y_center,
                "height": height
            })

        # Step 2: Hitung Y_THRESHOLD = 0.5 * median_height
        heights_sorted = sorted(heights)
        median_height = heights_sorted[len(heights_sorted) // 2]
        y_threshold = 0.5 * median_height

        # Step 3: Urutkan berdasarkan y_center (dari atas ke bawah)
        products_sorted_by_y = sorted(products_with_coords, key=lambda p: p["y_center"])

        # Step 4: Clustering berdasarkan Y_THRESHOLD
        rows = []
        current_row = []

        for i, prod in enumerate(products_sorted_by_y):
            if i == 0:
                current_row.append(prod)
            else:
                prev_prod = products_sorted_by_y[i - 1]
                y_diff = abs(prod["y_center"] - prev_prod["y_center"])

                if y_diff < y_threshold:
                    # Masuk ke baris yang sama
                    current_row.append(prod)
                else:
                    # Buat baris baru
                    rows.append(current_row)
                    current_row = [prod]

        # Tambahkan baris terakhir
        if current_row:
            rows.append(current_row)

        # Step 5: Sorting berdasarkan x_center dalam masing-masing baris
        for row in rows:
            row.sort(key=lambda p: p["x_center"])

        # Return original products, bukan products_with_coords
        result_rows = []
        for row in rows:
            result_rows.append([p["product"] for p in row])

        return result_rows
    
    def cek_sos(self) -> Dict:
        """
        Validasi Parameter 1: Share of Shelf (SoS) berdasarkan FACING COUNT (FMCG Standard).

        Rumus: SoS% = (Jumlah facing produk / Total facing kategori) * 100%
        
        Toleransi: ±5% (toleransi untuk variasi placement)
        
        Catatan: Menggunakan facing count (jumlah bounding boxes), bukan pixel width.
        Category mapping dari target untuk grouping produk per kategori.
        """
        sos_target = self.target.get("sos_target", {})
        category_mapping = self.target.get("category_mapping", {})

        if not self.products:
            self.results["sos"] = {
                "status": "FAIL",
                "parameter": 1,
                "reason": "Tidak ada produk terdeteksi"
            }
            return self.results["sos"]

        # Step 1: Count facing per produk (jumlah bounding boxes)
        facing_per_product = defaultdict(int)
        for product in self.products:
            name = product["product_name"]
            facing_per_product[name] += 1

        # Step 2: Count facing per kategori menggunakan category_mapping
        facing_per_category = defaultdict(int)
        for product_name, facing_count in facing_per_product.items():
            # Get category dari mapping, default ke product name jika tidak ada mapping
            category = category_mapping.get(product_name, product_name)
            facing_per_category[category] += facing_count

        # Step 3: Hitung total facing per kategori
        total_facing_per_category = {
            category: count
            for category, count in facing_per_category.items()
        }

        # Step 4: Validasi SoS untuk setiap produk target
        status = "PASS"
        details = {}

        for product_name, target_sos_percent in sos_target.items():
            # Get facing count untuk produk ini
            actual_facing = facing_per_product.get(product_name, 0)
            
            # Get kategori produk ini
            category = category_mapping.get(product_name, product_name)
            
            # Get total facing kategori
            total_category_facing = total_facing_per_category.get(category, 1)
            
            # Hitung SoS% = (facing produk / total facing kategori) * 100
            if total_category_facing > 0:
                actual_sos_percent = (actual_facing / total_category_facing) * 100.0
            else:
                actual_sos_percent = 0.0

            # Toleransi ±5%
            is_ok = abs(actual_sos_percent - target_sos_percent) <= 5.0
            
            details[product_name] = {
                "actual_percentage": round(actual_sos_percent, 2),
                "target_percentage": target_sos_percent,
                "actual_facing": actual_facing,
                "category_total_facing": total_category_facing,
                "category": category,
                "status": "✓" if is_ok else "✗"
            }
            
            if not is_ok:
                status = "FAIL"

        self.results["sos"] = {
            "status": status,
            "parameter": 1,
            "details": details,
            "facing_per_product": dict(facing_per_product),
            "facing_per_category": dict(facing_per_category),
            "category_mapping": category_mapping
        }
        return self.results["sos"]
    
    def cek_facing_dan_oos(self) -> Dict:
        """
        Validasi Parameter 2 & 7: Facing dan OOS
        """
        facing_target = self.target.get("facing_target", {})
        min_quantity = self.target.get("min_quantity", {})
        
        facing_actual = defaultdict(int)
        for product in self.products:
            name = product["product_name"]
            facing_actual[name] += 1
        
        facing_details = {}
        facing_status = "PASS"
        
        for product_name in facing_target:
            actual = facing_actual.get(product_name, 0)
            target = facing_target[product_name]
            is_ok = actual >= target
            
            facing_details[product_name] = {
                "actual": actual,
                "target": target,
                "status": "✓" if is_ok else "✗"
            }
            if not is_ok:
                facing_status = "FAIL"
        
        oos_status = "PASS"
        oos_details = []
        understock_details = []
        
        for product_name in facing_target:
            quantity = facing_actual.get(product_name, 0)
            min_qty = min_quantity.get(product_name, 0)
            
            if quantity == 0:
                oos_status = "FAIL"
                oos_details.append({
                    "product": product_name,
                    "quantity": 0,
                    "reason": "OOS"
                })
            elif quantity < min_qty:
                understock_details.append({
                    "product": product_name,
                    "actual": quantity,
                    "minimum": min_qty
                })
        
        self.results["facing_oos"] = {
            "parameter": "2 & 7",
            "facing_status": facing_status,
            "facing_details": facing_details,
            "oos_status": oos_status,
            "oos_details": oos_details,
            "understock_details": understock_details,
            "status": "FAIL" if (facing_status == "FAIL" or oos_status == "FAIL") else "PASS"
        }
        return self.results["facing_oos"]
    
    def cek_eye_level(self) -> Dict:
        """
        Validasi Parameter 3B: Eye Level Compliance
        
        Logika:
        1. Hitung shelf height dari min_y1 sampai max_y2 semua produk
        2. Zona eye level = 34% - 66% dari shelf height
        3. Untuk produk dengan eye_level_required=True:
           - Cek apakah y_center dalam zona
           - PASS jika dalam zona, FAIL jika di luar
        """
        eye_level_required = self.target.get("eye_level_required", {})
        
        if not self.products:
            self.results["eye_level"] = {
                "status": "SKIP",
                "parameter": "3B",
                "reason": "Tidak ada produk terdeteksi"
            }
            return self.results["eye_level"]
        
        # Hitung shelf height
        all_y1 = [p["bbox"][1] for p in self.products]
        all_y2 = [p["bbox"][3] for p in self.products]
        min_y1 = min(all_y1)
        max_y2 = max(all_y2)
        shelf_height = max_y2 - min_y1
        
        if shelf_height <= 0:
            self.results["eye_level"] = {
                "status": "SKIP",
                "parameter": "3B",
                "reason": "Invalid shelf height"
            }
            return self.results["eye_level"]
        
        # Hitung zona eye level (34% - 66%)
        batas_atas_zona = min_y1 + (0.34 * shelf_height)
        batas_bawah_zona = min_y1 + (0.66 * shelf_height)
        
        # Validasi produk yang require eye level
        eye_level_details = {}
        overall_status = "PASS"
        
        for product in self.products:
            product_name = product["product_name"]
            
            # Skip jika produk ini tidak require eye level
            if product_name not in eye_level_required or not eye_level_required[product_name]:
                continue
            
            # Hitung y_center produk
            y_center = (product["bbox"][1] + product["bbox"][3]) / 2.0
            
            # Cek apakah y_center dalam zona
            is_in_zone = batas_atas_zona <= y_center <= batas_bawah_zona
            
            if is_in_zone:
                eye_level_details[product_name] = {
                    "status": "✓",
                    "y_center": round(y_center, 1),
                    "zone_range": (round(batas_atas_zona, 1), round(batas_bawah_zona, 1))
                }
            else:
                eye_level_details[product_name] = {
                    "status": "✗",
                    "y_center": round(y_center, 1),
                    "zone_range": (round(batas_atas_zona, 1), round(batas_bawah_zona, 1)),
                    "placement": "Terlalu tinggi" if y_center < batas_atas_zona else "Terlalu rendah"
                }
                overall_status = "FAIL"
        
        self.results["eye_level"] = {
            "status": overall_status,
            "parameter": "3B",
            "details": eye_level_details,
            "shelf_height": round(shelf_height, 1),
            "zone_range": (round(batas_atas_zona, 1), round(batas_bawah_zona, 1))
        }
        return self.results["eye_level"]
    
    def cek_sequence(self) -> Dict:
        """
        Validasi Parameter 3: Sequence (Urutan Produk)
        
        Menggunakan Row Clustering untuk mengelompokkan produk berdasarkan Sumbu Y (tingkat rak),
        sebelum melakukan sorting berdasarkan Sumbu X (kiri ke kanan).
        """
        sequence_target = self.target.get("sequence_target", [])
        
        if not sequence_target:
            self.results["sequence"] = {
                "status": "SKIP",
                "parameter": 3,
                "reason": "Tidak ada target sequence"
            }
            return self.results["sequence"]
        
        if not self.products:
            self.results["sequence"] = {
                "status": "SKIP",
                "parameter": 3,
                "reason": "Tidak ada produk terdeteksi"
            }
            return self.results["sequence"]
        
        # Gunakan _cluster_into_rows untuk mendapatkan rows dengan proper sorting
        rows = self._cluster_into_rows(self.products)
        
        if not rows:
            self.results["sequence"] = {
                "status": "SKIP",
                "parameter": 3,
                "reason": "Clustering gagal"
            }
            return self.results["sequence"]
        
        # Hasilkan actual_sequence (List of Lists)
        actual_sequence = []
        for row in rows:
            row_names = [prod["product_name"] for prod in row]
            actual_sequence.append(row_names)
        
        # Bandingkan dengan sequence_target
        status = "PASS" if actual_sequence == sequence_target else "FAIL"
        
        row_details = {}
        for i, actual_row in enumerate(actual_sequence):
            if i < len(sequence_target):
                target_row = sequence_target[i]
                row_status = "✓" if actual_row == target_row else "✗"
                if row_status == "✗":
                    status = "FAIL"
            else:
                target_row = []
                row_status = "✗"
                status = "FAIL"
            
            row_details[f"Rak {i+1}"] = {
                "status": row_status,
                "actual": actual_row,
                "target": target_row
            }
        
        # Handle kasus jumlah baris berbeda
        if len(actual_sequence) != len(sequence_target):
            status = "FAIL"
        
        # Hitung Y_THRESHOLD untuk informasi
        heights = []
        for product in self.products:
            y1, y2 = product["bbox"][1], product["bbox"][3]
            height = y2 - y1
            heights.append(height)
        
        heights_sorted = sorted(heights)
        median_height = heights_sorted[len(heights_sorted) // 2]
        y_threshold = 0.5 * median_height
        
        self.results["sequence"] = {
            "status": status,
            "parameter": 3,
            "actual": actual_sequence,
            "target": sequence_target,
            "row_details": row_details,
            "y_threshold": round(y_threshold, 1),
            "median_product_height": round(median_height, 1)
        }
        return self.results["sequence"]
    
    def cek_price_tag(self) -> Dict:
        """
        Validasi Parameter 4: Price Tag dengan Product Blocking (Per-Row)
        
        Bug fix: Gunakan row clustering untuk menghindari cross-row blocking zone bugs.
        Setiap baris rak memiliki blocking zone yang terpisah.
        """
        price_tag_required = self.target.get("price_tag_required", {})
        
        if not self.price_tags:
            if any(price_tag_required.values()):
                self.results["price_tag"] = {
                    "status": "FAIL",
                    "parameter": 4,
                    "reason": "Tidak ada Price_Tag, namun diperlukan"
                }
            else:
                self.results["price_tag"] = {
                    "status": "PASS",
                    "parameter": 4,
                    "reason": "Price_Tag tidak diperlukan"
                }
            return self.results["price_tag"]
        
        # Cluster produk ke dalam rows
        rows = self._cluster_into_rows(self.products)
        
        price_tag_details = {}
        overall_status = "PASS"
        
        # Iterasi per baris untuk blocking zone per-row
        for row_idx, row in enumerate(rows):
            # Untuk setiap produk di dalam baris ini
            for product_name in price_tag_required:
                if not price_tag_required[product_name]:
                    continue
                
                # Cari produk dengan nama ini di dalam baris saat ini
                sku_products_in_row = [p for p in row if p["product_name"] == product_name]
                
                if not sku_products_in_row:
                    # Produk ini tidak ada di baris ini, skip
                    continue
                
                # Hitung blocking zone untuk produk ini di baris ini
                blocking_zone = hitung_blocking_zone(
                    [p["bbox"] for p in row],
                    [p["product_name"] for p in row],
                    product_name
                )
                
                if blocking_zone is None:
                    key = f"{product_name}_Rak{row_idx + 1}"
                    price_tag_details[key] = {
                        "status": "✗",
                        "reason": f"SKU '{product_name}' tidak terdeteksi di rak ini"
                    }
                    overall_status = "FAIL"
                    continue
                
                x_min_zone, x_max_zone = blocking_zone
                
                # Hitung y_center untuk produk di baris ini
                y_centers_product = [
                    hitung_center_point(p["bbox"])[1]
                    for p in sku_products_in_row
                ]
                y_center_product = max(y_centers_product)
                
                # Cari price tags yang valid di baris ini
                valid_price_tags = []
                for tag in self.price_tags:
                    x_tag, y_tag = hitung_center_point(tag["bbox"])
                    
                    # Tag harus dalam blocking zone X
                    if not apakah_x_dalam_zona(x_tag, x_min_zone, x_max_zone):
                        continue
                    
                    # Tag harus di bawah produk
                    if not apakah_y_di_bawah(y_center_product, y_tag):
                        continue
                    
                    valid_price_tags.append(tag)
                
                key = f"{product_name}_Rak{row_idx + 1}"
                if valid_price_tags:
                    price_tag_details[key] = {
                        "status": "✓",
                        "found_count": len(valid_price_tags),
                        "zone": (round(x_min_zone, 1), round(x_max_zone, 1))
                    }
                else:
                    price_tag_details[key] = {
                        "status": "✗",
                        "reason": "Tidak ada Price_Tag valid dalam zone",
                        "zone": (round(x_min_zone, 1), round(x_max_zone, 1))
                    }
                    overall_status = "FAIL"
        
        self.results["price_tag"] = {
            "status": overall_status,
            "parameter": 4,
            "details": price_tag_details,
            "total_tags": len(self.price_tags)
        }
        return self.results["price_tag"]
    
    def cek_void(self) -> Dict:
        """
        Validasi Parameter 5: Void Detection (Per-Row)
        
        Bug fix: Gunakan row clustering untuk menghindari cross-row gap calculations.
        Gap hanya dihitung antar produk yang bersebelahan dalam baris yang sama.
        """
        if len(self.products) < 2:
            self.results["void"] = {
                "status": "SKIP",
                "parameter": 5,
                "reason": "< 2 produk"
            }
            return self.results["void"]
        
        # Hitung median width dari SEMUA produk (threshold global)
        bboxes = [p["bbox"] for p in self.products]
        median_width = hitung_median_lebar(bboxes)
        
        # Cluster produk ke dalam rows
        rows = self._cluster_into_rows(self.products)
        
        void_violations = []
        
        # Iterasi per baris
        for row in rows:
            # Sort produk dalam baris berdasarkan X (dari kiri ke kanan)
            row_sorted = sorted(row, key=lambda p: p["bbox"][0])
            
            # Hitung gap hanya antar produk di dalam baris yang sama
            for i in range(len(row_sorted) - 1):
                prod_left = row_sorted[i]
                prod_right = row_sorted[i + 1]
                
                x2_left = prod_left["bbox"][2]
                x1_right = prod_right["bbox"][0]
                gap = hitung_gap(x2_left, x1_right)
                
                if gap >= median_width:
                    void_violations.append({
                        "between": f"{prod_left['product_name']} ← → {prod_right['product_name']}",
                        "gap": round(gap, 2),
                        "median_width": round(median_width, 2)
                    })
        
        status = "PASS" if len(void_violations) == 0 else "FAIL"
        
        self.results["void"] = {
            "status": status,
            "parameter": 5,
            "violations": void_violations,
            "median_width": round(median_width, 2)
        }
        return self.results["void"]
    
    def cek_posm(self) -> Dict:
        """
        Validasi Parameter 6: POSM (Point of Sale Material)
        """
        posm_required = self.target.get("posm_required", {})
        
        if not self.posm_list:
            if any(posm_required.values()):
                self.results["posm"] = {
                    "status": "FAIL",
                    "parameter": 6,
                    "reason": "Tidak ada POSM, namun diperlukan"
                }
            else:
                self.results["posm"] = {
                    "status": "PASS",
                    "parameter": 6,
                    "reason": "POSM tidak diperlukan"
                }
            return self.results["posm"]
        
        posm_details = {}
        overall_status = "PASS"
        
        for product in self.products:
            product_name = product["product_name"]
            
            if product_name not in posm_required or not posm_required[product_name]:
                continue
            
            lebar_produk = hitung_lebar_produk(product["bbox"][0], product["bbox"][2])
            radius_threshold = 1.5 * lebar_produk
            
            valid_posm = []
            for posm in self.posm_list:
                jarak = bbox_distance(product["bbox"], posm["bbox"])
                if jarak <= radius_threshold:
                    valid_posm.append({
                        "distance": round(jarak, 2),
                        "threshold": round(radius_threshold, 2)
                    })
            
            if valid_posm:
                posm_details[product_name] = {
                    "status": "✓",
                    "posm_found": len(valid_posm),
                    "distance": valid_posm[0]["distance"]
                }
            else:
                posm_details[product_name] = {
                    "status": "✗",
                    "reason": f"Tidak ada POSM dalam radius {round(radius_threshold, 1)}px"
                }
                overall_status = "FAIL"
        
        self.results["posm"] = {
            "status": overall_status,
            "parameter": 6,
            "details": posm_details,
            "total_posm": len(self.posm_list)
        }
        return self.results["posm"]
    
    def validate_all(self) -> Dict:
        """Jalankan semua validasi."""
        self.cek_sos()
        self.cek_facing_dan_oos()
        self.cek_eye_level()
        self.cek_sequence()
        self.cek_price_tag()
        self.cek_void()
        self.cek_posm()
        
        return self.results
    
    def get_summary(self) -> Dict:
        """Hitung summary score."""
        if not self.results:
            return {}
        
        pass_count = 0
        fail_count = 0
        skip_count = 0
        
        for param, result in self.results.items():
            status = result.get("status", "UNKNOWN")
            if status == "PASS":
                pass_count += 1
            elif status == "FAIL":
                fail_count += 1
            elif status == "SKIP" or status == "INFO":
                skip_count += 1
        
        total = pass_count + fail_count
        score = (pass_count / total * 100) if total > 0 else 0
        
        return {
            "pass_count": pass_count,
            "fail_count": fail_count,
            "skip_count": skip_count,
            "total_params": total,
            "compliance_score": round(score, 1)
        }
