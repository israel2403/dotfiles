# Java member generation

In a Java buffer, put the cursor inside the target class and press **Space J g**.
JDTLS must have finished loading the project.

Choose **Getters**, **Setters**, **Getters and setters**, **Empty constructor**,
or **Constructor with selected fields**.

For field-based actions:

1. Select a field and press Enter to toggle its checkbox.
2. Repeat for any additional fields, or choose **Select all**.
3. Choose **Generate selected fields** to insert the code.
4. Escape cancels without inserting anything.

Run the action again with different selections to give some fields only getters,
others only setters, and others both. Existing accessors are omitted by JDTLS;
final fields are not offered setters. The menu displays the methods available
for each field.

Constructors can include one or several chosen fields. The empty option selects
an accessible superclass constructor without parameters; when building a
parameterized constructor, a superclass choice appears if needed. Its parameters
are also included. Java's rules still apply: uninitialized final fields must be
initialized by every constructor, and constructor signatures must be unique.
Review Java diagnostics after generation, particularly when adding constructors
to a class with existing constructors or Lombok constructor annotations.

Generated methods are ordinary Java source in the current buffer. They are not
automatically saved; review them and save normally. Use Neovim's undo to revert.

Implementation: `lua/plugins/java-generate.lua` in the Neovim config. The live
`~/.config/nvim/lua/plugins/java-generate.lua` is linked to the dotfiles copy.
