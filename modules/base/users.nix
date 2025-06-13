# All my machines has a user named lifeym
# Put shared user configuration here for easy management
{
  users.users.lifeym = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSxBPvzOWFPojjiJORyVpVHsH38FonOvlLCmcmV2+iY leonardo_yu@hotmail.com"
    ];
  };
}
