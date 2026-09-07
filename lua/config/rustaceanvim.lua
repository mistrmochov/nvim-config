-- rustaceanvim manages the rust-analyzer LSP client *itself*. It is a filetype
-- plugin, so there is no `setup()` call: all configuration goes into
-- `vim.g.rustaceanvim`, which must be set before a rust buffer is opened.
--
-- IMPORTANT: do NOT also add `rust_analyzer` to `enabled_lsp_servers` in
-- lua/lsp_conf.lua. Two clients would attach to the same buffer and fight.
--
-- Docs:
--   `:h rustaceanvim`               plugin options
--   `:h rustaceanvim.config`        the full option table
--   https://rust-analyzer.github.io/book/configuration   server settings

vim.g.rustaceanvim = function()
  return {
    ---------------------------------------------------------------------------
    -- plugin behaviour
    ---------------------------------------------------------------------------
    tools = {
      -- how `:RustLsp run`/`debug` output is shown. Options: "termopen",
      -- "quickfix", "toggleterm", "vimux". termopen matches the AsyncRun-ish
      -- feel used for the other languages in this config.
      executor = "termopen",

      -- run `cargo test` in the background and turn failures into diagnostics
      -- instead of dumping them into a terminal. Set to "termopen" if you would
      -- rather watch the output scroll by.
      test_executor = "background",

      -- prefer clippy over plain `cargo check` for runnables/flycheck
      enable_clippy = true,

      -- rerun `:RustAnalyzer reloadWorkspace` when Cargo.toml is written
      reload_workspace_from_cargo_toml = true,

      code_actions = {
        group_icon = " ▶",
        -- rust-analyzer only *groups* some actions; fall back to vim.ui.select
        -- (snacks picker here) when there is nothing to group
        ui_select_fallback = true,
        keys = {
          confirm = { "<CR>" },
          quit = { "q", "<Esc>" },
        },
      },

      -- same look as the hover window configured in lua/lsp_conf.lua
      float_win_config = {
        border = "single",
        max_width = 100,
        max_height = 40,
        auto_focus = false,
        open_split = "horizontal",
      },

      -- edition assumed for standalone .rs files outside a cargo project
      rustc = {
        default_edition = "2024",
      },

      -- `:RustLsp crateGraph` needs `dot` from graphviz
      crate_graph = {
        backend = "x11",
        full = true,
      },
    },

    ---------------------------------------------------------------------------
    -- LSP client
    ---------------------------------------------------------------------------
    server = {
      -- rustaceanvim builds its own capabilities table, so only merge in the
      -- extra bit nvim-ufo needs (see lua/lsp_utils.lua for the generic case)
      capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },

      -- attach to .rs files that are not part of a cargo project. Diagnostics
      -- are limited there because most of them come from cargo.
      standalone = true,

      -- only notify on server errors, fidget.nvim already shows progress
      status_notify_level = "error",

      default_settings = {
        ["rust-analyzer"] = {
          cargo = {
            allFeatures = true,
            buildScripts = { enable = true },
            loadOutDirsFromCheck = true,
            -- give rust-analyzer its own target dir so its checks do not block
            -- on the same `target/` lock as a `cargo build` you run by hand.
            -- Costs extra disk, saves a lot of waiting.
            targetDir = true,
          },

          -- diagnostics from clippy on save rather than plain `cargo check`
          checkOnSave = true,
          check = {
            command = "clippy",
            -- don't lint your dependencies, only your own code
            extraArgs = { "--no-deps" },
            allTargets = true,
            workspace = true,
          },

          procMacro = {
            enable = true,
            ignored = {
              -- these expand to something rust-analyzer cannot follow and only
              -- produce noise. Add more here if a crate makes RA go quiet.
              ["async-trait"] = { "async_trait" },
              ["async-recursion"] = { "async_recursion" },
              ["napi-derive"] = { "napi" },
            },
          },

          diagnostics = {
            enable = true,
            -- rust-analyzer's own (non-rustc) lints for style issues
            styleLints = { enable = true },
            -- experimental diagnostics catch more, but produce false positives.
            -- Flip to true if you want to live dangerously.
            experimental = { enable = false },
            disabled = {},
          },

          imports = {
            granularity = {
              enforce = true,
              -- "preserve" | "crate" | "module" | "item" | "one"
              group = "crate",
            },
            -- "plain" | "self" | "crate"
            prefix = "plain",
            merge = { glob = false },
          },

          completion = {
            -- fill in argument placeholders you can <c-j> through
            callable = { snippets = "fill_arguments" },
            fullFunctionSignatures = { enable = true },
            postfix = { enable = true },
            privateEditable = { enable = true },
            -- suggest expressions that produce the expected type (slow-ish)
            termSearch = { enable = false },
          },

          -- these only show up once you run `:LspInlayHints enable`, since this
          -- config keeps inlay hints off by default (see lua/lsp_conf.lua)
          inlayHints = {
            bindingModeHints = { enable = false },
            chainingHints = { enable = true },
            closingBraceHints = { enable = true, minLines = 25 },
            closureCaptureHints = { enable = false },
            -- "always" | "never" | "with_block"
            closureReturnTypeHints = { enable = "never" },
            -- "always" | "never" | "fieldless"
            discriminantHints = { enable = "never" },
            -- "always" | "never" | "reborrow"
            expressionAdjustmentHints = { enable = "never" },
            genericParameterHints = {
              const = { enable = true },
              lifetime = { enable = false },
              type = { enable = false },
            },
            implicitDrops = { enable = false },
            -- "always" | "never" | "skip_trivial"
            lifetimeElisionHints = { enable = "never", useParameterNames = false },
            maxLength = 25,
            parameterHints = { enable = true },
            rangeExclusiveHints = { enable = true },
            -- "always" | "never" | "mutable"
            reborrowHints = { enable = "never" },
            renderColons = true,
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },

          -- code lens draws virtual text above items. This config turns off
          -- diagnostic virtual text on purpose (lua/diagnostic-conf.lua), so
          -- lens is off to match. `:RustLsp runnables` covers the same ground.
          -- If you do want it, also wire up vim.lsp.codelens.refresh().
          lens = {
            enable = false,
          },

          hover = {
            actions = {
              enable = true,
              debug = { enable = true },
              gotoTypeDef = { enable = true },
              implementations = { enable = true },
              references = { enable = true },
              run = { enable = true },
            },
            documentation = { enable = true, keywords = true },
            links = { enable = true },
            -- show size/alignment/niches of the type under the cursor
            memoryLayout = { enable = true, niches = true },
            show = { enumVariants = 8, fields = 8, traitAssocItems = 8 },
          },

          -- the "all Rust syntax stuff" part: rust-analyzer sends semantic
          -- tokens, Neovim applies them on top of the treesitter highlights.
          -- These options make the tokens more fine grained.
          semanticHighlighting = {
            doc = { comment = { inject = { enable = true } } },
            nonStandardTokens = true,
            operator = {
              enable = true,
              specialization = { enable = true },
            },
            punctuation = {
              enable = true,
              separate = { macro = { bang = true } },
              specialization = { enable = true },
            },
            strings = { enable = true },
          },

          workspace = {
            symbol = {
              search = {
                -- "only_types" | "all_symbols"
                kind = "all_symbols",
                -- "workspace" | "workspace_and_dependencies"
                scope = "workspace",
                limit = 512,
              },
            },
          },

          files = {
            excludeDirs = { ".direnv", ".git", ".github", "node_modules", "target" },
            watcher = "client",
          },

          rustfmt = {
            extraArgs = {},
            -- requires a nightly toolchain
            rangeFormatting = { enable = false },
          },

          assist = {
            -- "todo" | "default"
            expressionFillDefault = "todo",
            emitMustUse = false,
            termSearch = { fuel = 1800 },
          },

          references = {
            excludeImports = false,
            excludeTests = false,
          },

          typing = {
            autoClosingAngleBrackets = { enable = true },
          },

          -- warm the caches on startup so the first completion isn't slow
          cachePriming = { enable = true },
        },
      },
    },

    ---------------------------------------------------------------------------
    -- debugging
    ---------------------------------------------------------------------------
    -- The adapter is auto-detected: codelldb if it is on $PATH, otherwise
    -- lldb-dap. On Arch: `paru -S codelldb-bin`. nvim-dap must be installed,
    -- see lua/plugin_specs.lua.
    dap = {
      autoload_configurations = true,
    },
  }
end
