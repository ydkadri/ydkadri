{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;  # Set as $EDITOR
    viAlias = true;        # Create 'vi' alias
    vimAlias = true;       # Create 'vim' alias

    # Install neovim package
    # LazyVim will manage plugins via lazy.nvim, not nix
    # This keeps LazyVim's plugin management intact
  };

  # LSP servers and development tools for neovim
  # These are needed by LSP and other neovim plugins
  home.packages = with pkgs; [
    # --- Language Servers (LSP) ---
    # Python
    pyright               # Python LSP
    ruff                  # Python linter/formatter (fast, Rust-based)

    # Rust
    rust-analyzer         # Rust LSP

    # Lua (for neovim config itself)
    lua-language-server

    # Bash/Shell
    bash-language-server

    # JSON/YAML
    vscode-langservers-extracted  # JSON, HTML, CSS, ESLint

    # Markdown
    marksman              # Markdown LSP

    # TOML
    taplo                 # TOML LSP

    # Dockerfile
    dockerfile-language-server

    # Terraform
    terraform-ls

    # --- Formatters ---
    stylua                # Lua formatter
    shfmt                 # Shell script formatter
    nixpkgs-fmt           # Nix formatter

    # --- Debuggers (DAP) ---
    # Python
    # python3Packages.debugpy  # Python debugger

    # --- Other Tools ---
    ripgrep               # Fast grep (used by Telescope)
    fd                    # Fast find (used by Telescope)
    tree-sitter           # Syntax highlighting

    # Clipboard support (for neovim)
    # macOS has pbcopy/pbpaste built-in, but this ensures it works
  ];

  # LazyVim bootstrap configuration
  # This sets up the initial config that LazyVim expects
  home.file.".config/nvim/init.lua".text = ''
    -- Bootstrap lazy.nvim (LazyVim's plugin manager)
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    -- Load LazyVim
    require("lazy").setup({
      spec = {
        -- Import LazyVim and all extras
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- Import any additional plugins from lua/plugins/
        { import = "plugins" },
      },
      defaults = {
        lazy = false,
        version = false,
      },
      install = { colorscheme = { "tokyonight", "habamax" } },
      checker = { enabled = true }, -- Check for plugin updates
      performance = {
        rtp = {
          disabled_plugins = {
            "gzip",
            "tarPlugin",
            "tohtml",
            "tutor",
            "zipPlugin",
          },
        },
      },
    })

    -- Basic settings (LazyVim will override these with better defaults)
    vim.opt.number = true              -- Show line numbers
    vim.opt.relativenumber = true      -- Relative line numbers
    vim.opt.mouse = "a"                -- Enable mouse
    vim.opt.clipboard = "unnamedplus"  -- Use system clipboard
    vim.opt.ignorecase = true          -- Case insensitive search
    vim.opt.smartcase = true           -- Unless uppercase is used
  '';

  # LazyVim configuration directory
  # This is where you customize LazyVim behavior
  home.file.".config/nvim/lua/config/lazy.lua".text = ''
    -- LazyVim options
    -- See: https://www.lazyvim.org/configuration

    return {
      -- Colorscheme
      colorscheme = "tokyonight",

      -- Leader key (default is Space)
      -- LazyVim sets this automatically

      -- LazyVim will automatically load these
      defaults = {
        autocmds = true, -- Load LazyVim autocmds
        keymaps = true,  -- Load LazyVim keymaps
        options = true,  -- Load LazyVim options
      },
    }
  '';

  # Optional: Add custom keymaps
  home.file.".config/nvim/lua/config/keymaps.lua".text = ''
    -- Custom keymaps
    -- LazyVim already provides good defaults, add overrides here

    local map = vim.keymap.set

    -- Examples:
    -- map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
    -- map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
  '';

  # Optional: Custom options
  home.file.".config/nvim/lua/config/options.lua".text = ''
    -- Custom options
    -- LazyVim already provides good defaults, add overrides here

    local opt = vim.opt

    -- Examples:
    -- opt.wrap = false           -- Don't wrap lines
    -- opt.scrolloff = 8          -- Keep 8 lines above/below cursor
    -- opt.tabstop = 4            -- 4 spaces for tabs
    -- opt.shiftwidth = 4         -- 4 spaces for indent
  '';

  # Plugins directory for custom plugins
  home.file.".config/nvim/lua/plugins/example.lua".text = ''
    -- Custom plugins
    -- Add any plugins not included in LazyVim here
    --
    -- Example:
    -- return {
    --   {
    --     "plugin/name",
    --     config = function()
    --       -- Plugin configuration
    --     end,
    --   },
    -- }

    return {}
  '';
}
