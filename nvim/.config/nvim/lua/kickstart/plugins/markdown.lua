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
			-- This machine has several non-loopback interfaces (docker0, a
			-- minikube bridge, wifi). Left unset, mkdp's IP autodetection can
			-- bind the preview server to one of those instead of localhost,
			-- so the browser opens a URL that never loads. Pin it explicitly.
			vim.g.mkdp_open_ip = "127.0.0.1"
			-- Force the actual system default browser binary (`brave`, per
			-- `xdg-settings get default-web-browser`) rather than relying on
			-- xdg-open, whose mimeapps.list associations on this machine are
			-- inconsistent (several browsers claim text/html).
			vim.g.mkdp_browser = "brave"
		end,
	},
}
