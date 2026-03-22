.PHONY: help iso iso-local qemu qmec qemc check

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  iso       - Build the real Nix ISO"
	@echo "  iso-local - Build a minimal local ISO without Nix"
	@echo "  qemu      - Boot the latest ISO in QEMU"
	@echo "  qmec      - Alias for qemu"
	@echo "  qemc      - Alias for qemu"
	@echo "  check     - Run repository script checks"

iso:
	./scripts/build-iso.sh

iso-local:
	./scripts/build-iso-local.sh

qemu:
	./scripts/run-qemu.sh

qmec: qemu

qemc: qemu

check:
	./scripts/check-scripts.sh
