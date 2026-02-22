#!/bin/bash
#
# 智能代码搜索工具
# 功能: 快速搜索类定义、方法调用、测试用例等
#
# 用法:
#   scripts/search.sh -c BooleanALU          # 搜索类定义
#   scripts/search.sh -c CPU -n             # 搜索类并显示行号
#   scripts/search.sh -c CPU -I             # 只搜索接口
#   scripts/search.sh -c CPU -l             # 只搜索类，不包括接口
#   scripts/search.sh -m add                # 搜索方法定义
#   scripts/search.sh -M add                # 搜索方法调用
#   scripts/search.sh -t Add                # 搜索测试用例
#   scripts/search.sh -i "CPU.*step"        # 正则表达式搜索
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 默认参数
SEARCH_CLASS=false
SEARCH_METHOD=false
SEARCH_METHOD_CALL=false
SEARCH_TEST=false
REGEX_SEARCH=false
PATTERN=""
EXCLUDE_DIRS="target|.worktrees|.git"

# 类搜索选项
CLASS_ONLY=false
INTERFACE_ONLY=false
SHOW_LINE_NUMBERS=false

# 解析参数
while getopts "c:nIlm:M:t:i:" opt; do
    case $opt in
        c) SEARCH_CLASS=true; PATTERN="$OPTARG" ;;
        n) SHOW_LINE_NUMBERS=true ;;
        I) INTERFACE_ONLY=true ;;
        l) CLASS_ONLY=true ;;
        m) SEARCH_METHOD=true; PATTERN="$OPTARG" ;;
        M) SEARCH_METHOD_CALL=true; PATTERN="$OPTARG" ;;
        t) SEARCH_TEST=true; PATTERN="$OPTARG" ;;
        i) REGEX_SEARCH=true; PATTERN="$OPTARG" ;;
        \?) echo "用法: $0 [选项] <模式>" >&2; exit 1 ;;
    esac
done

# 如果没有指定模式，显示帮助
if [ -z "$PATTERN" ]; then
    echo "用法: $0 [选项] <模式>"
    echo ""
    echo "选项:"
    echo "  -c <模式>  搜索类定义"
    echo "  -n         显示行号 (用于 -c)"
    echo "  -I         只搜索接口 (用于 -c)"
    echo "  -l         只搜索类，不包括接口 (用于 -c)"
    echo "  -m <模式>  搜索方法定义"
    echo "  -M <模式>  搜索方法调用"
    echo "  -t <模式>  搜索测试用例"
    echo "  -i <模式>  正则表达式搜索"
    echo ""
    echo "示例:"
    echo "  $0 -c BooleanALU           # 查找 BooleanALU 类"
    echo "  $0 -c CPU -I               # 只查找接口"
    echo "  $0 -c CPU -l               # 只查找类，不包括接口"
    echo "  $0 -c ALU -n               # 查找类并显示行号"
    echo "  $0 -m add                  # 查找 add 方法定义"
    echo "  $0 -M add                  # 查找 add 方法调用"
    echo "  $0 -t AddInstruction       # 查找 AddInstruction 测试"
    echo "  $0 -i 'CPU.*step'          # 正则表达式搜索"
    exit 1
fi

# 输出标题
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}智能代码搜索${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# 搜索类定义
search_class() {
    local pattern="$1"
    echo -e "${CYAN}搜索类定义: ${YELLOW}${pattern}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    # 根据选项调整搜索
    if [ "$INTERFACE_ONLY" = true ]; then
        local results=$(find . -name "*.java" -type f \
            -exec grep -l "interface ${pattern}" {} \; 2>/dev/null | \
            grep -vE "$EXCLUDE_DIRS" | sort)
    elif [ "$CLASS_ONLY" = true ]; then
        # 搜索类但排除接口
        local results=$(find . -name "*.java" -type f \
            -exec grep -l "class ${pattern}" {} \; 2>/dev/null | \
            grep -vE "$EXCLUDE_DIRS" | \
            while read file; do
                if ! grep -q "interface ${pattern}" "$file"; then
                    echo "$file"
                fi
            done | sort)
    else
        # 搜索类或接口
        local results=$(find . -name "*.java" -type f \
            -exec grep -l "\(class\|interface\) ${pattern}" {} \; 2>/dev/null | \
            grep -vE "$EXCLUDE_DIRS" | sort)
    fi

    if [ -z "$results" ]; then
        echo -e "${RED}未找到匹配的类${NC}"
        return
    fi

    echo "$results" | while read file; do
        # 判断类型
        if grep -q "interface ${pattern}" "$file"; then
            local type="接口"
            local icon="📘"
        elif grep -q "enum ${pattern}" "$file"; then
            local type="枚举"
            local icon="📋"
        else
            local type="类"
            local icon="📄"
        fi

        # 获取模块
        local module=$(echo "$file" | cut -d'/' -f2)

        # 获取包名
        local package=$(grep "^package " "$file" 2>/dev/null | head -1 | sed 's/package //;s/;//')

        # 显示基本信息
        echo -e "${icon} ${BOLD}${pattern}${NC} ${CYAN}[${type}]${NC}"
        echo -e "   📦 模块: ${GREEN}${module}${NC}"
        echo -e "   📂 路径: ${YELLOW}${file#./}${NC}"

        # 显示行号
        if [ "$SHOW_LINE_NUMBERS" = true ]; then
            local line_num=$(grep -n "\(class\|interface\) ${pattern}" "$file" | head -1 | cut -d':' -f1)
            echo -e "   📍 位置: ${YELLOW}第 ${line_num} 行${NC}"
        fi

        echo -e "   🏷️  包名: ${package}"

        # 显示类的一行注释(如果有)
        local comment=$(grep -B2 "\(class\|interface\) ${pattern}" "$file" | grep "^\s*\*" | head -1 | sed 's/^\s*\*\s*//' | head -c 80)
        if [ -n "$comment" ]; then
            echo -e "   💬 ${comment}..."
        fi

        echo ""
    done

    echo -e "${GREEN}共找到 $(echo "$results" | wc -l | tr -d ' ') 个结果${NC}"
    echo ""
}

# 搜索方法定义
search_method_def() {
    local pattern="$1"
    echo -e "${CYAN}搜索方法定义: ${YELLOW}${pattern}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    local results=$(grep -rn "public.*${pattern}.*(" --include="*.java" . 2>/dev/null | \
        grep -vE "$EXCLUDE_DIRS" | grep -v "Test\.java:" | head -20)

    if [ -z "$results" ]; then
        echo -e "${RED}未找到匹配的方法定义${NC}"
        return
    fi

    local count=0
    echo "$results" | while read line; do
        ((count++))

        local file=$(echo "$line" | cut -d':' -f1)
        local line_num=$(echo "$line" | cut -d':' -f2)
        local content=$(echo "$line" | cut -d':' -f3-)

        # 提取方法签名
        local method_sig=$(echo "$content" | sed 's/^\s*//' | sed 's/{.*$//')

        echo -e "${GREEN}${count}.${NC} ${CYAN}${file#./}${NC}:${YELLOW}${line_num}${NC}"
        echo -e "   ${method_sig}"
        echo ""
    done

    echo -e "${GREEN}共找到 $(echo "$results" | wc -l | tr -d ' ') 个结果${NC}"
    echo ""
}

# 搜索方法调用
search_method_call() {
    local pattern="$1"
    echo -e "${CYAN}搜索方法调用: ${YELLOW}${pattern}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    local results=$(grep -rn "\.${pattern}(" --include="*.java" . 2>/dev/null | \
        grep -vE "$EXCLUDE_DIRS" | head -20)

    if [ -z "$results" ]; then
        echo -e "${RED}未找到匹配的方法调用${NC}"
        return
    fi

    local count=0
    echo "$results" | while read line; do
        ((count++))

        local file=$(echo "$line" | cut -d':' -f1)
        local line_num=$(echo "$line" | cut -d':' -f2)
        local content=$(echo "$line" | cut -d':' -f3-)

        echo -e "${GREEN}${count}.${NC} ${CYAN}${file#./}${NC}:${YELLOW}${line_num}${NC}"
        echo -e "   ${content}"
        echo ""
    done

    echo -e "${GREEN}共找到 $(echo "$results" | wc -l | tr -d ' ') 个结果${NC}"
    echo ""
}

# 搜索测试用例
search_test() {
    local pattern="$1"
    echo -e "${CYAN}搜索测试用例: ${YELLOW}${pattern}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    # 查找测试文件
    local test_files=$(find . -name "*Test.java" -type f 2>/dev/null | \
        grep -vE "$EXCLUDE_DIRS" | grep -i "$pattern")

    if [ -z "$test_files" ]; then
        echo -e "${RED}未找到匹配的测试文件${NC}"
        return
    fi

    echo "$test_files" | while read test_file; do
        local test_name=$(basename "$test_file" .java)

        echo -e "${BOLD}📝 ${test_name}${NC}"
        echo -e "   路径: ${CYAN}${test_file#./}${NC}"
        echo ""

        # 提取测试方法
        echo -e "   测试方法:"
        grep -n "@Test" -A 1 "$test_file" 2>/dev/null | grep "public void" | \
            sed 's/.*public void //' | sed 's/(.*$//' | head -10 | while read method; do
            echo -e "     • ${GREEN}${method}${NC}"
        done
        echo ""
    done

    echo -e "${GREEN}共找到 $(echo "$test_files" | wc -l | tr -d ' ') 个测试文件${NC}"
    echo ""
}

# 正则表达式搜索
regex_search() {
    local pattern="$1"
    echo -e "${CYAN}正则表达式搜索: ${YELLOW}${pattern}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    local results=$(grep -rn "$pattern" --include="*.java" . 2>/dev/null | \
        grep -vE "$EXCLUDE_DIRS" | head -30)

    if [ -z "$results" ]; then
        echo -e "${RED}未找到匹配的结果${NC}"
        return
    fi

    local count=0
    echo "$results" | while read line; do
        ((count++))

        local file=$(echo "$line" | cut -d':' -f1)
        local line_num=$(echo "$line" | cut -d':' -f2)
        local content=$(echo "$line" | cut -d':' -f3-)

        echo -e "${GREEN}${count}.${NC} ${CYAN}${file#./}${NC}:${YELLOW}${line_num}${NC}"
        echo -e "   ${content}"
        echo ""
    done

    echo -e "${GREEN}共找到 $(echo "$results" | wc -l | tr -d ' ') 个结果${NC}"
    echo ""
}

# 执行搜索
if [ "$SEARCH_CLASS" = true ]; then
    search_class "$PATTERN"
elif [ "$SEARCH_METHOD" = true ]; then
    search_method_def "$PATTERN"
elif [ "$SEARCH_METHOD_CALL" = true ]; then
    search_method_call "$PATTERN"
elif [ "$SEARCH_TEST" = true ]; then
    search_test "$PATTERN"
elif [ "$REGEX_SEARCH" = true ]; then
    regex_search "$PATTERN"
else
    # 默认：智能判断搜索类型
    # 如果是驼峰命名，可能是类或方法
    if echo "$PATTERN" | grep -q "^[A-Z]"; then
        search_class "$PATTERN"
    else
        search_method_def "$PATTERN"
    fi
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
