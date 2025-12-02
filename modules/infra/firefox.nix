{
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

            extensions = {
              packages = with pkgs.nur.repos.rycee.firefox-addons; [
                onepassword-password-manager
                plasma-integration
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
