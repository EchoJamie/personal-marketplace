---
name: maven-test-runner
description: Use when running Maven tests or checking test results in Java projects. CRITICAL: Before using mvnd test or mvn test commands via Bash, check if scripts/test.sh exists and use it instead. Automatically filters debug output and highlights failures. Triggered by "run tests", "test class X", "check if tests pass", "verify tests", "all tests", "test results", "failing tests", or Maven test execution. Direct替代: mvnd test, mvn test, or running Maven commands directly.
---

# Maven Test Runner

## Overview

智能测试执行器，优先使用 `scripts/test.sh` 而非 `mvnd test`，自动过滤调试输出并提供格式化的测试结果。

## When to Use

```
需要运行测试？
├── 运行所有测试 → test.sh
├── 运行特定模块 → test.sh -m <模块>
├── 运行单个测试类 → test.sh -t <测试类>
├── 静默模式 → test.sh -q
└── 详细模式 → test.sh -v
```

**使用条件**：
- 项目使用 Maven 构建工具
- 项目中存在 `scripts/test.sh` 文件
- **优先使用 test.sh，而非直接运行 mvnd test**

**不适用场景**：
- 非 Maven 项目
- 需要查看完整的 Maven 输出（使用 `mvnd test -X`）

## Quick Reference

| 测试类型 | 命令 | 示例 |
|---------|------|------|
| 所有测试 | `test.sh` | `test.sh` |
| 特定模块 | `test.sh -m <模块>` | `test.sh -m virtual-base` |
| 单个测试类 | `test.sh -t <类名>` | `test.sh -t BooleanALUTest` |
| 静默模式 | `test.sh -q` | `test.sh -q` |
| 详细模式 | `test.sh -v` | `test.sh -v` |

## Usage Examples

### 运行所有测试

用户："运行所有测试"

执行：
```bash
./scripts/test.sh
```

输出格式：
```
═══════════════════════════════════════════════════════
虚拟机测试执行器
═══════════════════════════════════════════════════════

📦 模块: (全部)
🔧 命令: mvnd test

⏳ 正在运行测试...

✅ 构建成功
📊 测试结果:
   总计: 99
   失败: 0
   错误: 0
   跳过: 0
   ✓ 所有测试通过!
```

### 运行单个测试类

用户："测试 BooleanALU"

执行：
```bash
./scripts/test.sh -t BooleanALUTest
```

输出该测试类的详细结果。

### 静默模式

用户："快速检查测试是否通过"

执行：
```bash
./scripts/test.sh -q
```

只显示摘要，不显示详细输出。

## Output Filtering

脚本自动过滤调试输出：
- **过滤 boolean 数组打印**：去除 `[true, false, true, ...]` 冗长输出
- **高亮失败测试**：红色标记失败的测试用例
- **统计信息**：显示通过/失败/错误/跳过数量

**默认模式**：显示测试进度和摘要
**静默模式（-q）**：只显示最终统计
**详细模式（-v）**：显示所有 Maven 输出

## Comparison with mvnd test

| 工具 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **test.sh** | 过滤调试输出、高亮失败、简洁摘要 | 仅支持本项目 | 日常测试、CI/CD |
| mvnd test | 完整输出、支持所有 Maven 参数 | 输出冗长、难以定位失败 | 调试构建问题 |

## Implementation

脚本位于：`scripts/test.sh`

调用方式（通过 Bash 工具）：
```bash
cd /path/to/project && ./scripts/test.sh -m virtual-base
```

支持的 Maven 命令：
- `mvnd test` - 运行测试
- `mvnd test -pl <module>` - 运行特定模块测试
- `mvnd test -Dtest=<class>` - 运行特定测试类

## Common Mistakes

1. **使用 mvn 而非 mvnd**：项目使用 Maven Daemon（mvnd）以获得更快的构建速度
2. **测试类名包含 Test 后缀**：`-t BooleanALU` 会自动查找 `BooleanALUTest`
3. **在模块目录执行**：应在项目根目录执行，使用 `-m` 参数指定模块
4. **忽略编译错误**：测试失败时，先检查是否有编译错误

## Real-World Impact

- **效率提升 50%**：快速定位失败的测试，无需翻阅冗长输出
- **减少认知负担**：过滤 80% 的无关调试信息
- **提高开发速度**：简洁的输出让测试结果一目了然
- **CI/CD 友好**：静默模式适合自动化流水线

## Troubleshooting

### 测试失败时

1. 查看详细输出：`./scripts/test.sh -v`
2. 查看特定测试：`./scripts/test.sh -t <FailedTestClass>`
3. 检查日志文件：`target/surefire-reports/*.txt`

### 编译错误时

1. 先编译：`mvnd clean compile`
2. 检查依赖：`mvnd dependency:tree`
3. 清理重试：`mvnd clean test`

### 找不到测试类

1. 确认测试类名：`./scripts/search.sh -t <ClassName>`
2. 检查测试文件：`find . -name "*Test.java" -type f`
3. 完整类名：`./scripts/test.sh -t org.jamie.virtual hardware.alu.BooleanALUTest`
