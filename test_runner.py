# run_matrix.py
import subprocess, json, time

RESULTS = []
TEST_MATRIX = [
    # Normal
    {"name": "fp32",  "dtype": "float32"},
    {"name": "fp16",  "dtype": "float16"},
    {"name": "bf16",  "dtype": "bfloat16"},

    # FP8 (if supported)
    {"name": "fp8_e4m3fn", "dtype": "float8_e4m3fn"},
    {"name": "fp8_e5m2",   "dtype": "float8_e5m2"},

    # Quant-like (simulated)
    {"name": "int8_sim", "quant": "int8"},
    {"name": "nf4_sim",  "quant": "nf4"},
]

for test in TEST_MATRIX:
    print(f"== Running {test['name']} ==")
    start = time.time()

    try:
        p = subprocess.run(
            ["python3", "worker.py", json.dumps(test)],
            capture_output=True,
            timeout=300
        )

        if p.returncode != 0:
            RESULTS.append({
                **test,
                "status": "crash",
                "error": p.stderr.decode().strip()
            })
        else:
            data = json.loads(p.stdout.decode())
            RESULTS.append({**test, **data})

    except Exception as e:
        RESULTS.append({**test, "status": "launcher_error", "error": str(e)})

    with open("results.jsonl", "a") as f:
        f.write(json.dumps(RESULTS[-1]) + "\n")

print("Done.")
