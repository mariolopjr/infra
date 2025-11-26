{
  infra.cli = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.bat # cat
          pkgs.bottom
          pkgs.curl
          pkgs.devenv
          pkgs.eza # ls
          pkgs.fd # find
          pkgs.htop
          pkgs.jq
          pkgs.ripgrep # grep
          pkgs.unzip
          pkgs.zip
          pkgs.zoxide # z
        ];
      };
  };
}
