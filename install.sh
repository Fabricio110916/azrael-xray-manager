#!/bin/bash

# Banner de login SSH - VERSÃO CORRIGIDA
install_login_banner() {
 # echo -e "${CYAN}Configurando banner automático...${NC}"
  
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
  
 # echo -e "${GREEN}✓ Banner configurado!${NC}"
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
  #echo -e "${CYAN}Instalando AZRAEL Xray Manager...${NC}"
  
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
   #   echo -e "${GREEN}✅ Instalado!${NC}"
   #   echo -e "${YELLOW}Faça logout e login${NC}"
      echo ""
   #   echo -e "${CYAN}Para usar:${NC}"
    #  echo -e "${GREEN}  sudo xray-menu${NC}"
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

check_expired_clients() {
  init_clients_file
  
  TODAY=$(date +%Y-%m-%d)
  
  EXPIRED_CLIENTS=$(jq --arg today "$TODAY" '
    .clients[] | 
    select(.expire_date != null and .expire_date != "" and .expire_date < $today and .enabled == true) |
    .name' "$CLIENTS_FILE")
  
  if [ -n "$EXPIRED_CLIENTS" ]; then
    echo -e "${YELLOW}⚠️  Clientes expirados:${NC}"
    echo "$EXPIRED_CLIENTS"
    
    jq --arg today "$TODAY" '
      .clients[] |= 
        if (.expire_date != null and .expire_date != "" and .expire_date < $today and .enabled == true) then 
          .enabled = false 
        else . 
        end' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
    
    echo -e "${YELLOW}Clientes desativados${NC}"
    update_xray_config
  fi
}

update_xray_config() {
  if [ ! -f "$CONFIG" ]; then
    return
  fi
  
  init_clients_file
  
  ACTIVE_CLIENTS=$(jq '[.clients[] | select(.enabled == true) | {"id": .uuid, "email": .email}]' "$CLIENTS_FILE")
  
  jq --argjson clients "$ACTIVE_CLIENTS" \
     '.inbounds[0].settings.clients = $clients' "$CONFIG" > /tmp/config.json && mv /tmp/config.json "$CONFIG"
  
  if systemctl is-active --quiet xray; then
    systemctl restart xray
    echo -e "${GREEN}Configuração atualizada${NC}"
  fi
}

# =========================
# Instalação do Xray Core
# =========================

install_xray_core() {
  echo -e "${CYAN}Instalando Xray Core...${NC}"

  ARCH=$(detect_arch)
  [ "$ARCH" = "unsupported" ] && echo -e "${RED}Arquitetura não suportada${NC}" && return 1

  apt update -y
  apt install -y curl unzip jq uuid-runtime socat dnsutils

  URL=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | \
    jq -r ".assets[] | select(.name==\"Xray-linux-$ARCH.zip\") | .browser_download_url")

  [ -z "$URL" ] && { echo -e "${RED}Falha ao obter URL${NC}"; return 1; }

  mkdir -p /tmp/xray
  curl -fsL "$URL" -o /tmp/xray/xray.zip || { echo -e "${RED}Falha no download${NC}"; return 1; }
  unzip -o /tmp/xray/xray.zip -d /tmp/xray || { echo -e "${RED}Falha ao extrair${NC}"; return 1; }

  install -m 755 /tmp/xray/xray "$XRAY_BIN"

  if [ ! -f "$SERVICE" ]; then
    cat >"$SERVICE" <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=$XRAY_BIN run -config $CONFIG
Restart=on-failure
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
  fi

  echo -e "${GREEN}Xray Core instalado${NC}"
}

# =========================
# Selecionar Protocolo
# =========================

select_protocol() {
  clear
  echo "══════════════════════════════════"
  echo "   SELECIONE O PROTOCOLO"
  echo "══════════════════════════════════"
  echo "1) WS (WebSocket)"
  echo "2) XHTTP (HTTP Upgrade)"
  echo "3) gRPC"
  echo "4) TCP (VLESS over TCP)"
  echo "0) Voltar"
  echo ""
  
  CURRENT_PROTO=$(get_current_protocol)
  [ -n "$CURRENT_PROTO" ] && echo -e "${CYAN}Protocolo atual: $CURRENT_PROTO${NC}\n"
  
  read -p "Escolha: " proto_choice
  
  case $proto_choice in
    1) setup_ws ;;
    2) setup_xhttp ;;
    3) setup_grpc ;;
    4) setup_tcp ;;
    0) return ;;
    *) echo -e "${RED}Opção inválida${NC}"; sleep 1; select_protocol ;;
  esac
}

# =========================
# Configurações por Protocolo
# =========================

setup_ws() {
  echo "ws" > "$PROTOCOL_FILE"
  
  read -p "Porta [80]: " PORT
  PORT=${PORT:-80}
  read -p "Path [/ws]: " PATHX
  PATHX=${PATHX:-/ws}
  
  init_clients_file
  
  cat >"$CONFIG" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "$PATHX",
          "headers": {}
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
  
  if [ $(jq '.clients | length' "$CLIENTS_FILE") -eq 0 ]; then
    DEFAULT_UUID=$(uuidgen)
    jq --arg uuid "$DEFAULT_UUID" \
       '.clients = [{
          "name": "default",
          "uuid": $uuid,
          "email": "default@xray.local",
          "data_limit": 0,
          "expire_date": "",
          "created_at": "'$(date +%Y-%m-%d)'",
          "enabled": true,
          "used_bytes": 0
       }]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  fi
  
  update_xray_config
  
  echo -e "${GREEN}Protocolo WS configurado${NC}"
  systemctl enable --now xray 2>/dev/null && echo -e "${GREEN}Xray iniciado${NC}"
}

setup_xhttp() {
  echo "xhttp" > "$PROTOCOL_FILE"
  
  read -p "Porta [80]: " PORT
  PORT=${PORT:-80}
  read -p "Path [/vless]: " PATHX
  PATHX=${PATHX:-/vless}
  
  init_clients_file
  
  cat >"$CONFIG" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "path": "$PATHX"
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
  
  if [ $(jq '.clients | length' "$CLIENTS_FILE") -eq 0 ]; then
    DEFAULT_UUID=$(uuidgen)
    jq --arg uuid "$DEFAULT_UUID" \
       '.clients = [{
          "name": "default",
          "uuid": $uuid,
          "email": "default@xray.local",
          "data_limit": 0,
          "expire_date": "",
          "created_at": "'$(date +%Y-%m-%d)'",
          "enabled": true,
          "used_bytes": 0
       }]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  fi
  
  update_xray_config
  
  echo -e "${GREEN}Protocolo XHTTP configurado${NC}"
  systemctl enable --now xray 2>/dev/null && echo -e "${GREEN}Xray iniciado${NC}"
}

setup_grpc() {
  echo "grpc" > "$PROTOCOL_FILE"
  
  read -p "Porta [443]: " PORT
  PORT=${PORT:-443}
  read -p "Service Name [grpc]: " SERVICE_NAME
  SERVICE_NAME=${SERVICE_NAME:-grpc}
  
  init_clients_file
  
  cat >"$CONFIG" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "$SERVICE_NAME"
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
  
  if [ $(jq '.clients | length' "$CLIENTS_FILE") -eq 0 ]; then
    DEFAULT_UUID=$(uuidgen)
    jq --arg uuid "$DEFAULT_UUID" \
       '.clients = [{
          "name": "default",
          "uuid": $uuid,
          "email": "default@xray.local",
          "data_limit": 0,
          "expire_date": "",
          "created_at": "'$(date +%Y-%m-%d)'",
          "enabled": true,
          "used_bytes": 0
       }]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  fi
  
  update_xray_config
  
  echo -e "${GREEN}Protocolo gRPC configurado${NC}"
  systemctl enable --now xray 2>/dev/null && echo -e "${GREEN}Xray iniciado${NC}"
}

setup_tcp() {
  echo "tcp" > "$PROTOCOL_FILE"
  
  read -p "Porta [443]: " PORT
  PORT=${PORT:-443}
  
  init_clients_file
  
  cat >"$CONFIG" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {}
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
  
  if [ $(jq '.clients | length' "$CLIENTS_FILE") -eq 0 ]; then
    DEFAULT_UUID=$(uuidgen)
    jq --arg uuid "$DEFAULT_UUID" \
       '.clients = [{
          "name": "default",
          "uuid": $uuid,
          "email": "default@xray.local",
          "data_limit": 0,
          "expire_date": "",
          "created_at": "'$(date +%Y-%m-%d)'",
          "enabled": true,
          "used_bytes": 0
       }]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
  fi
  
  update_xray_config
  
  echo -e "${GREEN}Protocolo TCP configurado${NC}"
  systemctl enable --now xray 2>/dev/null && echo -e "${GREEN}Xray iniciado${NC}"
}

# =========================
# Configurar TLS
# =========================

setup_tls() {
  echo -e "${CYAN}=== CONFIGURAR TLS ===${NC}"
  
  if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}Configure primeiro o protocolo${NC}"
    return
  fi
  
  CURRENT_PROTO=$(get_current_protocol)
  echo -e "Protocolo atual: ${CYAN}$CURRENT_PROTO${NC}"
  
  read -p "Domínio (ex: seu.dominio.com): " DOMAIN
  
  if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domínio é obrigatório${NC}"
    return
  fi
  
  check_domain_dns "$DOMAIN" || return
  
  echo "$DOMAIN" > "$DOMAIN_FILE"
  
  clean_old_certificates "$DOMAIN"
  
  if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    echo -e "${CYAN}Instalando ACME.sh...${NC}"
    curl https://get.acme.sh | sh -s email=admin@$DOMAIN
    source ~/.bashrc 2>/dev/null
  fi
  
  echo -e "${CYAN}Obtendo certificado...${NC}"
  
  mkdir -p "$CERT_DIR"
  
  systemctl stop nginx apache2 2>/dev/null || true
  
  if /root/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --keylength ec-256; then
    echo -e "${GREEN}✓ Certificado obtido${NC}"
    
    /root/.acme.sh/acme.sh --install-cert -d "$DOMAIN" --ecc \
      --fullchain-file "$CERT_DIR/fullchain.crt" \
      --key-file "$CERT_DIR/privkey.key"
    
    jq '.inbounds[0].streamSettings.security = "tls"' "$CONFIG" > /tmp/config.json
    mv /tmp/config.json "$CONFIG"
    
    jq --arg domain "$DOMAIN" \
       --arg cert "$CERT_DIR/fullchain.crt" \
       --arg key "$CERT_DIR/privkey.key" \
       '.inbounds[0].streamSettings.tlsSettings = {
          "certificates": [
            {
              "certificateFile": $cert,
              "keyFile": $key
            }
          ],
          "alpn": ["http/1.1"]
        }' "$CONFIG" > /tmp/config.json && mv /tmp/config.json "$CONFIG"
    
    CURRENT_PORT=$(jq -r '.inbounds[0].port' "$CONFIG")
    if [ "$CURRENT_PORT" != "443" ]; then
      read -p "Alterar porta para 443? (s/N): " CHANGE_PORT
      if [[ "$CHANGE_PORT" =~ ^[Ss]$ ]]; then
        jq '.inbounds[0].port = 443' "$CONFIG" > /tmp/config.json && mv /tmp/config.json "$CONFIG"
        echo -e "${GREEN}Porta alterada para 443${NC}"
      fi
    fi
    
    update_xray_config
    
    echo -e "${GREEN}✓ TLS configurado para $DOMAIN${NC}"
    
  else
    echo -e "${RED}Falha ao obter certificado${NC}"
    return 1
  fi
}

# =========================
# Remover TLS
# =========================

remove_tls() {
  echo -e "${CYAN}=== REMOVER TLS ===${NC}"
  
  if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}Configuração não encontrada${NC}"
    return
  fi
  
  jq 'del(.inbounds[0].streamSettings.tlsSettings)' "$CONFIG" > /tmp/config.json
  mv /tmp/config.json "$CONFIG"
  
  jq '.inbounds[0].streamSettings.security = "none"' "$CONFIG" > /tmp/config.json
  mv /tmp/config.json "$CONFIG"
  
  rm -f "$DOMAIN_FILE" 2>/dev/null
  rm -rf "$CERT_DIR" 2>/dev/null
  
  update_xray_config
  
  echo -e "${GREEN}✓ TLS removido${NC}"
}

# =========================
# Mostrar Status
# =========================

show_status() {
  echo -e "${CYAN}=== STATUS ===${NC}"
  
  if [ -f "$XRAY_BIN" ]; then
    XRAY_VERSION=$("$XRAY_BIN" version | head -1 | awk '{print $2}')
    echo -e "Xray Core: ${GREEN}$XRAY_VERSION${NC}"
  else
    echo -e "Xray Core: ${RED}Não instalado${NC}"
  fi
  
  if systemctl is-active --quiet xray; then
    echo -e "Serviço Xray: ${GREEN}ATIVO${NC}"
  else
    echo -e "Serviço Xray: ${RED}INATIVO${NC}"
  fi
  
  if [ -f "$CONFIG" ]; then
    CURRENT_PROTO=$(get_current_protocol)
    TLS_MODE=$(get_tls_mode)
    PORT=$(get_config_value '.inbounds[0].port' 2>/dev/null || echo "N/A")
    
    echo -e "Protocolo: ${CYAN}$CURRENT_PROTO${NC}"
    echo -e "Porta: ${CYAN}$PORT${NC}"
    echo -e "TLS: ${CYAN}$TLS_MODE${NC}"
    
    if [ "$TLS_MODE" = "tls" ] && [ -f "$DOMAIN_FILE" ]; then
      DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null)
      echo -e "Domínio: ${CYAN}$DOMAIN${NC}"
    fi
    
    if [ -f "$CLIENTS_FILE" ]; then
      TOTAL_CLIENTS=$(jq '.clients | length' "$CLIENTS_FILE")
      ACTIVE_CLIENTS=$(jq '[.clients[] | select(.enabled == true)] | length' "$CLIENTS_FILE")
      echo -e "Clientes: ${CYAN}$ACTIVE_CLIENTS/$TOTAL_CLIENTS ativos${NC}"
    fi
    
  else
    echo -e "Configuração: ${RED}Não configurada${NC}"
  fi
  
  echo ""
}

# =========================
# Menu Principal
# =========================

show_menu() {
  clear
  echo -e "\033[1;36m"
  echo "╔════════════════════════════════════════════╗"
  echo "║        AZRAEL XRAY MANAGER v2.0           ║"
  echo "╚════════════════════════════════════════════╝"
  echo -e "\033[0m"
  
  show_status
  
  echo -e "${BLUE}══════════════════════════════════════════════${NC}"
  echo -e "${CYAN}1) Instalar/Atualizar Xray Core${NC}"
  echo -e "${CYAN}2) Configurar Protocolo${NC}"
  echo -e "${CYAN}3) Configurar TLS (HTTPS)${NC}"
  echo -e "${CYAN}4) Remover TLS${NC}"
  echo -e "${BLUE}══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}5) Gerenciar Clientes${NC}"
  echo -e "${GREEN}6) Ver Status${NC}"
  echo -e "${GREEN}7) Reiniciar Xray${NC}"
  echo -e "${BLUE}══════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}8) Verificar Clientes Expirados${NC}"
  echo -e "${YELLOW}X) Desinstalar script${NC}"
  echo -e "${YELLOW}0) Sair${NC}"
  echo -e "${BLUE}══════════════════════════════════════════════${NC}"
  echo ""
}

# Submenu de Clientes
show_client_menu() {
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         GERENCIAMENTO DE CLIENTES          ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "1) Adicionar Novo Cliente"
  echo -e "2) Listar Todos os Clientes"
  echo -e "3) Gerar Link para Cliente"
  echo -e "4) Ativar/Desativar Cliente"
  echo -e "5) Atualizar Limite de Dados"
  echo -e "6) Atualizar Data de Expiração"
  echo -e "7) Deletar Cliente"
  echo -e "0) Voltar ao Menu Principal"
  echo ""
}

# =========================
# Loop Principal
# =========================

main_menu() {
  while true; do
    show_menu
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
      1) 
        install_xray_core
        read -p "Enter para continuar..." ;;
      2) 
        select_protocol
        read -p "Enter para continuar..." ;;
      3) 
        setup_tls
        read -p "Enter para continuar..." ;;
      4) 
        remove_tls
        read -p "Enter para continuar..." ;;
      5)
        while true; do
          show_client_menu
          read -p "Escolha: " client_choice
          case $client_choice in
            1) add_client ;;
            2) list_clients ;;
            3) show_client_link ;;
            4) toggle_client ;;
            5) update_client_limit ;;
            6) update_client_expiry ;;
            7) delete_client ;;
            0) break ;;
            *) echo -e "${RED}Opção inválida${NC}" ;;
          esac
          echo ""
          read -p "Enter para continuar..."
        done ;;
      6) 
        show_status
        read -p "Enter para continuar..." ;;
      7) 
        systemctl restart xray
        echo -e "${GREEN}Xray reiniciado${NC}"
        sleep 2 ;;
      8) 
        check_expired_clients
        read -p "Enter para continuar..." ;;
      x|X)
        uninstall_script ;;
      0) 
        echo -e "${GREEN}Saindo...${NC}"
        exit 0 ;;
      *)
        echo -e "${RED}Opção inválida${NC}"
        sleep 1 ;;
    esac
  done
}

# =========================
# Iniciar
# =========================

if [ -f "$MENU_CMD" ] && [ "$0" = "$MENU_CMD" ]; then
  main_menu
elif [ -f "$MENU_CMD" ] && [[ "$0" =~ /xm$ ]]; then
  main_menu
fi
