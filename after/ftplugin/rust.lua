-- Buffer-local settings and keymaps for Rust.
--
-- This file is sourced *before* rust-analyzer attaches, so the mappings set
-- here win over the generic LSP mappings in lua/lsp_conf.lua (which explicitly
-- skips `K` and `<space>ca` for rust-analyzer).
--
-- Do NOT set `vim.g.rustaceanvim` here, it is read before this file runs.
-- That lives in lua/config/rustaceanvim.lua.

local opt = vim.opt_local

-- rustfmt: 4 spaces, no tabs, 100 columns
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.colorcolumn = "100"

-- do not continue `//` when opening a line with o/O
opt.formatoptions:remove { "o" }

local bufnr = vim.api.nvim_get_current_buf()

---@param lhs string
---@param rhs string|function
---@param desc string
---@param mode? string|string[]
local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

--- Run a `:RustLsp` subcommand.
---@param ... string
local function rust_lsp(...)
  local args = { ... }
  return function()
    vim.cmd.RustLsp(#args == 1 and args[1] or args)
  end
end

--------------------------------------------------------------------------------
-- overrides of the generic LSP mappings
--------------------------------------------------------------------------------

-- hover actions: press K once for the docs, twice to jump into the window and
-- pick an action (run / debug / go to impl / references)
map("K", rust_lsp("hover", "actions"), "hover actions")

-- rust-analyzer groups its code actions, which vim.lsp.buf.code_action cannot
-- render. This falls back to vim.ui.select when there is nothing to group.
map("<space>ca", rust_lsp("codeAction"), "code action (grouped)")

-- format via rustfmt, driven by rust-analyzer. Same key as go/lua/python.
map("<space>f", function()
  vim.lsp.buf.format { async = false }
end, "format with rustfmt")

--------------------------------------------------------------------------------
-- build & run
--------------------------------------------------------------------------------

--- `:RustLsp run` needs a cargo project. Fall back to rustc for scratch files.
local function run_current()
  if vim.fs.root(bufnr, { "Cargo.toml" }) then
    vim.cmd.RustLsp("run")
    return
  end

  local src = vim.fn.shellescape(vim.fn.expand("%:p"))
  local out = vim.fn.shellescape(vim.fn.expand("%:p:r"))
  local cmd = string.format("rustc --edition 2024 -o %s %s && %s", out, src, out)

  if vim.fn.exists(":AsyncRun") == 2 then
    vim.cmd("AsyncRun " .. cmd)
  else
    vim.cmd("!" .. cmd)
  end
end

map("<F9>", run_current, "run current target / file")

map("<leader>rr", rust_lsp("runnables"), "pick a runnable")
map("<leader>rt", rust_lsp("testables"), "pick a testable")
map("<leader>rT", rust_lsp("relatedTests"), "tests related to symbol")
map("<leader>rf", rust_lsp("flyCheck"), "cargo check in the background")

--------------------------------------------------------------------------------
-- diagnostics
--------------------------------------------------------------------------------

-- the rustc error index entry for the error under/after the cursor
map("<leader>re", rust_lsp("explainError"), "explain error code")
-- the full cargo-style rendered diagnostic, with all the spans
map("<leader>rd", rust_lsp("renderDiagnostic"), "render diagnostic")
map("<leader>rl", rust_lsp("relatedDiagnostics"), "jump to related diagnostics")

--------------------------------------------------------------------------------
-- navigation & docs
--------------------------------------------------------------------------------

map("<leader>ro", rust_lsp("openDocs"), "open docs.rs for symbol")
map("<leader>rc", rust_lsp("openCargo"), "open Cargo.toml")
map("<leader>rp", rust_lsp("parentModule"), "go to parent module")
map("<leader>rw", rust_lsp("workspaceSymbol"), "workspace symbol search")

--------------------------------------------------------------------------------
-- refactor / edit
--------------------------------------------------------------------------------

map("<leader>rj", rust_lsp("moveItem", "down"), "move item down")
map("<leader>rk", rust_lsp("moveItem", "up"), "move item up")
map("<leader>rJ", rust_lsp("joinLines"), "join lines (syntax aware)")
map("<leader>rJ", rust_lsp("joinLines"), "join lines (syntax aware)", "x")
map("<leader>rs", rust_lsp("ssr"), "structural search & replace")
map("<leader>rs", rust_lsp("ssr"), "structural search & replace", "x")

--------------------------------------------------------------------------------
-- inspect the compiler's view
--------------------------------------------------------------------------------

map("<leader>rm", rust_lsp("expandMacro"), "expand macro recursively")
map("<leader>rP", rust_lsp("rebuildProcMacros"), "rebuild proc macros")
map("<leader>ry", rust_lsp("syntaxTree"), "show syntax tree")
map("<leader>rh", rust_lsp("view", "hir"), "view HIR")
map("<leader>rM", rust_lsp("view", "mir"), "view MIR")
map("<leader>rg", rust_lsp("crateGraph"), "crate graph (needs graphviz)")

--------------------------------------------------------------------------------
-- debugging (nvim-dap, loaded on demand)
--------------------------------------------------------------------------------

map("<leader>dd", rust_lsp("debuggables"), "pick a debuggable")
map("<leader>db", function()
  require("dap").toggle_breakpoint()
end, "toggle breakpoint")
map("<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
    if cond and cond ~= "" then
      require("dap").set_breakpoint(cond)
    end
  end)
end, "conditional breakpoint")
map("<leader>dc", function()
  require("dap").continue()
end, "continue / start")
map("<leader>di", function()
  require("dap").step_into()
end, "step into")
map("<leader>do", function()
  require("dap").step_over()
end, "step over")
map("<leader>du", function()
  require("dap").step_out()
end, "step out")
map("<leader>dr", function()
  require("dap").repl.toggle()
end, "toggle dap repl")
map("<leader>dq", function()
  require("dap").terminate()
end, "terminate session")
map("<leader>dw", function()
  require("dap.ui.widgets").hover()
end, "inspect value under cursor")
