{ config, pkgs-unstable, ... }:
{
  # Nix module(26.05) for paperless has a PAPERLESS_SECRET_KEY bug with v3,
  # So we cannot run paperless v3 under nixos 26.05 without magic.
  # There are 3 way to do:
  # 1. Return to paperless 2.20 under nixos 26.05
  # 2. Switch from nixos 26.05 to nixos unstable
  # 3. Replace native nix module with container under nixos 26.05
  # 4. Do some black magics...
  # Since the magics are black and dirty enough, I decide to fallback to paperless 2.20...
  # SeeAlso: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/misc/paperless.nix
  services.paperless = {
    enable = true;
    # under nixos 26.05, this module is always use a ${cfg.dataDir}/nixos-paperless-secret-key file.
    # next line is ready for paperless v3 and nixos 26.05+
    # environmentFile = config.sops.templates."paperless-secret-key".path;
    consumptionDirIsPublic = true;
    dataDir = "/mnt/data/lib/paperless";
    domain = "paperless.lifeym.xyz";
    # address = "127.0.0.1";
    # port = 28981;
    settings = {
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_OCR_LANGUAGE = "chi_sim+eng";
      PAPERLESS_OCR_LANGUAGES = [ "chi-sim" "eng" "chi-tra" "jpn" ];
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };
}
