# Rust setup

## What is installed

| Piece                          | Where                                  |
| ------------------------------ | -------------------------------------- |
| rust-analyzer client + tooling | `mrcjkb/rustaceanvim`                  |
| server settings                | `lua/config/rustaceanvim.lua`          |
| Cargo.toml management          | `saecki/crates.nvim`, `lua/config/crates.lua` |
| buffer options + keymaps       | `after/ftplugin/rust.lua`              |
| Cargo.toml keymaps             | `after/ftplugin/toml.lua`              |
| syntax / textobjects           | `rust` + `ron` parsers in `lua/config/treesitter.lua` |
| snippets                       | `my_snippets/rust.snippets` (UltiSnips) |
| debugging                      | `mfussenegger/nvim-dap` (lazy loaded)  |

`rust_analyzer` is **not** in `enabled_lsp_servers` in `lua/lsp_conf.lua` on
purpose. rustaceanvim starts that client itself; enabling it in both places
attaches two clients to every buffer.

## Toolchain

Everything is expected on `$PATH`, nothing is managed by mason.

```sh
# rustup ships rust-analyzer and rustfmt/clippy for the active toolchain
rustup component add rust-analyzer rust-src rustfmt clippy

# optional
cargo install cargo-nextest      # rustaceanvim uses it for tests if present
paru -S codelldb-bin             # debug adapter (Arch); or lldb-dap from llvm
sudo pacman -S graphviz          # only for :RustLsp crateGraph
```

`rust-src` matters: without it, hover and go-to-definition into `std` do not
work.

Check the result with `:checkhealth rustaceanvim`.

## Keymaps

`<leader>` is `,`. Everything below is buffer-local.

### In `.rs` files

| Key            | Action                                              |
| -------------- | --------------------------------------------------- |
| `K`            | hover; press again to enter the window and pick an action |
| `<space>ca`    | code actions, with rust-analyzer's grouping         |
| `<space>f`     | rustfmt                                             |
| `<F9>`         | run the target at the cursor (rustc for scratch files) |
| `<leader>rr`   | pick a runnable                                     |
| `<leader>rt`   | pick a testable                                     |
| `<leader>rT`   | tests related to the symbol under the cursor        |
| `<leader>rf`   | `cargo check` in the background                     |
| `<leader>re`   | explain the error code (from the rustc error index) |
| `<leader>rd`   | full cargo-style rendered diagnostic                |
| `<leader>rl`   | jump between related diagnostics                    |
| `<leader>ro`   | open docs.rs for the symbol                         |
| `<leader>rc`   | open Cargo.toml                                     |
| `<leader>rp`   | go to parent module                                 |
| `<leader>rw`   | filtered workspace symbol search                    |
| `<leader>rj/rk`| move item down / up                                 |
| `<leader>rJ`   | syntax-aware join lines (also visual)               |
| `<leader>rs`   | structural search & replace (also visual)           |
| `<leader>rm`   | expand macro recursively                            |
| `<leader>rP`   | rebuild proc macros                                 |
| `<leader>ry`   | show syntax tree                                    |
| `<leader>rh`   | view HIR                                            |
| `<leader>rM`   | view MIR                                            |
| `<leader>rg`   | crate graph                                         |
| `<leader>dd`   | pick a debuggable                                   |
| `<leader>db`   | toggle breakpoint                                   |
| `<leader>dB`   | conditional breakpoint                              |
| `<leader>dc`   | continue / start                                    |
| `<leader>di/do/du` | step into / over / out                          |
| `<leader>dr`   | toggle dap repl                                     |
| `<leader>dq`   | terminate session                                   |
| `<leader>dw`   | inspect the value under the cursor                  |

### In `Cargo.toml`

`K`, `<space>ca` and completion come from crates.nvim's in-process language
server, so they behave like any other LSP. The prefix for the rest is
`<leader>C` (capital), to stay clear of `<leader>cd`.

| Key            | Action                                     |
| -------------- | ------------------------------------------ |
| `<leader>Cv`   | versions popup                             |
| `<leader>Cf`   | features popup                             |
| `<leader>Cd`   | dependencies popup                         |
| `<leader>Ci`   | crate info popup                           |
| `<leader>Cu`   | update crate (newest compatible)           |
| `<leader>CU`   | upgrade crate (ignores the requirement)    |
| `<leader>Ca`   | update all                                 |
| `<leader>CA`   | upgrade all                                |
| `<leader>Cx`   | expand to inline table                     |
| `<leader>CX`   | extract into table                         |
| `<leader>Cg`   | switch to a git source                     |
| `<leader>CD/CR/CH/CC/CL` | open docs.rs / repo / homepage / crates.io / lib.rs |
| `<leader>Ct`   | toggle the crates UI                       |
| `<leader>Cr`   | reload crate data                          |

`<leader>Cu` and `<leader>CU` also work on a visual selection.

## Things left switched off

Both are one-line changes in `lua/config/rustaceanvim.lua`:

- `lens.enable = false` — code lens draws virtual text above every item. This
  config turns diagnostic virtual text off, so lens is off to match.
  `<leader>rr` covers the same ground. If you turn it on, wire up
  `vim.lsp.codelens.refresh()` on an autocmd too.
- `diagnostics.experimental.enable = false` — catches more, but produces false
  positives.

Inlay hints are configured but hidden, because this config keeps them off
globally. `:LspInlayHints enable` turns them on.

## Switching back to plain rust_analyzer

If rustaceanvim ever gets in the way:

1. Delete its spec from `lua/plugin_specs.lua`.
2. Add `rust_analyzer = { exe = "rust-analyzer", optional = false }` to
   `enabled_lsp_servers` in `lua/lsp_conf.lua`.
3. Move the `["rust-analyzer"]` table from `lua/config/rustaceanvim.lua` into a
   new `after/lsp/rust_analyzer.lua` as `return { settings = { ... } }`.
4. Drop the `is_rust_analyzer` guards in `lua/lsp_conf.lua` and the `:RustLsp`
   keymaps in `after/ftplugin/rust.lua`.
