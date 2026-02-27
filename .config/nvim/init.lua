-- Neovim Configuration File (init.lua)
-- Location: $HOME\AppData\Local\nvim\init.lua

-- Basic Settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.shiftwidth = 2          -- Number of spaces for indentation
vim.opt.tabstop = 2             -- Number of spaces a tab represents
vim.opt.smartindent = true      -- Smart indentation
vim.opt.wrap = true             -- Wrap long lines
vim.opt.ignorecase = true       -- Case insensitive search
vim.opt.smartcase = true        -- Case sensitive if uppercase is used
vim.opt.hlsearch = true         -- Highlight search results
vim.opt.incsearch = true        -- Incremental search
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.scrolloff = 8           -- Keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8       -- Keep 8 columns visible left/right of cursor

-- =============================
-- VSCode theme integration
-- Auto-bootstrap `vscode.nvim` colorscheme if missing, then apply it
-- =============================
-- Bootstrap lazy.nvim (auto-clone if missing) and register plugins
do
    local data = vim.fn.stdpath('data')
    local dbgfile = data .. '/lazy-bootstrap.log'
    local function dbg(msg)
        local f = io.open(dbgfile, 'a')
        if f then f:write(os.date('%Y-%m-%d %H:%M:%S') .. ' - ' .. tostring(msg) .. '\n'); f:close() end
    end
    dbg('bootstrap: start')
    local lazypath = data .. '/lazy/lazy.nvim'

    if not vim.loop.fs_stat(lazypath) then
        dbg('lazy not found at ' .. lazypath)
        if vim.fn.executable('git') == 1 then
            dbg('git is executable, attempting clone')
            local out = vim.fn.system({
                'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath
            })
            dbg('git clone exit: ' .. tostring(vim.v.shell_error) .. ' output: ' .. tostring(out))
        else
            dbg('git not executable')
            vim.notify('`git` not found — cannot bootstrap lazy.nvim', vim.log.levels.WARN)
        end
    else
        dbg('lazy already present')
    end

    -- Ensure vscode.nvim exists inside lazy's plugins root so colorscheme can be applied immediately
    local plugin_root = data .. '/lazy'
    local vscode_path = plugin_root .. '/vscode.nvim'
    if not vim.loop.fs_stat(vscode_path) then
        dbg('vscode.nvim not found at ' .. vscode_path)
        if vim.fn.executable('git') == 1 then
            dbg('attempting clone vscode.nvim')
            local out = vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/Mofiqul/vscode.nvim.git', vscode_path})
            dbg('vscode clone exit: ' .. tostring(vim.v.shell_error) .. ' output: ' .. tostring(out))
            if vim.v.shell_error ~= 0 then
                vim.notify('Failed to clone vscode.nvim: ' .. tostring(out), vim.log.levels.ERROR)
            end
        else
            dbg('git not executable for vscode clone')
            vim.notify('`git` not found — cannot auto-install vscode.nvim', vim.log.levels.WARN)
        end
    else
        dbg('vscode.nvim already present')
    end

    vim.opt.rtp:prepend(lazypath)

    local plugins = {
        {
            'Mofiqul/vscode.nvim',
            lazy = false,
            config = function()
                vim.g.vscode_style = vim.g.vscode_style or 'dark'
                if vim.g.vscode_style == 'light' then
                    vim.opt.background = 'light'
                else
                    vim.opt.background = 'dark'
                end
                vim.cmd('colorscheme vscode')
            end,
        },
    }

    local ok, lazy = pcall(require, 'lazy')
    dbg('require lazy ok: ' .. tostring(ok))
    if not ok then
        dbg('lazy require failed: ' .. tostring(lazy))
        vim.notify('lazy.nvim not available; plugin setup skipped', vim.log.levels.WARN)
    else
        dbg('calling lazy.setup')
        lazy.setup(plugins)
        dbg('lazy.setup finished')
    end
    dbg('bootstrap: end')
end

-- =============================
-- Neovide configuration
-- (GUI-only; this section documents and groups Neovide-specific settings)
-- =============================
if vim.g.neovide then
    -- Font (GUI only)
    vim.opt.guifont = "FiraCode Nerd Font Mono"

    -- Floating window blur
    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0

    -- Window transparency / background
    vim.g.neovide_transparency = 0.95
    vim.g.neovide_background_color = "#0f1117"

    -- Caret / cursor VFX (defaults)
    -- Common modes: "railgun", "torpedo", "pixiedust", "ripple"
    vim.g.neovide_cursor_vfx_mode = "railgun"
    vim.g.neovide_cursor_vfx_opacity = 0.8
    vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
    vim.g.neovide_cursor_animation_length = 0.13
    vim.g.neovide_cursor_trail_length = 0.8
    vim.g.neovide_cursor_animate_in_insert_mode = true

    -- Helper functions and keymaps for quick testing / toggling
    -- These are defined only in the Neovide GUI to avoid polluting terminal sessions.
    local _modes = { "railgun", "torpedo", "pixiedust", "ripple" }

    -- Toggle VFX on/off (stores previous mode)
    function _G.ToggleNeovideVFX()
        if vim.g.__neovide_vfx_enabled == nil then vim.g.__neovide_vfx_enabled = true end
        if vim.g.__neovide_vfx_enabled then
            vim.g.__neovide_vfx_prev_mode = vim.g.neovide_cursor_vfx_mode or _modes[1]
            vim.g.neovide_cursor_vfx_mode = ""
            vim.g.__neovide_vfx_enabled = false
            vim.notify("Neovide VFX disabled")
        else
            vim.g.neovide_cursor_vfx_mode = vim.g.__neovide_vfx_prev_mode or _modes[1]
            vim.g.__neovide_vfx_enabled = true
            vim.notify("Neovide VFX enabled: " .. tostring(vim.g.neovide_cursor_vfx_mode))
        end
    end

    -- Cycle to the next VFX mode
    function _G.CycleNeovideVFX()
        local cur = vim.g.neovide_cursor_vfx_mode or ""
        local idx = 0
        for i, m in ipairs(_modes) do if m == cur then idx = i break end end
        idx = (idx % #_modes) + 1
        vim.g.neovide_cursor_vfx_mode = _modes[idx]
        vim.notify("Neovide VFX mode: " .. _modes[idx])
    end

    -- Keybindings (Neovide only): <leader>vv toggles VFX, <leader>vc cycles modes
    vim.keymap.set('n', '<leader>vv', function() ToggleNeovideVFX() end, { silent = true })
    vim.keymap.set('n', '<leader>vc', function() CycleNeovideVFX() end, { silent = true })

    -- Notify on startup about current VFX mode (scheduled so notifications are available)
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.schedule(function()
                local mode = tostring(vim.g.neovide_cursor_vfx_mode)
                vim.notify("Neovide detected — VFX mode: " .. mode)
            end)
        end,
    })
end

-- Key Mappings
vim.g.mapleader = " "           -- Set space as leader key

-- Delete word backwards in insert mode (Ctrl+Backspace)
vim.keymap.set('i', '<C-BS>', '<C-w>')
vim.keymap.set('i', '<C-H>', '<C-w>')  -- Fallback for terminals that send Ctrl+H

-- Clear search highlighting
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Save file
vim.keymap.set('n', '<leader>w', ':w<CR>')

-- Quit
vim.keymap.set('n', '<leader>q', ':q<CR>')

-- Fallback: ensure colorscheme is applied once Neovim has finished startup
vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
        if vim.g.colors_name ~= 'vscode' then
            local ok, err = pcall(vim.cmd, 'colorscheme vscode')
            if not ok then
                vim.notify('Could not apply colorscheme vscode: ' .. tostring(err), vim.log.levels.WARN)
            end
        end
    end,
})


