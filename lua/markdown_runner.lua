local M = {}

-- Echo the result from running the code block
function M.runNormal()
  local ok, runner = pcall(M.run_code_block)
  if ok then
    display_result_in_nui_popup(runner.result)
    -- vim.api.nvim_echo({{runner.result, 'Normal'}}, false, {})
  else
    M.error(runner)
  end
end

-- Error handling function
function M.error(err)
  vim.api.nvim_command('normal! <Esc>')
  vim.api.nvim_echo({{"MarkdownRunner: " .. err, 'ErrorMsg'}}, true, {})
end

-- Run the code block logic
-- Get the appropriate runner for a language
function M.runner_for_language(lang)
  local markdown_runners = vim.b.markdown_runners or vim.g.markdown_runners or {}
  local default_runner = vim.fn.getenv('SHELL')

  return markdown_runners[lang] or default_runner
end

local Popup = require("nui.popup")
local nuiEvent = require("nui.utils.autocmd").event

function display_result_in_nui_popup(result)
  local popup = Popup({
    enter = true,
    focusable = true,
    position = '50%',
    size = {width = '80%', height = '85%'},
    border = {
      style = 'rounded',
      text = {
        top = 'Markdown Runner Result',
        top_align = 'center',
      },
    },
    buf_options = { filetype = 'markdown' },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  })

  popup:mount()
  -- unmount component when cursor leaves buffer
  popup:on(nuiEvent.BufLeave, function()
    popup:unmount()
  end)
  -- set content
  local result_lines = vim.split(result, '\n')
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, result_lines)

end

function M.run_code_block()
  local runner = M.parse_code_block()
  local Runner = M.runner_for_language(runner.language)

  vim.env.markdown_runner__embedding_file = vim.fn.expand('%:p')
  local cursorpos = vim.fn.getcurpos()
  vim.env.markdown_runner__line = cursorpos[1]

  vim.api.nvim_echo({{"MarkdownRunner: running code block with " .. Runner, 'Normal'}}, false, {})
  local result
  if type(Runner) == "function" then
    result = Runner(runner.src)
  elseif type(Runner) == "string" then
    result = vim.fn.system(Runner, runner.src)
  else
    error("Invalid runner")
  end

  -- if vim.g.markdown_runner_populate_location_list == 1 then
  --   local result_lines = vim.split(result, '\n')
  --   local loclist_items = {}
  --   for _, val in ipairs(result_lines) do
  --     table.insert(loclist_items, {text = val})
  --   end
  --   vim.fn.setloclist(0, loclist_items)
  -- end

  runner.result = result
  return runner
end

-- Parse fenced code blocks around the cursor
function M.parse_code_block()
  local cursor_line = vim.fn.getcurpos()[2]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local start_line, end_line
  for i = cursor_line, 1, -1 do
    if lines[i]:match('^```') then
      start_line = i
      break
    end
  end
  for i = cursor_line, #lines do
    if lines[i]:match('^```') then
      end_line = i
      break
    end
  end

  if not start_line or not end_line or start_line >= end_line then
    error('Invalid fenced code block')
  end

  local lang = lines[start_line]:match('^```(.*)') or ''
  local src = table.concat(lines, '\n', start_line + 1, end_line - 1)

  return {language = lang, src = src}
end

return M
