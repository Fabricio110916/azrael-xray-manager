#!/bin/bash

# ============================================================================
# AZRAEL XRAY MANAGER + WEB SOCKET SSH PROXY
# Instalação completa e automática
# ============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variáveis globais
VERSION="2.0.0"
INSTALL_DIR="/opt/azrael-manager"
CONFIG_DIR="/etc/azrael"
LOG_DIR="/var/log/azrael"
SERVICE_USER="azrael"
WS_PROXY_PORT="8081"
SSH_PORT="22"

# Banner
print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     █████╗ ███████╗██████╗  █████╗ ███████╗██╗              ║
    ║    ██╔══██╗╚══███╔╝██╔══██╗██╔══██╗██╔════╝██║              ║
    ║    ███████║  ███╔╝ ██████╔╝███████║█████╗  ██║              ║
    ║    ██╔══██║ ███╔╝  ██╔══██╗██╔══██║██╔══╝  ██║              ║
    ║    ██║  ██║███████╗██║  ██║██║  ██║███████╗███████╗         ║
    ║    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝         ║
    ║                                                              ║
    ║                XRAY MANAGER + WS SSH PROXY                   ║
    ║                    Version: $VERSION                         ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${YELLOW}Instalação completa: Xray-core + WebSocket SSH Proxy + Gerenciamento${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo ""
}

# Função para mostrar status
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script deve ser executado como root!"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Verificar sistema
check_system() {
    print_status "Verificando sistema..."
    
    # Verificar OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Não foi possível detectar o sistema operacional"
        exit 1
    fi
    
    print_success "Sistema: $OS $VER"
    
    # Verificar arquitetura
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            print_error "Arquitetura não suportada: $ARCH"
            exit 1
            ;;
    esac
    print_success "Arquitetura: $ARCH"
    
    # Verificar dependências básicas
    for cmd in curl wget git systemctl; do
        if ! command -v $cmd &> /dev/null; then
            print_warning "$cmd não encontrado, instalando..."
            apt update && apt install -y $cmd
        fi
    done
}

# Criar estrutura de diretórios
create_directories() {
    print_status "Criando estrutura de diretórios..."
    
    mkdir -p $INSTALL_DIR
    mkdir -p $CONFIG_DIR
    mkdir -p $LOG_DIR
    mkdir -p $INSTALL_DIR/scripts
    mkdir -p $INSTALL_DIR/proxy
    mkdir -p $INSTALL_DIR/xray
    
    # Criar usuário para serviços
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d $INSTALL_DIR $SERVICE_USER
    fi
    
    # Ajustar permissões
    chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR $CONFIG_DIR $LOG_DIR
    chmod 750 $INSTALL_DIR $CONFIG_DIR $LOG_DIR
    
    print_success "Estrutura de diretórios criada"
}

# Instalar Xray-core
install_xray() {
    print_status "Instalando Xray-core..."
    
    # URL do Xray
    XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$ARCH.zip"
    
    # Baixar e instalar
    cd /tmp
    wget -q $XRAY_URL -O xray.zip
    if [[ $? -ne 0 ]]; then
        print_error "Falha ao baixar Xray-core"
        return 1
    fi
    
    unzip -q xray.zip
    install -m 755 xray /usr/local/bin/xray
    install -m 644 geoip.dat /usr/local/bin/geoip.dat
    install -m 644 geosite.dat /usr/local/bin/geosite.dat
    
    # Criar diretório de configuração do Xray
    mkdir -p /etc/xray
    cp config.json /etc/xray/ 2>/dev/null || true
    
    # Criar serviço systemd
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    rm -f xray.zip
    
    print_success "Xray-core instalado"
}

# Instalar Proxy WebSocket SSH
install_websocket_proxy() {
    print_status "Instalando Proxy WebSocket SSH..."
    
    # Criar script do proxy
    cat > $INSTALL_DIR/proxy/ws_ssh_proxy.py << 'PYTHONEOF'
#!/usr/bin/env python3
"""
AZRAEL WebSocket SSH Proxy
Handshake: 101 Switching Protocols + 200 OK
"""

import asyncio
import websockets
import socket
import ssl
import logging
import json
import os
from typing import Optional
import sys

# Configuração
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SSHWebSocketProxy:
    def __init__(self, ws_host='0.0.0.0', ws_port=8081, ssh_host='localhost', ssh_port=22):
        self.ws_host = ws_host
        self.ws_port = ws_port
        self.ssh_host = ssh_host
        self.ssh_port = ssh_port
        self.connections = {}
        
    async def handle_websocket(self, websocket, path):
        """Manipula conexão WebSocket"""
        client_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        logger.info(f"[{client_id}] Nova conexão WebSocket")
        
        try:
            # 1. Primeiro enviamos uma resposta HTTP 101
            await websocket.send("HTTP/1.1 101 Switching Protocols\r\n")
            await websocket.send("Upgrade: websocket\r\n")
            await websocket.send("Connection: Upgrade\r\n")
            await websocket.send("Sec-WebSocket-Accept: AZRAEL-WS-SSH-PROXY\r\n")
            await websocket.send("\r\n")
            
            logger.info(f"[{client_id}] 101 Switching Protocols enviado")
            await asyncio.sleep(0.1)
            
            # 2. Enviamos HTTP 200 OK via WebSocket
            response_200 = json.dumps({
                "status": "200",
                "message": "Connection Established",
                "protocol": "ssh",
                "via": "AZRAEL-WS-PROXY"
            })
            
            await websocket.send(response_200)
            logger.info(f"[{client_id}] 200 OK enviado")
            
            # 3. Conectar ao SSH
            logger.info(f"[{client_id}] Conectando ao SSH {self.ssh_host}:{self.ssh_port}")
            
            # Criar conexão TCP com SSH
            reader, writer = await asyncio.open_connection(
                self.ssh_host, 
                self.ssh_port
            )
            
            logger.info(f"[{client_id}] Conexão SSH estabelecida")
            
            # 4. Iniciar proxy bidirecional
            self.connections[client_id] = {
                'websocket': websocket,
                'ssh_reader': reader,
                'ssh_writer': writer,
                'active': True
            }
            
            await self.bidirectional_proxy(websocket, reader, writer, client_id)
            
        except Exception as e:
            logger.error(f"[{client_id}] Erro: {e}")
        finally:
            if client_id in self.connections:
                del self.connections[client_id]
            logger.info(f"[{client_id}] Conexão encerrada")
    
    async def bidirectional_proxy(self, websocket, ssh_reader, ssh_writer, client_id):
        """Proxy bidirecional entre WebSocket e SSH"""
        try:
            # Tarefa 1: WebSocket → SSH
            async def ws_to_ssh():
                try:
                    async for message in websocket:
                        if isinstance(message, str):
                            message = message.encode()
                        ssh_writer.write(message)
                        await ssh_writer.drain()
                        logger.debug(f"[{client_id}] WS→SSH: {len(message)} bytes")
                except:
                    pass
                finally:
                    ssh_writer.close()
            
            # Tarefa 2: SSH → WebSocket
            async def ssh_to_ws():
                try:
                    while True:
                        data = await ssh_reader.read(4096)
                        if not data:
                            break
                        await websocket.send(data)
                        logger.debug(f"[{client_id}] SSH→WS: {len(data)} bytes")
                except:
                    pass
            
            # Executar ambas as tarefas
            await asyncio.gather(ws_to_ssh(), ssh_to_ws())
            
        except Exception as e:
            logger.error(f"[{client_id}] Erro no proxy: {e}")
    
    async def start(self):
        """Inicia o servidor WebSocket"""
        logger.info(f"Iniciando Proxy WebSocket SSH em ws://{self.ws_host}:{self.ws_port}")
        logger.info(f"SSH Backend: {self.ssh_host}:{self.ssh_port}")
        
        # Configurar SSL opcional
        ssl_context = None
        ssl_cert = "/etc/azrael/ssl/cert.pem"
        ssl_key = "/etc/azrael/ssl/key.pem"
        
        if os.path.exists(ssl_cert) and os.path.exists(ssl_key):
            ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ssl_context.load_cert_chain(ssl_cert, ssl_key)
            logger.info("SSL/TLS habilitado")
        
        server = await websockets.serve(
            self.handle_websocket,
            self.ws_host,
            self.ws_port,
            ssl=ssl_context
        )
        
        logger.info("Proxy WebSocket SSH pronto!")
        
        # Manter servidor rodando
        await server.wait_closed()
    
    def stop(self):
        """Para todas as conexões"""
        for client_id, conn in self.connections.items():
            try:
                conn['ssh_writer'].close()
            except:
                pass
        self.connections.clear()
        logger.info("Proxy parado")

async def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Proxy WebSocket SSH')
    parser.add_argument('--ws-host', default='0.0.0.0', help='Host WebSocket')
    parser.add_argument('--ws-port', type=int, default=8081, help='Porta WebSocket')
    parser.add_argument('--ssh-host', default='localhost', help='Host SSH')
    parser.add_argument('--ssh-port', type=int, default=22, help='Porta SSH')
    
    args = parser.parse_args()
    
    proxy = SSHWebSocketProxy(
        ws_host=args.ws_host,
        ws_port=args.ws_port,
        ssh_host=args.ssh_host,
        ssh_port=args.ssh_port
    )
    
    try:
        await proxy.start()
    except KeyboardInterrupt:
        logger.info("Encerrando proxy...")
        proxy.stop()

if __name__ == "__main__":
    asyncio.run(main())
PYTHONEOF
    
    # Criar script simplificado para systemd
    cat > $INSTALL_DIR/proxy/run_proxy.py << 'PYTHONEOF'
#!/usr/bin/env python3
import asyncio
import sys
import os
sys.path.append('/opt/azrael-manager/proxy')

# Importar do script principal
exec(open('/opt/azrael-manager/proxy/ws_ssh_proxy.py').read())

# Executar
if __name__ == "__main__":
    asyncio.run(main())
PYTHONEOF
    
    # Tornar executáveis
    chmod +x $INSTALL_DIR/proxy/*.py
    
    # Criar serviço systemd para o proxy
    cat > /etc/systemd/system/azrael-ws-proxy.service << EOF
[Unit]
Description=AZRAEL WebSocket SSH Proxy
After=network.target
Wants=network.target
Requires=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/proxy
ExecStart=/usr/bin/python3 $INSTALL_DIR/proxy/run_proxy.py \
    --ws-host 0.0.0.0 \
    --ws-port $WS_PROXY_PORT \
    --ssh-host localhost \
    --ssh-port $SSH_PORT
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=azrael-ws-proxy
Environment=PYTHONUNBUFFERED=1

# Segurança
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$INSTALL_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # Criar configuração
    cat > $CONFIG_DIR/ws-proxy.conf << EOF
# Configuração do Proxy WebSocket SSH
WS_HOST=0.0.0.0
WS_PORT=$WS_PROXY_PORT
SSH_HOST=localhost
SSH_PORT=$SSH_PORT
LOG_LEVEL=INFO
EOF
    
    print_success "Proxy WebSocket SSH instalado"
}

# Instalar script de gerenciamento
install_manager() {
    print_status "Instalando script de gerenciamento..."
    
    # Criar script principal
    cat > /usr/local/bin/azrael << 'BASHSCRIPTEOF'
#!/bin/bash

# AZRAEL XRAY MANAGER + WS SSH PROXY
# Script de gerenciamento completo

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
CONFIG_DIR="/etc/azrael"
LOG_DIR="/var/log/azrael"
INSTALL_DIR="/opt/azrael-manager"

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           AZRAEL MANAGER v2.0                ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║   Xray-core + WebSocket SSH Proxy            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Status dos serviços
check_status() {
    echo -e "${CYAN}=== STATUS DOS SERVIÇOS ===${NC}"
    echo ""
    
    # Xray
    if systemctl is-active --quiet xray; then
        echo -e "Xray: ${GREEN}● ATIVO${NC}"
        echo "  $(systemctl status xray --no-pager | grep 'Main PID')"
    else
        echo -e "Xray: ${RED}○ INATIVO${NC}"
    fi
    
    # WebSocket Proxy
    if systemctl is-active --quiet azrael-ws-proxy; then
        echo -e "WS Proxy: ${GREEN}● ATIVO${NC}"
        echo "  $(systemctl status azrael-ws-proxy --no-pager | grep 'Main PID')"
        
        # Mostrar endpoint
        if [ -f "$CONFIG_DIR/ws-proxy.conf" ]; then
            source $CONFIG_DIR/ws-proxy.conf
            IP=$(curl -s --max-time 3 https://api.ipify.org || echo "localhost")
            echo -e "  ${YELLOW}Endpoint:${NC} ws://$IP:$WS_PORT/"
        fi
    else
        echo -e "WS Proxy: ${RED}○ INATIVO${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}=== ESTATÍSTICAS ===${NC}"
    
    # Conexões ativas
    XRAY_CONNS=$(ss -tnp | grep xray | wc -l)
    WS_CONNS=$(ss -tnp | grep python | grep $WS_PROXY_PORT | wc -l 2>/dev/null || echo "0")
    
    echo "Conexões Xray: $XRAY_CONNS"
    echo "Conexões WS Proxy: $WS_CONNS"
}

# Menu de controle de serviços
service_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${CYAN}=== CONTROLE DE SERVIÇOS ===${NC}"
        echo ""
        echo "1. Iniciar todos os serviços"
        echo "2. Parar todos os serviços"
        echo "3. Reiniciar todos os serviços"
        echo "4. Status dos serviços"
        echo "5. Ver logs do Xray"
        echo "6. Ver logs do WS Proxy"
        echo "7. Habilitar na inicialização"
        echo "8. Voltar"
        echo ""
        
        read -p "Selecione: " choice
        
        case $choice in
            1)
                systemctl start xray
                systemctl start azrael-ws-proxy
                echo -e "${GREEN}Serviços iniciados${NC}"
                sleep 2
                ;;
            2)
                systemctl stop xray
                systemctl stop azrael-ws-proxy
                echo -e "${YELLOW}Serviços parados${NC}"
                sleep 2
                ;;
            3)
                systemctl restart xray
                systemctl restart azrael-ws-proxy
                echo -e "${GREEN}Serviços reiniciados${NC}"
                sleep 2
                ;;
            4)
                check_status
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                journalctl -u xray -f --no-pager -n 50
                ;;
            6)
                journalctl -u azrael-ws-proxy -f --no-pager -n 50
                ;;
            7)
                systemctl enable xray
                systemctl enable azrael-ws-proxy
                echo -e "${GREEN}Serviços habilitados na inicialização${NC}"
                sleep 2
                ;;
            8)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Testar conexões
test_connections() {
    echo -e "${CYAN}=== TESTES DE CONEXÃO ===${NC}"
    echo ""
    
    # Testar WebSocket Proxy
    if [ -f "$CONFIG_DIR/ws-proxy.conf" ]; then
        source $CONFIG_DIR/ws-proxy.conf
        
        echo -e "${YELLOW}Testando Proxy WebSocket...${NC}"
        
        # Teste 1: Handshake básico
        echo -n "Teste handshake: "
        if curl -s -i -H "Upgrade: websocket" -H "Connection: Upgrade" \
                -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
                http://localhost:$WS_PORT/ 2>/dev/null | grep -q "101"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FALHOU${NC}"
        fi
        
        # Teste 2: Conexão TCP
        echo -n "Teste porta aberta: "
        if timeout 2 bash -c "echo > /dev/tcp/localhost/$WS_PORT"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FALHOU${NC}"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Instruções para conectar:${NC}"
    echo "1. Via websocat:"
    echo "   websocat ws://SEU_IP:$WS_PORT/ tcp:localhost:22"
    echo ""
    echo "2. Via SSH com proxy:"
    echo "   ssh -o 'ProxyCommand=websocat -b ws://SEU_IP:$WS_PORT/ tcp:%h:%p' user@localhost"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

# Configurações
config_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${CYAN}=== CONFIGURAÇÕES ===${NC}"
        echo ""
        echo "1. Alterar porta do WebSocket Proxy"
        echo "2. Alterar backend SSH"
        echo "3. Gerar certificado SSL"
        echo "4. Configurar domínio"
        echo "5. Backup configuração"
        echo "6. Restaurar configuração"
        echo "7. Voltar"
        echo ""
        
        read -p "Selecione: " choice
        
        case $choice in
            1)
                read -p "Nova porta WebSocket [8081]: " new_port
                new_port=${new_port:-8081}
                
                if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -gt 0 ] && [ $new_port -lt 65536 ]; then
                    sed -i "s/WS_PORT=.*/WS_PORT=$new_port/" $CONFIG_DIR/ws-proxy.conf
                    systemctl restart azrael-ws-proxy
                    echo -e "${GREEN}Porta alterada para $new_port${NC}"
                else
                    echo -e "${RED}Porta inválida${NC}"
                fi
                sleep 2
                ;;
            2)
                read -p "Host SSH [localhost]: " ssh_host
                ssh_host=${ssh_host:-localhost}
                
                read -p "Porta SSH [22]: " ssh_port
                ssh_port=${ssh_port:-22}
                
                sed -i "s/SSH_HOST=.*/SSH_HOST=$ssh_host/" $CONFIG_DIR/ws-proxy.conf
                sed -i "s/SSH_PORT=.*/SSH_PORT=$ssh_port/" $CONFIG_DIR/ws-proxy.conf
                
                # Atualizar script do proxy
                sed -i "s/--ssh-host localhost/--ssh-host $ssh_host/" /etc/systemd/system/azrael-ws-proxy.service
                sed -i "s/--ssh-port 22/--ssh-port $ssh_port/" /etc/systemd/system/azrael-ws-proxy.service
                
                systemctl daemon-reload
                systemctl restart azrael-ws-proxy
                
                echo -e "${GREEN}Backend SSH atualizado${NC}"
                sleep 2
                ;;
            7)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Instalar websocat
install_websocat() {
    echo -e "${CYAN}=== INSTALAR WEBSOCAT ===${NC}"
    echo ""
    
    if command -v websocat &> /dev/null; then
        echo -e "${GREEN}websocat já está instalado${NC}"
    else
        echo -e "${YELLOW}Instalando websocat...${NC}"
        
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)
                ARCH="x86_64"
                ;;
            aarch64|arm64)
                ARCH="aarch64"
                ;;
            *)
                echo -e "${RED}Arquitetura não suportada${NC}"
                return
                ;;
        esac
        
        wget -q https://github.com/vi/websocat/releases/latest/download/websocat.$ARCH-unknown-linux-musl \
            -O /usr/local/bin/websocat
        chmod +x /usr/local/bin/websocat
        
        if [ -f /usr/local/bin/websocat ]; then
            echo -e "${GREEN}websocat instalado com sucesso${NC}"
            echo ""
            echo "Exemplo de uso:"
            echo "  websocat ws://localhost:8081/ tcp:localhost:22"
        else
            echo -e "${RED}Falha ao instalar websocat${NC}"
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Menu principal
main_menu() {
    while true; do
        clear
        show_banner
        check_status
        
        echo ""
        echo -e "${CYAN}=== MENU PRINCIPAL ===${NC}"
        echo ""
        echo "1. Controle de Serviços"
        echo "2. Testar Conexões"
        echo "3. Instalar Websocat (cliente)"
        echo "4. Configurações"
        echo "5. Atualizar AZRAEL"
        echo "6. Desinstalar"
        echo "7. Sair"
        echo ""
        
        read -p "Selecione: " choice
        
        case $choice in
            1)
                service_menu
                ;;
            2)
                test_connections
                ;;
            3)
                install_websocat
                ;;
            4)
                config_menu
                ;;
            5)
                echo -e "${YELLOW}Atualizando AZRAEL...${NC}"
                curl -s https://raw.githubusercontent.com/your-repo/azrael/main/install.sh | sudo bash
                ;;
            6)
                read -p "Tem certeza que deseja desinstalar? (s/N): " confirm
                if [[ $confirm =~ ^[Ss]$ ]]; then
                    echo -e "${YELLOW}Desinstalando...${NC}"
                    systemctl stop xray azrael-ws-proxy
                    systemctl disable xray azrael-ws-proxy
                    rm -f /etc/systemd/system/xray.service
                    rm -f /etc/systemd/system/azrael-ws-proxy.service
                    rm -rf /opt/azrael-manager /etc/azrael /var/log/azrael
                    rm -f /usr/local/bin/azrael
                    systemctl daemon-reload
                    echo -e "${GREEN}AZRAEL desinstalado${NC}"
                    exit 0
                fi
                ;;
            7)
                echo -e "${GREEN}Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Executar menu principal
if [ "$1" = "--status" ]; then
    check_status
elif [ "$1" = "--start" ]; then
    systemctl start xray azrael-ws-proxy
    echo "Serviços iniciados"
elif [ "$1" = "--stop" ]; then
    systemctl stop xray azrael-ws-proxy
    echo "Serviços parados"
elif [ "$1" = "--restart" ]; then
    systemctl restart xray azrael-ws-proxy
    echo "Serviços reiniciados"
elif [ "$1" = "--test" ]; then
    test_connections
else
    main_menu
fi
BASHSCRIPTEOF
    
    # Tornar executável
    chmod +x /usr/local/bin/azrael
    
    # Criar atalho
    ln -sf /usr/local/bin/azrael /usr/local/bin/az
    
    print_success "Script de gerenciamento instalado"
}

# Configurar firewall
setup_firewall() {
    print_status "Configurando firewall..."
    
    # Verificar se ufw está instalado
    if command -v ufw &> /dev/null; then
        ufw allow $WS_PROXY_PORT/tcp comment "AZRAEL WebSocket Proxy"
        ufw allow 443/tcp comment "Xray VLESS"
        ufw allow 22/tcp comment "SSH"
        print_success "Firewall configurado"
    else
        print_warning "UFW não encontrado, pulando configuração de firewall"
    fi
}

# Configurar banner SSH
setup_ssh_banner() {
    print_status "Configurando banner SSH..."
    
    cat > /etc/ssh/azrael-banner << 'BANNEREOF'
╔══════════════════════════════════════════════╗
║           SERVIDOR AZRAEL v2.0               ║
╠══════════════════════════════════════════════╣
║ • Xray Manager: azrael                       ║
║ • WS SSH Proxy: porta 8081                   ║
║ • SSH via WebSocket disponível               ║
╚══════════════════════════════════════════════╝
BANNEREOF
    
    # Configurar banner no SSH
    if grep -q "Banner" /etc/ssh/sshd_config; then
        sed -i 's|^#*Banner.*|Banner /etc/ssh/azrael-banner|' /etc/ssh/sshd_config
    else
        echo "Banner /etc/ssh/azrael-banner" >> /etc/ssh/sshd_config
    fi
    
    systemctl restart sshd
    print_success "Banner SSH configurado"
}

# Instalar websocat para testes
install_websocat_cli() {
    print_status "Instalando websocat (cliente de teste)..."
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            BIN_NAME="websocat.x86_64-unknown-linux-musl"
            ;;
        aarch64|arm64)
            BIN_NAME="websocat.aarch64-unknown-linux-musl"
            ;;
        *)
            print_warning "Arquitetura não suportada para websocat"
            return
            ;;
    esac
    
    wget -q https://github.com/vi/websocat/releases/latest/download/$BIN_NAME \
        -O /usr/local/bin/websocat
    chmod +x /usr/local/bin/websocat
    
    if [ -f /usr/local/bin/websocat ]; then
        print_success "websocat instalado"
    else
        print_warning "Não foi possível instalar websocat"
    fi
}

# Iniciar serviços
start_services() {
    print_status "Iniciando serviços..."
    
    systemctl daemon-reload
    
    # Habilitar e iniciar serviços
    systemctl enable xray 2>/dev/null || true
    systemctl enable azrael-ws-proxy
    
    systemctl start xray
    systemctl start azrael-ws-proxy
    
    sleep 2
    
    # Verificar status
    if systemctl is-active --quiet azrael-ws-proxy; then
        print_success "Proxy WebSocket SSH iniciado"
    else
        print_error "Falha ao iniciar proxy WebSocket"
        journalctl -u azrael-ws-proxy --no-pager -n 10
    fi
    
    if systemctl is-active --quiet xray; then
        print_success "Xray iniciado"
    else
        print_warning "Xray não iniciado (configuração necessária)"
    fi
}

# Mostrar informações finais
show_final_info() {
    clear
    print_banner
    
    # Obter IP público
    PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org || echo "SEU_IP")
    
    echo -e "${GREEN}✅ INSTALAÇÃO COMPLETA!${NC}"
    echo ""
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${YELLOW}📦 SERVIÇOS INSTALADOS:${NC}"
    echo -e "  • Xray-core (VPN/Proxy)"
    echo -e "  • WebSocket SSH Proxy (porta: ${WS_PROXY_PORT})"
    echo -e "  • Script de gerenciamento: ${GREEN}azrael${NC} ou ${GREEN}az${NC}"
    echo ""
    echo -e "${YELLOW}🔗 ENDPOINTS:${NC}"
    echo -e "  WebSocket SSH Proxy: ${GREEN}ws://${PUBLIC_IP}:${WS_PROXY_PORT}/${NC}"
    echo ""
    echo -e "${YELLOW}🔧 COMANDOS DE GERENCIAMENTO:${NC}"
    echo -e "  ${CYAN}azrael${NC}               - Menu interativo"
    echo -e "  ${CYAN}azrael --status${NC}      - Status dos serviços"
    echo -e "  ${CYAN}azrael --start${NC}       - Iniciar serviços"
    echo -e "  ${CYAN}azrael --stop${NC}        - Parar serviços"
    echo -e "  ${CYAN}azrael --restart${NC}     - Reiniciar serviços"
    echo ""
    echo -e "${YELLOW}🔌 CONECTAR VIA SSH:${NC}"
    echo -e "  ${CYAN}websocat ws://${PUBLIC_IP}:${WS_PROXY_PORT}/ tcp:localhost:22${NC}"
    echo ""
    echo -e "  ${CYAN}ssh -o 'ProxyCommand=websocat -b ws://${PUBLIC_IP}:${WS_PROXY_PORT}/ tcp:%h:%p' user@localhost${NC}"
    echo ""
    echo -e "${YELLOW}📊 VER LOGS:${NC}"
    echo -e "  ${CYAN}journalctl -u azrael-ws-proxy -f${NC}"
    echo -e "  ${CYAN}journalctl -u xray -f${NC}"
    echo ""
    echo -e "${CYAN}================================================================================${NC}"
    echo ""
    echo -e "${GREEN}🎉 Aproveite o AZRAEL Manager!${NC}"
    echo ""
    
    # Iniciar menu interativo
    if [[ $1 != "noninteractive" ]]; then
        read -p "Pressione Enter para abrir o menu de gerenciamento..."
        /usr/local/bin/azrael
    fi
}

# Função principal de instalação
main_install() {
    print_banner
    
    # Verificar root
    check_root
    
    # Verificar sistema
    check_system
    
    # Atualizar sistema
    print_status "Atualizando sistema..."
    apt update && apt upgrade -y
    
    # Instalar dependências Python
    print_status "Instalando dependências Python..."
    apt install -y python3 python3-pip python3-venv
    
    # Instalar websockets
    pip3 install websockets
    
    # Criar diretórios
    create_directories
    
    # Instalar componentes
    install_xray
    install_websocket_proxy
    install_manager
    install_websocat_cli
    
    # Configurar sistema
    setup_firewall
    setup_ssh_banner
    
    # Iniciar serviços
    start_services
    
    # Mostrar informações
    show_final_info
}

# Desinstalação
uninstall() {
    echo -e "${RED}=== DESINSTALAÇÃO COMPLETA ===${NC}"
    echo ""
    
    read -p "Tem certeza que deseja remover tudo? (s/N): " confirm
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        echo "Cancelado."
        exit 0
    fi
    
    print_status "Parando serviços..."
    systemctl stop xray azrael-ws-proxy 2>/dev/null || true
    systemctl disable xray azrael-ws-proxy 2>/dev/null || true
    
    print_status "Removendo arquivos..."
    rm -rf $INSTALL_DIR $CONFIG_DIR $LOG_DIR
    rm -f /usr/local/bin/azrael /usr/local/bin/az
    rm -f /etc/systemd/system/xray.service
    rm -f /etc/systemd/system/azrael-ws-proxy.service
    rm -f /etc/ssh/azrael-banner
    
    print_status "Removendo regras de firewall..."
    if command -v ufw &> /dev/null; then
        ufw delete allow $WS_PROXY_PORT/tcp 2>/dev/null || true
    fi
    
    print_status "Recarregando systemd..."
    systemctl daemon-reload
    
    echo ""
    echo -e "${GREEN}✅ AZRAEL Manager removido completamente!${NC}"
    echo ""
}

# Script de atualização
update_azrael() {
    echo -e "${CYAN}=== ATUALIZANDO AZRAEL ===${NC}"
    
    # Backup configurações
    if [ -f "$CONFIG_DIR/ws-proxy.conf" ]; then
        cp $CONFIG_DIR/ws-proxy.conf /tmp/azrael-backup.conf
    fi
    
    # Parar serviços
    systemctl stop azrael-ws-proxy
    
    # Baixar script atualizado
    wget -q https://raw.githubusercontent.com/your-repo/azrael/main/install.sh -O /tmp/azrael-update.sh
    chmod +x /tmp/azrael-update.sh
    
    # Executar atualização
    /tmp/azrael-update.sh
    
    # Restaurar configurações
    if [ -f "/tmp/azrael-backup.conf" ]; then
        cp /tmp/azrael-backup.conf $CONFIG_DIR/ws-proxy.conf
        systemctl restart azrael-ws-proxy
    fi
    
    echo -e "${GREEN}✅ Atualização completa!${NC}"
}

# Menu de instalação
if [[ $# -eq 0 ]]; then
    main_install
else
    case $1 in
        "--uninstall"|"-u")
            uninstall
            ;;
        "--update"|"-U")
            update_azrael
            ;;
        "--help"|"-h")
            echo "Uso: $0 [OPÇÃO]"
            echo ""
            echo "Opções:"
            echo "  --uninstall, -u    Remover completamente"
            echo "  --update, -U       Atualizar para versão mais recente"
            echo "  --help, -h         Mostrar esta ajuda"
            echo ""
            echo "Sem opções: Instalação interativa completa"
            ;;
        *)
            echo "Opção desconhecida: $1"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
fi
