SHELL := /usr/bin/env bash

.PHONY: help iso qemu qmec

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  iso    - Build the ISO image using scripts/build-iso.sh"
	@echo "  qemu   - Rebuild VM/launch QEMU via scripts/rebuild-vm.sh"
	@echo "  qmec   - Alias for 'qemu' (accepts your spelling)"

iso:
	@if command -v nix >/dev/null 2>&1; then \
		echo "Running build-iso.sh..."; \
		bash scripts/build-iso.sh; \
	else \
		echo "Nix not found — using local ISO fallback (requires xorriso/genisoimage/mkisofs)..."; \
		bash scripts/build-iso-local.sh; \
	fi

qemu:
	@echo "Running rebuild-vm.sh..."
	@bash scripts/rebuild-vm.sh

qmec: qemu
