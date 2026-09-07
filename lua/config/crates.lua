-- crates.nvim: version/feature/dependency management inside Cargo.toml.
--
-- Completion, hover and code actions are served by an *in-process* language
-- server, so they arrive through the normal `lsp` source in blink.cmp and the
-- normal `vim.lsp.buf.*` functions. Nothing extra to register.
--
-- Docs: https://github.com/Saecki/crates.nvim/wiki/Documentation-unstable

require("crates").setup {
  -- keep the virtual text and diagnostics in sync while you type
  autoload = true,
  autoupdate = true,
  smart_insert = true,
  insert_closing_quote = true,
  remove_enabled_default_features = true,
  remove_empty_features = true,
  enable_update_available_warning = true,

  -- the in-process LSP. This is what makes K, <space>ca and completion work
  -- in Cargo.toml the same way they do in a .rs file.
  lsp = {
    enabled = true,
    name = "crates.nvim",
    actions = true,
    completion = true,
    hover = true,
  },

  completion = {
    insert_closing_quote = true,
    -- complete crate *names* by searching crates.io, not just versions
    crates = {
      enabled = true,
      min_chars = 3,
      max_results = 8,
    },
  },

  popup = {
    border = "single",
    autofocus = true,
    hide_on_select = false,
    show_version_date = true,
    show_dependency_version = true,
    max_height = 30,
    min_width = 20,
  },
}
