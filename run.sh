# Set custom environment variables optimized for AMD Radeon VII
#export HIP_VISIBLE_DEVICES=1
export COMFYUI_USE_HIP=1
#export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
#export HSA_OVERRIDE_GFX_VERSION=9.0.6
# export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
#export PYTORCH_TUNABLEOP_ENABLED=1
export MIOPEN_FIND_MODE=2
export MIOPEN_USE_ROCBLAS=1
export MIOPEN_GEMM_ENFORCE_BACKEND=1
export MIOPEN_COMPILE_PARALLEL_LEVEL=16
#export TORCH_USE_HIPBLASLT=0
#export HIPBLASLT_FORCE_DISABLE=1
#export HIPBLASLT_DISABLE=1

#export ROCBLAS_LAYER=0
#export ROCBLAS_LOG_LEVEL=0

ulimit -c 0
# Define a simple, easy-to-edit list of arguments
ARG_LIST=(
	"--fast" 	#Enable some untested and potentially quality deteriorating optimizations. --fast with no arguments enables everything. You can pass a list specific optimizations if you
				#only want to enable specific ones. Current valid optimizations: fp16_accumulation fp8_matrix_mult cublas_ops
	#"--force-non-blocking" #Force non-blocking memory transfers (may cause instability on some systems)
  	#"--use-split-cross-attention" # Use the split cross attention optimization. Ignored when xformers is used.
  	#"--use-quad-cross-attention" # Use the sub-quadratic cross attention optimization . Ignored when xformers is used.
  	#"--use-pytorch-cross-attention" # Use the new pytorch 2.0 cross attention function.
  	#"--use-sage-attention"  #Use sage attention.
  	#"--use-flash-attention" #Use FlashAttention.
	"--force-fp16"          #Force fp16.
	"--fp16-text-enc"     #Use FP16 for text encoders.
	#"--verbose=DEBUG"
	"--default-device=1"
	#"--cache-none" # Reduced RAM/VRAM usage at the expense of executing every node for each run.
	#"--cache-ram=32" #[CACHE_RAM] Use RAM pressure caching with the specified headroom threshold. If available RAM drops below the threhold the cache remove large items to free RAM. Default 4GB
	#"--disable-smart-memory" #Force ComfyUI to agressively offload to regular ram instead of keeping models in vram when it can.
  	"--async-offload=8" # [NUM_STREAMS] Use async weight offloading. An optional argument controls the amount of offload streams. Default is 2. Enabled by default on Nvidia.
  	#"--disable-async-offload" # Disable async weight offloading.
	"--disable-xformers" #Disable xformers.
	#"--disable-manager-ui"  # Disables only the ComfyUI-Manager UI and endpoints. Scheduled
                			# installations and similar background tasks will still operate.
	"--disable-api-nodes"   # Disable loading all api nodes. Also prevents the frontend from
                        	# communicating with the internet.
	"--disable-all-custom-nodes"  # Disable loading all custom nodes.
	"--whitelist-custom-nodes=ComfyUI-GGUF" 		# WHITELIST_CUSTOM_NODES [WHITELIST_CUSTOM_NODES ...]
									# Specify custom node folders to load even when --disable-all-custom-nodes
                        			# is enabled.
	#"--novram"
	"--lowvram"          #Use lowvram mode.
	#"--normalvram"        #Use normal_vram mode.
	#"--highvram"         #Use highvram mode.
	#"--fp8_e5m2-unet"   #Use simulated FP8 (e5m2) for the UNet (may improve performance on some GPUs)
	#"--fp16-text-enc" #Use FP16 for text encoders
  	#"--base-directory=/media/luna/models" #BASE_DIRECTORY
                        #Set the ComfyUI base directory for models, custom_nodes,
                        #input, output, temp, and user directories.

)

echo "Running: python3 main.py ${ARG_LIST[@]}"
python3 main.py "${ARG_LIST[@]}"
