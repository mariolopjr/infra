{ inputs, ... }:
{
  flake-file.inputs = {
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  infra.firefox = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.firefox = {
          enable = true;

          profiles.default = {
            id = 0;
            name = "default";
            isDefault = true;

            extensions =
              # let
              #   firefox-addons-unfree = pkgs.callPackage inputs.firefox-addons;
              # in
              {
                packages = with inputs.firefox-addons.packages.${pkgs.system}; [
                  # packages = with firefox-addons-unfree; [
                  # onepassword-password-manager
                  ublock-origin
                  vimium
                ];

                force = true;

                settings = {
                  "ublock0@raymondhill.net".settings = {
                    privateAllowed = true;
                    settings = {
                      selectedFilterLists = [
                        "user-filters"
                        "ublock-filters"
                        "ublock-badware"
                        "ublock-privacy"
                        "ublock-unbreak"
                        "ublock-quick-fixes"
                        "easylist"
                        "easyprivacy"
                        "urlhaus-1"
                        "plowe-0"
                      ];
                    };
                    permissions = [
                      "alarms"
                      "dns"
                      "menus"
                      "privacy"
                      "storage"
                      "tabs"
                      "unlimitedStorage"
                      "webNavigation"
                      "webRequest"
                      "webRequestBlocking"
                      "<all_urls>"
                      "http://*/*"
                      "https://*/*"
                      "file://*/*"
                    ];
                  };
                };
              };

            settings = {
              "extensions.autoDisableScopes" = 0;
              "extensions.update.autoUpdateDefault" = false;
              "extensions.update.enabled" = false;
            };
          };
        };
      };
  };
}
