#!/bin/bash
# install-coral-tpu.sh
# Automates Coral TPU driver install on Proxmox (kernel 6.14+)

set -e

echo "=== Step 1: Install prerequisites ==="
sudo apt update
sudo apt install -y git devscripts dh-dkms dkms build-essential linux-headers-$(uname -r)

echo "=== Step 2: Clone and build gasket driver ==="
cd ~
if [ ! -d "gasket-driver" ]; then
  git clone https://github.com/google/gasket-driver.git
fi
cd gasket-driver
debuild -us -uc -tc -b
cd ..
sudo dpkg -i gasket-dkms_1.0-18_all.deb || true

echo "=== Step 3: Apply kernel patches ==="
cd /usr/src/gasket-1.0/

# Patch gasket_page_table.c
sudo sed -i 's/MODULE_IMPORT_NS(DMA_BUF);/#ifdef MODULE_IMPORT_NS\nMODULE_IMPORT_NS("DMA_BUF");\n#endif/' gasket_page_table.c

# Patch gasket_core.c
sudo sed -i 's/\.llseek = no_llseek,/\.llseek = noop_llseek,/' gasket_core.c

echo "=== Step 4: Rebuild and install DKMS module ==="
sudo dkms build -m gasket -v 1.0 -k $(uname -r)
sudo dkms install -m gasket -v 1.0 -k $(uname -r)

echo "=== Step 5: Load modules ==="
sudo modprobe gasket
sudo modprobe apex

echo "=== Step 6: Verify ==="
lsmod | grep gasket || echo "gasket not loaded"
lsmod | grep apex || echo "apex not loaded"
if [ -e /dev/apex_0 ]; then
  echo "TPU device node present: /dev/apex_0"
else
  echo "TPU device node missing!"
fi

echo "=== Done! Coral TPU driver installed and loaded. ==="
