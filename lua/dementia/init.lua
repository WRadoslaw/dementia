local has_telescope = pcall(require, "telescope")
if not has_telescope then
	error("This plugin requires telescope.nvim")
end

local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

local M = {}

local function get_modified_buffers()
	local buffers = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(bufnr, "modified") then
			table.insert(buffers, {
				bufnr = bufnr,
				filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:."),
				saved = false, -- Add a saved field to track if the buffer is saved
				discarded = false,
			})
		end
	end
	return buffers
end

local function entry_maker(entry)
	return {
		value = entry,
		display = function(e)
			if e.value.saved then
				return string.format("%s %s", e.value.filename, "[saved]")
			elseif e.value.discarded then
				return string.format("%s %s", e.value.filename, "[discarded]")
			else
				return e.value.filename
			end
		end,
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
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					vim.api.nvim_buf_call(entry.value.bufnr, function()
						vim.cmd("silent! windo diffthis")
					end)
					local bufnr = self.state.bufnr
					vim.api.nvim_buf_set_lines(
						bufnr,
						0,
						-1,
						false,
						vim.api.nvim_buf_get_lines(entry.value.bufnr, 0, -1, false)
					)
					vim.api.nvim_buf_call(entry.value.bufnr, function()
						vim.cmd("silent! windo diffoff")
					end)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				local function save_selected_buffer()
					local selection = action_state.get_selected_entry()
					vim.api.nvim_buf_call(selection.value.bufnr, function()
						vim.cmd("write")
					end)
					selection.value.saved = true -- Mark buffer as saved
					-- Refresh the picker
					local current_picker = action_state.get_current_picker(prompt_bufnr)
					current_picker:refresh(
						finders.new_table({
							results = buffers,
							entry_maker = entry_maker,
						}),
						{ reset_prompt = false }
					)
				end

				local function discard_selected_buffer()
					local selection = action_state.get_selected_entry()
					vim.api.nvim_buf_call(selection.value.bufnr, function()
						vim.cmd("edit!")
					end)
					selection.value.discarded = true
					-- Refresh the picker
					local current_picker = action_state.get_current_picker(prompt_bufnr)
					current_picker:refresh(
						finders.new_table({
							results = buffers,
							entry_maker = entry_maker,
						}),
						{ reset_prompt = false }
					)
				end

				map("i", "<CR>", save_selected_buffer)
				map("n", "<CR>", save_selected_buffer)
				map("i", "<BS>", discard_selected_buffer)
				map("n", "<BS>", discard_selected_buffer)

				return true
			end,
		})
		:find()
end

return M
