return {
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		config = function()
			local root_markers = { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", ".git" }

			local function start()
				local root_dir = vim.fs.root(0, root_markers) or vim.fn.getcwd()
				local workspace = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. vim.fn.fnamemodify(root_dir, ":p:h:gs?/?%?")

				local capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

				require("jdtls").start_or_attach({
					cmd = { vim.fn.stdpath("data") .. "/mason/bin/jdtls", "-data", workspace },
					root_dir = root_dir,
					capabilities = capabilities,
					-- Lets jdtls fetch `jdt://` contents (library classes) so gd works on them.
					init_options = { extendedClientCapabilities = require("jdtls").extendedClientCapabilities },
				})
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				group = vim.api.nvim_create_augroup("nvim-jdtls-start", { clear = true }),
				callback = start,
			})
			start()
		end,
	},
}
