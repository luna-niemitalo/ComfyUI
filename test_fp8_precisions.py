import torch
import time

# Settings
SEQ_LEN = 4096
EMBED_DIM = 1024
HEADS = 16
BATCH = 2
DEVICE = "cuda"

def simulate_fp8(tensor, fmt="e4m3fn"):
    """
    Simulate FP8 storage by quantizing and dequantizing.
    fmt can be: "e4m3fn", "e5m2", "e8m0fnu"
    """
    if fmt == "e4m3fn":
        # 4-bit exponent, 3-bit mantissa (simulated)
        scale = 2**3
    elif fmt == "e5m2":
        scale = 2**2
    elif fmt == "e8m0fnu":
        scale = 1  # extreme quantization
    else:
        raise ValueError(f"Unknown FP8 format: {fmt}")

    t_scaled = tensor * scale
    t_quant = t_scaled.round().clamp(-127, 127)  # simulate 8-bit range
    t_dequant = t_quant / scale
    return t_dequant

def benchmark_fp8(fmt, runs=5):
    torch.cuda.empty_cache()
    x = torch.randn((BATCH, HEADS, SEQ_LEN, EMBED_DIM // HEADS), device=DEVICE, dtype=torch.float32)

    # Warm-up
    y = simulate_fp8(x, fmt)
    torch.cuda.synchronize()

    start = time.time()
    for _ in range(runs):
        y = simulate_fp8(x, fmt)
    torch.cuda.synchronize()

    elapsed = time.time() - start
    vram = torch.cuda.memory_allocated() / (1024**2)
    print(f"{fmt:<15} | Time for {runs} runs: {elapsed:.3f}s | VRAM: {vram:.1f} MB")

if __name__ == "__main__":
    print(f"Testing simulated FP8 formats on {torch.cuda.get_device_name(0)} (HIP {torch.version.hip})\n")
    for fmt in ["e4m3fn", "e5m2", "e8m0fnu"]:
        benchmark_fp8(fmt, runs=50000)
