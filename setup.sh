#!/bin/bash
# =============================================================================
# KB-TEMPLATE SETUP SCRIPT
# Автоматическая настройка базы знаний для macOS
# =============================================================================
set -euo pipefail

# =============================================================================
# CONSTANTS & COLORS
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly ARROW="→"

readonly SKILLS_REPO="mdemyanov/ai-assistants"
readonly SKILLS_TO_INSTALL=("correspondence-2" "meeting-debrief")

# Global variables for user data
declare -g USER_ROLE=""
declare -g USER_COMPANY=""
declare -g USER_AREAS=""
declare -g VAULT_NAME=""
declare -g VAULT_PATH=""

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  $title${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    local step_num="$1"
    local total="$2"
    local description="$3"
    echo ""
    echo -e "${CYAN}[${step_num}/${total}]${NC} ${BOLD}$description${NC}"
}

print_success() {
    echo -e "  ${GREEN}${CHECK_MARK}${NC} $1"
}

print_error() {
    echo -e "  ${RED}${CROSS_MARK}${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "  ${DIM}${ARROW}${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local answer

    if [[ "$default" == "y" ]]; then
        echo -en "${YELLOW}$prompt [Y/n]:${NC} "
    else
        echo -en "${YELLOW}$prompt [y/N]:${NC} "
    fi

    read -r answer
    answer=${answer:-$default}

    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

wait_for_enter() {
    local message="${1:-Нажмите Enter для продолжения...}"
    echo -en "${DIM}$message${NC}"
    read -r
}

open_browser() {
    local url="$1"
    if command -v open &> /dev/null; then
        open "$url"
        return 0
    fi
    return 1
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "Этот скрипт поддерживает только macOS"
        exit 1
    fi
}

check_xcode_cli() {
    xcode-select -p &> /dev/null
}

check_homebrew() {
    command -v brew &> /dev/null
}

check_ollama() {
    if command -v ollama &> /dev/null; then
        return 0
    fi
    if [[ -d "/Applications/Ollama.app" ]]; then
        return 0
    fi
    return 1
}

check_ollama_running() {
    curl -s --connect-timeout 2 http://localhost:11434/api/version &> /dev/null
}

check_ollama_model() {
    local model="$1"
    ollama list 2>/dev/null | grep -q "$model"
}

check_uv() {
    if command -v uv &> /dev/null; then
        return 0
    fi
    if [[ -f "$HOME/.local/bin/uv" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    fi
    if [[ -f "$HOME/.cargo/bin/uv" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        return 0
    fi
    return 1
}

check_aigrep() {
    uv run aigrep --version &> /dev/null 2>&1
}

check_skills_installed() {
    local skills_dir="$HOME/.claude/skills"
    for skill in "${SKILLS_TO_INSTALL[@]}"; do
        if [[ ! -d "$skills_dir/$skill" ]]; then
            return 1
        fi
    done
    return 0
}

# =============================================================================
# INSTALL FUNCTIONS
# =============================================================================

install_xcode_cli() {
    print_info "Установка Xcode Command Line Tools..."

    xcode-select --install 2>/dev/null || true

    echo ""
    echo -e "  ${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${YELLOW}│${NC}  ${BOLD}Откроется диалог установки Xcode CLI Tools${NC}        ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}│${NC}  Нажмите \"Install\" в появившемся окне               ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}│${NC}  Дождитесь завершения установки                     ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}└─────────────────────────────────────────────────────┘${NC}"
    echo ""

    wait_for_enter "После завершения установки нажмите Enter..."

    if check_xcode_cli; then
        print_success "Xcode CLI Tools установлены"
        return 0
    else
        print_error "Xcode CLI Tools не обнаружены"
        return 1
    fi
}

install_homebrew() {
    print_info "Установка Homebrew..."

    echo ""
    echo -e "  ${DIM}Homebrew — менеджер пакетов для macOS${NC}"
    echo -e "  ${DIM}https://brew.sh${NC}"
    echo ""

    if ! confirm "Установить Homebrew?"; then
        print_warning "Пропускаю установку Homebrew"
        return 1
    fi

    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if check_homebrew; then
        print_success "Homebrew установлен"
        return 0
    else
        print_error "Ошибка установки Homebrew"
        return 1
    fi
}

wait_for_ollama() {
    local max_attempts=60
    local attempt=0

    print_info "Ожидание запуска Ollama..."

    while ! check_ollama_running; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $max_attempts ]]; then
            print_error "Ollama не запустился в течение ${max_attempts} секунд"
            return 1
        fi
        printf "\r  Попытка %d/%d..." "$attempt" "$max_attempts"
        sleep 1
    done

    printf "\r                                              \r"
    print_success "Ollama запущен"
    return 0
}

install_ollama_app() {
    print_info "Открываю страницу загрузки Ollama..."

    if open_browser "https://ollama.ai/download"; then
        echo ""
        echo -e "  ${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${YELLOW}│${NC}  ${BOLD}Инструкция:${NC}                                       ${YELLOW}│${NC}"
        echo -e "  ${YELLOW}│${NC}  1. Скачайте Ollama для macOS                       ${YELLOW}│${NC}"
        echo -e "  ${YELLOW}│${NC}  2. Откройте .dmg файл и перетащите в Applications  ${YELLOW}│${NC}"
        echo -e "  ${YELLOW}│${NC}  3. Запустите Ollama из Applications                ${YELLOW}│${NC}"
        echo -e "  ${YELLOW}│${NC}  4. Дождитесь появления иконки в меню бар           ${YELLOW}│${NC}"
        echo -e "  ${YELLOW}└─────────────────────────────────────────────────────┘${NC}"
        echo ""

        wait_for_enter "После установки и запуска Ollama нажмите Enter..."

        if ! check_ollama; then
            print_error "Ollama не обнаружен. Убедитесь, что приложение установлено."
            return 1
        fi

        if ! wait_for_ollama; then
            print_warning "Попробуйте запустить Ollama из Applications вручную"
            wait_for_enter "Нажмите Enter после запуска..."

            if ! wait_for_ollama; then
                return 1
            fi
        fi

        print_success "Ollama успешно установлен и запущен"
        return 0
    else
        print_error "Не удалось открыть браузер"
        echo "  Откройте вручную: https://ollama.ai/download"
        return 1
    fi
}

pull_ollama_model() {
    local model="${1:-mxbai-embed-large}"

    if check_ollama_model "$model"; then
        print_success "Модель $model уже загружена"
        return 0
    fi

    print_info "Загрузка модели $model..."
    echo ""

    if ollama pull "$model"; then
        print_success "Модель $model загружена"
        return 0
    else
        print_error "Ошибка загрузки модели $model"
        return 1
    fi
}

install_uv() {
    print_info "Установка UV (Python package manager)..."

    curl -LsSf https://astral.sh/uv/install.sh | sh

    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    if [[ -f "$HOME/.zshrc" ]]; then
        # shellcheck disable=SC1091
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    if check_uv; then
        print_success "UV установлен: $(uv --version)"
        return 0
    else
        print_error "Ошибка установки UV"
        return 1
    fi
}

install_aigrep() {
    print_info "Установка aigrep..."

    uv pip install aigrep

    if check_aigrep; then
        print_success "aigrep установлен"
        return 0
    else
        print_error "Ошибка установки aigrep"
        return 1
    fi
}

get_latest_release() {
    local repo="$1"
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4
}

install_skills_from_release() {
    local skills_dir="$HOME/.claude/skills"
    local temp_dir="/tmp/kb-skills-$$"

    print_info "Получение последней версии skills..."

    local latest
    latest=$(get_latest_release "$SKILLS_REPO")

    if [[ -z "$latest" ]]; then
        print_error "Не удалось получить версию релиза"
        return 1
    fi

    print_info "Версия: $latest"

    local base_url="https://github.com/${SKILLS_REPO}/releases/download/${latest}"

    mkdir -p "$skills_dir" "$temp_dir"

    for skill in "${SKILLS_TO_INSTALL[@]}"; do
        print_info "Загрузка $skill..."

        if curl -L -f -o "$temp_dir/${skill}.zip" "${base_url}/${skill}.zip" 2>/dev/null; then
            unzip -o -q "$temp_dir/${skill}.zip" -d "$skills_dir/"
            print_success "Установлен: $skill"
        else
            print_warning "Не удалось загрузить: $skill"
        fi
    done

    rm -rf "$temp_dir"

    print_success "Skills установлены в $skills_dir"
    return 0
}

configure_vault() {
    local vault_path="$1"
    local vault_name="$2"

    print_info "Настройка vault: $vault_name"

    uv run aigrep config add-vault --name "$vault_name" --path "$vault_path"

    print_info "Индексация vault (может занять время)..."
    uv run aigrep index-all

    print_success "Vault '$vault_name' настроен"
    uv run aigrep stats --vault "$vault_name" 2>/dev/null || true
}

configure_mcp() {
    print_info "Настройка MCP для Claude Desktop..."

    uv run aigrep claude-config --apply

    echo ""
    echo -e "  ${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${YELLOW}│${NC}  ${BOLD}ВАЖНО: Перезапустите Claude Desktop${NC}               ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}│${NC}  Cmd+Q → Откройте заново                            ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}│${NC}  Без перезапуска MCP не активируется                ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}└─────────────────────────────────────────────────────┘${NC}"
    echo ""

    print_success "MCP конфигурация применена"
}

# =============================================================================
# PERSONALIZATION
# =============================================================================

collect_user_data() {
    print_header "Персонализация базы знаний"

    echo -e "${DIM}Ответьте на несколько вопросов для настройки базы под вашу роль.${NC}"
    echo ""

    # Role
    echo -e "${BOLD}Вопрос 1/3: Должность${NC}"
    echo "  1) CTO"
    echo "  2) CPO"
    echo "  3) COO"
    echo "  4) HR Director"
    echo "  5) Product Manager"
    echo "  6) Другое"
    echo ""

    local role_choice
    read -rp "  Выберите [1-6]: " role_choice

    case "$role_choice" in
        1) USER_ROLE="CTO" ;;
        2) USER_ROLE="CPO" ;;
        3) USER_ROLE="COO" ;;
        4) USER_ROLE="HR Director" ;;
        5) USER_ROLE="Product Manager" ;;
        6) read -rp "  Введите должность: " USER_ROLE ;;
        *) USER_ROLE="CTO"; print_warning "Выбрано по умолчанию: CTO" ;;
    esac
    echo ""

    # Company
    echo -e "${BOLD}Вопрос 2/3: Компания${NC}"
    read -rp "  Название компании: " USER_COMPANY
    echo ""

    # Areas
    echo -e "${BOLD}Вопрос 3/3: Области ответственности${NC}"
    echo -e "  ${DIM}Пример: технологическая стратегия, архитектура, команды${NC}"
    read -rp "  Введите через запятую: " USER_AREAS
    echo ""

    # Generate vault name and path
    local company_slug
    company_slug=$(echo "$USER_COMPANY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    local role_slug
    role_slug=$(echo "$USER_ROLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    VAULT_NAME="${company_slug}-${role_slug}"

    local company_formatted
    company_formatted=$(echo "$USER_COMPANY" | tr ' ' '_')
    local role_formatted
    role_formatted=$(echo "$USER_ROLE" | tr ' ' '_')
    VAULT_PATH="$HOME/Documents/${company_formatted}_${role_formatted}"

    # Summary
    echo ""
    echo -e "${BOLD}Сводка:${NC}"
    echo -e "  ${CYAN}Роль:${NC}         $USER_ROLE"
    echo -e "  ${CYAN}Компания:${NC}     $USER_COMPANY"
    echo -e "  ${CYAN}Области:${NC}      $USER_AREAS"
    echo -e "  ${CYAN}Vault name:${NC}   $VAULT_NAME"
    echo -e "  ${CYAN}Vault path:${NC}   $VAULT_PATH"
    echo ""

    if ! confirm "Всё верно?"; then
        print_info "Начинаем заново..."
        collect_user_data
    fi
}

escape_for_sed() {
    printf '%s\n' "$1" | sed 's/[&/\]/\\&/g'
}

replace_placeholders_in_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local safe_role safe_company safe_areas safe_vault_name safe_vault_path
    safe_role=$(escape_for_sed "$USER_ROLE")
    safe_company=$(escape_for_sed "$USER_COMPANY")
    safe_areas=$(escape_for_sed "$USER_AREAS")
    safe_vault_name=$(escape_for_sed "$VAULT_NAME")
    safe_vault_path=$(escape_for_sed "$VAULT_PATH")
    local today
    today=$(date +%Y-%m-%d)

    sed -i '' \
        -e "s/{{ROLE}}/${safe_role}/g" \
        -e "s/{{COMPANY}}/${safe_company}/g" \
        -e "s/{{AREAS}}/${safe_areas}/g" \
        -e "s/{{VAULT_NAME}}/${safe_vault_name}/g" \
        -e "s|{{VAULT_PATH}}|${safe_vault_path}|g" \
        -e "s/{{date}}/${today}/g" \
        "$file"

    print_success "Обновлён: $(basename "$file")"
}

# =============================================================================
# VERIFICATION
# =============================================================================

run_preflight_checks() {
    print_header "Проверка окружения"

    echo -e "${BOLD}Компоненты:${NC}"
    echo ""

    local all_ok=true

    printf "  %-30s" "Xcode CLI Tools"
    if check_xcode_cli; then
        echo -e "${GREEN}${CHECK_MARK} установлен${NC}"
    else
        echo -e "${YELLOW}○ не установлен${NC}"
        all_ok=false
    fi

    printf "  %-30s" "Homebrew"
    if check_homebrew; then
        echo -e "${GREEN}${CHECK_MARK} установлен${NC}"
    else
        echo -e "${YELLOW}○ не установлен${NC}"
        all_ok=false
    fi

    printf "  %-30s" "Ollama"
    if check_ollama; then
        if check_ollama_running; then
            echo -e "${GREEN}${CHECK_MARK} установлен и запущен${NC}"
        else
            echo -e "${YELLOW}○ установлен, не запущен${NC}"
            all_ok=false
        fi
    else
        echo -e "${YELLOW}○ не установлен${NC}"
        all_ok=false
    fi

    printf "  %-30s" "Модель mxbai-embed-large"
    if check_ollama_model "mxbai-embed-large"; then
        echo -e "${GREEN}${CHECK_MARK} загружена${NC}"
    else
        echo -e "${YELLOW}○ не загружена${NC}"
        all_ok=false
    fi

    printf "  %-30s" "UV"
    if check_uv; then
        echo -e "${GREEN}${CHECK_MARK} установлен${NC}"
    else
        echo -e "${YELLOW}○ не установлен${NC}"
        all_ok=false
    fi

    printf "  %-30s" "aigrep"
    if check_aigrep; then
        echo -e "${GREEN}${CHECK_MARK} установлен${NC}"
    else
        echo -e "${YELLOW}○ не установлен${NC}"
        all_ok=false
    fi

    printf "  %-30s" "Claude Skills"
    if check_skills_installed; then
        echo -e "${GREEN}${CHECK_MARK} установлены${NC}"
    else
        echo -e "${YELLOW}○ не установлены${NC}"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_success "Все компоненты установлены"
        return 0
    else
        print_info "Некоторые компоненты требуют установки"
        return 1
    fi
}

print_final_checklist() {
    echo ""
    print_header "Установка завершена"

    echo -e "${BOLD}Автоматически настроено:${NC}"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} Xcode CLI Tools"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} Homebrew"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} Ollama + модель mxbai-embed-large"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} UV (Python package manager)"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} aigrep + vault '${VAULT_NAME}'"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} Claude Skills"
    echo -e "  ${GREEN}${CHECK_MARK}${NC} MCP конфигурация"
    echo ""

    echo -e "${BOLD}Требуется вручную:${NC}"
    echo -e "  ${YELLOW}○${NC} Перезапустить Claude Desktop (Cmd+Q → открыть)"
    echo -e "  ${YELLOW}○${NC} Открыть базу в Obsidian: ${VAULT_PATH}"
    echo -e "  ${YELLOW}○${NC} Установить плагины Dataview и Templater в Obsidian"
    echo ""

    echo -e "${BOLD}Для проверки выполните:${NC}"
    echo -e "  ${DIM}uv run aigrep doctor${NC}"
    echo -e "  ${DIM}uv run aigrep stats --vault \"${VAULT_NAME}\"${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}Готово!${NC}"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
    echo -e "${BOLD}${BLUE}║       KB-TEMPLATE SETUP                                    ║${NC}"
    echo -e "${BOLD}${BLUE}║       Автоматическая настройка базы знаний                 ║${NC}"
    echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_macos
    print_success "macOS обнаружена"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    run_preflight_checks || true

    echo ""
    if ! confirm "Начать установку?"; then
        echo "Выход."
        exit 0
    fi

    collect_user_data

    local total_steps=9
    local current_step=0

    # Step 1: Xcode CLI
    ((current_step++))
    print_step $current_step $total_steps "Xcode Command Line Tools"
    if ! check_xcode_cli; then
        install_xcode_cli || exit 1
    else
        print_success "Уже установлен"
    fi

    # Step 2: Homebrew
    ((current_step++))
    print_step $current_step $total_steps "Homebrew"
    if ! check_homebrew; then
        install_homebrew || exit 1
    else
        print_success "Уже установлен"
    fi

    # Step 3: Ollama
    ((current_step++))
    print_step $current_step $total_steps "Ollama"
    if ! check_ollama; then
        install_ollama_app || exit 1
    else
        print_success "Уже установлен"
        if ! check_ollama_running; then
            print_info "Запуск Ollama..."
            open -a Ollama 2>/dev/null || brew services start ollama 2>/dev/null || true
            wait_for_ollama || true
        fi
    fi

    # Step 4: Ollama model
    ((current_step++))
    print_step $current_step $total_steps "Модель mxbai-embed-large"
    pull_ollama_model "mxbai-embed-large"

    # Step 5: UV
    ((current_step++))
    print_step $current_step $total_steps "UV"
    if ! check_uv; then
        install_uv || exit 1
    else
        print_success "Уже установлен: $(uv --version 2>/dev/null || echo 'ok')"
    fi

    # Step 6: aigrep
    ((current_step++))
    print_step $current_step $total_steps "aigrep"
    if ! check_aigrep; then
        install_aigrep || exit 1
    else
        print_success "Уже установлен"
    fi

    # Step 7: Copy and personalize vault
    ((current_step++))
    print_step $current_step $total_steps "Настройка базы знаний"

    if [[ "$SCRIPT_DIR" != "$VAULT_PATH" ]]; then
        print_info "Копирование базы в $VAULT_PATH..."
        mkdir -p "$(dirname "$VAULT_PATH")"
        cp -R "$SCRIPT_DIR" "$VAULT_PATH"
    fi

    print_info "Персонализация файлов..."
    replace_placeholders_in_file "$VAULT_PATH/CLAUDE.md" || true
    replace_placeholders_in_file "$VAULT_PATH/CLAUDE_DESKTOP.md" || true
    replace_placeholders_in_file "$VAULT_PATH/00_CORE/identity/scope.md" || true
    replace_placeholders_in_file "$VAULT_PATH/00_CORE/identity/constraints.md" || true
    replace_placeholders_in_file "$VAULT_PATH/00_CORE/stakeholders/index.md" || true

    configure_vault "$VAULT_PATH" "$VAULT_NAME"

    # Step 8: Skills
    ((current_step++))
    print_step $current_step $total_steps "Claude Skills"
    if ! check_skills_installed; then
        install_skills_from_release
    else
        print_success "Уже установлены"
    fi

    # Step 9: MCP
    ((current_step++))
    print_step $current_step $total_steps "MCP конфигурация"
    configure_mcp

    print_final_checklist
}

main "$@"
