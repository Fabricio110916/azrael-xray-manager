#!/bin/bash

# Banner de login SSH - VERSÃO CORRIGIDA
install_login_banner() {
  # Limpar configurações antigas com erros primeiro
  sed -i '/if \[ -f \/etc\/profile.d\/azrael-banner.sh \]; then/,/^fi$/d' /root/.bashrc ~/.bashrc 2>/dev/null
  sed -i '/AZRAEL XRAY MANAGER/d' /root/.bashrc ~/.bashrc 2>/dev/null
  sed -i '/azrael-banner/d' /root/.bashrc ~/.bashrc 2>/dev/null
  
  # 1. Criar banner no profile.d
  cat << 'EOF' > /etc/profile.d/azrael-banner.sh
#!/bin/bash

# AZRAEL XRAY MANAGER - BANNER MÍNIMO

# Verificar se é shell interativo
if [[ $- == *i* ]] && [ -n "$PS1" ]; then
  # Aguardar terminal carregar
  sleep 0.1
  
  # Limpar tela
  clear 2>/dev/null || printf "\033c"
  
  # Banner colorido - CORRETO
  printf "\033[0;35m"
  printf ' █████╗ ███████╗██████╗  █████╗ ███████╗██╗\n'
  printf '██╔══██╗╚══███╔╝██╔══██╗██╔══██╗██╔════╝██║\n'
  printf '███████║  ███╔╝ ██████╔╝███████║█████╗  ██║\n'
  printf '██╔══██║ ███╔╝  ██╔══██╗██╔══██║██╔══╝  ██║\n'
  printf '██║  ██║███████╗██║  ██║██║  ██║███████╗███████╗\n'
  printf '╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝\n'
  printf "\033[0m"
  
  printf "\033[1;36m═══════════════════════════════════════════════\033[0m\n"
  printf "\033[1;32m     AZRAEL XRAY MANAGER\033[0m\n"
  printf "\033[1;33m     Comandos: xray-menu ou xm\033[0m\n"
  printf "\033[1;36m═══════════════════════════════════════════════\033[0m\n"
fi
EOF

  chmod +x /etc/profile.d/azrael-banner.sh
  
  # 2. Configurar .bashrc do usuário atual - SEM ERROS
  USER_BASHRC="$HOME/.bashrc"
  if [ -f "$USER_BASHRC" ]; then
    echo "" >> "$USER_BASHRC"
    echo "# AZRAEL XRAY MANAGER - BANNER" >> "$USER_BASHRC"
    echo "if [ -f /etc/profile.d/azrael-banner.sh ]; then" >> "$USER_BASHRC"
    echo "    if [ -z \"\$AZRAEL_BANNER_SHOWN\" ]; then" >> "$USER_BASHRC"
    echo "        . /etc/profile.d/azrael-banner.sh" >> "$USER_BASHRC"
    echo "        export AZRAEL_BANNER_SHOWN=1" >> "$USER_BASHRC"
    echo "    fi" >> "$USER_BASHRC"
    echo "fi" >> "$USER_BASHRC"
    echo "" >> "$USER_BASHRC"
    echo "# Aliases" >> "$USER_BASHRC"
    echo "alias xray-menu='sudo /usr/local/bin/xray-menu'" >> "$USER_BASHRC"
    echo "alias xm='sudo /usr/local/bin/xray-menu'" >> "$USER_BASHRC"
  fi
  
  # 3. Configurar .bashrc do root - SEM ERROS
  ROOT_BASHRC="/root/.bashrc"
  if [ -f "$ROOT_BASHRC" ]; then
    echo "" >> "$ROOT_BASHRC"
    echo "# AZRAEL XRAY MANAGER - BANNER" >> "$ROOT_BASHRC"
    echo "if [ -f /etc/profile.d/azrael-banner.sh ]; then" >> "$ROOT_BASHRC"
    echo "    if [ -z \"\$AZRAEL_BANNER_SHOWN\" ]; then" >> "$ROOT_BASHRC"
    echo "        . /etc/profile.d/azrael-banner.sh" >> "$ROOT_BASHRC"
    echo "        export AZRAEL_BANNER_SHOWN=1" >> "$ROOT_BASHRC"
    echo "    fi" >> "$ROOT_BASHRC"
    echo "fi" >> "$ROOT_BASHRC"
    echo "" >> "$ROOT_BASHRC"
    echo "# Aliases" >> "$ROOT_BASHRC"
    echo "alias xray-menu='/usr/local/bin/xray-menu'" >> "$ROOT_BASHRC"
    echo "alias xm='/usr/local/bin/xray-menu'" >> "$ROOT_BASHRC"
  fi
  
  # 4. Configurar MOTD simples
  cat << 'EOF' > /etc/motd

AZRAEL XRAY MANAGER
Use: xray-menu ou xm
EOF
}

# =========================
# Função para desinstalar - SIMPLIFICADA
# =========================

uninstall_script() {
  echo -e "${RED}=== DESINSTALAR TUDO ===${NC}"
  echo ""
  
  read -p "Confirmar remoção completa? (s/N): " RESPONSE
  if [[ ! "$RESPONSE" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}Cancelado${NC}"
    return
  fi
  
  echo -e "${CYAN}Removendo...${NC}"
  
  # Parar serviços
  systemctl stop xray 2>/dev/null
  systemctl disable xray 2>/dev/null
  
  # Remover comandos
  rm -f /usr/local/bin/xray-menu /usr/local/bin/xm 2>/dev/null
  
  # Remover banner
  rm -f /etc/profile.d/azrael-banner.sh /etc/motd 2>/dev/null
  
  # Limpar .bashrc - remover apenas nossas linhas
  sed -i '/# AZRAEL XRAY MANAGER - BANNER/,/^fi$/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xray-menu/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xm/d' ~/.bashrc 2>/dev/null
  
  sed -i '/# AZRAEL XRAY MANAGER - BANNER/,/^fi$/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xray-menu/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xm/d' /root/.bashrc 2>/dev/null
  
  # Remover tudo do Xray
  rm -f /etc/systemd/system/xray.service 2>/dev/null
  rm -f /usr/local/bin/xray 2>/dev/null
  rm -rf /etc/xray 2>/dev/null
  rm -rf /root/.acme.sh 2>/dev/null
  
  # Recarregar systemd
  systemctl daemon-reload 2>/dev/null
  
  echo ""
  echo -e "${GREEN}✅ Tudo removido!${NC}"
  echo ""
  
  exit 0
}

XRAY_BIN="/usr/local/bin/xray"
XRAY_DIR="/etc/xray"
CONFIG="$XRAY_DIR/config.json"
SERVICE="/etc/systemd/system/xray.service"
CERT_DIR="$XRAY_DIR/cert"
DOMAIN_FILE="$XRAY_DIR/domain.txt"
PROTOCOL_FILE="$XRAY_DIR/protocol.txt"
CLIENTS_FILE="$XRAY_DIR/clients.json"

# COMANDO DO SISTEMA
MENU_CMD="/usr/local/bin/xray-menu"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$XRAY_DIR"

# =========================
# Instalar comando no sistema
# =========================

install_command() {
  # 1. Copiar script para /usr/local/bin
  sudo cp "$0" "$MENU_CMD"
  sudo chmod +x "$MENU_CMD"
  
  # 2. Criar atalho
  sudo ln -sf "$MENU_CMD" /usr/local/bin/xm 2>/dev/null || true
  
  # 3. Instalar banner de login
  install_login_banner
  
  echo -e "${GREEN} Instalação completa!${NC}"
  echo ""
  echo -e "${CYAN}Use o comando:${NC}"
  echo -e "  ${GREEN}xray-menu${NC}   ou   ${GREEN}xm${NC}"
  echo ""
}

# =========================
# Instalação Automática
# =========================

auto_install_command() {
  if [ ! -f "$MENU_CMD" ] && [ "$0" = "./$(basename "$0")" ]; then
    clear
    printf "\033[0;35m"
    printf ' █████╗ ███████╗██████╗  █████╗ ███████╗██╗\n'
    printf '██╔══██╗╚══███╔╝██╔══██╗██╔══██╗██╔════╝██║\n'
    printf '███████║  ███╔╝ ██████╔╝███████║█████╗  ██║\n'
    printf '██╔══██║ ███╔╝  ██╔══██╗██╔══██║██╔══╝  ██║\n'
    printf '██║  ██║███████╗██║  ██║██║  ██║███████╗███████╗\n'
    printf '╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝\n'
    printf "\033[0m"
    
    printf "\033[1;36m═══════════════════════════════════════════════\033[0m\n"
    printf "\033[1;32m      AZRAEL XRAY MANAGER\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════\033[0m\n"
    echo ""
    
    read -p "Instalar? (s/N): " RESPONSE
    if [[ "$RESPONSE" =~ ^[Ss]$ ]]; then
      install_command
      echo ""
      exit 0
    else
      echo -e "${RED}Cancelado${NC}"
      exit 1
    fi
  fi
}

# =========================
# Verificar modo de execução
# =========================

if [[ "$0" =~ /xray-menu$ ]] || [[ "$0" =~ /xm$ ]]; then
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Execute como root:${NC}"
    echo -e "${CYAN}sudo xray-menu${NC}"
    exec sudo "$0" "$@"
  fi
fi

# Executar auto-instalação
auto_install_command

# =========================
# Utils
# =========================

init_clients_file() {
  if [ ! -f "$CLIENTS_FILE" ]; then
    cat >"$CLIENTS_FILE" <<EOF
{
  "clients": []
}
EOF
  fi
}

get_current_protocol() {
  if [ -f "$PROTOCOL_FILE" ]; then
    cat "$PROTOCOL_FILE"
  else
    if [ -f "$CONFIG" ]; then
      jq -r '.inbounds[0].streamSettings.network' "$CONFIG" 2>/dev/null || echo ""
    fi
  fi
}

get_tls_mode() {
  if [ ! -f "$CONFIG" ]; then
    echo "none"
    return
  fi
  jq -r '.inbounds[0].streamSettings.security // "none"' "$CONFIG"
}

get_config_value() {
  local key="$1"
  jq -r "$key" "$CONFIG" 2>/dev/null
}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "64" ;;
    aarch64|arm64) echo "arm64-v8a" ;;
    armv7*) echo "arm32-v7a" ;;
    *) echo "unsupported" ;;
  esac
}

check_domain_dns() {
  local domain="$1"
  
  SERVER_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "")
  [ -z "$SERVER_IP" ] && return 0
  
  DOMAIN_IP=$(dig +short "$domain" | head -1)
  
  if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✓ DNS OK${NC}"
    return 0
  else
    echo -e "${YELLOW}⚠️  DNS não configurado${NC}"
    echo -e "IP servidor: $SERVER_IP"
    echo -e "IP domínio: $DOMAIN_IP"
    
    read -p "Continuar? (s/N): " RESPONSE
    if [[ ! "$RESPONSE" =~ ^[Ss]$ ]]; then
      return 1
    fi
    return 0
  fi
}

clean_old_certificates() {
  local domain="$1"
  
  if [ -d "/root/.acme.sh" ]; then
    echo -e "${CYAN}Limpando certificados...${NC}"
    
    if /root/.acme.sh/acme.sh --list | grep -q "$domain"; then
      /root/.acme.sh/acme.sh --revoke -d "$domain" --ecc >/dev/null 2>&1 || true
    fi
    
    rm -rf "/root/.acme.sh/${domain}_ecc" >/dev/null 2>&1 || true
    
    if [ -f "/root/.acme.sh/account.conf" ]; then
      sed -i "/$domain/d" "/root/.acme.sh/account.conf" 2>/dev/null || true
    fi
  fi
  
  rm -rf "$CERT_DIR"/* >/dev/null 2>&1 || true
}

# =========================
# Sistema de Clientes
# =========================

add_client() {
  init_clients_file
  
  echo -e "${CYAN}=== ADICIONAR CLIENTE ===${NC}"
  
  read -p "Nome: " CLIENT_NAME
  [ -z "$CLIENT_NAME" ] && { echo -e "${RED}Nome obrigatório${NC}"; return; }
  
  if jq -e --arg name "$CLIENT_NAME" '.clients[] | select(.name == $name)' "$CLIENTS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}Cliente já existe${NC}"
    return
  fi
  
  CLIENT_UUID=$(uuidgen)
  
  read -p "Limite (GB) [0=ilimitado]: " DATA_LIMIT_GB
  DATA_LIMIT_GB=${DATA_LIMIT_GB:-0}
  
  if [ "$DATA_LIMIT_GB" -gt 0 ]; then
    DATA_LIMIT_BYTES=$((DATA_LIMIT_GB * 1024 * 1024 * 1024))
  else
    DATA_LIMIT_BYTES=0
  fi
  
  read -p "Expira (YYYY-MM-DD) [enter=sem]: " EXPIRE_DATE
  
  CLIENT_EMAIL="${CLIENT_NAME,,}@xray.local"
  
  jq --arg name "$CLIENT_NAME" \
     --arg uuid "$CLIENT_UUID" \
     --arg email "$CLIENT_EMAIL" \
     --argjson limit "$DATA_LIMIT_BYTES" \
     --arg expire "$EXPIRE_DATE" \
     '.clients += [{
        "name": $name,
        "uuid": $uuid,
        "email": $email,
        "data_limit": $limit,
        "expire_date": $expire,
        "created_at": "'$(date +%Y-%m-%d)'",
        "enabled": true,
        "used_bytes": 0
     }]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  
  echo -e "${GREEN}Cliente criado!${NC}"
  echo -e "UUID: ${CYAN}$CLIENT_UUID${NC}"
  
  update_xray_config
}

list_clients() {
  init_clients_file
  
  echo -e "${CYAN}=== CLIENTES ===${NC}\n"
  
  local clients_count=$(jq '.clients | length' "$CLIENTS_FILE")
  
  if [ "$clients_count" -eq 0 ]; then
    echo -e "${YELLOW}Nenhum cliente${NC}"
    return
  fi
  
  printf "${BLUE}%-20s %-10s %-12s %-8s${NC}\n" \
    "Nome" "Limite(GB)" "Expiração" "Status"
  echo "--------------------------------------------------"
  
  jq -r '.clients[] | 
    [.name, 
     (if .data_limit > 0 then (.data_limit / (1024*1024*1024) | tostring) else "∞" end),
     (.expire_date // "∞"),
     (if .enabled then "✅" else "❌" end)
    ] | @tsv' "$CLIENTS_FILE" | while IFS=$'\t' read -r name limit expire status; do
    printf "%-20s %-10s %-12s %-8s\n" \
      "$name" "$limit" "$expire" "$status"
  done
  
  echo ""
  echo -e "${GREEN}Total: $clients_count cliente(s)${NC}"
}

delete_client() {
  init_clients_file
  
  echo -e "${CYAN}=== DELETAR CLIENTE ===${NC}"
  list_clients
  
  read -p "UUID ou nome: " CLIENT_ID
  
  if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}UUID/nome não informado${NC}"
    return
  fi
  
  CLIENT_INFO=$(jq --arg id "$CLIENT_ID" '.clients[] | select(.uuid == $id or .name == $id)' "$CLIENTS_FILE")
  
  if [ -z "$CLIENT_INFO" ]; then
    echo -e "${RED}Cliente não encontrado${NC}"
    return
  fi
  
  CLIENT_NAME=$(echo "$CLIENT_INFO" | jq -r '.name')
  
  read -p "Confirmar exclusão de '$CLIENT_NAME'? (s/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "Cancelado"
    return
  fi
  
  jq --arg id "$CLIENT_ID" \
     '[.clients[] | select(.uuid != $id and .name != $id)] as $new_clients |
      .clients = $new_clients' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  
  echo -e "${GREEN}Cliente deletado${NC}"
  update_xray_config
}

toggle_client() {
  init_clients_file
  
  echo -e "${CYAN}=== ATIVAR/DESATIVAR ===${NC}"
  list_clients
  
  read -p "UUID ou nome: " CLIENT_ID
  
  if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}UUID/nome não informado${NC}"
    return
  fi
  
  CURRENT_STATUS=$(jq --arg id "$CLIENT_ID" '.clients[] | select(.uuid == $id or .name == $id) | .enabled' "$CLIENTS_FILE")
  
  if [ -z "$CURRENT_STATUS" ]; then
    echo -e "${RED}Cliente não encontrado${NC}"
    return
  fi
  
  NEW_STATUS="false"
  ACTION="desativado"
  if [ "$CURRENT_STATUS" = "false" ]; then
    NEW_STATUS="true"
    ACTION="ativado"
  fi
  
  jq --arg id "$CLIENT_ID" \
     --argjson status "$NEW_STATUS" \
     '.clients[] |= if (.uuid == $id or .name == $id) then .enabled = $status else . end' \
     "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  
  echo -e "${GREEN}Cliente $ACTION${NC}"
  update_xray_config
}

update_client_expiry() {
  init_clients_file
  
  echo -e "${CYAN}=== ATUALIZAR EXPIRAÇÃO ===${NC}"
  list_clients
  
  read -p "UUID ou nome: " CLIENT_ID
  
  if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}UUID/nome não informado${NC}"
    return
  fi
  
  read -p "Nova data (YYYY-MM-DD) [enter=sem]: " NEW_DATE
  
  jq --arg id "$CLIENT_ID" \
     --arg date "$NEW_DATE" \
     '.clients[] |= if (.uuid == $id or .name == $id) then .expire_date = $date else . end' \
     "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  
  echo -e "${GREEN}Data atualizada${NC}"
}

update_client_limit() {
  init_clients_file
  
  echo -e "${CYAN}=== ATUALIZAR LIMITE ===${NC}"
  list_clients
  
  read -p "UUID ou nome: " CLIENT_ID
  
  if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}UUID/nome não informado${NC}"
    return
  fi
  
  read -p "Novo limite (GB) [0=ilimitado]: " NEW_LIMIT_GB
  NEW_LIMIT_GB=${NEW_LIMIT_GB:-0}
  
  if [ "$NEW_LIMIT_GB" -gt 0 ]; then
    NEW_LIMIT_BYTES=$((NEW_LIMIT_GB * 1024 * 1024 * 1024))
  else
    NEW_LIMIT_BYTES=0
  fi
  
  jq --arg id "$CLIENT_ID" \
     --argjson limit "$NEW_LIMIT_BYTES" \
     '.clients[] |= if (.uuid == $id or .name == $id) then .data_limit = $limit else . end' \
     "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  
  echo -e "${GREEN}Limite atualizado${NC}"
}

show_client_link() {
  init_clients_file
  
  echo -e "${CYAN}=== GERAR LINK ===${NC}"
  list_clients
  
  read -p "UUID ou nome: " CLIENT_ID
  
  if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}UUID/nome não informado${NC}"
    return
  fi
  
  CLIENT_INFO=$(jq --arg id "$CLIENT_ID" '.clients[] | select(.uuid == $id or .name == $id)' "$CLIENTS_FILE")
  
  if [ -z "$CLIENT_INFO" ]; then
    echo -e "${RED}Cliente não encontrado${NC}"
    return
  fi
  
  CLIENT_UUID=$(echo "$CLIENT_INFO" | jq -r '.uuid')
  CLIENT_NAME=$(echo "$CLIENT_INFO" | jq -r '.name')
  
  CURRENT_PROTO=$(get_current_protocol)
  TLS_MODE=$(get_tls_mode)
  PORT=$(get_config_value '.inbounds[0].port')
  
  [ -z "$CURRENT_PROTO" ] && { echo -e "${RED}Protocolo não configurado${NC}"; return; }
  
  echo ""
  echo -e "${GREEN}Cliente: $CLIENT_NAME${NC}"
  echo ""
  
  if [ "$TLS_MODE" = "tls" ] && [ -f "$DOMAIN_FILE" ]; then
    DOMAIN=$(cat "$DOMAIN_FILE")
    
    case $CURRENT_PROTO in
      ws)
        PATHX=$(get_config_value '.inbounds[0].streamSettings.wsSettings.path')
        echo "vless://${CLIENT_UUID}@${DOMAIN}:${PORT}?type=ws&path=${PATHX}&security=tls&sni=${DOMAIN}#${CLIENT_NAME}"
        ;;
      xhttp)
        PATHX=$(get_config_value '.inbounds[0].streamSettings.xhttpSettings.path')
        echo "vless://${CLIENT_UUID}@${DOMAIN}:${PORT}?type=xhttp&path=${PATHX}&security=tls&sni=${DOMAIN}#${CLIENT_NAME}"
        ;;
      grpc)
        SERVICE_NAME=$(get_config_value '.inbounds[0].streamSettings.grpcSettings.serviceName')
        echo "vless://${CLIENT_UUID}@${DOMAIN}:${PORT}?type=grpc&serviceName=${SERVICE_NAME}&security=tls&sni=${DOMAIN}#${CLIENT_NAME}"
        ;;
      tcp)
        echo "vless://${CLIENT_UUID}@${DOMAIN}:${PORT}?type=tcp&security=tls&sni=${DOMAIN}#${CLIENT_NAME}"
        ;;
    esac
  else
    IP=$(curl -s --max-time 5 https://api.ipify.org || echo "IP_DESCONHECIDO")
    
    case $CURRENT_PROTO in
      ws)
        PATHX=$(get_config_value '.inbounds[0].streamSettings.wsSettings.path')
        echo "vless://${CLIENT_UUID}@${IP}:${PORT}?type=ws&path=${PATHX}&security=none#${CLIENT_NAME}"
        ;;
      xhttp)
        PATHX=$(get_config_value '.inbounds[0].streamSettings.xhttpSettings.path')
        echo "vless://${CLIENT_UUID}@${IP}:${PORT}?type=xhttp&path=${PATHX}&security=none#${CLIENT_NAME}"
        ;;
      grpc)
        SERVICE_NAME=$(get_config_value '.inbounds[0].streamSettings.grpcSettings.serviceName')
        echo "vless://${CLIENT_UUID}@${IP}:${PORT}?type=grpc&serviceName=${SERVICE_NAME}&security=none#${CLIENT_NAME}"
        ;;
      tcp)
        echo "vless://${CLIENT_UUID}@${IP}:${PORT}?type=tcp&security=none#${CLIENT_NAME}"
        ;;
    esac
  fi
  echo ""
}

# =========================
# Mostrar link VLESS
# =========================
show_vless_link() {
  if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}Xray não está configurado!${NC}"
    return 1
  fi
  
  echo -e "${CYAN}=== GERAR LINK VLESS ===${NC}"
  
  # Obter informações da configuração
  PORT=$(get_config_value '.inbounds[0].port')
  CURRENT_PROTO=$(get_current_protocol)
  TLS_MODE=$(get_tls_mode)
  
  if [ "$TLS_MODE" = "tls" ] && [ -f "$DOMAIN_FILE" ]; then
    DOMAIN=$(cat "$DOMAIN_FILE")
    echo -e "${GREEN}Modo: TLS (Domain: $DOMAIN)${NC}"
  else
    DOMAIN=$(curl -s --max-time 5 https://api.ipify.org || echo "IP_PÚBLICO")
    echo -e "${YELLOW}Modo: Sem TLS (IP: $DOMAIN)${NC}"
  fi
  
  echo -e "${CYAN}Protocolo: $CURRENT_PROTO${NC}"
  echo -e "${CYAN}Porta: $PORT${NC}"
  echo ""
  
  # Listar clientes para seleção
  init_clients_file
  local clients_count=$(jq '.clients | length' "$CLIENTS_FILE")
  
  if [ "$clients_count" -eq 0 ]; then
    echo -e "${YELLOW}Nenhum cliente configurado.${NC}"
    read -p "Deseja criar um cliente agora? (s/N): " RESPONSE
    if [[ "$RESPONSE" =~ ^[Ss]$ ]]; then
      add_client
    fi
    return
  fi
  
  echo -e "${CYAN}Clientes disponíveis:${NC}"
  echo ""
  
  jq -r '.clients[] | "\(.name) - \(.uuid) - \(if .enabled then "✅" else "❌" end)"' "$CLIENTS_FILE" | nl -w 2 -s ') '
  echo ""
  
  read -p "Selecione o número do cliente ou digite o UUID: " CLIENT_SELECTION
  
  if [ -z "$CLIENT_SELECTION" ]; then
    echo -e "${RED}Seleção cancelada${NC}"
    return
  fi
  
  # Verificar se é um número
  if [[ "$CLIENT_SELECTION" =~ ^[0-9]+$ ]]; then
    CLIENT_UUID=$(jq -r ".clients[$((CLIENT_SELECTION-1))].uuid" "$CLIENTS_FILE" 2>/dev/null)
  else
    CLIENT_UUID="$CLIENT_SELECTION"
  fi
  
  if [ -z "$CLIENT_UUID" ] || [ "$CLIENT_UUID" = "null" ]; then
    echo -e "${RED}Cliente não encontrado${NC}"
    return
  fi
  
  # Obter informações do cliente
  CLIENT_INFO=$(jq --arg uuid "$CLIENT_UUID" '.clients[] | select(.uuid == $uuid)' "$CLIENTS_FILE")
  
  if [ -z "$CLIENT_INFO" ]; then
    echo -e "${RED}Cliente não encontrado${NC}"
    return
  fi
  
  CLIENT_NAME=$(echo "$CLIENT_INFO" | jq -r '.name')
  CLIENT_ENABLED=$(echo "$CLIENT_INFO" | jq -r '.enabled')
  
  if [ "$CLIENT_ENABLED" = "false" ]; then
    echo -e "${YELLOW}Este cliente está desativado.${NC}"
    read -p "Deseja ativá-lo? (s/N): " RESPONSE
    if [[ "$RESPONSE" =~ ^[Ss]$ ]]; then
      toggle_client
    fi
  fi
  
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}LINK VLESS PARA: $CLIENT_NAME${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
  echo ""
  
  # Gerar link baseado no protocolo
  if [ "$TLS_MODE" = "tls" ] && [ -f "$DOMAIN_FILE" ]; then
    DOMAIN=$(cat "$DOMAIN_FILE")
    
    case $CURRENT_PROTO in
      ws)
        PATHX=$(get_config_value '.inbounds[0].streamSettings.wsSettings.path')
        VLESS_LINK="vless://${CL
