{ config
, pkgs
, lib
, ...
}:
let
  # Fall back to "glats" when imported standalone (no omarchy config)
  cfg = config.omarchy or { };
  themeName = if cfg ? theme && cfg.theme != null then cfg.theme else "glats";
  palette = config.colorScheme.palette;
in
{
  home.file = {
    ".config/btop/themes/${themeName}.theme" = {
      text = ''
        # Glats custom theme for btop

        theme[main_bg]="#${palette.base00}"
        theme[main_fg]="#${palette.base05}"
        theme[title]="#${palette.base07}"
        theme[hi_fg]="#${palette.base0D}"
        theme[selected_bg]="#${palette.base02}"
        theme[selected_fg]="#${palette.base07}"
        theme[inactive_fg]="#${palette.base03}"
        theme[graph_text]="#${palette.base04}"
        theme[proc_misc]="#${palette.base04}"
        theme[cpu_box]="#${palette.base0B}"
        theme[mem_box]="#${palette.base09}"
        theme[net_box]="#${palette.base0E}"
        theme[proc_box]="#${palette.base0C}"
        theme[div_line]="#${palette.base02}"
        theme[temp_start]="#${palette.base0B}"
        theme[temp_mid]="#${palette.base0A}"
        theme[temp_end]="#${palette.base08}"
        theme[cpu_start]="#${palette.base0B}"
        theme[cpu_mid]="#${palette.base0A}"
        theme[cpu_end]="#${palette.base08}"
        theme[free_start]="#${palette.base0B}"
        theme[free_mid]="#${palette.base0A}"
        theme[free_end]="#${palette.base08}"
        theme[cached_start]="#${palette.base0C}"
        theme[cached_mid]="#${palette.base0D}"
        theme[cached_end]="#${palette.base0E}"
        theme[available_start]="#${palette.base0B}"
        theme[available_mid]="#${palette.base0A}"
        theme[available_end]="#${palette.base08}"
        theme[used_start]="#${palette.base08}"
        theme[used_mid]="#${palette.base09}"
        theme[used_end]="#${palette.base0A}"
        theme[download_start]="#${palette.base0E}"
        theme[download_mid]="#${palette.base0D}"
        theme[download_end]="#${palette.base0C}"
        theme[upload_start]="#${palette.base0E}"
        theme[upload_mid]="#${palette.base0D}"
        theme[upload_end]="#${palette.base0C}"
        theme[process_start]="#${palette.base0B}"
        theme[process_mid]="#${palette.base0A}"
        theme[process_end]="#${palette.base08}"
      '';
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = themeName;
      theme_background = true;
      truecolor = true;
      force_tty = false;
      disable_presets = "Off";
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      vim_keys = false;
      disable_mouse = false;
      rounded_corners = true;
      terminal_sync = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_gpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "cpu gpu mem net proc";
      update_ms = 200;
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;
      proc_follow_detailed = true;
      proc_aggregate = false;
      keep_dead_proc_usage = false;
      cpu_graph_upper = "Auto";
      cpu_graph_lower = "Auto";
      show_gpu_info = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      cpu_core_map = "";
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      freq_mode = "first";
      clock_format = "%X";
      background_update = true;
      custom_cpu_name = "";
      disks_filter = "";
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      io_graph_speeds = "";
      swap_upload_download = false;
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      net_iface = "";
      base_10_bitrate = "Auto";
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;
      log_level = "WARNING";
      save_config_on_exit = false;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
      shown_gpus = "nvidia amd intel";
      custom_gpu_name0 = "";
      custom_gpu_name1 = "";
      custom_gpu_name2 = "";
      custom_gpu_name3 = "";
      custom_gpu_name4 = "";
      custom_gpu_name5 = "";
    };
  };
}
