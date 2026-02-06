# Azrael Xray Manager

Um script de gerenciamento completo para Xray-core com interface de menu e sistema de clientes.

## Funcionalidades
- Instalação automática do Xray-core
- Suporte para múltiplos protocolos (WS, gRPC, TCP, HTTP/2)
- Sistema de gerenciamento de clientes
- TLS automático com Let's Encrypt
- Banner de login personalizado
- Interface de menu interativa

## Instalação
```bash
curl -sL https://raw.githubusercontent.com/Fabricio110916/azrael-xray-manager/main/install.sh | sudo bash
```

Ou:

```bash
wget https://raw.githubusercontent.com/Fabricio110916/azrael-xray-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

Uso

Após instalação, execute:

```bash
xray-menu
```

ou

```bash
xm
```

Requisitos

· Sistema operacional baseado em Debian/Ubuntu
· Acesso root
· Conexão com internet

Aviso

Este script deve ser usado apenas em servidores que você possui permissão para configurar.
