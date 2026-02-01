import torch
import time
from aule import flash_attention as flash_attn_func
from aule import install
install(backend='triton', verbose=True)  # Force backend + logging

# Device setup
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")
dtype = torch.float16  # FlashAttention works best in FP16
torch.manual_seed(0)

# Parameters
batch, seq_len, heads, head_dim = 4, 512, 8, 64

# Create input tensors
q = torch.randn(batch, seq_len, heads, head_dim, device=device, dtype=dtype, requires_grad=True)
k = torch.randn_like(q)
v = torch.randn_like(q)

def benchmark(func, warmup=5, runs=1000):
    # Warmup
    for _ in range(warmup):
        func()
    torch.cuda.synchronize()
    start = time.time()
    for _ in range(runs):
        func()
    torch.cuda.synchronize()
    end = time.time()
    return (end - start) / runs

# Standard PyTorch attention
def vanilla_attention():
    attn_weights = torch.matmul(q, k.transpose(-1, -2)) / (head_dim ** 0.5)
    attn_probs = torch.nn.functional.softmax(attn_weights, dim=-1)
    return torch.matmul(attn_probs, v)

# FlashAttention
def flash_attention():
    return flash_attn_func(q, k, v, causal=False)

runs = 100000
vanilla_time = benchmark(vanilla_attention, runs=runs)
flash_time = benchmark(flash_attention, runs=runs)

print(f"Vanilla Attention: {vanilla_time*1000:.2f} ms")
print(f"FlashAttention:   {flash_time*1000:.2f} ms")
print(f"Speedup: {vanilla_time/flash_time:.2f}x")
