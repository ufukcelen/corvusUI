# Corvus Mac (CorvusUI)

Uykusuz Tosba & Radio Mocas YouTube yayın duyuru otomasyonu için geliştirilmiş yerel macOS (SwiftUI) masaüstü uygulaması.

Orijinal Python CLI otomasyon motoru (`corvus.py`), After Effects şablonları, Photoshop JSX komutları ve varlıkları Git Submodule olarak `CorvusEngine/` dizininde yer almaktadır.

---

## 🚀 Başlangıç ve Kurulum

### 1. Repoyu Klonlama (Alt Modüllerle Birlikte)
Başka bir kullanıcı (veya yeni bir Mac) projeyi klonlarken şu komutu kullanmalıdır:

```bash
git clone --recurse-submodules https://github.com/ufukcelen/corvusUI.git
```

Eğer proje normal klonlandıysa alt modülü getirmek için:
```bash
git submodule update --init --recursive
```

### 2. Gereksinimler
- **macOS Sonoma veya üzeri**
- **Xcode 15+**
- **Python 3** (Homebrew önerilir: `brew install python`)
- Gerekli Python kütüphaneleri:
  ```bash
  pip3 install requests rich pillow
  ```
- **Adobe After Effects** (2024 / 2025 / 2026) - `aerender` için
- **Adobe Photoshop** (2024 / 2025 / 2026) - Thumbnail oluşturma için

---

## 🔄 Çekirdek (CLI) Güncellemeleri

CLI reposunda (`github.com/ufukcelen/Corvus`) yeni bir commit veya özellik yayınlandığında:

1. **Uygulama İçinden (Tek Tıkla):**
   - **Ayarlar** sekmesine gidin.
   - **"Çekirdeği Güncelle (Git Pull)"** butonuna tıklayın.
2. **Terminal Üzerinden:**
   ```bash
   git submodule update --remote --merge
   ```

---

## 🎨 Özellikler
- 📅 **Canlı Takvim:** Firebase Realtime Database + Ntfy entegrasyonu, yayın planlama ve durum takibi.
- 💬 **Ekip Sohbeti:** Ekip içi renk kodlu mesajlaşma ve bildirimler.
- 🐢 **Uykusuz Tosba Stüdyosu:** Haftalık Program, Canlı Maç, Maç Sonu, Tek Maçtan Yatanlar, FC27 Kariyer.
- 📻 **Radio Mocas Stüdyosu:** Filtresiz Memleket Havası, Albert ve Cem, Memleket Thumbnail üretimi.
- 🎨 **Photoshop Thumbnail Stüdyosu:** Smart Object optik ağırlıklandırma ve otomatik kapak tasarımı.
- 💻 **Canlı Terminal Konsolu:** Render ve otomasyon süreçlerinin gerçek zamanlı akışı.
