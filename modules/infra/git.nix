{ lib, ... }:
let
  allowedSigners = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLb9jN80JWeFl1DOHD0ZcKXrGzq/Oa/bbb5lGG64AW7
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHm/mGV1V29VjYYNp1Ug3zeEOlMVomP3CrG4eaNXF6Sk
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhF7/5agjGzrAiS7eOH+tY5GhqdLKqbCuvGwkbR0lyr
  '';

  ide = ''
    .session.nvim
  '';
  ignore = lib.concatStringsSep "\n" [ ide ];
in
{
  infra.git = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.delta = {
          enable = true;
          enableGitIntegration = true;
        };

        programs.lazygit = {
          enable = true;

          settings = {
            disableStartupPopups = true;
          };
        };

        programs.git = {
          enable = true;
          lfs.enable = true;

          ignores = map (v: "${toString v}") (builtins.split "\n" ignore);

          settings = {
            user.name = "Mario";
            user.email = "mariolopjr@users.noreply.github.com";
            # TODO: allow configuring this to 1Password
            user.signingkey = "~/.ssh/id_ed25519.pub";

            gpg.format = "ssh";
            gpg.ssh.allowedSignersFile = "${pkgs.writeText "allowed_signers" allowedSigners}";
            commit.gpgsign = true;
            tag.gpgsign = true;

            init.defaultBranch = "main";
            pull.rebase = true;
            push.autoSetupRemote = true;
          };
        };
      };
  };
}
