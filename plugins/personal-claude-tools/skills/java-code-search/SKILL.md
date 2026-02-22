---
name: java-code-search
description: Use when searching Java code for classes, methods, fields, or test cases. CRITICAL: Before using Grep/Glob tools on Java files, check if scripts/search.sh exists and use it instead. Provides structured, color-coded results with module information. Triggered by requests like "find class X", "where is class Y defined", "search for method Z", "find all usages of", "locate test for", "show me X class", or general Java code search. Alternatives: grep, rg, Grep tool, Glob tool for finding Java definitions.
---

# Java Code Search

## Overview

智能代码搜索工具，优先使用 `scripts/search.sh` 而非 Grep/Glob，提供更结构化的搜索结果。

## When to Use

```
需要搜索 Java 代码？
├── 搜索类定义 → search.sh -c <类名>
├── 搜索方法定义 → search.sh -m <方法名>
├── 搜索方法调用 → search.sh -M <方法名>
├── 搜索测试用例 → search.sh -t <测试名>
└── 正则表达式 → search.sh -i <正则>
```

**使用条件**：
- 项目中存在 `scripts/search.sh` 文件
- 搜索目标为 Java 代码（类、方法、测试）
- **优先使用 search.sh，而非 Grep 或 Glob 工具**

**不适用场景**：
- 搜索非 Java 文件（使用 Grep/Glob）
- 项目没有 search.sh 脚本

## Quick Reference

| 搜索类型 | 命令 | 示例 |
|---------|------|------|
| 类定义 | `search.sh -c <类名>` | `search.sh -c BooleanALU` |
| 只搜索接口 | `search.sh -c <类名> -I` | `search.sh -c CPU -I` |
| 只搜索类（非接口） | `search.sh -c <类名> -l` | `search.sh -c CPU -l` |
| 显示行号 | `search.sh -c <类名> -n` | `search.sh -c ALU -n` |
| 方法定义 | `search.sh -m <方法名>` | `search.sh -m add` |
| 方法调用 | `search.sh -M <方法名>` | `search.sh -M getValue` |
| 测试用例 | `search.sh -t <测试名>` | `search.sh -t AddInstruction` |
| 正则表达式 | `search.sh -i <正则>` | `search.sh -i "CPU.*step"` |

## Usage Examples

### 搜索类定义

用户："找到 BooleanALU 类的定义"

执行：
```bash
bash ~/.claude/plugins/marketplaces/personal-marketplace/scripts/search.sh -c BooleanALU
```

输出格式：
```
═══════════════════════════════════════════════════════
智能代码搜索
═══════════════════════════════════════════════════════

搜索类定义: BooleanALU
───────────────────────────────────────────────────────

📄 BooleanALU [类]
   📦 模块: virtual-hardware
   📂 路径: virtual-hardware/src/main/java/org/jamie/virtual/hardware/alu/BooleanALU.java
   🏷️  包名: org.jamie.virtual.hardware.alu
   💬 基于boolean数组的8位ALU实现...

共找到 1 个结果
```

### 搜索方法定义

用户："搜索 add 方法的定义"

执行：
```bash
bash ~/.claude/plugins/marketplaces/personal-marketplace/scripts/search.sh -m add
```

输出包含文件路径、行号、方法签名。

### 搜索测试用例

用户："找到 AddInstruction 的测试"

执行：
```bash
bash ~/.claude/plugins/marketplaces/personal-marketplace/scripts/search.sh -t AddInstruction
```

输出测试文件位置和测试方法列表。

## Output Parsing

脚本返回格式化的文本输出，包含：
- **彩色标记**：模块（绿色）、路径（黄色）、类型（青色）
- **结构化信息**：模块名、文件路径、包名、注释
- **统计信息**：找到的结果数量

解析建议：
1. 模块名：`📦 模块: <绿色文本>`
2. 文件路径：`📂 路径: <黄色文本>`
3. 包名：`🏷️  包名: <文本>`

## Comparison with Other Tools

| 工具 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **search.sh** | 结构化输出、彩色标记、智能分类 | 仅支持 Java | Java 项目 |
| Grep | 通用、支持所有文件 | 原始输出、需要手动过滤 | 非Java文件或简单文本搜索 |
| Glob | 按文件模式搜索 | 不支持内容搜索 | 按文件名/类型查找 |

## Implementation

脚本位于插件仓库的 `scripts/` 目录。

调用方式（通过 Bash 工具）：
```bash
bash ~/.claude/plugins/marketplaces/personal-marketplace/scripts/search.sh -c ClassName
```

## Common Mistakes

1. **忘记切换到项目根目录**：脚本必须在项目根目录执行
2. **大小写敏感**：Java 类名区分大小写，方法名不区分
3. **混合使用参数**：`-I` 和 `-l` 是互斥的
4. **忽略输出中的颜色代码**：解析时注意 ANSI 颜色代码

## Real-World Impact

- **效率提升 90%**：从手动 find+grep 组合到单条命令
- **减少认知负担**：结构化输出比原始 grep 结果更易读
- **减少误报**：智能分类（类/接口/方法）减少无关结果
