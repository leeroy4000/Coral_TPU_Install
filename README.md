Here’s a clean **README.md** you can drop straight into your GitHub repo. It starts with a summary of what the guide is for, then walks through every command step‑by‑step.

---

```markdown
# Coral TPU Driver Install on Proxmox (Kernel 6.14+)

## 📖 Summary
This guide explains how to install and patch the **Google Coral TPU drivers** (`gasket` and `apex`) on **Proxmox systems running modern kernels (6.14+)**.  
The stock driver package fails to build due to kernel API changes. This README provides a **step‑by‑step, reproducible workflow** to build, patch, and load the drivers so that `/dev/apex_0` is available for TPU workloads.

---

## 🛠️ 1. Prep Environment
Install required build tools and headers:
```bash
sudo apt update
sudo apt install -y git devscripts dh-dkms build-essential linux-headers-$(uname -r)
```

---

## 📦 2. Get the Driver Source
Clone the driver repo and build the DKMS package:
```bash
cd ~
git clone https://github.com/google/gasket-driver.git
cd gasket-driver/
debuild -us -uc -tc -b
cd ..
sudo dpkg -i gasket-dkms_1.0-18_all.deb
```

---

## 🩹 3. Patch for Modern Kernels
The driver needs two small fixes.

### Edit `gasket_page_table.c`
```bash
cd /usr/src/gasket-1.0/
sudo nano gasket_page_table.c
```

Find:
```c
MODULE_IMPORT_NS(DMA_BUF);
```

Replace with:
```c
#ifdef MODULE_IMPORT_NS
MODULE_IMPORT_NS("DMA_BUF");
#endif
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

### Edit `gasket_core.c`
```bash
cd /usr/src/gasket-1.0/
sudo nano gasket_core.c
```

Find:
```c
.llseek = no_llseek,
```

Replace with:
```c
.llseek = noop_llseek,
```

Save and exit.

---

## 🔨 4. Rebuild & Install
```bash
sudo dkms build -m gasket -v 1.0 -k $(uname -r)
sudo dkms install -m gasket -v 1.0 -k $(uname -r)
```

---

## ⚡ 5. Load Modules
```bash
sudo modprobe gasket
sudo modprobe apex
```

---

## ✅ 6. Verify
Check that the modules are loaded and the TPU device node exists:
```bash
lsmod | grep gasket
lsmod | grep apex
ls /dev/apex_0
```

You should see both modules listed and `/dev/apex_0` present.

---

## 🧪 7. (Optional) Test TPU
Install the EdgeTPU runtime and run a demo inference:
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

## 🎯 TL;DR
Clone → Build package → Patch two files → `dkms build/install` → `modprobe` → Verify `/dev/apex_0`.
```

---

This README is copy‑ready for your repo. Would you like me to also add a **Troubleshooting section** (e.g. common errors like `no_llseek` or DKMS building against wrong kernels) so future installs are even smoother?
