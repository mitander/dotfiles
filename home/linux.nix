{ pkgs, ... }:
{
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.isLinux;
      message = "home/linux.nix must only be used for Linux profiles.";
    }
  ];

  # GPU drivers, display/audio integration, and the login shell intentionally
  # remain owned by the Linux host during the first migration milestone.
}
