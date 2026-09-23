#!/usr/bin/env bash
# Downloads terraform (cached per agent under $HOME) and puts it on PATH.
# Must be sourced so the PATH change reaches the calling step.
set -euo pipefail

TF_VERSION="${TF_VERSION:-1.15.8}"
TF_BIN_DIR="$HOME/.terraform-bin/$TF_VERSION"

if [[ ! -x "$TF_BIN_DIR/terraform" ]]; then
  case "$(uname -m)" in
    x86_64|amd64)  TF_ARCH=amd64 ;;
    aarch64|arm64) TF_ARCH=arm64 ;;
    *) echo "Unsupported arch: $(uname -m)"; exit 1 ;;
  esac

  TF_URL="https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${TF_ARCH}.zip"
  TF_ZIP="$(mktemp -d)/terraform.zip"
  echo "Downloading $TF_URL"
  curl -fsSL -o "$TF_ZIP" "$TF_URL"

  mkdir -p "$TF_BIN_DIR"
  if command -v unzip >/dev/null; then
    unzip -o -q "$TF_ZIP" terraform -d "$TF_BIN_DIR"
  else
    python3 -m zipfile -e "$TF_ZIP" "$TF_BIN_DIR"
  fi
  chmod +x "$TF_BIN_DIR/terraform"
fi

export PATH="$TF_BIN_DIR:$PATH"
terraform version
