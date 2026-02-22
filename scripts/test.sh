#!/bin/bash
#
# 智能测试脚本
# 功能: 运行Maven测试并格式化输出结果
#
# 用法:
#   scripts/test.sh                    # 运行所有测试
#   scripts/test.sh -m virtual-hardware # 运行特定模块测试
#   scripts/test.sh -t BooleanALUTest  # 运行单个测试类
#   scripts/test.sh -q                 # 静默模式,只显示摘要
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
MODULE=""
TEST_CLASS=""
QUIET_MODE=false
VERBOSE=false

# 解析参数
while getopts "m:t:qv" opt; do
    case $opt in
        m) MODULE="$OPTARG" ;;
        t) TEST_CLASS="$OPTARG" ;;
        q) QUIET_MODE=true ;;
        v) VERBOSE=true ;;
        \?) echo "用法: $0 [-m module] [-t test_class] [-q] [-v]" >&2; exit 1 ;;
    esac
done

# 构建Maven命令
MVN_CMD="mvnd test"
if [ -n "$MODULE" ]; then
    MVN_CMD="mvnd test -pl $MODULE"
fi
if [ -n "$TEST_CLASS" ]; then
    MVN_CMD="$MVN_CMD -Dtest=$TEST_CLASS"
fi

# 输出标题
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}虚拟机测试执行器${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# 显示执行信息
if [ -n "$MODULE" ]; then
    echo -e "📦 模块: ${GREEN}$MODULE${NC}"
fi
if [ -n "$TEST_CLASS" ]; then
    echo -e "🧪 测试类: ${GREEN}$TEST_CLASS${NC}"
fi
echo -e "🔧 命令: ${YELLOW}$MVN_CMD${NC}"
echo ""

# 执行测试并捕获输出
echo -e "${BLUE}⏳ 正在运行测试...${NC}"
echo ""

if [ "$QUIET_MODE" = true ]; then
    # 静默模式:只显示摘要
    OUTPUT=$(eval $MVN_CMD 2>&1)
    EXIT_CODE=$?

    # 提取测试结果
    TESTS_RUN=$(echo "$OUTPUT" | grep -oE 'Tests run: [0-9]+' | grep -oE '[0-9]+' | head -1)
    FAILURES=$(echo "$OUTPUT" | grep -oE 'Failures: [0-9]+' | grep -oE '[0-9]+' | head -1)
    ERRORS=$(echo "$OUTPUT" | grep -oE 'Errors: [0-9]+' | grep -oE '[0-9]+' | head -1)
    SKIPPED=$(echo "$OUTPUT" | grep -oE 'Skipped: [0-9]+' | grep -oE '[0-9]+' | head -1)

    # 显示摘要
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✅ 构建成功${NC}"
    else
        echo -e "${RED}❌ 构建失败${NC}"
    fi

    if [ -n "$TESTS_RUN" ]; then
        TOTAL_TESTS=$((TESTS_RUN + 0))
        TOTAL_FAILURES=$((FAILURES + 0))
        TOTAL_ERRORS=$((ERRORS + 0))
        TOTAL_SKIPPED=$((SKIPPED + 0))

        echo -e "📊 测试结果:"
        echo -e "   总计: ${BLUE}$TOTAL_TESTS${NC}"
        echo -e "   失败: ${RED}$TOTAL_FAILURES${NC}"
        echo -e "   错误: ${RED}$TOTAL_ERRORS${NC}"
        echo -e "   跳过: ${YELLOW}$TOTAL_SKIPPED${NC}"

        if [ $TOTAL_FAILURES -eq 0 ] && [ $TOTAL_ERRORS -eq 0 ]; then
            echo -e "${GREEN}   ✓ 所有测试通过!${NC}"
        else
            echo -e "${RED}   ✗ 存在失败的测试${NC}"
        fi
    fi
else
    # 正常模式:实时显示输出
    OUTPUT=$(eval $MVN_CMD 2>&1)
    EXIT_CODE=$?

    # 过滤并格式化输出
    echo "$OUTPUT" | while IFS= read -r line; do
        # 高亮失败信息
        if echo "$line" | grep -q "FAILURE\|ERROR"; then
            echo -e "${RED}$line${NC}"
        # 高亮测试通过信息
        elif echo "$line" | grep -q "Tests run:"; then
            echo -e "${GREEN}$line${NC}"
        # 高亮构建状态
        elif echo "$line" | grep -q "BUILD SUCCESS"; then
            echo -e "${GREEN}$line${NC}"
        elif echo "$line" | grep -q "BUILD FAILURE"; then
            echo -e "${RED}$line${NC}"
        # 静默模式:过滤掉boolean数组输出
        elif echo "$line" | grep -q "^\[.*\]\[INFO\]\[stdout\]  ==>"; then
            : # 丢弃这些行
        elif echo "$line" | grep -q "^\[.*\]\[INFO\]\[stdout\] 被加数:"; then
            : # 丢弃这些行
        elif echo "$line" | grep -q "^\[.*\]\[INFO\]\[stdout\] 加数:"; then
            : # 丢弃这些行
        elif echo "$line" | grep -q "^\[.*\]\[INFO\]\[stdout\] 结果:"; then
            : # 丢弃这些行
        elif echo "$line" | grep -q "^\[.*\]\[INFO\]\[stdout\] .*Tests" && echo "$line" | grep -q "Tests"; then
            : # 丢弃测试标题
        # 详细模式:显示所有Maven输出
        elif [ "$VERBOSE" = true ]; then
            echo "$line"
        # 默认模式:只显示重要信息
        elif echo "$line" | grep -q "BUILD\|Running\|Tests run:"; then
            echo "$line"
        fi
    done

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

    # 显示最终摘要
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✅ 所有测试通过!${NC}"
    else
        echo -e "${RED}❌ 存在失败的测试,请查看上方详情${NC}"
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

exit $EXIT_CODE
