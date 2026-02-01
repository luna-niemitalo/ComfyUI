{
  description = "ComfyUI ROCm 6.3 dev shell (gfx906)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    #gpu-platform.url = "path:/home/luna/nix/gpu-platform";
    nixpkgs-rocm63.url = "github:NixOS/nixpkgs/1c1c9b3f5ec0421eaa0f22746295466ee6a8d48f";
  };

  outputs =
    {
      self,
      nixpkgs,
      #gpu-platform,
      nixpkgs-rocm63,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgs63 = import nixpkgs-rocm63 { inherit system; };
      lib = pkgs.lib;

      # ROCm 6.3 set
      rocm = pkgs63.rocmPackages_6;

      runtimeLibs = [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.zstd
        pkgs.libglvnd
		pkgs.gcc
        pkgs.vulkan-loader

        rocm.rocm-runtime
        rocm.clr
        rocm.rocblas
        #rocm.hipblas
		    rocm.hip-common
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [
          #gpu-platform.devShells.full
        ];

		packages = [
			pkgs.git
			pkgs.git-lfs
			pkgs.ccache
			pkgs.cmakeWithGui
			pkgs63.rocmPackages_6.rocminfo
			pkgs.vulkan-tools

			pkgs.python313
			pkgs.python313Packages.setuptools
			pkgs.python313Packages.wheel

			pkgs.zlib
			pkgs.libxml2
		];

        shellHook = ''
		export PATH=${pkgs.python313}/bin:${rocm.clr}/bin:$PATH
		hash -r
        echo "ComfyUI ROCm 6.3 shell (gfx906)"

        # ---- ROCm 6.3 single source of truth ----
        export ROCM_ROOT=${rocm.rocm-runtime}
        export ROCM_PATH=$ROCM_ROOT
        export HIP_PATH=${rocm.clr}
		export CFLAGS="-I${pkgs.python313}/include/python3.13 $CFLAGS"
		export CPPFLAGS="$CFLAGS"
		export CPATH=${pkgs.python313}/include/python3.13
		export C_INCLUDE_PATH=$CPATH
		export PATH=${rocm.clr}/bin:${rocm.clr}/llvm/bin:$PATH
		export CPLUS_INCLUDE_PATH=$CPATH
		echo "${pkgs.python313}/include/python3.13/Python.h"
		#curl -LsSf https://astral.sh/uv/install.sh | INSTALLER_DOWNLOAD_URL=https://wheelnext.astral.sh/v0.0.3 sh

        export LD_LIBRARY_PATH=$ROCM_ROOT/lib:$HIP_PATH/lib:${rocm.rocblas}/lib:${rocm.hipblas}/lib
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib.makeLibraryPath runtimeLibs}

        # ---- PyTorch / HIP ----
        export USE_ROCM=1
        export USE_SYSTEM_ROCM=1
        export PYTORCH_ROCM_ARCH=gfx906
        export HCC_AMDGPU_TARGET=gfx906
        export CMAKE_HIP_ARCHITECTURES=gfx906
        export HIP_VISIBLE_DEVICES=0


		export PYTHON_EXECUTABLE=${pkgs.python313}/bin/python3.13
		export Python3_EXECUTABLE=$PYTHON_EXECUTABLE

		export PYTHON_INCLUDE_DIR=${pkgs.python313}/include/python3.13
		export Python3_INCLUDE_DIR=$PYTHON_INCLUDE_DIR

		export PYTHON_LIBRARY=${pkgs.python313}/lib/libpython3.13.so
		export Python3_LIBRARY=$PYTHON_LIBRARY

		export CPATH=$PYTHON_INCLUDE_DIR
		export C_INCLUDE_PATH=$CPATH
		export CPLUS_INCLUDE_PATH=$CPATH

		export PKG_CONFIG_PATH=${pkgs.zlib.dev}/lib/pkgconfig:${pkgs.libxml2.dev}/lib/pkgconfig:$PKG_CONFIG_PATH

		export CMAKE_PREFIX_PATH=${pkgs.zlib.dev}/lib:${pkgs.libxml2.dev}:$CMAKE_PREFIX_PATH
		export ZLIB_LIBRARY=${pkgs.zlib.dev}/lib/libz.so
		export ZLIB_INCLUDE_DIR=${pkgs.zlib.dev}/include
		export LLVM_TARGETS_TO_BUILD=AMDGPU
		export CMAKE_BUILD_WITH_INSTALL_RPATH=ON
        # Vega safety
        export ROC_ENABLE_PRE_VEGA=1
        export HIP_FORCE_DEV_KERNARG=1

        echo "hipcc: $(which hipcc)"
        hipcc --version
        echo "rocminfo:"
        rocminfo | head -n 10

		# ---- Python venv ----
		if [ ! -d "venv" ]; then
			echo "Creating Python venv..."
			#uv venv venv
	  		source venv/bin/activate
			echo "Installing Python packages..."
			#uv pip install --upgrade pip setuptools wheel
			#uv pip install -r requirements.txt -r requirements_additional.txt
		fi
		source venv/bin/activate
		echo $CPATH
		ls $CPATH/Python.h
        echo
        echo "Ready."
      '';
      };
    };
}
