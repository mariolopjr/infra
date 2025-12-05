{ inputs, ... }:
{
  flake-file.inputs = {
    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";
  };

  infra.firefox = _: {
    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.betterfox.modules.homeManager.betterfox ];

        programs.firefox = {
          enable = true;

          betterfox = {
            enable = true;
            version = "main";

            profiles.default = {
              enableAllSections = true;

              settings = {
                securefox = {
                  enable = true;
                  tracking-protection."browser.download.start_downloads_in_tmp_dir".value = false;
                };
              };
            };
          };

          nativeMessagingHosts = [
            pkgs.kdePackages.plasma-browser-integration
          ];

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
              # auto-enable extensions and disable updates
              "extensions.autoDisableScopes" = 0;
              "extensions.update.autoUpdateDefault" = false;
              "extensions.update.enabled" = false;

              "signon.rememberSignons" = false; # Disable login manager

              # Disable address and credit card manager
              "extensions.formautofill.addresses.enabled" = false;
              "extensions.formautofill.creditCards.enabled" = false;

              # Enable DRM by default
              "browser.eme.ui.enabled" = true;
              "media.eme.enabled" = true;

              "browser.tabs.inTitlebar" = 0; # Remove close button

              # Vertical tabs
              "sidebar.verticalTabs" = true;
              "sidebar.visibility" = "expand-on-hover";
              "sidebar.revamp" = true;
              "sidebar.main.tools" = [
                "history"
                "bookmarks"
              ];
              "sidebar.notification.badge.aichat" = false;

              "browser.startup.page" = 3; # restore previous session

              "browser.tabs.closeWindowWithLastTab" = false;

              "browser.toolbarbuttons.introduced.sidebar-button" = false;
            };

            search = {
              force = true;
              default = "ddg";
              privateDefault = "ddg";
            };
          };
        };
      };
  };
}
