# What a downstream flake imports: den setup, features and users, no hosts. Nothing in it may
# reference inputs.self or a host name: it evaluates with the consumer's inputs.
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];
  flake.flakeModules.default = {
    imports = [
      # Only flake-file's options, so the shared modules' flake-file.inputs resolve without its
      # write-flake packages and check-flake-file check. Deduped if the consumer imports flake-file.
      "${inputs.flake-file}/modules/options"
      (inputs.import-tree [
        ../den.nix
        ../features
        ../users
      ])
    ];
  };
}
