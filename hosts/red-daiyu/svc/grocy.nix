{ config, pkgs, lib, ... }:
let
  c = import ../consts.nix;
in
{
  services.grocy = {
    enable = true;

    dataDir = "${c.statePath}grocy";
    # 必须填一个 hostname，模块会据此生成 nginx virtualHost。
    # 这里填你反代用的内部名即可，不要求真实 DNS；
    # 如果你反代用的是别的 server_name，把下面的 grocy.internal 改成一致。
    hostName = "grocy.lifeym.xyz";

    # 本地化与货币（按需修改）
    settings = {
      culture = "zh_CN";      # 中文界面；可选 en / de / ja 等
      currency = "CNY";        # ISO 4217 货币代码
      calendar = {
        showWeekNumber = false;
        firstDayOfWeek = 1;    # 1 = 周一
      };
    };

    nginx.enableSSL = false;

    # 可选：关闭不需要的功能开关（grocy v4.x 起支持）
    # extraConfig = ''
    #   Setting('FEATURE_FLAG_RECIPES', false);
    #   Setting('FEATURE_FLAG_STOCK_PRODUCT_FREEZING', false);
    # '';
  };
}
