-- Expand packages only after their Java source folder is opened manually.
local function expand_maven_packages(state)
	if state.name ~= "filesystem" or state.search_pattern or not state.path then
		return
	end
	local root = state.path
	state.maven_expanded_sources = state.maven_expanded_sources or {}
	if not state.tree or vim.fn.filereadable(root .. "/pom.xml") ~= 1 then
		return
	end

	local folders = {}
	local sources = {}
	local function collect_packages(path)
		table.insert(folders, path)
		local scan = vim.uv.fs_scandir(path)
		if not scan then
			return
		end
		while true do
			local name, kind = vim.uv.fs_scandir_next(scan)
			if not name then
				break
			end
			-- Do not follow symlinks out of the source tree or into cycles.
			if kind == "directory" then
				collect_packages(path .. "/" .. name)
			end
		end
	end
	for _, source in ipairs({ "main", "test" }) do
		local path = root .. "/src/" .. source .. "/java"
		local node = state.tree:get_node(path)
		if node and node:is_expanded() and not state.maven_expanded_sources[path]
			and state.explicitly_opened_nodes and state.explicitly_opened_nodes[path] then
			state.maven_expanded_sources[path] = true
			table.insert(sources, path)
			collect_packages(path)
		end
	end
	if #folders == 0 then
		return
	end

	-- Schedule a refresh after rendering the manually opened source folder.
	vim.schedule(function()
		local renderer = require("neo-tree.ui.renderer")
		if state.path ~= root or state.search_pattern or not renderer.window_exists(state) then
			for _, path in ipairs(sources) do
				state.maven_expanded_sources[path] = nil
			end
			return
		end
		local expanded = renderer.get_expanded_nodes(state.tree)
		vim.list_extend(expanded, folders)
		state.force_open_folders = expanded
		require("neo-tree.sources.filesystem").navigate(state, root)
	end)
end

return {
	"nvim-neo-tree/neo-tree.nvim",
	keys = {
		{
			"<leader>e",
			function()
				local start_dir = vim.g.nvim_start_cwd or vim.uv.cwd()
				require("neo-tree.command").execute({ action = "focus", source = "filesystem", dir = start_dir, reveal = true })
			end,
			desc = "Explorer NeoTree (Focus)",
		},
		{
			"<leader>E",
			function()
				require("neo-tree.command").execute({ action = "close" })
			end,
			desc = "Close NeoTree",
		},
	},
	opts = {
		event_handlers = {
			{ event = "after_render", handler = expand_maven_packages },
		},
		filesystem = {
			-- Reveal files opened from a picker and keep their parent folders expanded.
			follow_current_file = { enabled = true, leave_dirs_open = true },
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
				hide_gitignored = false,
			},
		},
	},
}
