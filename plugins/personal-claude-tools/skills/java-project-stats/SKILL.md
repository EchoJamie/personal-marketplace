---
name: java-project-stats
description: Use when needing project statistics, code metrics, or test coverage information for Java projects. CRITICAL: Before manually counting files with find/wc or using Glob to count Java files, check if scripts/stats.sh exists and use it instead. Provides comprehensive metrics including line counts, module statistics, and test coverage. Triggered by "project stats", "how many files", "lines of code", "test coverage", "project size", "code statistics", "count files", or project analysis requests. Alternatives: find + wc, cloc, or manually counting with Glob.
---

# Java Project Stats

## Overview

项目统计工具，使用 `scripts/stats.sh` 快速查看代码行数、测试覆盖率、模块统计等指标。

## When to Use

```
需要项目统计？
├── 完整统计 → stats.sh
├── 只显示代码行数 → stats.sh -l
├── 只显示模块统计 → stats.sh -m
└── 只显示测试统计 → stats.sh -t
```

**使用条件**：
- 项目中存在 `scripts/stats.sh` 文件
- 需要快速了解项目规模或测试覆盖率

**不适用场景**：
- 需要精确的代码复杂度分析（使用专业工具如 SonarQube）

## Quick Reference

| 统计类型 | 命令 | 示例 |
|---------|------|------|
| 完整统计 | `stats.sh` | `stats.sh` |
| 代码行数 | `stats.sh -l` | `stats.sh -l` |
| 模块统计 | `stats.sh -m` | `stats.sh -m` |
| 测试统计 | `stats.sh -t` | `stats.sh -t` |

## Usage Examples

### 查看完整统计

用户："显示项目统计信息"

执行：
```bash
./scripts/stats.sh
```

输出格式：
```
═══════════════════════════════════════════════════════
虚拟机项目统计
═══════════════════════════════════════════════════════

📁 总体统计
───────────────────────────────────────────────────────
Java源文件: 280 个
测试文件:    99 个
测试覆盖率:  35.3%

📊 代码行数统计
───────────────────────────────────────────────────────
virtual-base:
  总计: 2046 行
  生产: 890 行
  测试: 1156 行

virtual-hardware:
  总计: 5432 行
  生产: 3890 行
  测试: 1542 行
```

### 只查看代码行数

用户："统计代码行数"

执行：
```bash
./scripts/stats.sh -l
```

### 只查看测试统计

用户："测试覆盖率多少？"

执行：
```bash
./scripts/stats.sh -t
```

## Understanding Metrics

### 测试覆盖率

```
测试覆盖率 = 测试文件数 / (Java 源文件数 + 测试文件数)
```

- **35.3%**：表示每 3 个文件中有 1 个是测试文件
- **注意**：这是文件级覆盖率，不是代码行覆盖率

### 代码行数分类

- **总计**：生产代码 + 测试代码
- **生产**：src/main/java 下的代码
- **测试**：src/test/java 下的代码

**健康指标**：
- 测试代码占比 > 30%：良好
- 测试代码占比 > 50%：优秀
- 测试代码占比 < 20%：需改进

## Output Parsing

脚本返回格式化的文本输出，包含：
- **彩色标记**：模块（绿色）、数字（黄色）、警告（红色）
- **树状结构**：按模块组织统计信息
- **汇总信息**：总体文件数、测试覆盖率

解析建议：
1. 模块名：`virtual-base:` 或 `${GREEN}${module}${NC}:`
2. 行数：`总计: 2046 行` 格式
3. 覆盖率：`测试覆盖率: 35.3%` 格式

## Comparison with Manual Calculation

| 方法 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **stats.sh** | 一条命令、格式化输出、模块级统计 | 仅支持本项目结构 | 快速了解项目规模 |
| find + wc + cloc | 更精确、支持复杂统计 | 需要组合多个命令 | 需要自定义统计 |

手动计算示例：
```bash
# 统计 Java 文件数
find . -name "*.java" -type f | grep -v target | wc -l

# 统计代码行数（不含空行和注释）
find . -name "*.java" -type f | grep -v target | xargs wc -l

# 使用 cloc（需要安装）
cloc . --exclude-dir=target
```

## Implementation

脚本位于：`scripts/stats.sh`

调用方式（通过 Bash 工具）：
```bash
cd /path/to/project && ./scripts/stats.sh
```

脚本使用的命令：
- `find` - 查找文件
- `wc` - 统计行数
- `grep` - 过滤文件

## Common Mistakes

1. **包含 target 目录**：脚本自动过滤编译输出目录
2. **混淆文件覆盖率和行覆盖率**：stats.sh 显示的是文件级覆盖率
3. **忽略空白项目**：新项目测试覆盖率低是正常的
4. **过度追求高覆盖率**：70-80% 的文件覆盖率通常是合理的平衡点

## Real-World Impact

- **效率提升 80%**：从多个命令组合到一条命令
- **快速评估项目规模**：新成员 5 秒了解项目大小
- **数据驱动决策**：量化测试覆盖，识别测试不足的模块
- **项目健康监控**：定期运行，跟踪代码增长趋势

## Use Cases

### 场景 1：新成员加入

用户："这个项目有多大？"

执行：`./scripts/stats.sh`

快速了解：280 个源文件，99 个测试文件，约 1.5 万行代码。

### 场景 2：评估测试覆盖

用户："哪些模块测试不足？"

执行：`./scripts/stats.sh -m`

查看各模块的测试代码占比，识别 < 20% 的模块。

### 场景 3：代码审查前

用户："这次变更增加了多少代码？"

执行：
```bash
# 变更前
./scripts/stats.sh > before.txt

# 变更后
./scripts/stats.sh > after.txt

# 对比
diff before.txt after.txt
```

### 场景 4：重构评估

用户："重构后代码行数变化？"

执行：`./scripts/stats.sh -l`

对比重构前后的代码行数，验证简化效果。
