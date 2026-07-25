{ pkgs, ... }:
{
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.isDarwin;
      message = "home/darwin.nix must only be used for Darwin profiles.";
    }
  ];

  # Native graphical applications and macOS system settings intentionally stay
  # host-managed during the first migration milestone.
}
