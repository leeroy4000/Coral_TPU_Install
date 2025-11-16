
```markdown
# Coral TPU Driver Install on Proxmox (Kernel 6.14+)

## 📖 Summary
This guide explains how to install and patch the **Google Coral TPU drivers** (`gasket` and `apex`)
on **Proxmox systems running modern kernels (6.14+)**.  
The stock driver package fails to build due to kernel API changes.
This README provides a **step‑by‑step, reproducible workflow** to build, patch,
and load the drivers so that `/dev/apex_0` is available for TPU workloads.

---

## 🛠️ 1. Prep Environment
```bash
sudo apt update
sudo apt install -y git devscripts dh-dkms build-essential linux-headers-$(uname -r)
```

---

## 📦 2. Get the Driver Source
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
```bash
lsmod | grep gasket
lsmod | grep apex
ls /dev/apex_0
```

---

## 🧪 7. (Optional) Test TPU
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

---

## 📜 Script Usage
For convenience, you can automate the entire process with the included script:

```bash
chmod +x install-coral-tpu.sh
./install-coral-tpu.sh
```

The script will:
- Install prerequisites  
- Clone and build the driver package  
- Apply the required patches automatically  
- Rebuild and install via DKMS  
- Load the modules and verify `/dev/apex_0`  

This is the fastest way to repeat the setup on new Proxmox hosts.
```
