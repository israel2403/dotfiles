-- Obsidian-style notes + image pasting.
-- Telescope is assumed to be available (pulled in here as a dependency of obsidian.nvim).
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    cmd = { "Obsidian" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "main",
          path = "~/notes",
        },
      },

      notes_subdir = "inbox",

      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
        alias_format = "%B %-d, %Y",
        template = "daily.md",
      },

      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 2,
      },

      new_notes_location = "notes_subdir",

      legacy_commands = false,

      -- File naming strategy: use the user-provided title (kebab-case, ASCII-safe).
      -- Falls back to a timestamp when no title is given (e.g. bare `:Obsidian new`).
      note_id_func = function(title)
        if title ~= nil and title ~= "" then
          -- normalize unicode -> ascii-ish, lowercase, spaces -> dashes,
          -- strip anything that isn't [a-z0-9-], collapse repeats, trim edges.
          local slug = title
            :lower()
            :gsub("[%s_]+", "-")
            :gsub("[^%w%-]", "")
            :gsub("%-+", "-")
            :gsub("^%-", "")
            :gsub("%-$", "")
          if slug ~= "" then
            return slug
          end
        end
        return os.date("%Y-%m-%d") .. "-" .. tostring(os.time())
      end,

      -- Keep the note's H1 / frontmatter title as the human-readable title,
      -- even though the filename is a slug.
      note_frontmatter_func = function(note)
        if note.title then
          note:add_alias(note.title)
        end
        local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,

      frontmatter = {
        enabled = true,
      },

      link = {
        style = "wiki",
        wiki_link = "prepend_note_path",
      },

      attachments = {
        folder = "assets/img",
      },

      picker = {
        name = "telescope.nvim",
      },
    },
  },

  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
      },
      filetypes = {
        markdown = {
          url_encode_path = false,
          relative_to_current_file = false,
          dir_path = "assets/img",
          extension = "png",
          template = "![$CURSOR]($FILE_PATH)",
        },
      },
    },
    keys = {
      { "<leader>ip", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
    },
  },
}
