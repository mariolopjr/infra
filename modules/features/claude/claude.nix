# Claude Code user config (moved from chezmoi). ~/.claude itself stays mutable: Claude writes
# projects/, plugins/ and settings.json there, so only individual files are linked.
{
  den.aspects.mario.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        tag = "v4.9.0";
        hash = "sha256-8cYggVltBAlZ/Zj4pl1bOu7mQdZFXCmDGW4RSpvRA+w=";
      };
      managed = pkgs.writeText "claude-settings.json" (builtins.toJSON config.claude.settings);
      plugins = pkgs.writeShellApplication {
        name = "claude-plugins";
        runtimeInputs = [
          pkgs.claude-code
          pkgs.git
          pkgs.jq
        ];
        text = builtins.readFile ./activate-plugins.sh;
      };
      settings = pkgs.writeShellApplication {
        name = "claude-settings";
        runtimeInputs = [ pkgs.jq ];
        text = builtins.readFile ./activate-settings.sh;
      };
    in
    {
      options.claude.settings = lib.mkOption {
        type = lib.types.attrs;
        description = "Top-level keys merged into ~/.claude/settings.json on activation.";
      };

      config = {
        # Hooks and scripts call these by name.
        home.packages = [
          pkgs.beans
          pkgs.ccusage
          pkgs.gh
          pkgs.jq
          pkgs.python3
        ];

        home.file =
          lib.genAttrs [ "CLAUDE.md" "keybindings.json" "statusline.sh" ] (f: {
            target = ".claude/${f}";
            source = ./${f};
          })
          //
            lib.genAttrs
              [
                "agents"
                "commands"
                "hooks"
                "scripts"
                "skills"
              ]
              (d: {
                target = ".claude/${d}";
                source = ./${d};
                recursive = true;
              })
          // {
            # hooks/ponytail.sh reads ~/.claude/ponytail/skills/ponytail/SKILL.md
            ".claude/ponytail/skills/ponytail/SKILL.md".source = "${ponytail}/skills/ponytail/SKILL.md";
            ".claude/ponytail/LICENSE".source = "${ponytail}/LICENSE";
            ".claude/skills/ponytail-review/SKILL.md".source = "${ponytail}/skills/ponytail-review/SKILL.md";
          };

        claude.settings = {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
          env = {
            CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS = "50";
            PONYTAIL_DEFAULT_MODE = "full";
            PONYTAIL_SUBAGENT_MATCHER = "^(?!(?:explore|plan|claude-code-guide|statusline-setup)$).";
          };
          attribution = {
            commit = "";
            pr = "";
            sessionUrl = false;
          };
          includeGitInstructions = false;
          outputStyle = "Concise";
          tui = "fullscreen";
          promptCacheTtl = "1h";
          cleanupPeriodDays = 365;
          autoCompactWindow = 300000;
          crossSessionInbound = "hold";
          preferredNotifChannel = "notifications_disabled";
          permissions = {
            defaultMode = "auto";
            allow = [
              "Read(//tmp/claude-*/**)"
              "Read(//private/tmp/claude-*/**)"
              "Edit(//tmp/claude-*/**)"
              "Edit(//private/tmp/claude-*/**)"
            ];
            deny = [
              "Read(**/.env*)"
              "Read(**/env.php*)"
              "Read(**/*.pem)"
              "Read(**/*.key)"
              "Read(**/secrets/**)"
              "Read(**/credentials/**)"
              "Read(**/.aws/**)"
              "Read(**/.ssh/**)"
              "Read(**/docker-compose*.yml)"
              "Read(**/config/database.yml)"
            ];
          };
          hooks = {
            SessionStart = [
              {
                matcher = "startup|resume|clear|compact";
                hooks = [
                  {
                    type = "command";
                    command = "~/.claude/hooks/ponytail.sh";
                    timeout = 5;
                    statusMessage = "Loading ponytail mode...";
                  }
                ];
              }
            ];
            SubagentStart = [
              {
                hooks = [
                  {
                    type = "command";
                    command = "~/.claude/hooks/ponytail.sh --subagent";
                    timeout = 5;
                    statusMessage = "Loading ponytail mode...";
                  }
                ];
              }
            ];
            PreToolUse = [
              {
                matcher = "Write";
                hooks = [
                  {
                    type = "command";
                    command = "~/.claude/hooks/rules-on-create.sh";
                    timeout = 10;
                    statusMessage = "Checking rules...";
                  }
                ];
              }
            ];
          };
          statusLine = {
            type = "command";
            command = "~/.claude/statusline.sh";
          };
          disableClaudeAiConnectors = true;
          skillOverrides = lib.genAttrs [
            "keybindings-help"
            "fewer-permission-prompts"
            "loop"
            "schedule"
            "workflow-authoring"
            "run"
            "init"
            "security-review"
            "claude-api"
            "dataviz"
            "update-config"
          ] (_: "user-invocable-only");
          enabledPlugins = {
            "lua-lsp@claude-plugins-official" = false;
            "rust-analyzer-lsp@claude-plugins-official" = false;
            "skill-creator@claude-plugins-official" = true;
            "clangd-lsp@claude-plugins-official" = false;
            "frontend-design@claude-plugins-official" = false;
            "gopls-lsp@claude-plugins-official" = false;
            "modern-go-guidelines@goland-claude-marketplace" = false;
            "superpowers@claude-plugins-official" = false;
            "csharp-lsp@claude-plugins-official" = true;
            "typescript-lsp@claude-plugins-official" = false;
            "swift-lsp@claude-plugins-official" = false;
          };
          extraKnownMarketplaces = {
            goland-claude-marketplace.source = {
              source = "github";
              repo = "JetBrains/go-modern-guidelines";
            };
          };
        };

        # Claude rewrites settings.json at runtime, so it stays a plain file: managed keys
        # replace the same top-level keys, everything else Claude wrote is kept.
        home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe settings} ${managed}
        '';

        # Network-bound, so a failure (offline, marketplace down) only warns. Reruns when the
        # managed settings change, like chezmoi's run_onchange.
        home.activation.claudePlugins = lib.hm.dag.entryAfter [ "claudeSettings" ] ''
          stamp=${lib.escapeShellArg "${config.xdg.stateHome}/claude-plugins"}
          if [ "$(cat "$stamp" 2>/dev/null)" != ${managed} ]; then
            run ${lib.getExe plugins} ${managed} "$stamp" ||
              echo "claude: plugin install incomplete, retried on next activation" >&2
          fi
        '';
      };
    };
}
