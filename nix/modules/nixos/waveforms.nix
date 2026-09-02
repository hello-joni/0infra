# Digilent WaveForms and Adept Runtime (Analog Discovery 2).
{ inputs, ... }:
{
  imports = [
    # Installs WaveForms and sets up USB device permissions.
    inputs.waveforms.nixosModules.default
  ];

  allowedUnfreePackages = [
    "waveforms" # Digilent Oscilloscope
    "adept2-runtime" # Digilent Oscilloscope
  ];
}
