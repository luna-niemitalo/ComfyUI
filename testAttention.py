from aule import flash_attention, get_available_backends, install

backends = get_available_backends()  # ['triton-amd', 'triton', 'vulkan', 'cpu']

print("Available attention backends:", backends)

install(backend='triton', verbose=True)  # Force backend + logging

import torch

q = torch.randn(1, 32, 512, 128, device='cuda')
k = torch.randn(1, 8, 512, 128, device='cuda')
v = torch.randn(1, 8, 512, 128, device='cuda')

output = flash_attention(q, k, v, causal=False)
print("Output shape:", output.shape)  # Should be [1, 32, 512, 128]