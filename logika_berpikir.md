# 📋 DOKUMENTASI LOGIKA PLANOGRAM VALIDATION - PARAMETER 1-7

**Ringkasan:** Sistem validasi planogram menggunakan 7 parameter compliance untuk memastikan standar retail FMCG terpenuhi. Setiap parameter fokus pada aspek berbeda dari penjajaran produk di rak.

---

## **PARAMETER 1: Share of Shelf (SoS) - Dominasi Produk**

### 📐 Rumus
$$SoS = \left(\frac{\text{Actual Facing Produk Target}}{\text{Total Facing Kategori}}\right) \times 100\%$$

**Catatan:** 
- "Facing" = jumlah barang/kotak yang terlihat di depan
- Bisa juga menggunakan total pixel lebar bounding box jika ukuran bervariasi
- Formula: `actual_facing / total_category_facing * 100`

### 🧠 Flow Logika Berpikir

1. **Mapping Kategori**: Sistem memetakan setiap produk yang terdeteksi YOLO ke kategori dagang (misal: Chitato → Snack, Indomie → Instant Noodles)
2. **Perhitungan Total Kategori**: Hitung jumlah SEMUA produk dalam kategori yang sama (misal: total semua mie instan)
3. **Perhitungan Target**: Hitung jumlah produk target saja (misal: hanya Indomie)
4. **Persentase**: Bagi target dengan total, kalikan 100%
5. **Validasi**: Bandingkan dengan `sos_target` dari config
   - Jika actual_sos ≥ sos_target → **PASS** ✅
   - Jika actual_sos < sos_target → **FAIL** ❌

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_sos()`

```python
def cek_sos(self, detections, planogram_target):
    """
    Cek Share of Shelf (SoS) - dominasi produk di kategori
    """
    sos_target = planogram_target.get('sos_target', 30)  # Target minimal 30%
    category_mapping = planogram_target.get('category_mapping', {})
    
    # 1. Group detections by category
    category_products = {}
    for detection in detections:
        product_name = detection['product_name'].lower()
        category = category_mapping.get(product_name, 'unknown')
        
        if category not in category_products:
            category_products[category] = []
        category_products[category].append(product_name)
    
    # 2. Hitung persentase per kategori
    actual_sos = {}
    for category, products in category_products.items():
        target_count = products.count(self.target_product)
        total_count = len(products)
        
        if total_count > 0:
            sos_percent = (target_count / total_count) * 100
            actual_sos[category] = sos_percent
    
    # 3. Validasi
    max_sos = max(actual_sos.values()) if actual_sos else 0
    status = "PASS" if max_sos >= sos_target else "FAIL"
    
    return {
        'status': status,
        'actual_sos': max_sos,
        'target_sos': sos_target,
        'details': actual_sos
    }
```

### 🔑 Keyword Code
- **Function**: `cek_sos()`
- **Key Data**: 
  - `category_mapping` - Dict pemetaan produk → kategori
  - `sos_target` - Target persentase minimum
  - `actual_facing` - Jumlah produk aktual
  - `total_facing` - Total produk dalam kategori
- **Tech Stack**: Python, dict operations, percentage calculation

---

## **PARAMETER 2: Facing & Out of Stock (OOS)**

### 📐 Rumus
$$\text{Actual Facing} \ge \text{Target Facing}$$

**Status Conditions:**
- Jika `actual_facing == 0` → **OOS** (Out of Stock)
- Jika `0 < actual_facing < facing_target` → **UNDERFACING** / FAIL
- Jika `actual_facing ≥ facing_target` → **PASS**

### 🧠 Flow Logika Berpikir

1. **Definisi Target**: Principal/perusahaan menetapkan minimum barang pajangan (misal: "Indomie minimal 4 baris")
2. **Hitung Aktual**: Loop semua deteksi YOLO dan hitung berapa kali produk target muncul
3. **Cek Status**:
   - Jika 0 → Barang habis terjual (Out of Stock = tidak boleh terjual)
   - Jika kurang dari target → Underfacing (tidak cukup banyak)
   - Jika sesuai/lebih → Compliance tercapai
4. **Catatan**: OOS adalah kondisi paling kritis karena konsumen tidak bisa membeli

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_facing_dan_oos()`

```python
def cek_facing_dan_oos(self, detections, planogram_target):
    """
    Cek Facing & Out of Stock (OOS)
    """
    facing_target = planogram_target.get('facing_target', 4)
    target_product = planogram_target.get('target_product', 'indomie')
    
    # 1. Hitung actual facing
    actual_facing = sum(
        1 for d in detections 
        if d['product_name'].lower() == target_product
    )
    
    # 2. Tentukan status
    if actual_facing == 0:
        status = "OOS"  # Out of Stock - KRITIS!
        reason = f"Product {target_product} tidak ada sama sekali"
    elif actual_facing < facing_target:
        status = "FAIL"  # Underfacing
        reason = f"Hanya {actual_facing} unit, target {facing_target}"
    else:
        status = "PASS"
        reason = f"OK: {actual_facing} unit ≥ target {facing_target}"
    
    return {
        'status': status,
        'actual_facing': actual_facing,
        'facing_target': facing_target,
        'reason': reason
    }
```

### 🔑 Keyword Code
- **Function**: `cek_facing_dan_oos()`
- **Key Data**:
  - `facing_target` - Jumlah minimum barang
  - `actual_facing` - Jumlah aktual terdeteksi
  - `target_product` - Nama produk yang dicek
- **Status Enum**: "PASS", "FAIL", "OOS"
- **Tech Stack**: Python, filtering, counting

---

## **PARAMETER 3: Sequence (Urutan Barang Kiri-Kanan)**

### 📐 Rumus
$$\text{Produk Aktual Baris ke-}i = \text{Produk Target Baris ke-}i$$

**Logika urutan:**
1. Baris atas (Y paling kecil)
2. Baris tengah (Y medium)
3. Baris bawah (Y paling besar)

Dalam setiap baris, urut dari kiri ke kanan berdasarkan X coordinate.

### 🧠 Flow Logika Berpikir

1. **Row Clustering**: Kelompokkan produk menjadi baris-baris berdasarkan sumbu Y
   - Produk dengan Y-center yang mirip dianggap satu baris
   - Threshold toleransi: 0.5 × median tinggi produk
   
2. **Sorting per Baris**: Dalam setiap baris, urutkan dari X terkecil (kiri) ke terbesar (kanan)

3. **Matching**: Bandingkan urutan aktual dengan sequence target
   - Urutan harus sesuai pattern dari planogram
   - Misal: Target = [Indomie, Chitato], Aktual = [Chitato, Indomie] → FAIL

4. **Validasi**: Jika semua baris sesuai urutan → PASS

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_sequence()`

```python
def cek_sequence(self, detections, planogram_target):
    """
    Cek Sequence (urutan barang kiri ke kanan per baris)
    """
    sequence_target = planogram_target.get('sequence_target', [
        'indomie', 'chitato', 'pepsodent'
    ])
    
    # 1. Cluster produk menjadi baris-baris
    rows = self._cluster_into_rows(detections)
    
    # 2. Dalam setiap baris, urutkan berdasarkan X coordinate
    actual_sequence = []
    for row in rows:
        # Sort by x_center (ascending = left to right)
        sorted_row = sorted(
            row,
            key=lambda d: (d['bbox'][0] + d['bbox'][2]) / 2
        )
        row_sequence = [d['product_name'].lower() for d in sorted_row]
        actual_sequence.extend(row_sequence)
    
    # 3. Validasi
    sequence_match = actual_sequence == sequence_target
    status = "PASS" if sequence_match else "FAIL"
    
    return {
        'status': status,
        'actual_sequence': actual_sequence,
        'target_sequence': sequence_target,
        'reason': "Sequence sesuai" if sequence_match else "Urutan produk berbeda"
    }

def _cluster_into_rows(self, detections):
    """
    Kelompokkan deteksi menjadi baris berdasarkan Y-coordinate
    """
    if not detections:
        return []
    
    # Calculate median height
    heights = [d['bbox'][3] - d['bbox'][1] for d in detections]
    median_height = sorted(heights)[len(heights) // 2]
    y_threshold = median_height * 0.5
    
    # Sort by Y coordinate
    sorted_by_y = sorted(detections, key=lambda d: d['bbox'][1])
    
    rows = []
    current_row = []
    current_y = None
    
    for detection in sorted_by_y:
        y_center = (detection['bbox'][1] + detection['bbox'][3]) / 2
        
        if current_y is None or abs(y_center - current_y) <= y_threshold:
            current_row.append(detection)
            current_y = y_center
        else:
            rows.append(current_row)
            current_row = [detection]
            current_y = y_center
    
    if current_row:
        rows.append(current_row)
    
    return rows
```

### 🔑 Keyword Code
- **Function**: `cek_sequence()`, `_cluster_into_rows()`
- **Key Data**:
  - `sequence_target` - Array urutan produk yang diharapkan
  - `y_threshold` - Tolerance untuk clustering (0.5 × median height)
  - `median_height` - Tinggi rata-rata produk di rak
  - `x_center` - Koordinat horizontal pusat produk
  - `y_center` - Koordinat vertikal pusat produk
- **Tech Stack**: Python, sorting, clustering algoritm

---

## **PARAMETER 4: Price Tag (Label Harga)**

### 📐 Rumus
$$\text{Distance} = \sqrt{(X_{produk} - X_{tag})^2 + (Y_{produk\_bawah} - Y_{tag\_atas})^2} \le \text{Threshold}$$

**Atau lebih sederhana (BBox distance):**
$$\text{Gap} = |Y_{\text{produk bawah}} - Y_{\text{tag atas}}| \le 10\text{px}$$

### 🧠 Flow Logika Berpikir

1. **Deteksi Dual-Object**: Price tag dan produk adalah dua kotak terpisah yang terdeteksi YOLO
2. **Pairing Strategy**: Cari pasangan terdekat antara produk dan price tag
   - Titik referensi produk: tengah bawah (mid-X, Y-max)
   - Titik referensi tag: tengah atas (mid-X, Y-min)
3. **Kalkulasi Jarak**: Gunakan Euclidean distance atau selisih Y saja
4. **Threshold**: Biasanya <10px untuk dianggap "satu kesatuan"
5. **Validasi**: Jika product terdekat dengan tag → ada price tag ✅

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_price_tag()`

```python
def cek_price_tag(self, detections, planogram_target):
    """
    Cek Price Tag - apakah label harga ada di bawah produk
    """
    price_tag_threshold = planogram_target.get('price_tag_threshold', 10)
    
    # Separate products and price tags
    products = [d for d in detections if d['class_name'] == 'Product']
    price_tags = [d for d in detections if d.get('class_name') == 'Price_Tag']
    
    if not products:
        return {'status': 'SKIP', 'reason': 'Tidak ada produk terdeteksi'}
    
    if not price_tags:
        return {'status': 'FAIL', 'reason': 'Tidak ada price tag terdeteksi'}
    
    # 1. Hitung jarak untuk setiap produk
    products_with_tag = 0
    
    for product in products:
        # Titik referensi produk: tengah-bawah
        prod_x = (product['bbox'][0] + product['bbox'][2]) / 2
        prod_y_bottom = product['bbox'][3]
        
        # Cari tag terdekat
        min_distance = float('inf')
        
        for tag in price_tags:
            tag_x = (tag['bbox'][0] + tag['bbox'][2]) / 2
            tag_y_top = tag['bbox'][1]
            
            # Hitung Euclidean distance
            distance = ((prod_x - tag_x)**2 + (prod_y_bottom - tag_y_top)**2)**0.5
            min_distance = min(min_distance, distance)
        
        if min_distance <= price_tag_threshold:
            products_with_tag += 1
    
    # 2. Validasi
    coverage = (products_with_tag / len(products)) * 100
    status = "PASS" if coverage >= 80 else "FAIL"
    
    return {
        'status': status,
        'products_total': len(products),
        'products_with_tag': products_with_tag,
        'coverage_percent': coverage,
        'reason': f'{coverage:.0f}% produk memiliki price tag'
    }

def hitung_jarak_euclidean(self, x1, y1, x2, y2):
    """Helper: Hitung jarak Euclidean antara 2 titik"""
    return ((x2 - x1)**2 + (y2 - y1)**2)**0.5
```

### 🔑 Keyword Code
- **Function**: `cek_price_tag()`, `hitung_jarak_euclidean()`
- **Key Data**:
  - `price_tag_threshold` - Jarak maksimal (biasanya 10px)
  - `class_name` - Filter untuk "Product" vs "Price_Tag"
  - Koordinat tengah-bawah produk
  - Koordinat tengah-atas tag harga
- **Tech Stack**: Python, Euclidean distance, object matching

---

## **PARAMETER 5: Void (Ruang Kosong di Rak)**

### 📐 Rumus
$$\text{Gap} = X1_{\text{produk kanan}} - X2_{\text{produk kiri}} > \text{Batas Toleransi}$$

**Batas toleransi dihitung dinamis:**
$$\text{Void Threshold} = 0.5 \times \text{Median Lebar Produk}$$

### 🧠 Flow Logika Berpikir

1. **Definisi Void**: Jarak/celah terlalu lebar antara 2 produk yang seharusnya berdampingan
2. **Deteksi Void**: 
   - Dalam setiap baris, hitung jarak antara ujung kanan produk A dan ujung kiri produk B
   - Jika gap > threshold → ada void
3. **Konteks Retail**: Rak yang "ompong" (banyak void) terlihat kurang menarik dan signal stok kurang
4. **Threshold Dinamis**: Dihitung dari median lebar produk agar adaptive
5. **Validasi**: Jika total void dalam rak < threshold → PASS

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_void()`

```python
def cek_void(self, detections, planogram_target):
    """
    Cek Void - celah terlalu lebar antar produk
    """
    void_threshold_ratio = planogram_target.get('void_threshold_ratio', 0.5)
    
    # 1. Cluster menjadi baris
    rows = self._cluster_into_rows(detections)
    
    # 2. Hitung median lebar produk
    widths = [d['bbox'][2] - d['bbox'][0] for d in detections]
    median_width = sorted(widths)[len(widths) // 2]
    void_threshold = median_width * void_threshold_ratio
    
    # 3. Cek gap dalam setiap baris
    total_voids = 0
    void_details = []
    
    for row_idx, row in enumerate(rows):
        # Sort by X coordinate
        sorted_row = sorted(row, key=lambda d: d['bbox'][0])
        
        # Cek gap antar tetangga
        for i in range(len(sorted_row) - 1):
            prod_right = sorted_row[i]
            prod_left = sorted_row[i + 1]
            
            x_right_edge = prod_right['bbox'][2]  # Ujung kanan produk A
            x_left_edge = prod_left['bbox'][0]    # Ujung kiri produk B
            gap = x_left_edge - x_right_edge
            
            if gap > void_threshold:
                total_voids += 1
                void_details.append({
                    'row': row_idx,
                    'products': f"{prod_right['product_name']}-{prod_left['product_name']}",
                    'gap': gap
                })
    
    status = "PASS" if total_voids == 0 else "FAIL"
    
    return {
        'status': status,
        'void_count': total_voids,
        'void_threshold': void_threshold,
        'details': void_details,
        'reason': "Tidak ada void" if total_voids == 0 else f"Ditemukan {total_voids} void"
    }

def hitung_median_lebar(self, detections):
    """Helper: Hitung lebar rata-rata produk"""
    widths = [d['bbox'][2] - d['bbox'][0] for d in detections]
    return sorted(widths)[len(widths) // 2]

def hitung_gap(self, bbox_right, bbox_left):
    """Helper: Hitung gap antara 2 produk"""
    return bbox_left[0] - bbox_right[2]
```

### 🔑 Keyword Code
- **Function**: `cek_void()`, `hitung_gap()`, `hitung_median_lebar()`
- **Key Data**:
  - `void_threshold` - Gap maksimal yang diizinkan
  - `void_threshold_ratio` - Rasio terhadap median width (biasanya 0.5)
  - `median_width` - Lebar rata-rata produk
  - `gap` - Jarak antara produk A dan B
- **Tech Stack**: Python, bbox arithmetic, statistical analysis (median)

---

## **PARAMETER 6: POSM (Point of Sales Material)**

### 📐 Rumus
$$\text{Count(POSM)} \ge \text{POSM Target} \text{ AND } \text{X dalam zona blocking}$$

**Blocking zone condition:**
$$X_{\text{POSM}} \in [X_{\text{produk min}}, X_{\text{produk max}}]$$

### 🧠 Flow Logika Berpikir

1. **Definisi POSM**: Materi promosi seperti Wobbler, Banner, Strip harga, atau display khusus
2. **Deteksi POSM**: 
   - Sistem YOLO harus punya class khusus untuk POSM (misal: "Wobbler", "Banner")
   - Atau generic "POSM" class
3. **Validasi Keberadaan**: 
   - Minimal ada 1 POSM di rak → PASS
   - Tidak ada POSM → FAIL
4. **Validasi Posisi** (optional):
   - POSM harus berada di zona dekat produk target (blocking zone)
   - Zone: dari X minimum produk target sampai X maximum produk target
5. **Context**: POSM adalah indicator bahwa principal sudah standees/install promotional materials

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_posm()`

```python
def cek_posm(self, detections, planogram_target):
    """
    Cek POSM - keberadaan materi promosi (Wobbler, Banner, dll)
    """
    posm_target = planogram_target.get('posm_target', 1)
    target_product = planogram_target.get('target_product', 'indomie')
    
    # 1. Filter POSM dari deteksi
    posm_detections = [
        d for d in detections 
        if d.get('class_name') in ['POSM', 'Wobbler', 'Banner', 'Promo']
    ]
    
    posm_count = len(posm_detections)
    
    # 2. Cek keberadaan
    if posm_count == 0:
        return {
            'status': 'FAIL',
            'posm_count': 0,
            'posm_target': posm_target,
            'reason': 'Tidak ada POSM terdeteksi'
        }
    
    # 3. (Optional) Cek apakah POSM berada di blocking zone produk target
    target_products = [
        d for d in detections
        if d['product_name'].lower() == target_product
    ]
    
    if target_products:
        min_x = min(d['bbox'][0] for d in target_products)
        max_x = max(d['bbox'][2] for d in target_products)
        
        posm_in_zone = sum(
            1 for posm in posm_detections
            if min_x <= (posm['bbox'][0] + posm['bbox'][2]) / 2 <= max_x
        )
    else:
        posm_in_zone = posm_count
    
    # 4. Validasi
    status = "PASS" if posm_in_zone >= posm_target else "FAIL"
    
    return {
        'status': status,
        'posm_count': posm_count,
        'posm_in_zone': posm_in_zone,
        'posm_target': posm_target,
        'reason': f'POSM ditemukan: {posm_in_zone}/{posm_target}'
    }

def apakah_x_dalam_zona(self, x_center, zone_min, zone_max):
    """Helper: Cek apakah X center dalam zona"""
    return zone_min <= x_center <= zone_max
```

### 🔑 Keyword Code
- **Function**: `cek_posm()`, `apakah_x_dalam_zona()`
- **Key Data**:
  - `class_name` - Filter untuk "POSM", "Wobbler", "Banner"
  - `posm_target` - Jumlah minimum POSM yang harus ada
  - `blocking_zone` - Zona X tempat POSM harus berada
  - `x_center` - Koordinat horizontal pusat POSM
- **Tech Stack**: Python, filtering, zone validation

---

## **PARAMETER 7: Eye Level (Posisi Tingkat Mata)**

### 📐 Rumus
$$\frac{1}{3} \times Y_{\text{max}} \le Y_{\text{center produk}} \le \frac{2}{3} \times Y_{\text{max}}$$

**Zone breakdown:**
- **Top Zone**: 0 - 1/3 tinggi (Above Eye Level)
- **Eye Level Zone**: 1/3 - 2/3 tinggi (GOLDEN ZONE) ← Target produk harus di sini
- **Bottom Zone**: 2/3 - 100% tinggi (Below Eye Level)

### 🧠 Flow Logika Berpikir

1. **Prinsip Retail**: Produk di tingkat mata konsumen lebih mudah dilihat, sehingga lebih likely terjual
2. **Definisi Eye Level**: 
   - Rata-rata tinggi mata konsumen adalah di 1/3 hingga 2/3 dari tinggi rak
   - Umumnya antara 1000-1700 pixel (tergantung tinggi rak)
3. **Validasi Posisi**:
   - Hitung Y center dari produk target
   - Cek apakah Y center masuk di golden zone (1/3 - 2/3)
4. **Strategi Merchandising**: Produk top-selling/margin harus ditempatkan di eye level
5. **Failure Mode**: Jika produk berada di top atau bottom saja → FAIL

### 💻 Implementasi Code

**File:** `rules_engine.py` - Function `cek_eye_level()`

```python
def cek_eye_level(self, detections, planogram_target):
    """
    Cek Eye Level - produk target berada di tingkat mata konsumen
    """
    eye_level_target = planogram_target.get('eye_level_target', True)
    target_product = planogram_target.get('target_product', 'indomie')
    
    # 1. Hitung zona eye level dari total tinggi gambar
    # Asumsi: Y max dari image adalah height, bisa dari detection max Y
    y_max = max(d['bbox'][3] for d in detections) if detections else 1000
    
    eye_level_min = y_max / 3
    eye_level_max = (y_max * 2) / 3
    
    # 2. Filter produk target
    target_detections = [
        d for d in detections
        if d['product_name'].lower() == target_product
    ]
    
    if not target_detections:
        return {
            'status': 'SKIP',
            'reason': f'{target_product} tidak terdeteksi'
        }
    
    # 3. Cek posisi setiap produk target
    in_eye_level = 0
    details = []
    
    for detection in target_detections:
        y_center = (detection['bbox'][1] + detection['bbox'][3]) / 2
        in_zone = eye_level_min <= y_center <= eye_level_max
        
        zone_name = "Top" if y_center < eye_level_min else \
                   "Eye Level" if in_zone else \
                   "Bottom"
        
        details.append({
            'y_center': y_center,
            'zone': zone_name,
            'in_eye_level': in_zone
        })
        
        if in_zone:
            in_eye_level += 1
    
    # 4. Validasi
    coverage = (in_eye_level / len(target_detections)) * 100
    status = "PASS" if coverage >= 80 else "FAIL"
    
    return {
        'status': status,
        'in_eye_level': in_eye_level,
        'total_products': len(target_detections),
        'coverage_percent': coverage,
        'eye_level_zone': [eye_level_min, eye_level_max],
        'details': details,
        'reason': f'{coverage:.0f}% produk di eye level'
    }

def apakah_y_di_bawah(self, y_center, threshold):
    """Helper: Cek apakah Y di bawah threshold"""
    return y_center > threshold

def hitung_jarak_ke_center(self, y_center, y_min, y_max):
    """Helper: Hitung jarak dari Y center ke tengah zone"""
    zone_center = (y_min + y_max) / 2
    return abs(y_center - zone_center)
```

### 🔑 Keyword Code
- **Function**: `cek_eye_level()`, `apakah_y_di_bawah()`
- **Key Data**:
  - `eye_level_target` - Flag apakah harus di eye level
  - `target_product` - Produk yang dicek posisinya
  - `y_max` - Tinggi total gambar/rak
  - `eye_level_min` - Y batas bawah zone (1/3 × y_max)
  - `eye_level_max` - Y batas atas zone (2/3 × y_max)
  - `y_center` - Koordinat vertikal pusat produk
- **Tech Stack**: Python, coordinate geometry, zone validation

---

## 📊 RINGKASAN TABEL PARAMETER

| No | Parameter | Fokus Utama | Key Method | Status Pass Condition |
|----|-----------|------------|-----------|----------------------|
| 1 | SoS | Dominasi produk di kategori | `cek_sos()` | actual_sos ≥ sos_target |
| 2 | Facing/OOS | Jumlah barang minimum | `cek_facing_dan_oos()` | actual_facing ≥ facing_target |
| 3 | Sequence | Urutan produk L-R per baris | `cek_sequence()` | actual_seq == target_seq |
| 4 | Price Tag | Label harga ada di bawah | `cek_price_tag()` | 80% produk punya tag |
| 5 | Void | Tidak ada celah lebar | `cek_void()` | gap ≤ void_threshold |
| 6 | POSM | Material promosi ada | `cek_posm()` | posm_count ≥ posm_target |
| 7 | Eye Level | Produk di tingkat mata | `cek_eye_level()` | 80% produk di zone |

---

## 🔧 IMPLEMENTASI OVERALL

**File Utama:** `rules_engine.py`

```python
class PlanogramValidator:
    def __init__(self, detections, planogram_target):
        self.detections = detections
        self.planogram_target = planogram_target
        self.results = {}
    
    def validate_all(self):
        """Jalankan semua 7 parameter validation"""
        self.results['sos'] = self.cek_sos(self.detections, self.planogram_target)
        self.results['facing_oos'] = self.cek_facing_dan_oos(self.detections, self.planogram_target)
        self.results['sequence'] = self.cek_sequence(self.detections, self.planogram_target)
        self.results['price_tag'] = self.cek_price_tag(self.detections, self.planogram_target)
        self.results['void'] = self.cek_void(self.detections, self.planogram_target)
        self.results['posm'] = self.cek_posm(self.detections, self.planogram_target)
        self.results['eye_level'] = self.cek_eye_level(self.detections, self.planogram_target)
        
        return self.results
    
    def get_summary(self):
        """Generate summary dari 7 parameter"""
        pass_count = sum(1 for r in self.results.values() if r['status'] == 'PASS')
        fail_count = sum(1 for r in self.results.values() if r['status'] == 'FAIL')
        skip_count = sum(1 for r in self.results.values() if r['status'] == 'SKIP')
        
        compliance_score = (pass_count / 7) * 100
        
        return {
            'pass_count': pass_count,
            'fail_count': fail_count,
            'skip_count': skip_count,
            'total_params': 7,
            'compliance_score': compliance_score
        }
```

---

## 📝 DATA FLOW

```
📸 YOLO Detection
   ↓
[{product_name, bbox, confidence, class_name}, ...]
   ↓
PlanogramValidator.validate_all()
   ├─ cek_sos() → PASS/FAIL
   ├─ cek_facing_dan_oos() → PASS/FAIL/OOS
   ├─ cek_sequence() → PASS/FAIL
   ├─ cek_price_tag() → PASS/FAIL
   ├─ cek_void() → PASS/FAIL
   ├─ cek_posm() → PASS/FAIL
   └─ cek_eye_level() → PASS/FAIL
   ↓
{
  'status': 'success',
  'summary': {
    'pass_count': 5,
    'fail_count': 2,
    'skip_count': 0,
    'compliance_score': 71.4%,
    'grade': 'NEEDS_ATTENTION'
  },
  'parameters': {
    'sos': {...},
    'facing_oos': {...},
    ...
  }
}
   ↓
🎨 Flutter UI Display
```

---

**Last Updated:** March 13, 2026  
**Version:** 1.0 - Planogram Validation System  
**Tech Stack:** Python (backend), Flutter (frontend), YOLOv8 (detection)
