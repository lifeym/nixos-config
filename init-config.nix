{
  config,
  pkgs,
  ...
}:
let
  proxyCfg = {
    httpProxy = "http://192.168.0.6:10809";
    port = 10809;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };
in
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
  };

  networking = {
    # Configure network proxy if necessary
    proxy.default = proxyCfg.httpProxy;
    proxy.noProxy = proxyCfg.noProxy; #"localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    gnumake
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  ];

  environment.variables = {
    EDITOR = "vim";
    XDG_CONFIG_HOME = "$HOME/.config";
  };
}
