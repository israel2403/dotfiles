# Discrete Math Symbols

These insert-mode expansions are configured in
`~/.config/nvim/lua/config/autocmds.lua`, which is stowed from
`~/dotfiles/nvim`.

They are buffer-local for:

- Lean
- Markdown
- Text
- TeX / Plain TeX

Type the left-hand sequence while in insert mode. The symbol expands immediately
when the sequence is complete.

## Number Sets

```text
;N      -> ℕ
;Z      -> ℤ
;Q      -> ℚ
;R      -> ℝ
;C      -> ℂ
```

## Superscripts

Use these for exponents in Markdown notes. Compose multi-digit powers one digit
at a time: `x;1;2` becomes `x¹²`.

```text
;0      -> ⁰
;1      -> ¹
;2      -> ²
;3      -> ³
;4      -> ⁴
;5      -> ⁵
;6      -> ⁶
;7      -> ⁷
;8      -> ⁸
;9      -> ⁹
```

## Set Membership

```text
;in     -> ∈
;elem   -> ∈
;notin  -> ∉
```

## Set Relations

```text
;sub    -> ⊆
;subset -> ⊆
;psub   -> ⊂
;sup    -> ⊇
;supset -> ⊇
;psup   -> ⊃
```

## Set Operations

```text
;empty    -> ∅
;cup      -> ∪
;union    -> ∪
;cap      -> ∩
;inter    -> ∩
;diff     -> ∖
;setminus -> ∖
;prod     -> ×
;pow      -> ℘
```

## Logic

```text
;all    -> ∀
;ex     -> ∃
;and    -> ∧
;or     -> ∨
;not    -> ¬
;iff    -> ↔
;->     -> →
;<-     -> ←
;=>     -> ⇒
;<->    -> ↔
;<=     -> ≤
;>=     -> ≥
;!=     -> ≠
```
