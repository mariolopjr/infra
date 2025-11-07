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
          nixf-diagnose = {
            # Ensure nixfmt cleans up after nixf-diagnose.
            priority = -1;
            options = [
              "--auto-fix"
              # Rule names can currently be looked up here:
              # https://github.com/nix-community/nixd/blob/main/libnixf/src/Basic/diagnostic.py
              # TODO: Remove the following and fix things.
              "--ignore=sema-unused-def-lambda-noarg-formal"
              "--ignore=sema-unused-def-lambda-witharg-arg"
              "--ignore=sema-unused-def-lambda-witharg-formal"
              "--ignore=sema-unused-def-let"
            ];
          };
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
