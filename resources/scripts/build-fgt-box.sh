#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build-fgt-box.sh <VERSION> <IMAGE_FILE>
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <VERSION> <IMAGE_FILE>"
  echo "Example: $0 7.2.0 fortios.qcow2"
  exit 1
fi

VM_VERSION="$1"
IMAGE_NAME="$2"

POOL="default"
IMAGES_DIR="/var/lib/libvirt/images"
REPO_URL="https://github.com/celeroon/fortigate-vagrant-libvirt"
WORKDIR="/tmp/fortigate-vagrant-libvirt"

# Cache sudo credentials for the entire script
sudo -v

# Keep sudo alive in background during long operations (like Packer build)
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

echo "[1/8] Removing FortiGate domains..."
sudo virsh list --all --name | grep -v '^$' | while read -r vm; do
  if sudo virsh dumpxml "$vm" | grep -qi "fortigate"; then
    echo "  - Force stopping $vm"
    sudo virsh destroy "$vm" >/dev/null 2>&1 || true
    echo "  - Undefining $vm (and removing attached storage)"
    sudo virsh undefine "$vm" --remove-all-storage --nvram >/dev/null 2>&1 \
      || sudo virsh undefine "$vm" --remove-all-storage >/dev/null 2>&1 || true
  fi
done

echo "[2/8] Ensuring storage pool '$POOL' is up..."
sudo virsh pool-info "$POOL" >/dev/null 2>&1 || sudo virsh pool-start "$POOL"
sudo virsh pool-refresh "$POOL"

echo "[3/8] Deleting FortiGate Vagrant box .img volumes from pool '$POOL'..."
mapfile -t forti_imgs < <(
  sudo virsh vol-list --pool "$POOL" \
    | awk 'NR>2 {print $1}' \
    | sed '/^$/d' \
    | grep -Ei 'fortinet-fortigate_vagrant_box_image_.*\.img$|fortigate.*\.img$' || true
)
if (( ${#forti_imgs[@]} == 0 )); then
  echo "  - No matching .img volumes found."
else
  for vol in "${forti_imgs[@]}"; do
    echo "  - Deleting volume: $vol"
    sudo virsh vol-delete --pool "$POOL" "$vol"
  done
fi

echo "[4/8] Removing Vagrant box: fortinet-fortigate (libvirt, version $VM_VERSION)..."
VGUSER="${SUDO_USER:-$USER}"
if [[ -z "$VGUSER" ]]; then
  echo "  - Could not determine non-root user; skipping vagrant box remove."
else
  sudo -u "$VGUSER" -H bash -lc '
    if command -v vagrant >/dev/null 2>&1; then
      echo "  - Attempting version-specific remove"
      vagrant box remove fortinet-fortigate --provider libvirt --box-version '"$VM_VERSION"' --force >/dev/null 2>&1 \
        || {
          echo "  - Version not present or failed; attempting provider-wide remove"
          vagrant box remove fortinet-fortigate --provider libvirt --force >/dev/null 2>&1 || true
        }
    else
      echo "  - Vagrant not found for user '"$VGUSER"', skipping."
    fi
  '
fi

echo "[5/8] Ensure $IMAGES_DIR/$IMAGE_NAME exists with proper owner/perms..."
if [[ ! -f "$IMAGES_DIR/$IMAGE_NAME" ]]; then
  echo "  ERROR: $IMAGES_DIR/$IMAGE_NAME not found. Place the image first and re-run."
  exit 1
fi

# Detect the appropriate libvirt user:group based on distribution
if [[ -f /etc/debian_version ]]; then
  # Debian/Ubuntu based
  LIBVIRT_USER="libvirt-qemu:kvm"
elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
  # RHEL/Fedora/CentOS based
  LIBVIRT_USER="qemu:qemu"
else
  # Fallback: try to detect by checking which user exists
  if id -u libvirt-qemu >/dev/null 2>&1; then
    LIBVIRT_USER="libvirt-qemu:kvm"
  elif id -u qemu >/dev/null 2>&1; then
    LIBVIRT_USER="qemu:qemu"
  else
    echo "  WARNING: Could not detect libvirt user. Using root:root as fallback."
    LIBVIRT_USER="root:root"
  fi
fi

echo "  Using ownership: $LIBVIRT_USER"
sudo chown "$LIBVIRT_USER" "$IMAGES_DIR/$IMAGE_NAME"
sudo chmod 0744 "$IMAGES_DIR/$IMAGE_NAME"
ls -l "$IMAGES_DIR/$IMAGE_NAME"

echo "[6/8] Clone repo into /tmp..."
if [[ -d "$WORKDIR/.git" ]]; then
  git -C "$WORKDIR" fetch --all --prune
  git -C "$WORKDIR" reset --hard origin/HEAD
else
  rm -rf "$WORKDIR"
  git clone "$REPO_URL" "$WORKDIR"
fi

echo "[7/8] Build box with Packer (version=$VM_VERSION, image_name=$IMAGE_NAME)..."
pushd "$WORKDIR" >/dev/null
PACKER_LOG=1 packer build -var "version=$VM_VERSION" -var "image_name=$IMAGE_NAME" fortigate-ssl-vrf.pkr.hcl
popd >/dev/null

echo "[8/8] Move artifacts, patch JSON, and add box..."
BOX_PATH="$(ls -1 "$WORKDIR"/builds/fortinet-fortigate-*.box | head -n1 || true)"
if [[ -z "${BOX_PATH:-}" || ! -f "$BOX_PATH" ]]; then
  echo "  ERROR: Built .box not found under $WORKDIR/builds/"
  exit 1
fi
sudo mv "$BOX_PATH" "$IMAGES_DIR/"
BOX_BASENAME="$(basename "$BOX_PATH")"
echo "  Moved: $IMAGES_DIR/$BOX_BASENAME"

if [[ ! -f "$WORKDIR/src/fortigate.json" ]]; then
  echo "  ERROR: fortigate.json not found at $WORKDIR/src/fortigate.json"
  exit 1
fi
sudo mv "$WORKDIR/src/fortigate.json" "$IMAGES_DIR/fortigate.json"

sudo sed -i \
  -e "s/\"version\": \"VER\"/\"version\": \"$VM_VERSION\"/" \
  -e "s#\"url\": \"file:///var/lib/libvirt/images/fortinet-fortigate-VER.box\"#\"url\": \"file://$IMAGES_DIR/fortinet-fortigate-$VM_VERSION.box\"#" \
  "$IMAGES_DIR/fortigate.json"

sudo -u "$VGUSER" -H bash -lc '
  if command -v vagrant >/dev/null 2>&1; then
    vagrant box add --provider libvirt --box-version '"$VM_VERSION"' '"$IMAGES_DIR"'/fortigate.json
  else
    echo "  - Vagrant not found for user '"$VGUSER"'. Skipping box add."
  fi
'

echo "Done."
