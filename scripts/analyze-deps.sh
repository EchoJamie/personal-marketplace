#!/bin/bash
#
# 模块依赖分析工具
# 功能: 分析Maven模块间的依赖关系
#
# 用法:
#   scripts/analyze-deps.sh              # 显示依赖树
#   scripts/analyze-deps.sh -m           # 显示依赖矩阵
#   scripts/analyze-deps.sh -c           # 检测循环依赖
#   scripts/analyze-deps.sh -s virtual-base # 分析特定模块
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 默认参数
SHOW_MATRIX=false
CHECK_CIRCULAR=false
SPECIFIC_MODULE=""

# 解析参数
while getopts "mcs:" opt; do
    case $opt in
        m) SHOW_MATRIX=true ;;
        c) CHECK_CIRCULAR=true ;;
        s) SPECIFIC_MODULE="$OPTARG" ;;
        \?) echo "用法: $0 [-m] [-c] [-s module]" >&2; exit 1 ;;
    esac
done

# 输出标题
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Maven模块依赖分析工具${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# 获取所有模块
get_modules() {
    grep "<module>" pom.xml | sed 's/.*<module>\(.*\)<\/module>.*/\1/' | grep -v "virtual-cpu" || true
}

# 获取模块的依赖
get_module_dependencies() {
    local module=$1
    local pom_file="${module}/pom.xml"

    if [ ! -f "$pom_file" ]; then
        echo ""
        return
    fi

    # 提取dependencies
    awk '/<dependencies>/,/<\/dependencies>/' "$pom_file" | \
        grep '<artifactId>virtual-' | \
        sed 's/.*<artifactId>\(virtual-.*\)<\/artifactId>.*/\1/' | \
        grep -v "^virtual-cpu$" || true
}

# 显示依赖树
show_dependency_tree() {
    echo -e "${CYAN}📊 模块依赖树${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    for module in $(get_modules); do
        if [ ! -d "$module" ]; then
            continue
        fi

        echo -e "${GREEN}${module}${NC}"
        deps=$(get_module_dependencies "$module")

        if [ -z "$deps" ]; then
            echo -e "  ${YELLOW}无依赖${NC}"
        else
            echo "$deps" | while read dep; do
                echo -e "  ├── ${dep}"
            done
        fi
        echo ""
    done
}

# 显示依赖矩阵
show_dependency_matrix() {
    echo -e "${CYAN}📊 依赖关系矩阵${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    local modules=($(get_modules))
    local module_count=${#modules[@]}

    # 打印表头
    printf "%-20s" ""
    for mod in "${modules[@]}"; do
        printf " %-3s" "$(echo $mod | cut -c1-3 | tr '[:lower:]' '[:upper:]')"
    done
    echo ""

    # 打印矩阵
    for i in "${!modules[@]}"; do
        local mod1="${modules[$i]}"
        printf "%-20s" "$mod1"

        for j in "${!modules[@]}"; do
            local mod2="${modules[$j]}"

            if [ "$i" -eq "$j" ]; then
                printf " ${GREEN}●${NC}  "
            elif depends_on "$mod1" "$mod2"; then
                printf " ${RED}↑${NC}  "
            else
                printf "    "
            fi
        done
        echo ""
    done

    echo ""
    echo -e "图例: ${GREEN}●${NC} 自己  ${RED}↑${NC} 依赖"
    echo ""
}

# 检查模块A是否依赖模块B
depends_on() {
    local module_a=$1
    local module_b=$2
    local deps=$(get_module_dependencies "$module_a")
    echo "$deps" | grep -q "^${module_b}$"
}

# 检测循环依赖
check_circular_dependencies() {
    echo -e "${CYAN}🔍 循环依赖检测${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    local modules=($(get_modules))
    local found_circular=false

    # 使用深度优先搜索检测循环
    for start_module in "${modules[@]}"; do
        local visited=""
        local path=""

        if detect_cycle "$start_module" "$visited" "$path"; then
            found_circular=true
        fi
    done

    if [ "$found_circular" = false ]; then
        echo -e "${GREEN}✅ 未检测到循环依赖${NC}"
    fi

    echo ""
}

# 检测循环依赖(递归)
detect_cycle() {
    local current_module=$1
    local visited="$2"
    local path="$3"

    # 如果已在路径中,发现循环
    if echo "$visited" | grep -q ":${current_module}:"; then
        echo -e "${RED}❌ 发现循环依赖:${NC}"
        echo "$path" | tr ':' '\n' | while read mod; do
            [ -n "$mod" ] && echo -e "  ${YELLOW}→${NC} ${mod}"
        done
        echo -e "  ${YELLOW}→${NC} ${current_module} ${RED}(循环!)${NC}"
        echo ""
        return 0
    fi

    # 标记为已访问
    local new_visited="${visited}:${current_module}:"
    local new_path="${path}:${current_module}"

    # 递归检查依赖
    local deps=$(get_module_dependencies "$current_module")
    echo "$deps" | while read dep; do
        [ -n "$dep" ] && detect_cycle "$dep" "$new_visited" "$new_path"
    done

    return 1
}

# 分析特定模块
analyze_specific_module() {
    local module=$1

    echo -e "${CYAN}📦 模块分析: ${GREEN}${module}${NC}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo ""

    # 显示直接依赖
    echo -e "📥 直接依赖:"
    local direct_deps=$(get_module_dependencies "$module")
    if [ -z "$direct_deps" ]; then
        echo -e "  ${YELLOW}无依赖${NC}"
    else
        echo "$direct_deps" | while read dep; do
            echo -e "  • ${dep}"
        done
    fi
    echo ""

    # 显示被哪些模块依赖
    echo -e "📤 被依赖:"
    local dependents=""
    for mod in $(get_modules); do
        if [ "$mod" != "$module" ]; then
            if depends_on "$mod" "$module"; then
                dependents="${dependents}${mod} "
            fi
        fi
    done

    if [ -z "$dependents" ]; then
        echo -e "  ${YELLOW}无${NC}"
    else
        echo "$dependents" | tr ' ' '\n' | grep -v "^$" | while read dep; do
            echo -e "  • ${dep}"
        done
    fi
    echo ""

    # 计算耦合度
    local dep_count=$(echo "$direct_deps" | grep -c "^.*$" || echo "0")
    local dependent_count=$(echo "$dependents" | tr ' ' '\n' | grep -c "^.*$" || echo "0")

    echo -e "📊 耦合度分析:"
    echo -e "  下行依赖(afferent): ${GREEN}${dep_count}${NC}"
    echo -e "  上行依赖(efferent): ${GREEN}${dependent_count}${NC}"

    # 计算不稳定性指标(I)
    # I = Ce / (Ce + Ca)
    # Ce = efferent coupling (向外依赖)
    # Ca = afferent coupling (被依赖)
    if [ $((dep_count + dependent_count)) -gt 0 ]; then
        local instability=$(echo "scale=2; $dep_count / ($dep_count + $dependent_count)" | bc)
        echo -e "  不稳定性(I): ${YELLOW}${instability}${NC} ${CYAN}(越接近0越稳定)${NC}"
    fi
    echo ""
}

# 主逻辑
if [ -n "$SPECIFIC_MODULE" ]; then
    if [ ! -d "$SPECIFIC_MODULE" ]; then
        echo -e "${RED}❌ 模块不存在: $SPECIFIC_MODULE${NC}"
        exit 1
    fi
    analyze_specific_module "$SPECIFIC_MODULE"
elif [ "$SHOW_MATRIX" = true ]; then
    show_dependency_matrix
elif [ "$CHECK_CIRCULAR" = true ]; then
    check_circular_dependencies
else
    show_dependency_tree
fi

# 显示建议
echo -e "${CYAN}💡 建议${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
echo -e "• ${YELLOW}依赖过多${NC}: 考虑拆分模块或引入接口层"
echo -e "• ${YELLOW}被依赖过多${NC}: 说明模块是核心,需保持稳定"
echo -e "• ${YELLOW}不稳定性过高${NC}: 模块过于依赖外部,容易受影响"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
