return {
  schema_version = 1,
  colorscheme = "tokyonight-night",
  background = "dark",
  priority = 1000,
  plugin = {
    repo = "folke/tokyonight.nvim",
    name = "tokyonight.nvim",
    main = "tokyonight",
    opts = {
      style = "night",
      transparent = false,
    },
  },
}
