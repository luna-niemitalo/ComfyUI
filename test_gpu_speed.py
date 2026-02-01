import torch
import time

dtypes = {
    "fp32": torch.float32,
    "fp16": torch.float16,
    "bf16": torch.bfloat16,
    "fp64": torch.float64,  # rarely useful, but testable
}

device = "cuda"
size = 4096  # 4096x4096 matrix multiply for stress test

print(f"Testing precisions on {torch.cuda.get_device_name(0)}")
print(f"ROCm/HIP: {torch.version.hip}\n")

for name, dtype in dtypes.items():
    print(f"=== Testing {name.upper()} ===")
    try:
        torch.cuda.empty_cache()
        x = torch.randn((size, size), device=device, dtype=dtype)
        y = torch.randn((size, size), device=device, dtype=dtype)

        # Warm-up run
        _ = x @ y
        torch.cuda.synchronize()

        # Timed runs
        start = time.time()
        for _ in range(500):
            z = x @ y
        torch.cuda.synchronize()
        elapsed = time.time() - start

        vram_alloc = torch.cuda.memory_allocated(device) / (1024**2)
        print(f"  Time for 5 matmuls: {elapsed:.3f}s")
        print(f"  VRAM allocated: {vram_alloc:.1f} MB\n")

    except Exception as e:
        print(f"  Failed: {e}\n")
