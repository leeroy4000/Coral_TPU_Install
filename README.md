Got it Nathan — here’s the **full command‑by‑command recipe**, including every `cd` and edit step, so you can drop this straight into your GitHub repo as a reproducible How‑To.

---

# 🛠️ Coral TPU Driver Install on Proxmox (Kernel 6.14+)

### 1. Prep Environment
```bash
sudo apt update
sudo apt install -y git devscripts dh-dkms build-essential linux-headers-$(uname -r)
```

---

### 2. Get the Driver Source
```bash
cd ~
git clone https://github.com/google/gasket-driver.git
cd gasket-driver/
debuild -us -uc -tc -b
cd ..
sudo dpkg -i gasket-dkms_1.0-18_all.deb
```

---

### 3. Patch for Modern Kernels

#### Edit `gasket_page_table.c`
```bash
cd /usr/src/gasket-1.0/
sudo nano gasket_page_table.c
```

Find the line:
```c
MODULE_IMPORT_NS(DMA_BUF);
```

Replace it with:
```c
#ifdef MODULE_IMPORT_NS
MODULE_IMPORT_NS("DMA_BUF");
#endif
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

#### Edit `gasket_core.c`
```bash
cd /usr/src/gasket-1.0/
sudo nano gasket_core.c
```

Find the line:
```c
.llseek = no_llseek,
```

Replace it with:
```c
.llseek = noop_llseek,
```

Save and exit.

---

### 4. Rebuild & Install
```bash
sudo dkms build -m gasket -v 1.0 -k $(uname -r)
sudo dkms install -m gasket -v 1.0 -k $(uname -r)
```

---

### 5. Load Modules
```bash
sudo modprobe gasket
sudo modprobe apex
```

---

### 6. Verify
```bash
lsmod | grep gasket
lsmod | grep apex
ls /dev/apex_0
```

You should see both modules loaded and `/dev/apex_0` present.

---

### 7. (Optional) Test TPU
```bash
python3 -m pip install --upgrade pip edgetpu
wget https://storage.googleapis.com/edgetpu-public/models/mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite
wget https://storage.googleapis.com/edgetpu-public/images/parrot.jpg

python3 -m edgetpu.demo.classify_image \
  --model mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite \
  --image parrot.jpg
```

---

## 📝 Notes
- Ignore PCIe **Correctable RxErr** messages in `dmesg` — they’re harmless.
- Purge unused kernels to avoid DKMS trying to build against them:
  ```bash
  sudo apt purge linux-image-<old> linux-headers-<old>
  ```
- Always patch inside `/usr/src/gasket-1.0/`, not the cloned repo copy.

---

This is the **minimal, repeatable path**:  
clone → build package → patch two files → dkms build/install → modprobe → verify.  

Would you like me to format this into a **Markdown README.md** with headings and copy‑friendly code blocks so you can drop it straight into your repo?
