local has_telescope = pcall(require, "telescope")

if not has_telescope then
	error("This plugin requires telescope.nvim")
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local M = {}

local function get_modified_buffers()
	local buffers = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(bufnr, "modified") then
			table.insert(buffers, {
				bufnr = bufnr,
				filename = vim.api.nvim_buf_get_name(bufnr),
			})
		end
	end
	return buffers
end

local function entry_maker(entry)
	return {
		value = entry,
		display = entry.filename,
		ordinal = entry.filename,
	}
end

M.show_modified_buffers = function()
	local buffers = get_modified_buffers()
	if vim.tbl_isempty(buffers) then
		print("No modified buffers")
		return
	end

	pickers
		.new({}, {
			prompt_title = "Modified Buffers",
			finder = finders.new_table({
				results = buffers,
				entry_maker = entry_maker,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local function save_selected_buffer()
					local selection = action_state.get_selected_entry()
					vim.api.nvim_buf_call(selection.value.bufnr, function()
						vim.cmd("write")
					end)

					local remaining_buffers = get_modified_buffers()
					if vim.tbl_isempty(remaining_buffers) then
						actions.close(prompt_bufnr)
						print("Your dementia is temporarily cured")
					end
				end

				map("i", "<CR>", save_selected_buffer)
				map("n", "<CR>", save_selected_buffer)

				return true
			end,
		})
		:find()
end

return M
