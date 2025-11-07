{
  infra.documentation.nixos = {
    # https://mastodon.online/@nomeata/109915786344697931
    # Excerpt:
    # TIL that NixOS by default installs nixos’s own guide, and that
    # that’s derivation depends on the full `nixos/` source directory.
    # So even unrelated changes to some nix code there will cause a
    # rebuild of my system. But with
    #
    # documentation.nixos.enable = false;
    #
    # out of the last 39 commits on release-22.11, only 2 change my
    # server’s configuration derivation, instead of 7 otherwise. #nix
    documentation = {
      enable = false;
      doc.enable = false;
      info.enable = false;
    };
  };
}
