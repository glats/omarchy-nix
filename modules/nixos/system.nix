inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omarchy;
  packages = import ../packages.nix { inherit pkgs config lib; };

  # wayvnc config file for the greeter session. Built lazily — only
  # realized when omarchy.greeter.wayvnc.enable = true pulls it into
  # the tmpfiles rule below. Content is key=value per line, the format
  # wayvnc expects.
  wayvncConfigFile = pkgs.writeText "wayvnc-greeter-config" (
    lib.concatStringsSep "\n" [
      "address=${cfg.greeter.wayvnc.address}"
      "port=${toString cfg.greeter.wayvnc.port}"
      "enable_pam=${if cfg.greeter.wayvnc.enable_pam then "true" else "false"}"
    ]
  );

  # ── Greeter layout indicator (waybar-based keyboard layout display) ──
  # Polls hyprctl every 1s to show "ES"/"LATAM" on a 24px bottom bar.
  # Gated on cfg.greeter.layoutIndicator.enable; break all paths with
  # full store references so no PATH dependency is needed.
  layoutIndicatorScript = pkgs.writeShellScriptBin "greetd-kb-layout" ''
    ACTIVE=$(${pkgs.hyprland}/bin/hyprctl devices -j 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.keyboards[] | select(.main) | .active_keymap' 2>/dev/null)
    case "$ACTIVE" in
      *Spanish*) echo "ES" ;;
      *Latino*|*Latin*) echo "LATAM" ;;
      *) echo "?" ;;
    esac
  '';

  waybarGreeterConfig = pkgs.writeText "waybar-greeter-config" (
    builtins.toJSON {
      layer = "overlay";
      position = "top";
      height = 24;
      modules-left = [ ];
      modules-center = [ ];
      modules-right = [ "custom/kb-layout" ];
      "custom/kb-layout" = {
        exec = "${layoutIndicatorScript}/bin/greetd-kb-layout";
        interval = 1;
        format = "{}";
        tooltip = false;
      };
    }
  );

  waybarGreeterStyle = pkgs.writeText "waybar-greeter-style" ''
    * { font-family: sans-serif; font-size: 14px; color: #cdd6f4; }
    window#waybar { background: rgba(30, 30, 46, 0.9); }
    #custom-kb-layout { padding: 0 12px; font-weight: bold; }
    ${cfg.greeter.layoutIndicator.style}
  '';

  elephantPkg = inputs.elephant.packages.${pkgs.stdenv.hostPlatform.system}.elephant;

  providersPkg = inputs.elephant.packages.${pkgs.stdenv.hostPlatform.system}.elephant-providers;

  elephantCombined = pkgs.stdenv.mkDerivation {
    pname = "elephant-with-providers";
    version = "2.17.2-patched";
    dontUnpack = true;

    buildInputs = [
      elephantPkg
      providersPkg
    ];

    nativeBuildInputs = with pkgs; [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin $out/lib/elephant
      cp ${elephantPkg}/bin/elephant $out/bin/
      cp -r ${providersPkg}/lib/elephant/providers $out/lib/elephant/
    '';

    postFixup = ''
      wrapProgram $out/bin/elephant \
        --prefix PATH : ${
          pkgs.lib.makeBinPath (
            with pkgs;
            [
              bash # Required for executing desktop entries (sh command)
              wl-clipboard
              libqalculate
              imagemagick
              bluez
            ]
          )
        } \
        --suffix PATH : /run/current-system/sw/bin:/etc/profiles/per-user/${cfg.username}/bin:/run/wrappers/bin
    '';
  };
in
{
  # Create /bin/bash symlink for Omarchy script compatibility.
  # When greeter wayvnc is enabled, also deploy the wayvnc config
  # file (and its parent directories) into the greeter user's home so
  # the greeter Hyprland session can launch wayvnc with the configured
  # address/port/PAM settings. The `+` prefix on the `f` rule tells
  # systemd-tmpfiles to copy the contents of the source derivation
  # into the target file, preserving newlines in the wayvnc config.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ]
  ++ lib.optionals cfg.greeter.wayvnc.enable [
    "d /var/lib/greeter/.config 0750 greeter greeter - -"
    "d /var/lib/greeter/.config/wayvnc 0750 greeter greeter - -"
    "C+ /var/lib/greeter/.config/wayvnc/config 0640 greeter greeter - ${wayvncConfigFile}"
  ];

  security.rtkit.enable = true;

  # PAM configuration for hyprlock (required for authentication)
  security.pam.services.hyprlock = { };

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Seamless boot and login experience
  boot = lib.mkIf cfg.seamless_boot.enable {
    # Plymouth boot splash
    plymouth = {
      enable = true;
      theme = cfg.seamless_boot.plymouth_theme;
      themePackages = packages.plymouthThemes;
    };

    # Silent boot configuration
    consoleLogLevel = lib.mkIf cfg.seamless_boot.silent_boot 3;
    initrd.verbose = lib.mkIf cfg.seamless_boot.silent_boot false;
    kernelParams = lib.mkIf cfg.seamless_boot.silent_boot [
      "quiet"
      "splash"
      "loglevel=3"
      "systemd.show_status=auto"
      "udev.log_priority=3"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
    ];
  };

  # UWSM integration for Hyprland
  # Decoupled from `omarchy.seamless_boot.enable` so that omarchy userland
  # scripts (omarchy-launch-walker, omarchy-toggle-*, omarchy-restart-app,
  # etc.) can always invoke `uwsm-app` to start GUI daemons as detached
  # children of the session, even when the host uses a traditional login
  # manager (tuigreet) and does not enable Plymouth/auto-login.
  programs.uwsm.enable = true;

  # Login configuration.
  #
  # Escape hatch: if the Hyprland/ReGreet greeter ever fails to start and
  # the user is locked out, append `systemd.mask=greetd.service` to the
  # kernel command line at the bootloader to skip greetd entirely and
  # fall back to a VT login prompt. The console keymap (omarchy.tty) is
  # preserved untouched, so the VT login still has a working keyboard.
  services.greetd =
    let
      # Use seamless_boot.username if set, otherwise fall back to main username
      loginUser = if cfg.seamless_boot.username != null then cfg.seamless_boot.username else cfg.username;
    in
    {
      enable = true;
      settings = lib.mkMerge [
        # Seamless auto-login when enabled
        (lib.mkIf cfg.seamless_boot.enable {
          initial_session = {
            command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
            user = loginUser;
          };
          default_session = {
            command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
            user = loginUser;
          };
        })
        # TUI greeter (default when seamless_boot is disabled)
        (lib.mkIf (!cfg.seamless_boot.enable && cfg.greeter.type == "tuigreet") {
          default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop'";
        })
        # ReGreet (GTK) inside a minimal Hyprland session — exposes the
        # keyboard layout toggle at the login screen. `lib.mkForce` overrides
        # the `cage` default_session that `programs.regreet.enable` would
        # otherwise install via its own `lib.mkDefault`.
        (lib.mkIf (!cfg.seamless_boot.enable && cfg.greeter.type == "regreet") {
          default_session = {
            command = lib.mkForce "${pkgs.hyprland}/bin/start-hyprland -- --config /etc/greetd/hyprland.conf";
            user = "greeter";
          };
        })
      ];
    };

  # ReGreet: enable the module (package, GTK theme hooks, config helpers).
  # Its built-in cage default_session is overridden above via `lib.mkForce`.
  programs.regreet.enable = lib.mkIf (cfg.greeter.type == "regreet") true;

  # Dark theme matching Nautilus (libadwaita) look.
  programs.regreet.settings = lib.mkIf (cfg.greeter.type == "regreet") {
    GTK = {
      application_prefer_dark_theme = true;
    };
  };

  # ReGreet refuses to run as root; create a dedicated non-root user.
  # `video` membership is required for Hyprland KMS access in the greeter
  # session.
  users.users.greeter = lib.mkIf (cfg.greeter.type == "regreet") {
    isSystemUser = true;
    group = "greeter";
    extraGroups = [ "video" ];
    home = "/var/lib/greeter";
    createHome = true;
  };
  users.groups.greeter = lib.mkIf (cfg.greeter.type == "regreet") { };

  # Greeter Hyprland config: launch ReGreet, then exit. Keyboard layout
  # and XKB options come from `omarchy.greeter.keyboard.*` so the user's
  # Alt+Shift toggle works at the password prompt.
  environment.etc."greetd/hyprland.conf".text = lib.mkIf (cfg.greeter.type == "regreet") (
    let
      greeterScript = pkgs.writeShellScriptBin "greetd-regreet-start" ''
        ${lib.optionalString cfg.greeter.layoutIndicator.enable ''
          # ── Phase 0: wait for waybar layer-shell surface to map ─────
          sleep 0.5
        ''}
        # ── Phase 1: monitor selection ──────────────────────────────
        # Logs to stderr (captured by Hyprland/greetd journal). 2s budget
        # (20 × 100ms) for Hyprland monitor enumeration — up from the old
        # 1s (10 × 100ms) which occasionally raced on cold boot.
        FOCUS='${cfg.greeter.focusMonitor}'

        if [ -n "$FOCUS" ]; then
          enumerated=0
          for _ in $(seq 1 20); do
            if ${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null \
              | ${pkgs.jq}/bin/jq -e 'length > 0' >/dev/null 2>&1; then
              enumerated=1
              break
            fi
            sleep 0.1
          done
          if [ "$enumerated" -eq 0 ]; then
            echo "[greetd-regreet-start] WARNING: monitor enumeration timed out after 2s" >&2
          fi

          # Match the target monitor by description substring.
          TARGET_MON=$(${pkgs.hyprland}/bin/hyprctl monitors all -j 2>/dev/null \
            | ${pkgs.jq}/bin/jq -r --arg d "$FOCUS" \
              '.[] | select((.description // "") | contains($d)) | .name' \
            | head -1)

          if [ -n "$TARGET_MON" ] && [ "$TARGET_MON" != "null" ]; then
            echo "[greetd-regreet-start] focusing monitor: $TARGET_MON" >&2
            # Disable every external monitor except the target.
            for m in $(${pkgs.hyprland}/bin/hyprctl monitors all -j 2>/dev/null \
              | ${pkgs.jq}/bin/jq -r '.[].name'); do
              case "$m" in
                eDP-*) ;;
                "$TARGET_MON") ;;
                *) ${pkgs.hyprland}/bin/hyprctl keyword monitor "$m,disable" >/dev/null 2>&1 ;;
              esac
            done
            ${pkgs.hyprland}/bin/hyprctl dispatch focusmonitor "$TARGET_MON" >/dev/null 2>&1
          else
            echo "[greetd-regreet-start] WARNING: no monitor matched focus '$FOCUS'" >&2
          fi
        fi

        # ── Phase 2: internal panel disable ─────────────────────────
        echo "[greetd-regreet-start] checking external displays" >&2
        for s in /sys/class/drm/card*-*/status; do
          case "$s" in *-eDP-*) continue;; esac
          read -r st < "$s" 2>/dev/null
          if [ "$st" = connected ]; then
            echo "[greetd-regreet-start] external display connected; disabling eDP-1" >&2
            ${pkgs.hyprland}/bin/hyprctl keyword monitor eDP-1,disable
            break
          fi
        done
        echo "[greetd-regreet-start] panel disable done" >&2

        # ── Phase 3: launch greeter ─────────────────────────────────
        echo "[greetd-regreet-start] launching regreet" >&2
        ${pkgs.regreet}/bin/regreet
        ${pkgs.hyprland}/bin/hyprctl dispatch exit
      '';
      monitorBlock = lib.optionalString (cfg.greeter.monitors != [ ]) (
        lib.concatMapStrings (m: "monitor = ${m}\n") cfg.greeter.monitors
      );
      cursorEnv = lib.optionalString (cfg.greeter.cursor.theme != "") ''
        env = XCURSOR_THEME,${cfg.greeter.cursor.theme}
        env = HYPRCURSOR_THEME,${cfg.greeter.cursor.theme}
        env = XCURSOR_SIZE,${toString cfg.greeter.cursor.size}
        env = HYPRCURSOR_SIZE,${toString cfg.greeter.cursor.size}
      '';
      inputBlock = lib.optionalString (cfg.greeter.keyboard.layouts != [ ]) ''
        input {
            kb_layout = ${lib.concatStringsSep "," cfg.greeter.keyboard.layouts}
            kb_options = ${cfg.greeter.keyboard.options}
        }
      '';
      # wayvnc must launch BEFORE greetd-regreet-start so that the
      # backgrounded VNC server is already listening when regreet comes
      # up. Both are exec-once (run once at Hyprland startup); wayvnc
      # is backgrounded with `&` so a slow start cannot block regreet.
      wayvncOutputFlag = lib.optionalString (cfg.greeter.wayvnc.output != "") (
        "-o " + cfg.greeter.wayvnc.output + " "
      );
      wayvncExec = lib.optionalString cfg.greeter.wayvnc.enable "exec-once = ${pkgs.wayvnc}/bin/wayvnc ${wayvncOutputFlag}${cfg.greeter.wayvnc.address} ${toString cfg.greeter.wayvnc.port} &\n";
      gtkPortalEnv = lib.optionalString cfg.greeter.layoutIndicator.enable "env = GTK_USE_PORTAL,0\n";
      waybarExec = lib.optionalString cfg.greeter.layoutIndicator.enable "exec-once = ${pkgs.waybar}/bin/waybar -c /etc/greetd/waybar-config -s /etc/greetd/waybar-style.css\n";
    in
    ''
      ${gtkPortalEnv}${waybarExec}${monitorBlock}${cursorEnv}${wayvncExec}exec-once = ${greeterScript}/bin/greetd-regreet-start
      ${inputBlock}
      misc {
          disable_hyprland_logo = true
          disable_splash_rendering = true
          disable_hyprland_guiutils_check = true
      }
    ''
  );

  # Greeter waybar config files — deployed on /etc/greetd/ for the greeter
  # Hyprland session. Gated on both regreet being the active greeter type
  # AND the layoutIndicator submodule being enabled.
  environment.etc."greetd/waybar-config".source = lib.mkIf (
    cfg.greeter.type == "regreet" && cfg.greeter.layoutIndicator.enable
  ) waybarGreeterConfig;

  environment.etc."greetd/waybar-style.css".source = lib.mkIf (
    cfg.greeter.type == "regreet" && cfg.greeter.layoutIndicator.enable
  ) waybarGreeterStyle;

  # Binary cache for Walker (speeds up builds)
  nix.settings = {
    extra-substituters = [
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
    ];
    extra-trusted-public-keys = [
      "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
    ];
  };

  # Install packages
  environment.systemPackages = packages.systemPackages ++ [
    inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default
    elephantCombined
  ];
  programs.direnv.enable = true;

  # nix-ld for running unpatched binaries (e.g., Python venvs with native deps)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc ];

  # Set ELEPHANT_PROVIDER_DIR globally so walker can find providers when running elephant listproviders
  environment.sessionVariables = {
    ELEPHANT_PROVIDER_DIR = "${elephantCombined}/lib/elephant/providers";
    OMARCHY_PATH = "$HOME/.local/share/omarchy";
    # Set PATH as a list (not a string) so consumers can extend it with
    # mkBefore/mkAfter without string-concatenation pitfalls. Order:
    # omarchy user scripts → nix user profiles → per-user profile → system
    # profile → current-system sw (last wins on duplicates).
    PATH = [
      "/home/${cfg.username}/.local/share/omarchy/bin"
      "/home/${cfg.username}/.nix-profile/bin"
      "/nix/profile/bin"
      "/home/${cfg.username}/.local/state/nix/profile/bin"
      "/etc/profiles/per-user/${cfg.username}/bin"
      "/nix/var/nix/profiles/default/bin"
      "/run/current-system/sw/bin"
    ];
  };

  # Raise soft fd limit (omarchy install/config/increase-fd-limit.sh equivalent)
  systemd.settings.Manager.DefaultLimitNOFILESoft = 65536;

  # Elephant systemd service
  systemd.user.services.elephant = {
    description = "Elephant launcher backend";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${elephantCombined}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 3;
    };
    environment = {
      ELEPHANT_PROVIDER_DIR = "${elephantCombined}/lib/elephant/providers";
    };
  };

  # Network service discovery and file manager network browsing
  # (Arch provides these implicitly with most desktop setups)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    browseDomains = [ "local" ];
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  services.gvfs.enable = true;

  # Printing support (CUPS stack - matches Omarchy's cups/cups-browsed/cups-filters/cups-pdf)
  services.printing = {
    enable = true;
    browsing = true;
  };

  # Power management profiles (performance/balanced/power-saver)
  services.power-profiles-daemon.enable = true;

  # Credential storage for apps (gnome-keyring)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Networking
  services.resolved.enable = true;
  hardware.bluetooth.enable = true;

  # iwd is always available (required by impala TUI and omarchy app launchers)
  networking.wireless.iwd.enable = true;

  networking = {
    networkmanager = {
      enable = true;

      # wifi.backend = "nm-iwd": NM manages WiFi through iwd backend.
      #   NM registers as iwd's D-Bus netconfig agent. Use standard
      #   desktop WiFi controls (nm-applet, nmtui).
      # wifi.backend = "standalone-iwd": iwd runs independently for WiFi.
      #   NM ignores wlan0. impala/iwctl talk directly to iwd. iwd
      #   handles its own DHCP and DNS via systemd-resolved.
      wifi.backend = lib.mkIf (cfg.wifi.backend != "standalone-iwd") "iwd";
      unmanaged = lib.mkIf (cfg.wifi.backend == "standalone-iwd") [ "interface-name:wlan0" ];
    };
  };

  # Prevent NixOS from enabling wpa_supplicant when NM uses default backend
  # (standalone-iwd mode). The NM module sets wireless.enable = true for
  # wpa_supplicant, which conflicts with iwd's assertion. We force it off.
  networking.wireless.enable = lib.mkIf (cfg.wifi.backend == "standalone-iwd") (lib.mkForce false);

  # iwd standalone mode: enable iwd's built-in DHCP and DNS integration
  # with systemd-resolved (NM's netconfig agent is not registered).
  networking.wireless.iwd.settings = lib.mkIf (cfg.wifi.backend == "standalone-iwd") {
    General.EnableNetworkConfiguration = true;
    Network.NameResolvingService = "systemd";
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono

    # Omarchy icon font (U+E900 logo glyph) — required at system level so
    # fontconfig picks it up for waybar, walker, and other system services.
    (pkgs.stdenvNoCC.mkDerivation {
      name = "omarchy-font";
      src = ../../config;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp $src/omarchy.ttf $out/share/fonts/truetype/omarchy.ttf
      '';
    })
  ];
}
