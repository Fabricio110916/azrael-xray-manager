#!/bin/bash

# ============================================
# AZRAEL XRAY MANAGER - SCRIPT COMPLETO
# Versão: 2.0
# ============================================

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Diretórios e arquivos
XRAY_BIN="/usr/local/bin/xray"
XRAY_DIR="/etc/xray"
CONFIG="$XRAY_DIR/config.json"
SERVICE="/etc/systemd/system/xray.service"
CERT_DIR="$XRAY_DIR/cert"
DOMAIN_FILE="$XRAY_DIR/domain.txt"
PROTOCOL_FILE="$XRAY_DIR/protocol.txt"
CLIENTS_FILE="$XRAY_DIR/clients.json"
MENU_CMD="/usr/local/bin/xray-menu"

# ============================================
# FUNÇÃO: BANNER DE LOGIN SSH MELHORADO
# ============================================

install_login_banner() {
  echo -e "${CYAN}Configurando banner automático...${NC}"
  
  # Limpar configurações antigas
  sed -i '/if \[ -f \/etc\/profile.d\/azrael-banner.sh \]; then/,/^fi$/d' /root/.bashrc ~/.bashrc 2>/dev/null
  sed -i '/AZRAEL XRAY MANAGER/d' /root/.bashrc ~/.bashrc 2>/dev/null
  sed -i '/azrael-banner/d' /root/.bashrc ~/.bashrc 2>/dev/null
  
  # 1. Criar banner no profile.d
  cat << 'EOF' > /etc/profile.d/azrael-banner.sh
#!/bin/bash

# AZRAEL XRAY MANAGER - BANNER PROFISSIONAL

# Verificar se é shell interativo
if [[ $- == *i* ]] && [ -n "$PS1" ]; then
  # Aguardar terminal carregar
  sleep 0.1
  
  # Limpar tela
  clear 2>/dev/null || printf "\033c"
  
  # Banner ASCII Art com cores
  printf "\033[38;5;213m"
  cat << "ART"
╔══════════════════════════════════════════════════════════════╗
║     █████╗ ███████╗██████╗  █████╗ ███████╗██╗              ║
║    ██╔══██╗╚══███╔╝██╔══██╗██╔══██╗██╔════╝██║              ║
║    ███████║  ███╔╝ ██████╔╝███████║█████╗  ██║              ║
║    ██╔══██║ ███╔╝  ██╔══██╗██╔══██║██╔══╝  ██║              ║
║    ██║  ██║███████╗██║  ██║██║  ██║███████╗███████╗         ║
║    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝         ║
╠══════════════════════════════════════════════════════════════╣
║                    \033[1;96mX-RAY MANAGER PROFESSIONAL\033[38;5;213m                 ║
╠══════════════════════════════════════════════════════════════╣
ART
  printf "\033[0m"
  
  # Informações do sistema
  printf "\033[1;93m"
  printf "║  🔧 \033[1;97mSistema:\033[1;93m %-47s \033[38;5;213m║\n" "$(uname -o) $(uname -r)"
  printf "║  🖥️  \033[1;97mHostname:\033[1;93m %-46s \033[38;5;213m║\n" "$(hostname)"
  printf "║  📅 \033[1;97mData:\033[1;93m %-49s \033[38;5;213m║\n" "$(date '+%d/%m/%Y %H:%M:%S')"
  ip_public=$(curl -s --max-time 3 https://api.ipify.org || echo 'Não disponível')
  printf "║  🌐 \033[1;97mIP Público:\033[1;93m %-44s \033[38;5;213m║\n" "$ip_public"
  printf "╠══════════════════════════════════════════════════════════════╣\n"
  
  # Comandos disponíveis
  printf "\033[1;92m"
  printf "║  📋 \033[1;97mCOMANDOS DISPONÍVEIS:\033[1;92m                               \033[38;5;213m║\n"
  printf "║                                                              ║\n"
  printf "║  \033[1;96m● xray-menu / xm\033[1;92m   - Menu principal do Xray Manager     \033[38;5;213m║\n"
  printf "║  \033[1;96m● wsproxy\033[1;92m         - Status do WebSocket Proxy          \033[38;5;213m║\n"
  printf "║  \033[1;96m● xray-status\033[1;92m     - Status do serviço Xray            \033[38;5;213m║\n"
  printf "║  \033[1;96m● xray-logs\033[1;92m       - Ver logs do Xray em tempo real    \033[38;5;213m║\n"
  printf "║                                                              ║\n"
  
  # Status dos serviços
  if systemctl is-active --quiet xray 2>/dev/null; then
    printf "║  ✅ \033[1;92mXray:\033[1;97m ATIVO                                        \033[38;5;213m║\n"
  else
    printf "║  ❌ \033[1;91mXray:\033[1;97m INATIVO                                      \033[38;5;213m║\n"
  fi
  
  if systemctl is-active --quiet websocket-proxy 2>/dev/null; then
    printf "║  ✅ \033[1;92mWS Proxy:\033[1;97m ATIVO                                    \033[38;5;213m║\n"
  else
    printf "║  ❌ \033[1;91mWS Proxy:\033[1;97m INATIVO                                  \033[38;5;213m║\n"
  fi
  
  printf "╠══════════════════════════════════════════════════════════════╣\n"
  
  # Avisos de segurança
  printf "\033[1;91m"
  printf "║  ⚠️  \033[1;97mAVISO DE SEGURANÇA:\033[1;91m                                 \033[38;5;213m║\n"
  printf "║  • Mantenha o sistema atualizado                            ║\n"
  printf "║  • Use senhas fortes e únicas                               ║\n"
  printf "║  • Monitore os logs regularmente                            ║\n"
  printf "╚══════════════════════════════════════════════════════════════╝\033[0m\n"
  
  printf "\n\033[1;36mDigite 'xray-menu' ou 'xm' para iniciar a configuração\033[0m\n"
  printf "\033[1;33mVersão: 2.0 • Conexões ativas: $(who | wc -l) usuário(s)\033[0m\n\n"
fi
EOF

  chmod +x /etc/profile.d/azrael-banner.sh
  
  # 2. Configurar .bashrc do usuário atual
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
    echo "alias wsproxy='sudo systemctl status websocket-proxy'" >> "$USER_BASHRC"
    echo "alias xray-status='sudo systemctl status xray'" >> "$USER_BASHRC"
    echo "alias xray-logs='sudo journalctl -u xray -f'" >> "$USER_BASHRC"
  fi
  
  # 3. Configurar .bashrc do root
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
    echo "alias wsproxy='systemctl status websocket-proxy'" >> "$ROOT_BASHRC"
    echo "alias xray-status='systemctl status xray'" >> "$ROOT_BASHRC"
    echo "alias xray-logs='journalctl -u xray -f'" >> "$ROOT_BASHRC"
  fi
  
  # 4. Configurar MOTD
  cat << 'EOF' > /etc/motd

╔═══════════════════════════════════════════════════════╗
║              AZRAEL XRAY MANAGER v2.0                ║
╠═══════════════════════════════════════════════════════╣
║ Comandos: xray-menu, xm, wsproxy, xray-status        ║
║ Uso: Gerenciamento completo de proxy Xray             ║
╚═══════════════════════════════════════════════════════╝
EOF
  
  echo -e "${GREEN}✓ Banner profissional configurado!${NC}"
  echo -e "${YELLOW}Reinicie a sessão SSH para ver o novo banner${NC}"
}

# ============================================
# FUNÇÃO: DESINSTALAR COMPLETAMENTE
# ============================================

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
  systemctl stop websocket-proxy 2>/dev/null
  systemctl disable websocket-proxy 2>/dev/null
  
  # Remover comandos
  rm -f /usr/local/bin/xray-menu /usr/local/bin/xm 2>/dev/null
  rm -f /usr/local/bin/ws-proxy 2>/dev/null
  
  # Remover banner
  rm -f /etc/profile.d/azrael-banner.sh /etc/motd 2>/dev/null
  
  # Limpar .bashrc
  sed -i '/# AZRAEL XRAY MANAGER - BANNER/,/^fi$/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xray-menu/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xm/d' ~/.bashrc 2>/dev/null
  sed -i '/alias wsproxy/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xray-status/d' ~/.bashrc 2>/dev/null
  sed -i '/alias xray-logs/d' ~/.bashrc 2>/dev/null
  
  sed -i '/# AZRAEL XRAY MANAGER - BANNER/,/^fi$/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xray-menu/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xm/d' /root/.bashrc 2>/dev/null
  sed -i '/alias wsproxy/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xray-status/d' /root/.bashrc 2>/dev/null
  sed -i '/alias xray-logs/d' /root/.bashrc 2>/dev/null
  
  # Remover Xray
  rm -f /etc/systemd/system/xray.service 2>/dev/null
  rm -f /usr/local/bin/xray 2>/dev/null
  rm -rf /etc/xray 2>/dev/null
  rm -rf /root/.acme.sh 2>/dev/null
  
  # Remover WebSocket Proxy
  rm -f /etc/systemd/system/websocket-proxy.service 2>/dev/null
  rm -f /opt/websocket-proxy/proxy_ws_ssh.py 2>/dev/null
  rm -rf /opt/websocket-proxy 2>/dev/null
  rm -f /etc/websocket-proxy.conf 2>/dev/null
  
  # Recarregar systemd
  systemctl daemon-reload 2>/dev/null
  
  echo ""
  echo -e "${GREEN}✅ Tudo removido!${NC}"
  echo ""
  
  exit 0
}

# ============================================
# FUNÇÕES DO PROXY WEBSOCKET SSH
# ============================================

install_websocket_proxy() {
    echo -e "${CYAN}=== INSTALAR PROXY WEBSOCKET SSH ===${NC}"
    echo ""
    
    # Verificar se Python está instalado
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python3 não encontrado. Instalando...${NC}"
        apt update && apt install -y python3 python3-pip
    fi
    
    # Criar diretório
    mkdir -p /opt/websocket-proxy
    
    # Criar script do proxy
    cat << 'EOF' > /opt/websocket-proxy/proxy_ws_ssh.py
#!/usr/bin/env python3
"""
Proxy WebSocket-SSH para AZRAEL XRAY MANAGER
"""

import socket
import threading
import select
import time
import base64
import hashlib
import struct
import json
import logging
from typing import Optional, Tuple
import os

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class WebSocketSSHProxy:
    """Proxy WebSocket para SSH"""
    
    def __init__(self, listen_host: str = '0.0.0.0', listen_port: int = 8081,
                 ssh_host: str = 'localhost', ssh_port: int = 22):
        self.listen_host = listen_host
        self.listen_port = listen_port
        self.ssh_host = ssh_host
        self.ssh_port = ssh_port
        self.server_socket = None
        self.running = False
        
    def _generate_websocket_accept(self, key: str) -> str:
        """Gera a chave de aceitação WebSocket"""
        magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        accept_key = base64.b64encode(
            hashlib.sha1((key + magic).encode()).digest()
        ).decode()
        return accept_key
    
    def _create_websocket_frame(self, data: bytes, opcode: int = 0x2) -> bytes:
        """Cria um frame WebSocket"""
        frame = bytearray()
        
        # FIN=1, opcode
        frame.append(0x80 | (opcode & 0x0F))
        
        # Tamanho do payload
        data_len = len(data)
        if data_len <= 125:
            frame.append(data_len)
        elif data_len <= 65535:
            frame.append(126)
            frame.extend(struct.pack('>H', data_len))
        else:
            frame.append(127)
            frame.extend(struct.pack('>Q', data_len))
        
        frame.extend(data)
        return bytes(frame)
    
    def _parse_websocket_frame(self, data: bytes) -> Tuple[Optional[int], Optional[bytes], int]:
        """Parseia um frame WebSocket"""
        if len(data) < 2:
            return None, None, 0
            
        byte1 = data[0]
        fin = (byte1 & 0x80) != 0
        opcode = byte1 & 0x0F
        
        byte2 = data[1]
        masked = (byte2 & 0x80) != 0
        payload_len = byte2 & 0x7F
        
        ptr = 2
        
        if payload_len == 126:
            if len(data) < ptr + 2:
                return None, None, 0
            payload_len = struct.unpack('>H', data[ptr:ptr+2])[0]
            ptr += 2
        elif payload_len == 127:
            if len(data) < ptr + 8:
                return None, None, 0
            payload_len = struct.unpack('>Q', data[ptr:ptr+8])[0]
            ptr += 8
        
        mask = None
        if masked:
            if len(data) < ptr + 4:
                return None, None, 0
            mask = data[ptr:ptr+4]
            ptr += 4
        
        if len(data) < ptr + payload_len:
            return None, None, 0
        
        payload = data[ptr:ptr + payload_len]
        
        if masked and mask:
            payload = bytearray(payload)
            for i in range(len(payload)):
                payload[i] ^= mask[i % 4]
            payload = bytes(payload)
        
        return opcode, payload, ptr + payload_len
    
    def _handle_connection(self, client_socket: socket.socket, client_addr: Tuple[str, int]):
        """Manipula uma conexão cliente"""
        logger.info(f"Nova conexão de {client_addr}")
        
        ssh_socket = None
        buffer = b""
        
        try:
            # Receber handshake HTTP/WebSocket
            data = client_socket.recv(4096)
            if not data:
                return
            
            request = data.decode('utf-8', errors='ignore')
            
            # Verificar se é WebSocket
            if 'Upgrade: websocket' in request.lower() and 'Sec-WebSocket-Key:' in request:
                # Extrair chave WebSocket
                ws_key = None
                for line in request.split('\r\n'):
                    if line.startswith('Sec-WebSocket-Key:'):
                        ws_key = line.split(': ', 1)[1].strip()
                        break
                
                if not ws_key:
                    ws_key = "dGhlIHNhbXBsZSBub25jZQ=="
                
                # 1. Enviar resposta 101 Switching Protocols
                accept_key = self._generate_websocket_accept(ws_key)
                response_101 = (
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Upgrade: websocket\r\n"
                    "Connection: Upgrade\r\n"
                    f"Sec-WebSocket-Accept: {accept_key}\r\n"
                    "Sec-WebSocket-Protocol: ssh\r\n\r\n"
                )
                client_socket.sendall(response_101.encode())
                logger.info(f"[{client_addr}] 101 Switching Protocols enviado")
                
                # 2. Enviar resposta 200 OK via WebSocket
                time.sleep(0.05)
                message_200 = "HTTP/1.1 200 OK\r\nVia: AZRAEL-WS-SSH-PROXY\r\n\r\nWebSocket handshake completo!"
                frame_200 = self._create_websocket_frame(message_200.encode(), opcode=0x1)
                client_socket.sendall(frame_200)
                logger.info(f"[{client_addr}] 200 OK enviado via WebSocket")
                
                # 3. Conectar ao SSH
                logger.info(f"[{client_addr}] Conectando ao SSH {self.ssh_host}:{self.ssh_port}")
                ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                ssh_socket.settimeout(10)
                ssh_socket.connect((self.ssh_host, self.ssh_port))
                ssh_socket.setblocking(0)
                logger.info(f"[{client_addr}] Conexão SSH estabelecida")
                
                # Processar dados após handshake
                handshake_end = request.find('\r\n\r\n') + 4
                if handshake_end > 0 and handshake_end < len(data):
                    buffer = data[handshake_end:]
                
                client_socket.setblocking(0)
                
                # Loop de proxy
                while True:
                    rlist = [client_socket, ssh_socket]
                    wlist = []
                    xlist = []
                    
                    try:
                        readable, _, exceptional = select.select(rlist, wlist, xlist, 1)
                        
                        for sock in readable:
                            if sock is client_socket:
                                # Dados do WebSocket
                                try:
                                    data = sock.recv(4096)
                                    if not data:
                                        raise ConnectionError("Cliente desconectado")
                                    
                                    buffer += data
                                    
                                    # Processar frames
                                    while len(buffer) >= 2:
                                        opcode, payload, consumed = self._parse_websocket_frame(buffer)
                                        
                                        if opcode is None:
                                            break
                                        
                                        if opcode == 0x8:  # Close
                                            logger.info(f"[{client_addr}] Close frame recebido")
                                            close_frame = self._create_websocket_frame(b'', opcode=0x8)
                                            client_socket.sendall(close_frame)
                                            return
                                        
                                        elif opcode == 0x9:  # Ping
                                            pong_frame = self._create_websocket_frame(payload, opcode=0xA)
                                            client_socket.sendall(pong_frame)
                                        
                                        elif opcode in [0x1, 0x2]:  # Text ou Binary
                                            if ssh_socket:
                                                ssh_socket.sendall(payload)
                                        
                                        buffer = buffer[consumed:]
                                        
                                except (socket.error, ConnectionError) as e:
                                    logger.info(f"[{client_addr}] Cliente desconectado: {e}")
                                    return
                            
                            elif sock is ssh_socket:
                                # Dados do SSH
                                try:
                                    data = sock.recv(4096)
                                    if data:
                                        frame = self._create_websocket_frame(data, opcode=0x2)
                                        client_socket.sendall(frame)
                                except socket.error:
                                    pass
                        
                        for sock in exceptional:
                            logger.error(f"[{client_addr}] Erro no socket")
                            return
                            
                    except (socket.error, ValueError) as e:
                        logger.error(f"[{client_addr}] Erro no select: {e}")
                        break
                    
                    time.sleep(0.001)
                    
            else:
                # Resposta HTTP normal
                html = """HTTP/1.1 200 OK
Content-Type: text/html
Connection: close

<html>
<head><title>AZRAEL WS-SSH Proxy</title></head>
<body style="font-family: Arial; padding: 20px;">
<h1>WebSocket SSH Proxy</h1>
<p>Conecte-se via WebSocket para túnel SSH</p>
<hr>
<small>AZRAEL XRAY MANAGER</small>
</body></html>"""
                client_socket.sendall(html.encode())
                
        except Exception as e:
            logger.error(f"[{client_addr}] Erro: {e}")
            
        finally:
            if ssh_socket:
                try:
                    ssh_socket.close()
                except:
                    pass
            client_socket.close()
            logger.info(f"[{client_addr}] Conexão encerrada")
    
    def start(self):
        """Inicia o servidor proxy"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.listen_host, self.listen_port))
            self.server_socket.listen(100)
            self.server_socket.settimeout(1)
            
            self.running = True
            logger.info(f"Proxy WebSocket-SSH iniciado em {self.listen_host}:{self.listen_port}")
            logger.info(f"SSH Backend: {self.ssh_host}:{self.ssh_port}")
            logger.info("Pressione Ctrl+C para parar")
            
            while self.running:
                try:
                    client_socket, client_addr = self.server_socket.accept()
                    thread = threading.Thread(
                        target=self._handle_connection,
                        args=(client_socket, client_addr),
                        daemon=True
                    )
                    thread.start()
                    
                except socket.timeout:
                    continue
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    logger.error(f"Erro ao aceitar conexão: {e}")
                    time.sleep(1)
                    
        except Exception as e:
            logger.error(f"Erro ao iniciar servidor: {e}")
            
        finally:
            self.stop()
    
    def stop(self):
        """Para o servidor"""
        self.running = False
        if self.server_socket:
            try:
                self.server_socket.close()
            except:
                pass
        logger.info("Proxy encerrado")

def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Proxy WebSocket SSH para AZRAEL')
    parser.add_argument('--listen-host', default='0.0.0.0', help='Host para escutar')
    parser.add_argument('--listen-port', type=int, default=8081, help='Porta para escutar')
    parser.add_argument('--ssh-host', default='localhost', help='Host SSH')
    parser.add_argument('--ssh-port', type=int, default=22, help='Porta SSH')
    
    args = parser.parse_args()
    
    # Carregar configuração do arquivo se existir
    config_file = '/etc/websocket-proxy.conf'
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip()
                            
                            if key == 'LISTEN_HOST':
                                args.listen_host = value
                            elif key == 'LISTEN_PORT':
                                args.listen_port = int(value)
                            elif key == 'SSH_HOST':
                                args.ssh_host = value
                            elif key == 'SSH_PORT':
                                args.ssh_port = int(value)
        except Exception as e:
            logger.error(f"Erro ao ler configuração: {e}")
    
    proxy = WebSocketSSHProxy(
        listen_host=args.listen_host,
        listen_port=args.listen_port,
        ssh_host=args.ssh_host,
        ssh_port=args.ssh_port
    )
    
    try:
        proxy.start()
    except KeyboardInterrupt:
        logger.info("Interrompido pelo usuário")
        proxy.stop()

if __name__ == "__main__":
    main()
EOF

    chmod +x /opt/websocket-proxy/proxy_ws_ssh.py
    
    # Criar arquivo de configuração
    cat << 'EOF' > /etc/websocket-proxy.conf
# Configuração do Proxy WebSocket SSH
LISTEN_HOST=0.0.0.0
LISTEN_PORT=8081
SSH_HOST=localhost
SSH_PORT=22
EOF
    
    # Criar serviço systemd
    cat << 'EOF' > /etc/systemd/system/websocket-proxy.service
[Unit]
Description=AZRAEL WebSocket SSH Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/websocket-proxy
ExecStart=/usr/bin/python3 /opt/websocket-proxy/proxy_ws_ssh.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Criar comando para o proxy
    cat << 'EOF' > /usr/local/bin/ws-proxy
#!/bin/bash
/usr/bin/python3 /opt/websocket-proxy/proxy_ws_ssh.py "$@"
EOF
    
    chmod +x /usr/local/bin/ws-proxy
    
    # Recarregar systemd e iniciar serviço
    systemctl daemon-reload
    systemctl enable websocket-proxy
    systemctl start websocket-proxy
    
    echo -e "${GREEN}✓ Proxy WebSocket SSH instalado!${NC}"
    echo -e "${YELLOW}Porta: 8081${NC}"
    echo -e "${YELLOW}Use 'systemctl status websocket-proxy' para verificar${NC}"
}

# ============================================
# FUNÇÕES DO XRAY
# ============================================

install_xray() {
    echo -e "${CYAN}=== INSTALAR XRAY CORE ===${NC}"
    
    # Baixar Xray
    latest_version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep tag_name | cut -d'"' -f4)
    if [ -z "$latest_version" ]; then
        latest_version="v1.8.11"
    fi
    
    echo -e "${YELLOW}Baixando Xray $latest_version...${NC}"
    
    # Detectar arquitetura
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="64" ;;
        aarch64) ARCH="arm64-v8a" ;;
        armv7l) ARCH="arm32-v7a" ;;
        *) ARCH="64" ;;
    esac
    
    wget -q "https://github.com/XTLS/Xray-core/releases/download/$latest_version/Xray-linux-$ARCH.zip" -O /tmp/xray.zip
    
    if [ ! -f /tmp/xray.zip ]; then
        echo -e "${RED}Falha ao baixar Xray${NC}"
        return 1
    fi
    
    # Extrair e instalar
    unzip -q -o /tmp/xray.zip -d /tmp/xray
    mv /tmp/xray/xray $XRAY_BIN
    chmod +x $XRAY_BIN
    
    # Criar diretórios
    mkdir -p $XRAY_DIR $CERT_DIR
    
    # Criar configuração básica
    cat << 'EOF' > $CONFIG
{
  "log": {
    "loglevel": "warning"
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": []
  },
  "inbounds": [],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF
    
    # Criar serviço systemd
    cat << 'EOF' > $SERVICE
[Unit]
Description=Xray Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$XRAY_BIN run -config $CONFIG
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Corrigir variáveis no serviço
    sed -i "s|\$XRAY_BIN|$XRAY_BIN|g" $SERVICE
    sed -i "s|\$CONFIG|$CONFIG|g" $SERVICE
    
    # Recarregar e iniciar
    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
    
    # Criar arquivos de configuração
    echo "meudominio.com" > $DOMAIN_FILE
    echo "vless" > $PROTOCOL_FILE
    echo '{"clients": []}' > $CLIENTS_FILE
    
    echo -e "${GREEN}✓ Xray instalado com sucesso!${NC}"
}

# ============================================
# FUNÇÃO: MENU PRINCIPAL
# ============================================

create_menu_command() {
    cat << 'EOF' > $MENU_CMD
#!/bin/bash

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           AZRAEL XRAY MANAGER v2.0              ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║     Gerenciamento Completo de Proxy Xray         ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main_menu() {
    while true; do
        show_banner
        
        echo -e "${YELLOW}MENU PRINCIPAL${NC}"
        echo -e "${BLUE}════════════════════════════════${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. Status dos Serviços"
        echo -e "  ${GREEN}2${NC}. Gerenciar Xray"
        echo -e "  ${GREEN}3${NC}. Gerenciar WebSocket Proxy"
        echo -e "  ${GREEN}4${NC}. Configurar Domínio/SSL"
        echo -e "  ${GREEN}5${NC}. Gerenciar Usuários"
        echo -e "  ${GREEN}6${NC}. Ver Logs"
        echo -e "  ${GREEN}7${NC}. Instalar/Atualizar"
        echo -e "  ${GREEN}8${NC}. Configurar Banner SSH"
        echo -e "  ${GREEN}9${NC}. Desinstalar Tudo"
        echo -e "  ${GREEN}0${NC}. Sair"
        echo ""
        echo -e "${BLUE}════════════════════════════════${NC}"
        echo ""
        
        read -p "Selecione uma opção [0-9]: " choice
        
        case $choice in
            1) show_status ;;
            2) xray_menu ;;
            3) wsproxy_menu ;;
            4) ssl_menu ;;
            5) users_menu ;;
            6) logs_menu ;;
            7) install_update_menu ;;
            8) configure_banner ;;
            9) uninstall_menu ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
        esac
    done
}

# Funções do menu (implementação básica)
show_status() {
    echo -e "${CYAN}=== STATUS DOS SERVIÇOS ===${NC}"
    echo ""
    systemctl status xray --no-pager -l
    echo ""
    systemctl status websocket-proxy --no-pager -l
    echo ""
    read -p "Pressione Enter para continuar..."
}

xray_menu() {
    echo -e "${CYAN}=== GERENCIAR XRAY ===${NC}"
    echo ""
    echo "1. Reiniciar Xray"
    echo "2. Parar Xray"
    echo "3. Iniciar Xray"
    echo "4. Ver configuração"
    echo "5. Voltar"
    echo ""
    read -p "Opção: " opt
    # Implementar ações
    echo "Funcionalidade em desenvolvimento..."
    sleep 2
}

# Outras funções do menu podem ser implementadas aqui

# Executar menu principal
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Este script precisa ser executado como root!${NC}"
    exit 1
fi

main_menu
EOF

    chmod +x $MENU_CMD
    
    # Criar alias
    ln -sf $MENU_CMD /usr/local/bin/xm
    
    echo -e "${GREEN}✓ Comando 'xray-menu' instalado!${NC}"
    echo -e "${YELLOW}Use 'xray-menu' ou 'xm' para acessar o menu${NC}"
}

# ============================================
# FUNÇÃO PRINCIPAL DE INSTALAÇÃO
# ============================================

main_install() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         INSTALADOR AZRAEL XRAY MANAGER          ║"
    echo "║                Versão 2.0                        ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Verificar root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Este script precisa ser executado como root!${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Iniciando instalação...${NC}"
    echo ""
    
    # Atualizar sistema
    echo -e "${CYAN}[1/5] Atualizando sistema...${NC}"
    apt update && apt upgrade -y
    
    # Instalar dependências
    echo -e "${CYAN}[2/5] Instalando dependências...${NC}"
    apt install -y curl wget unzip zip python3 python3-pip jq
    
    # Instalar Xray
    install_xray
    
    # Instalar WebSocket Proxy
    install_websocket_proxy
    
    # Criar menu
    create_menu_command
    
    # Instalar banner
    install_login_banner
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}COMANDOS DISPONÍVEIS:${NC}"
    echo -e "  ${CYAN}xray-menu${NC} ou ${CYAN}xm${NC} - Menu principal"
    echo -e "  ${CYAN}wsproxy${NC} - Status do WebSocket Proxy"
    echo -e "  ${CYAN}xray-status${NC} - Status do Xray"
    echo -e "  ${CYAN}xray-logs${NC} - Ver logs em tempo real"
    echo ""
    echo -e "${YELLOW}PRÓXIMOS PASSOS:${NC}"
    echo -e "  1. Configure seu domínio com SSL"
    echo -e "  2. Adicione usuários pelo menu"
    echo -e "  3. Reinicie a sessão SSH para ver o banner"
    echo ""
    echo -e "${BLUE}Reinicie o servidor ou faça novo login SSH para aplicar todas as configurações.${NC}"
}

# ============================================
# MENU INTERATIVO DE INSTALAÇÃO
# ============================================

show_install_menu() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         AZRAEL XRAY MANAGER - INSTALADOR        ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║   Uma solução completa de proxy com Xray Core    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}OPÇÕES DE INSTALAÇÃO:${NC}"
    echo -e "${BLUE}════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. Instalação COMPLETA (Recomendado)"
    echo -e "  ${GREEN}2${NC}. Instalar apenas Xray Core"
    echo -e "  ${GREEN}3${NC}. Instalar apenas WebSocket Proxy"
    echo -e "  ${GREEN}4${NC}. Instalar apenas Banner SSH"
    echo -e "  ${GREEN}5${NC}. Instalar apenas Menu"
    echo -e "  ${GREEN}6${NC}. Desinstalar Tudo"
    echo -e "  ${GREEN}0${NC}. Sair"
    echo ""
    echo -e "${BLUE}════════════════════════════════${NC}"
    echo ""
    
    read -p "Selecione uma opção [0-6]: " option
    
    case $option in
        1)
            echo -e "${CYAN}Iniciando instalação completa...${NC}"
            main_install
            ;;
        2)
            echo -e "${CYAN}Instalando Xray Core...${NC}"
            install_xray
            ;;
        3)
            echo -e "${CYAN}Instalando WebSocket Proxy...${NC}"
            install_websocket_proxy
            ;;
        4)
            echo -e "${CYAN}Instalando Banner SSH...${NC}"
            install_login_banner
            ;;
        5)
            echo -e "${CYAN}Instalando Menu...${NC}"
            create_menu_command
            ;;
        6)
            uninstall_script
            ;;
        0)
            echo -e "${GREEN}Saindo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 2
            show_install_menu
            ;;
    esac
}

# ============================================
# EXECUÇÃO PRINCIPAL
# ============================================

# Verificar se foi passado argumento
if [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    main_install
elif [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    uninstall_script
elif [ "$1" = "--banner" ] || [ "$1" = "-b" ]; then
    install_login_banner
elif [ "$1" = "--menu" ] || [ "$1" = "-m" ]; then
    create_menu_command
else
    # Mostrar menu interativo
    show_install_menu
fi

echo ""
echo -e "${GREEN}Script finalizado!${NC}"
