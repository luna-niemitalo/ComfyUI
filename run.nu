#!/usr/bin/env nu

# ==============================
# Environment variables
# ==============================

# Enable HIP backend for AMD GPUs
$env.COMFYUI_USE_HIP = "1"
#$env.SAM3_FORCE_CPU = "1"
# MIOpen / ROCm tuning
$env.MIOPEN_FIND_MODE = "2"                 # 2 = aggressive find, caches best kernels
$env.MIOPEN_USE_ROCBLAS = "1"               # Prefer rocBLAS for GEMMs
$env.MIOPEN_GEMM_ENFORCE_BACKEND = "1"       # Force backend choice
$env.MIOPEN_COMPILE_PARALLEL_LEVEL = "16"    # Parallel kernel compilation
$env.USE_FLASH_ATTN = false                        # Flash attention is unstable on ROCm, disable it
#$env.OLD_GPU = true
#$env.COMFYUI_SAM3_FORCE_CPU_OFFLOAD = "1"  # Force SAM3 model offloading to CPU to save VRAM
#$env.TORCH_USE_HIP_DSA = "1"  # Allow SAM3 to use GPU if available
#$env.AMD_SERIALIZE_KERNEL = "3"


# ==============================
# Disable core dumps (ulimit -c 0)
# ==============================
ulimit -c 0

# ==============================
# Whitelisted custom nodes
# ==============================
# Only these custom_nodes folders will be loaded,
# even though --disable-all-custom-nodes is enabled.
let whitelist_custom_nodes = [
  #SwarmComfyExtra      # SwarmUI integration helpers
  #SwarmComfyCommon     # Shared SwarmUI node utilities
  ComfyUI-GGUF         # GGUF / LLM loader nodes
  AspectRatioResolution # Custom aspect ratio node with better behavior
  MaterialSaver	  # Advanced prompt composition node
  ComfyUI-DepthAnythingV2
  ComfyUI-SAM3
  ImageBatchPostprocess
]

# ==============================
# Main argument list
# ==============================
let args = [
  # Enable specific fast-path optimizations
  # Valid values include: fp16_accumulation, fp8_matrix_mult, cublas_ops
  "--fast=fp16_accumulation"

  # Precision control
  "--fp32-vae"         # Keep VAE in FP32 for stability / quality
  "--fp16-unet"        # Run UNet in FP16
  "--force-fp16"       # Force FP16 everywhere possible
  "--fp16-text-enc"    # Text encoders in FP16

  # Device selection
  "--default-device=1" # First visible GPU
  #"--force-non-blocking"

  # Memory behavior
  "--async-offload=8"  # Async weight offloading with 8 streams
                       # Helps hide PCIe latency on large models

  # Disable features that are unstable or unnecessary on ROCm
  "--disable-xformers" # xformers is CUDA-centric and flaky on AMD

  # Practicality over subscriptions
  "--disable-api-nodes"        # Not paying for flaky third-party API providers

  # Startup speed > feature hoarding
  "--disable-all-custom-nodes" # Suppress ComfyUI-Manager and its slow startup scans

  # Load only the custom nodes that are actually needed
  "--whitelist-custom-nodes"
  ...$whitelist_custom_nodes

  # VRAM strategy
  "--lowvram"          # Aggressive VRAM conservation
  "--listen"
  "--enable-cors-header"
]

# ==============================
# Debug: show final argv
# ==============================
print $"Running: python3 main.py ($args | str join ' ')"

# ==============================
# Execute
# ==============================
python3 main.py ...$args