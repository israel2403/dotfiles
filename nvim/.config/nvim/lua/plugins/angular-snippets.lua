return {
  {
    "L3MON4D3/LuaSnip",
    opts = function(_, opts)
      opts.history = true
      opts.updateevents = "TextChanged,TextChangedI"

      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("typescript", {
        s("ngcomp", {
          t({
            "import { Component } from '@angular/core';",
            "",
            "@Component({",
            "  selector: 'app-",
          }),
          i(1, "example"),
          t({
            "',",
            "  standalone: true,",
            "  imports: [],",
            "  templateUrl: './",
          }),
          i(2, "example"),
          t({
            ".component.html',",
            "  styleUrl: './",
          }),
          i(3, "example"),
          t({
            ".component.scss',",
            "})",
            "export class ",
          }),
          i(4, "ExampleComponent"),
          t({
            " {",
            "}",
          }),
        }),

        s("ngservice", {
          t({
            "import { Injectable } from '@angular/core';",
            "",
            "@Injectable({",
            "  providedIn: 'root',",
            "})",
            "export class ",
          }),
          i(1, "ExampleService"),
          t({
            " {",
            "  constructor() {}",
            "}",
          }),
        }),

        s("nginput", {
          t("readonly "),
          i(1, "value"),
          t(" = input<"),
          i(2, "string"),
          t(">();"),
        }),

        s("ngoutput", {
          t("readonly "),
          i(1, "changed"),
          t(" = output<"),
          i(2, "void"),
          t(">();"),
        }),
      })

      ls.add_snippets("htmlangular", {
        s("ngif", {
          t("@if ("),
          i(1, "condition"),
          t({
            ") {",
            "  ",
          }),
          i(2, "<p>Content</p>"),
          t({
            "",
            "}",
          }),
        }),

        s("ngfor", {
          t("@for ("),
          i(1, "item"),
          t(" of "),
          i(2, "items"),
          t("; track "),
          i(3, "item.id"),
          t({
            ") {",
            "  ",
          }),
          i(4, "<p>{{ item }}</p>"),
          t({
            "",
            "}",
          }),
        }),
      })
    end,
  },
}
