return {
  schema_version = 1,
  colorscheme = "catppuccin",
  background = "dark",
  priority = 1000,
  plugin = {
    repo = "catppuccin/nvim",
    name = "catppuccin",
    main = "catppuccin",
    opts = {
      flavour = "mocha",
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
    },
  },
}
