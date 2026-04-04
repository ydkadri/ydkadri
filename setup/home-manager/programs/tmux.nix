{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Use zsh as the default shell
    shell = "${pkgs.zsh}/bin/zsh";

    # Prefix key (keeping default Ctrl+B)
    prefix = "C-b";

    # Start window and pane numbering at 0 (default)
    baseIndex = 0;

    # Use 256 colors
    terminal = "screen-256color";

    # Increase scrollback buffer
    historyLimit = 50000;

    # Enable mouse support
    mouse = true;

    # Reduce escape time (faster vim)
    escapeTime = 10;

    # Use vim keybindings in copy mode
    keyMode = "vi";

    # Custom key bindings
    extraConfig = ''
      # === True color support ===
      set -ga terminal-overrides ",xterm-256color:Tc"

      # === Focus events for vim ===
      set -g focus-events on

      # === Renumber windows when one is closed ===
      set -g renumber-windows on

      # === Vim-like pane navigation ===
      # Use hjkl to navigate between panes
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # === Vim-like pane resizing ===
      # Hold prefix and use HJKL to resize panes
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # === Split panes with current directory ===
      # New panes inherit the directory of current pane
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # === Better split pane bindings ===
      # | and - are more intuitive for splits
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # === Reload config ===
      # Quickly reload tmux config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # === Copy mode improvements ===
      # v to begin selection, y to yank (like vim)
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # Make copying to clipboard work on macOS
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

      # === Status bar ===
      # Position at top
      set -g status-position top

      # Status bar styling
      set -g status-style bg=colour235,fg=colour255
      set -g status-left-length 40
      set -g status-left '#[fg=colour255,bold] #S #[default]'
      set -g status-right '#[fg=colour255] %H:%M %d-%b-%y '

      # Window status styling
      setw -g window-status-format ' #I:#W '
      setw -g window-status-current-format '#[fg=colour0,bg=colour255,bold] #I:#W '

      # Pane border styling
      set -g pane-border-style fg=colour240
      set -g pane-active-border-style fg=colour255

      # === Activity monitoring ===
      # Highlight windows with activity (but don't show notifications)
      setw -g monitor-activity on
      set -g visual-activity off

      # === sesh integration ===
      # Bind Ctrl+B T for sesh project switcher
      # This will be enabled once sesh is installed via manual/install.sh
      bind-key "T" run-shell "sesh connect \"$(
        sesh list | fzf-tmux -p 55%,60% \
          --no-sort --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
      )\""
    '';

    # Tmux plugins via Tmux Plugin Manager (TPM)
    # Uncomment to enable useful plugins:
    plugins = with pkgs.tmuxPlugins; [
      # Sensible default settings
      sensible

      # Better status bar
      # {
      #   plugin = catppuccin;
      #   extraConfig = ''
      #     set -g @catppuccin_flavour 'mocha'
      #   '';
      # }

      # Persist tmux sessions across reboots
      # {
      #   plugin = resurrect;
      #   extraConfig = ''
      #     set -g @resurrect-strategy-nvim 'session'
      #     set -g @resurrect-capture-pane-contents 'on'
      #   '';
      # }

      # Auto-save/restore sessions
      # {
      #   plugin = continuum;
      #   extraConfig = ''
      #     set -g @continuum-restore 'on'
      #     set -g @continuum-save-interval '15'
      #   '';
      # }

      # Easy copying to system clipboard
      yank
    ];
  };
}
