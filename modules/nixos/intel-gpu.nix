# Intel iGPU (Gen 12+ / Alder Lake and newer): VA-API (iHD), Quick Sync (oneVPL) and OpenCL
# (e.g. HDR tone-mapping), plus the usual diagnostic tools (intel_gpu_top, vainfo).
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    libva-utils
  ];
}
