{ den, ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn dragonstone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaGF5WxANyrUZqR65w31DvRzK6n9IaGCjpIT3kxozaV winterfell"
  ];
  # login only
  phoneKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBImMg0zbBLjw6D9UBA7LHvtPX8PqJs3tYaMkWreh+vLgQlJS5f3Mwaw43nRxJ17TV/yRs+MgdN9qknmRrkgevr0= rex@iPhone"
  ];
in
{
  # Every host's slim home; hosts add den.aspects.dev for the heavier one.
  den.aspects.mario = {
    includes = with den.aspects; [
      den.batteries.define-user
      den.batteries.primary-user
      shell
      git
      lazygit
      neovim
    ];

    homeManager =
      { lib, ... }:
      {
        # git gpg.ssh.allowedSignersFile
        home.file.".ssh/allowed_signers".text = lib.concatMapStrings (k: "* ${k}\n") sshKeys;
        # Intermediate build artifacts per workspace under ~/.cargo
        home.file.".cargo/config.toml".text = ''
          [build]
          build-dir = "{cargo-cache-home}/build/{workspace-path-hash}"
        '';
        programs.nushell.shellAliases.rebuild = "just -f ~/.config/infra/justfile rebuild";
      };
  };

  # Personal hosts include it; a downstream flake sharing this user brings its own keys.
  den.aspects.mario-keys.os.users.users.mario.openssh.authorizedKeys.keys = sshKeys ++ phoneKeys;
}
