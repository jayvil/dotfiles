return {
	-- MarkdownPreview plugin
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		init = function()
			-- With several network interfaces (docker0, VPNs, bridges), mkdp's IP
			-- autodetection can pick one other than localhost, so the browser
			-- opens a URL that never loads. Pin it explicitly.
			vim.g.mkdp_open_ip = "127.0.0.1"
			-- Prefer brave directly when it is installed: xdg-open's text/html
			-- association can be inconsistent when several browsers claim it.
			-- Without brave, mkdp falls back to the system default browser.
			if vim.fn.executable("brave") == 1 then
				vim.g.mkdp_browser = "brave"
			end
		end,
	},
}
