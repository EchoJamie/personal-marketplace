#!/bin/bash
#
# 项目统计脚本
# 功能: 显示项目代码统计信息
#
# 用法:
#   scripts/stats.sh                    # 显示完整统计
#   scripts/stats.sh -l                 # 只显示代码行数
#   scripts/stats.sh -m                 # 只显示模块统计
#   scripts/stats.sh -t                 # 只显示测试统计
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认参数
SHOW_LINES=true
SHOW_MODULES=true
SHOW_TESTS=true

# 解析参数
while getopts "lmt" opt; do
    case $opt in
        l) SHOW_LINES=true; SHOW_MODULES=false; SHOW_TESTS=false ;;
        m) SHOW_LINES=false; SHOW_MODULES=true; SHOW_TESTS=false ;;
        t) SHOW_LINES=false; SHOW_MODULES=false; SHOW_TESTS=true ;;
        \?) echo "用法: $0 [-l] [-m] [-t]" >&2; exit 1 ;;
    esac
done

# 输出标题
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}虚拟机项目统计${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# 1. 显示总体统计
echo -e "${CYAN}📁 总体统计${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

# 统计Java文件总数
JAVA_FILES=$(find . -name "*.java" -type f | wc -l | tr -d ' ')
echo -e "Java源文件: ${GREEN}$JAVA_FILES${NC} 个"

# 统计测试文件
TEST_FILES=$(find . -name "*Test.java" -type f | wc -l | tr -d ' ')
echo -e "测试文件:    ${GREEN}$TEST_FILES${NC} 个"

# 计算测试覆盖率
if [ "$JAVA_FILES" -gt 0 ]; then
    COVERAGE=$(echo "scale=1; $TEST_FILES * 100 / $JAVA_FILES" | bc)
    echo -e "测试覆盖率:  ${YELLOW}$COVERAGE%${NC}"
fi
echo ""

# 2. 显示代码行数统计
if [ "$SHOW_LINES" = true ]; then
    echo -e "${CYAN}📊 代码行数统计${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

    # 统计各模块代码行数
    for module in virtual-base virtual-hardware virtual-memory virtual-storage virtual-computer virtual-instruction virtual-app virtual-cpu; do
        if [ -d "$module" ]; then
            # 统计Java代码行数(排除注释和空行)
            LINES=$(find "$module"/src -name "*.java" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
            # 统计测试代码行数
            TEST_LINES=$(find "$module"/src/test -name "*.java" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
            # 统计生产代码行数
            PROD_LINES=$(find "$module"/src/main -name "*.java" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")

            if [ "$LINES" != "0" ]; then
                echo -e "$module:"
                echo -e "  总计: ${GREEN}$LINES${NC} 行"
                echo -e "  生产: ${GREEN}$PROD_LINES${NC} 行"
                echo -e "  测试: ${GREEN}$TEST_LINES${NC} 行"
            fi
        fi
    done

    # 统计总行数
    TOTAL_LINES=$(find . -path ./virtual-cpu -prune -o -name "*.java" -type f -print | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    echo -e ""
    echo -e "总计: ${GREEN}$TOTAL_LINES${NC} 行代码"
    echo ""
fi

# 3. 显示模块统计
if [ "$SHOW_MODULES" = true ]; then
    echo -e "${CYAN}📦 模块统计${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

    for module in virtual-base virtual-hardware virtual-memory virtual-storage virtual-computer virtual-instruction virtual-app virtual-cpu; do
        if [ -d "$module" ]; then
            # 统计该模块的Java文件
            MODULE_JAVA=$(find "$module"/src -name "*.java" -type f 2>/dev/null | wc -l | tr -d ' ')
            # 统计该模块的测试文件
            MODULE_TEST=$(find "$module"/src/test -name "*Test.java" -type f 2>/dev/null | wc -l | tr -d ' ')

            if [ "$MODULE_JAVA" != "0" ]; then
                echo -e "$module: ${GREEN}$MODULE_JAVA${NC} 文件, ${YELLOW}$MODULE_TEST${NC} 测试"
            fi
        fi
    done
    echo ""
fi

# 4. 显示测试统计
if [ "$SHOW_TESTS" = true ]; then
    echo -e "${CYAN}🧪 测试统计${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

    # 统计各模块测试数
    for module in virtual-base virtual-hardware virtual-memory virtual-storage virtual-computer virtual-instruction virtual-app virtual-cpu; do
        if [ -d "$module" ]; then
            TEST_COUNT=$(find "$module"/src/test -name "*Test.java" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$TEST_COUNT" != "0" ]; then
                echo -e "$module: ${GREEN}$TEST_COUNT${NC} 个测试类"
            fi
        fi
    done
    echo ""

    # 统计总测试用例数(如果有Maven)
    if command -v mvnd &> /dev/null; then
        echo -e "运行所有测试以获取详细统计..."
        echo -e "命令: ${YELLOW}./scripts/test.sh -q${NC}"
    fi
    echo ""
fi

# 5. 显示文件类型统计
echo -e "${CYAN}📄 文件类型统计${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

# 统计各种文件类型
JAVA_COUNT=$(find . -name "*.java" | wc -l | tr -d ' ')
XML_COUNT=$(find . -name "pom.xml" | wc -l | tr -d ' ')
MD_COUNT=$(find . -name "*.md" | wc -l | tr -d ' ')
SH_COUNT=$(find . -name "*.sh" | wc -l | tr -d ' ')

echo -e "Java文件:  ${GREEN}$JAVA_COUNT${NC} 个"
echo -e "POM文件:   ${GREEN}$XML_COUNT${NC} 个"
echo -e "Markdown:  ${GREEN}$MD_COUNT${NC} 个"
echo -e "Shell脚本: ${GREEN}$SH_COUNT${NC} 个"
echo ""

# 6. 显示Git统计(如果在git仓库中)
if [ -d ".git" ]; then
    echo -e "${CYAN}🔧 Git统计${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

    # 统计分支数
    BRANCHES=$(git branch -a | wc -l | tr -d ' ')
    echo -e "分支数量: ${GREEN}$BRANCHES${NC} 个"

    # 统计提交数
    COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "N/A")
    echo -e "提交总数: ${GREEN}$COMMITS${NC} 次"

    # 统计 contributors
    if command -v git &> /dev/null; then
        CONTRIBUTORS=$(git shortlog -sn | wc -l | tr -d ' ')
        echo -e "贡献者:   ${GREEN}$CONTRIBUTORS${NC} 人"
    fi

    # 显示当前分支
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
    echo -e "当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 统计完成!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
