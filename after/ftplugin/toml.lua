-- crates.nvim keymaps, only inside a Cargo.toml.
--
-- Hover (K), code actions (<space>ca) and completion already work through
-- crates.nvim's in-process language server and the generic mappings in
-- lua/lsp_conf.lua. These are the extras that have no LSP equivalent.
--
-- The prefix is <leader>C (capital) so it does not collide with <leader>cd
-- ("change cwd") from lua/mappings.lua.

if vim.fn.expand("%:t") ~= "Cargo.toml" then
  return
end

local ok, crates = pcall(require, "crates")
if not ok then
  return
end

local bufnr = vim.api.nvim_get_current_buf()

---@param lhs string
---@param rhs function
---@param desc string
---@param mode? string|string[]
local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

-- popups
map("<leader>Cv", crates.show_versions_popup, "crate versions")
map("<leader>Cf", crates.show_features_popup, "crate features")
map("<leader>Cd", crates.show_dependencies_popup, "crate dependencies")
map("<leader>Ci", crates.show_crate_popup, "crate info")

-- update = newest *compatible* version, upgrade = newest version, ignoring the
-- existing requirement
map("<leader>Cu", crates.update_crate, "update crate")
map("<leader>Cu", crates.update_crates, "update selected crates", "x")
map("<leader>Ca", crates.update_all_crates, "update all crates")
map("<leader>CU", crates.upgrade_crate, "upgrade crate")
map("<leader>CU", crates.upgrade_crates, "upgrade selected crates", "x")
map("<leader>CA", crates.upgrade_all_crates, "upgrade all crates")

-- rewrite `foo = "1.0"` into `foo = { version = "1.0" }` and friends
map("<leader>Cx", crates.expand_plain_crate_to_inline_table, "expand to inline table")
map("<leader>CX", crates.extract_crate_into_table, "extract into table")
map("<leader>Cg", crates.use_git_source, "switch to git source")

-- open things in the browser
map("<leader>CD", crates.open_documentation, "open docs.rs")
map("<leader>CR", crates.open_repository, "open repository")
map("<leader>CH", crates.open_homepage, "open homepage")
map("<leader>CC", crates.open_crates_io, "open crates.io")
map("<leader>CL", crates.open_lib_rs, "open lib.rs")

map("<leader>Ct", crates.toggle, "toggle crates UI")
map("<leader>Cr", crates.reload, "reload crate data")
