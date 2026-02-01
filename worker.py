# worker.py
import torch, json, sys, time

test = json.loads(sys.argv[1])
device = "cuda" if torch.cuda.is_available() else "cpu"

DTYPE = {
    "float32": torch.float32,
    "float16": torch.float16,
    "bfloat16": torch.bfloat16,
    "float8_e4m3fn": getattr(torch, "float8_e4m3fn", None),
    "float8_e5m2": getattr(torch, "float8_e5m2", None),
}

try:
    torch.cuda.reset_peak_memory_stats()

    model = torch.nn.Linear(8192, 8192).to(device)

    if test.get("dtype"):
        dt = DTYPE[test["dtype"]]
        if dt is None:
            raise RuntimeError("dtype not supported on this build")
        model = model.to(dt)

    x = torch.randn(4, 8192, device=device)
    if test.get("dtype"):
        x = x.to(dt)

    torch.cuda.synchronize()
    t0 = time.time()

    for _ in range(10):
        y = model(x)

    torch.cuda.synchronize()
    dt_s = time.time() - t0

    mem = torch.cuda.max_memory_allocated() / 1024**2

    print(json.dumps({
        "status": "ok",
        "time_s": round(dt_s, 4),
        "vram_mb": round(mem, 1)
    }))

except Exception as e:
    print(json.dumps({
        "status": "fail",
        "error": str(e)
    }))
