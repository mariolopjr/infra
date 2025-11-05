{
  infra.cli = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.bat # cat
          pkgs.bottom
          pkgs.devenv
          pkgs.eza # ls
          pkgs.fd # find
          pkgs.fzf
          pkgs.htop
          pkgs.jq
          pkgs.ripgrep # grep
        ];
      };
  };
}
