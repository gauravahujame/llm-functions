# Tool Creation Reference

Quick reference for creating tools in Bash, JavaScript, and Python.

## Bash Tools

```bash
#!/usr/bin/env bash
set -e

# @describe Description of tool
# @option --param!        Required param
# @option --param*         Optional array
# @option --param+        Required array
# @flag --bool            Boolean flag
# @option --num! <INT>    Integer
# @option --val! <NUM>     Number/float
# @option --enum![a|b]     Enum

# @env LLM_OUTPUT=/dev/stdout

main() {
    echo "$argc_param" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
```

## JavaScript Tools

```javascript
/**
 * Description
 * @typedef {Object} Args
 * @property {string} param - Required string
 * @property {string[]} [arr] - Optional array
 * @property {Integer} count - Integer (capital I)
 * @property {number} val - Number
 * @property {'a'|'b'} enum - Enum
 * @param {Args} args
 */
exports.run = function (args) {
  return `result: ${args.param}`;
};
```

## Python Tools

```python
from typing import List, Literal, Optional

def run(
    param: str,
    arr: Optional[List[str]] = None,
    count: int,
    val: float,
    enum: Literal["a", "b"]
):
    """Description
    Args:
        param: Required string
        arr: Optional array
        count: Integer
        val: Number
        enum: Enum value
    """
    return f"result: {param}"
```

## Type Mapping

| JSON Schema | Bash | JS JSDoc | Python |
|-------------|------|----------|--------|
| string | (default) | `string` | `str` |
| integer | `<INT>` | `Integer` | `int` |
| number | `<NUM>` | `number` | `float` |
| array | `+` or `*` | `string[]` | `List[str]` |
| enum | `[a\|b]` | `'a'\|'b'` | `Literal["a","b"]` |
| required | `!` | (no brackets) | (no Optional) |
| optional | (no suffix) | `[optional]` | `Optional[T]` |

## Parameter Name Conversion

- Bash kebab-case (`--my-param`) → `$argc_my_param` (underscore)
- JS/Python camelCase/snake_case → same in args object

## Output

Always write to `$LLM_OUTPUT` (default: `/dev/stdout`)
