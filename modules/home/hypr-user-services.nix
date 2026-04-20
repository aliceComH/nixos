{ pkgs, ... }:

{
  systemd.user.services = {
    hypr-gaming-monitor = {
      Unit = {
        Description = "Hyprland gaming submap monitor";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash %h/.config/hypr/hyprland/scripts/gaming_monitor.sh";
        Restart = "always";
        RestartSec = 1;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypr-mic-gain-loop = {
      Unit = {
        Description = "Keep microphone gain fixed";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash %h/.config/hypr/hyprland/scripts/mic-gain-loop.sh";
        Restart = "always";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypr-opentabletdriver-autostart = {
      Unit = {
        Description = "Start opentabletdriver user service at session start";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.systemd}/bin/systemctl --user start opentabletdriver.service || true'";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
