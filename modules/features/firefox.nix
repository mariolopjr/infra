# Firefox with configured settings
let
  policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DontCheckDefaultBrowser = true;
    HttpsOnlyMode = "enabled";
    SearchEngines.Default = "DuckDuckGo";
    FirefoxHome = {
      SponsoredTopSites = false;
      SponsoredPocket = false;
      Pocket = false;
    };
    ExtensionSettings."uBlock0@raymondhill.net" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    };
  };
in
{
  den.aspects.workstation = {
    nixos = {
      programs.firefox = {
        enable = true;
        inherit policies;
      };
      preservation.preserveAt."/persist".users.mario.directories = [
        ".config/mozilla"
        ".mozilla"
      ];
    };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = [ (pkgs.firefox.override { extraPolicies = policies; }) ];
      };
  };
}
