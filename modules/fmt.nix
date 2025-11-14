{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { self', lib, ... }:
    {
      treefmt = {
        programs = {
          # nix
          nixfmt.enable = true;
          deadnix.enable = true;
          nixf-diagnose.enable = true;

          just.enable = true;
          prettier.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
          yamlfmt.enable = true;
        };
        settings.on-unmatched = "fatal";
        settings.global.excludes = [
          "LICENSE"

          # config files
          ".editorconfig"
          ".yamlfmt"
        ];

        settings.formatter = {
          nixf-diagnose = { };
          prettier = {
            includes = [
              "*.md"
              "*.json"
            ];
            excludes = [
              "*.yml"
              "*.yaml"
            ];
          };

          yamlfmt.settings = {
            formatter.type = "basic";
            formatter.max_line_length = 120;
            formatter.indent = 4;
            formatter.trim_trailing_whitespace = true;
            formatter.scan_folded_as_literal = true;
            formatter.include_document_start = true;
          };
        };
      };

      packages.fmt = lib.mkDefault self'.formatter;
    };
}
