{ config, pkgs, ... }:

let
  # Import user configuration
  userConfig = import ../user-config.nix;
in
{
  programs.git = {
    enable = true;

    # All settings now go under 'settings'
    settings = {
      # User identity (from user-config.nix)
      user = {
        name = userConfig.gitName;
        email = userConfig.gitEmail;
      };

      # Editor
      core = {
        editor = "nvim";
      };

      # Push/Pull behavior
      push = {
        default = "current";
      };
      pull = {
        rebase = true;
      };

      # Rebase settings
      rebase = {
        autosquash = true;
      };

      # Better merge conflict markers
      # zdiff3 shows common ancestor in conflicts, making them easier to resolve
      merge = {
        conflictstyle = "zdiff3";
      };

      # Remember conflict resolutions (helpful when rebasing)
      rerere = {
        enabled = true;
      };

      # Default branch name
      init = {
        defaultBranch = "main";
      };

      # Fetch settings
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Better diff algorithm - produces more intuitive diffs
      diff = {
        algorithm = "histogram";
        tool = "difftastic";
        # Highlight whitespace errors
        wsErrorHighlight = "all";
        submodule = "log";
      };

      # Difftool settings
      difftool = {
        prompt = false;
      };
      "difftool \"difftastic\"" = {
        cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      };

      # Pager settings
      pager = {
        difftool = true;
      };

      # Show submodule changes in status/diff
      status = {
        submodulesummary = true;
      };

      # Use SSH instead of HTTPS for GitHub
      "url \"git@github.com:\"" = {
        insteadOf = "https://github.com/";
      };

      # Commit template (if you want a custom commit message template)
      # commit = {
      #   template = "${config.home.homeDirectory}/.config/git/commit-template.txt";
      # };

      # Git aliases
      alias = {
      # Basic shortcuts
      br = "branch";
      brv = "branch -v";
      cl = "clone";
      co = "checkout";
      cob = "checkout -b";
      ct = "commit";
      ctm = "commit -m";
      ctam = "commit -am";
      st = "status";

      # Push/Pull
      pl = "pull";
      ps = "push";
      psf = "push -f";
      psh = "push -u origin HEAD";
      # Safer force push - only forces if no one else has pushed
      psfl = "push --force-with-lease";

      # Rebase
      rb = "rebase";
      rbi = "rebase --interactive";

      # Diff
      dft = "difftool";
      dno = "diff --name-only";

      # Logs
      lg = "log --graph --oneline --abbrev-commit --decorate --color --all";
      # Prettier log with colors and relative dates
      lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";

      # Quick operations
      # Undo last commit (keeps changes staged)
      undo = "reset HEAD~1 --mixed";
      # Quick amend without editing message
      amend = "commit --amend --no-edit";
      # Show what would be pushed
      outgoing = "log @{u}..";
      # Show files changed in last commit
      last = "diff --name-only HEAD^ HEAD";

      # Branch management
      # Show recent branches by commit date
      recent = "branch --sort=-committerdate --format='%(committerdate:relative)%09%(refname:short)'";
      # Clean up merged branches (keeps main/master)
      tidy = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";

      # Stash
      # Quick stash with message
      save = "stash push -m";
      };
    };

    # Ignore files globally
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"

      # Editors
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"

      # Python
      "__pycache__/"
      "*.py[cod]"
      ".pytest_cache/"
      ".coverage"
      "htmlcov/"
      ".venv/"
      "venv/"
      "*.egg-info/"

      # Rust
      "target/"
      "Cargo.lock"  # For libraries; keep for binaries

      # Node
      "node_modules/"

      # Environment
      ".env"
      ".env.local"

      # Build artifacts
      "dist/"
      "build/"
    ];

    # Git LFS (Large File Storage)
    lfs = {
      enable = true;
    };

    # Delta - better diff viewer (optional, uncomment to enable)
    # delta = {
    #   enable = true;
    #   options = {
    #     features = "line-numbers decorations";
    #     syntax-theme = "Dracula";
    #     navigate = true;
    #   };
    # };
  };

  # Difftastic - structural diff tool
  home.packages = with pkgs; [
    difftastic
  ];
}
