# Markdown Showcase — H1 Title

A preview fixture that exercises every feature the renderer supports, so the
typography (line-height, heading scale, spacing) can be judged against GitHub at a
glance. This first paragraph is deliberately long so you can see how body text wraps
and how the **1.5 line-height** reads across multiple lines — the airy spacing is the
biggest single difference from cramped, default-leading text.

## Heading Level 2

### Heading Level 3

#### Heading Level 4

##### Heading Level 5

###### Heading Level 6

---

## Inline formatting

Regular text with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and
`inline code` all in one line. Here is a [link to a website](https://example.com),
an autolink <https://example.com>, and some inline HTML like <b>bold via tag</b> and
a hard break here →<br>…the line continued after a `<br>`.

You can also nest emphasis: **bold with `code` and *italic* inside**, or a link whose
text is `code`: [`someFunction()`](https://example.com).

## Blockquotes

> A single-level blockquote. It should be indented with a left bar (once the bar
> decoration lands) and read in a slightly muted color.
>
> > A nested blockquote, one level deeper, to check the indent stacking.
>
> Back to the first level, with a list inside:
>
> - quoted list item one
> - quoted list item two

## Lists

### Unordered (nested)

- First item
- Second item with a longer line so you can see how the wrapped text hangs past the
  bullet marker and stays aligned to the text, not the bullet.
  - Nested item A
  - Nested item B
    - Deeply nested item
- Third item

### Ordered (nested)

1. Step one
2. Step two
   1. Sub-step 2a
   2. Sub-step 2b
3. Step three

### Task list

- [x] Ported the 1.5 line-height
- [x] Body-relative heading sizes
- [ ] H1/H2 bottom hairline rule
- [ ] Code-block padding + rounded corners
- [ ] GitHub-faithful tables

## Code

Inline `let x = 42` versus fenced blocks in several languages (these should be
syntax-highlighted by the tree-sitter formatter):

```swift
func greet(_ name: String) -> String {
    let greeting = "Hello, \(name)!"
    return greeting  // string interpolation
}
```

```python
def fib(n: int) -> int:
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

```javascript
const sum = (nums) => nums.reduce((acc, n) => acc + n, 0);
console.log(sum([1, 2, 3, 4]));  // 10
```

```json
{
  "name": "sidewatch",
  "version": "1.0.0",
  "features": ["preview", "diff", "terminal"],
  "nested": { "ok": true, "count": 3 }
}
```

```bash
git status --short
swift build 2>&1 | grep -iE "error:|Build complete"
```

## Tables

| Feature          | Native | Webview | Notes                          |
| ---------------- | :----: | :-----: | ------------------------------ |
| Line-height 1.5  |   ✅   |   ✅    | Ported in this pass            |
| Heading scale    |   ✅   |   ✅    | Body-relative, semibold        |
| Code padding     |   ⚠️   |   ✅    | Needs custom drawing natively  |
| Tables           |   ⚠️   |   ✅    | The hard one to match          |
| Scroll-sync      |   ✅   |   ⚠️    | Native wins here               |

Alignment check: the middle two columns are centered, the last is left-aligned.

## Images

An image reference (falls back to alt text if the path can't be resolved locally):

![Sidewatch app icon](AppIcon.png)

## A longer prose section

Sidewatch is a pure-AppKit, TextKit-2 macOS code-review cockpit for terminal AI
agents — *"a windshield, not a second steering wheel."* You run the agent in the
terminal; Sidewatch is the native surface for reviewing what it did. It talks to **no**
model, keeps no account, and sends no telemetry. Every feature must pass the test:
*does it help you see and verify what the agent did?*

This paragraph, the blockquotes, the lists, and the headings above should together
give a fair read on how close the native renderer gets to GitHub before any of the
box-decoration drawing is done.

---

*End of showcase.*
