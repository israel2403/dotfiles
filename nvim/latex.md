# LaTeX and Beamer

Open a `.tex` file in Neovim. The LaTeX extra provides VimTeX syntax,
Texlab completion/navigation/diagnostics, and LaTeX/BibTeX parser support.

- `\ll`: start/stop continuous latexmk compilation; saves rebuild the PDF.
- `\lv`: open Zathura / jump from source to the PDF (SyncTeX).
- `\le`: show compiler errors.
- `\lt`: document table of contents.
- `\lk`: stop compilation.

These use the default local leader `\`; a custom local leader replaces it.
Zathura supports inverse search with Ctrl+left-click in the PDF.

Compile this project from its directory:

```sh
latexmk -pdf -synctex=1 -interaction=nonstopmode -file-line-error presentacion.tex
```

System packages (Omarchy/Arch): texlive-latexrecommended,
texlive-latexextra, texlive-pictures, texlive-fontsrecommended,
texlive-fontsextra (Font Awesome 5), texlive-langspanish,
texlive-binextra (latexmk/chktex), texlab, zathura, zathura-pdf-mupdf.
