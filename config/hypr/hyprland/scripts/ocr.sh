#!/usr/bin/env bash

set -euo pipefail

# Nome do arquivo temporário
TEMP_IMG="/tmp/ocr_shot.png"
PROC_IMG="/tmp/ocr_proc.png"

# 1. Captura a seleção (grim + slurp)
grim -g "$(slurp)" "$TEMP_IMG" || exit 1

# 2. Pré-processamento com ImageMagick (A mágica acontece aqui)
# -resize 300%: Aumenta para melhor reconhecimento
# -colorspace gray: Remove cores
# -threshold 50%: Transforma em P&B puro (ajustável se precisar)
magick "$TEMP_IMG" -resize 300% -colorspace gray -type grayscale -sharpen 0x1 "$PROC_IMG"

# 3. OCR com Tesseract usando Português e Inglês
# O "-" manda o resultado direto pro stdout
if tesseract --list-langs 2>/dev/null | grep -qx "por"; then
  OCR_LANGS="por+eng"
else
  OCR_LANGS="eng"
fi

tesseract "$PROC_IMG" - -l "$OCR_LANGS" 2>/dev/null | wl-copy

# 5. Limpeza
rm "$TEMP_IMG" "$PROC_IMG"
