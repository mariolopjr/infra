# Firefox with configured policies: no telemetry, studies or Pocket, HTTPS-only, DuckDuckGo search, uBlock Origin.
{
  den.aspects.desktop.nixos = {
    programs.firefox = {
      enable = true;
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
    };
    preservation.preserveAt."/persist".users.mario.directories = [
      ".config/mozilla"
      ".mozilla"
    ];
  };
}
