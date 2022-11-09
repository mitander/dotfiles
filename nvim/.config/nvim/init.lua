-- faster load times
local ok, impatient = pcall(require, "impatient")
if ok then
	impatient.enable_profile()
end

-- nvim configuration
require("general.options")
require("general.autocmd")
require("general.colors")
require("general.keymaps")
require("general.packer")
