# A NixOS module applying cfg only where the preservation module is imported
# (den.aspects.preservation), so shared aspects also evaluate on a persistent root.
# `config =` keeps the module's attribute names fixed; shorthand would recurse on `options`.
cfg:
{ lib, options, ... }:
{
  config = lib.optionalAttrs (options ? preservation) cfg;
}
