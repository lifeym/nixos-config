{ config, pkgs-unstable, ... }:
{
  services.paperless = {
    enable = true;
    environmentFile = config.sops.templates."paperless-secret-key".path;
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
      PAPERLESS_OCR_LANGUAGES = [ "chi_sim" "eng" "chi_tra" "jpn" ];
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };

    package = pkgs-unstable.paperless-ngx;
  };
}
