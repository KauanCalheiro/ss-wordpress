# 🚀 Infraestrutura Docker para WordPress com SSL

Ambiente Docker completo e seguro para desenvolvimento e testes de WordPress com SSL/TLS autoassinado, proxy reverso Nginx e isolamento de rede.

---

## 📋 Índice

- [Características](#-características)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Instalação](#-instalação)
- [Uso](#-uso)
- [Configuração](#-configuração)
- [Segurança](#-segurança)
- [Troubleshooting](#-troubleshooting)
- [Comandos Úteis](#-comandos-úteis)

---

## ✨ Características

- ✅ **WordPress** (última versão estável)
- ✅ **MySQL 8.0** com persistência de dados
- ✅ **Nginx** como proxy reverso com SSL/TLS
- ✅ **Certificado SSL autoassinado** para testes locais
- ✅ **Rede interna isolada** (apenas Nginx exposto)
- ✅ **Redirecionamento automático HTTP → HTTPS**
- ✅ **Health checks** em todos os serviços
- ✅ **Variáveis de ambiente** para configurações sensíveis
- ✅ **Volumes persistentes** para dados e uploads

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────┐
│                  MÁQUINA HOST                    │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │         Portas Expostas                  │   │
│  │   HTTP (80) ──┐    HTTPS (443) ──┐      │   │
│  └───────────────┼───────────────────┼──────┘   │
└─────────────────┼───────────────────┼───────────┘
                  │                   │
                  ▼                   ▼
         ┌─────────────────────────────────┐
         │         NGINX CONTAINER          │
         │    (Proxy Reverso + SSL)        │
         │  • Redirecionamento HTTP→HTTPS  │
         │  • Terminação SSL               │
         │  • Headers de Segurança         │
         └──────────────┬──────────────────┘
                        │
              ┌─────────┴──────────┐
              │  Rede Interna      │
              │  (Isolada)         │
              └─────────┬──────────┘
                        │
         ┌──────────────┴──────────────────┐
         │                                  │
         ▼                                  ▼
┌──────────────────┐            ┌──────────────────┐
│   WORDPRESS      │            │      MYSQL       │
│   CONTAINER      │◄───────────┤   CONTAINER      │
│                  │            │                  │
│ • PHP-FPM        │            │ • MySQL 8.0      │
│ • Apache         │            │ • Port 3306      │
│ • Port 80        │            │ (Interno)        │
│ (Interno)        │            │                  │
└────────┬─────────┘            └────────┬─────────┘
         │                               │
         ▼                               ▼
  ┌─────────────┐                ┌─────────────┐
  │   Volume:   │                │   Volume:   │
  │ WordPress   │                │   MySQL     │
  │   Data      │                │    Data     │
  └─────────────┘                └─────────────┘
```

### 🔒 Isolamento de Rede

- **Rede Interna (`wordpress_internal_network`)**: Todos os containers se comunicam por essa rede privada
- **MySQL**: Acessível SOMENTE pelos containers na rede interna
- **WordPress**: Acessível SOMENTE pelos containers na rede interna
- **Nginx**: ÚNICO serviço exposto ao host (portas 80 e 443)

---

## 📦 Pré-requisitos

Certifique-se de ter instalado:

- [Docker](https://docs.docker.com/get-docker/) (versão 20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (versão 1.29+)
- **OpenSSL** (para gerar certificados SSL)

### Verificar instalação:

```bash
docker --version
docker-compose --version
openssl version
```

---

## 📁 Estrutura do Projeto

```
ss-project/
├── docker-compose.yml          # Orquestração de containers
├── .env                        # Variáveis de ambiente (senhas, configurações)
├── .gitignore                  # Arquivos ignorados pelo Git
├── generate-ssl.sh             # Script para gerar certificado SSL
├── README.md                   # Esta documentação
│
├── db/
│   ├── data/                  # Dados persistentes do MySQL
│   │   └── .gitkeep           # Mantém estrutura no Git
│   └── README.md              # Documentação do MySQL
│
├── wordpress/
│   ├── data/                  # Arquivos do WordPress (themes, plugins, uploads)
│   │   └── .gitkeep           # Mantém estrutura no Git
│   └── README.md              # Documentação do WordPress
│
└── nginx/
    ├── conf/
    │   └── nginx.conf         # Configuração do Nginx (proxy reverso)
    ├── ssl/
    │   ├── self-signed.crt    # Certificado SSL (gerado)
    │   └── self-signed.key    # Chave privada SSL (gerado)
    ├── logs/                  # Logs de acesso e erro do Nginx
    │   └── .gitkeep           # Mantém estrutura no Git
    └── README.md              # Documentação do Nginx
```

---

## 🚀 Instalação

### 1️⃣ Clone ou baixe este projeto

```bash
cd /home/kauan/Desktop/ss-project
```

### 2️⃣ Configure as variáveis de ambiente

Edite o arquivo `.env` e altere as senhas padrão:

```bash
nano .env
```

**⚠️ IMPORTANTE:** Nunca use as senhas padrão em produção!

### 3️⃣ Gere o certificado SSL

Execute o script automatizado:

```bash
./generate-ssl.sh
```

Ou manualmente:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/self-signed.key \
    -out nginx/ssl/self-signed.crt \
    -subj "/C=BR/ST=State/L=City/O=Development/OU=IT/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

### 4️⃣ Inicie o ambiente

```bash
docker-compose up -d
```

### 5️⃣ Aguarde a inicialização

Acompanhe os logs:

```bash
docker-compose logs -f
```

Aguarde até ver mensagens indicando que todos os serviços estão prontos.

### 6️⃣ Acesse o WordPress

Abra seu navegador e acesse:

**🌐 https://localhost**

⚠️ **Aviso de Segurança**: Seu navegador alertará sobre o certificado autoassinado. Isso é **normal** e esperado. Clique em "Avançado" → "Aceitar Risco e Continuar" (Firefox) ou "Avançar para localhost" (Chrome).

---

## 🎯 Uso

### Acessar o WordPress

1. Navegue para: **https://localhost**
2. Complete a instalação do WordPress:
   - Escolha idioma
   - Defina título do site
   - Crie usuário administrador
   - Defina email

### Acessar o banco de dados

Para conectar ao MySQL via terminal:

```bash
docker-compose exec db mysql -u wordpress_user -p
```

Senha: (definida no arquivo `.env`)

### Parar o ambiente

```bash
docker-compose down
```

### Reiniciar o ambiente

```bash
docker-compose restart
```

---

## ⚙️ Configuração

### Variáveis de Ambiente (`.env`)

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `MYSQL_DATABASE` | Nome do banco de dados | `wordpress_db` |
| `MYSQL_USER` | Usuário do MySQL | `wordpress_user` |
| `MYSQL_PASSWORD` | Senha do usuário MySQL | `secure_password_123` |
| `MYSQL_ROOT_PASSWORD` | Senha do root MySQL | `root_secure_password_456` |
| `WORDPRESS_DB_HOST` | Host do banco (interno) | `db:3306` |
| `INTERNAL_NETWORK` | Nome da rede interna | `wordpress_internal_network` |

### Armazenamento de Dados

Os dados são armazenados em **diretórios locais** (bind mounts) ao invés de volumes Docker:

| Diretório | Conteúdo | Backup |
|-----------|----------|--------|
| `./db/data/` | Dados do MySQL | `mysqldump` ou copiar diretório |
| `./wordpress/data/` | Arquivos WordPress | `tar` ou copiar diretório |
| `./nginx/logs/` | Logs do Nginx | Rotação automática recomendada |

**Vantagens:**
- ✅ Acesso direto aos arquivos
- ✅ Backup simplificado (copiar pastas)
- ✅ Desenvolvimento facilitado (editar temas/plugins)
- ✅ Fácil migração entre ambientes

### Portas Expostas

| Serviço | Porta Interna | Porta Externa | Protocolo |
|---------|---------------|---------------|-----------|
| Nginx   | 80            | 80            | HTTP (redireciona para HTTPS) |
| Nginx   | 443           | 443           | HTTPS |
| MySQL   | 3306          | ❌ (não exposto) | TCP |
| WordPress | 80          | ❌ (não exposto) | HTTP |

---

## 🔐 Segurança

### ✅ Implementações de Segurança

1. **Rede Isolada**: MySQL e WordPress não são acessíveis externamente
2. **SSL/TLS**: Todo tráfego HTTP é redirecionado para HTTPS
3. **Headers de Segurança**:
   - `Strict-Transport-Security` (HSTS)
   - `X-Frame-Options`
   - `X-Content-Type-Options`
   - `X-XSS-Protection`
4. **Proteção de Arquivos**: Bloqueio de acesso a arquivos `.ht*`, `.git`, e PHPs em uploads
5. **Health Checks**: Monitoramento automático da saúde dos serviços

### ⚠️ Avisos de Segurança

- **NÃO USE EM PRODUÇÃO** sem modificações adequadas
- **ALTERE TODAS AS SENHAS PADRÃO** do arquivo `.env`
- **Certificados autoassinados** são SOMENTE para desenvolvimento
- Para produção, use certificados válidos (Let's Encrypt, etc.)
- Adicione `.env` ao `.gitignore` (já configurado)

---

## 🔧 Troubleshooting

### Problema: "Certificado não confiável"

✅ **Normal**: Certificados autoassinados não são confiáveis por padrão. Aceite a exceção no navegador.

### Problema: Porta 80 ou 443 já em uso

```bash
# Verificar processos usando as portas
sudo lsof -i :80
sudo lsof -i :443

# Parar Apache (se estiver rodando)
sudo systemctl stop apache2
```

### Problema: Containers não iniciam

```bash
# Ver logs detalhados
docker-compose logs

# Verificar status
docker-compose ps

# Rebuild completo
docker-compose down -v
docker-compose up -d --build
```

### Problema: WordPress não conecta ao MySQL

1. Verifique as variáveis no `.env`
2. Aguarde o health check do MySQL:
   ```bash
   docker-compose logs db
   ```
3. Reinicie o WordPress:
   ```bash
   docker-compose restart wordpress
   ```

### Problema: Erro de permissão nos volumes

```bash
# Ajustar permissões (se necessário)
sudo chown -R $USER:$USER volumes/
```

---

## 📚 Comandos Úteis

### Gerenciamento de Containers

```bash
# Iniciar em background
docker-compose up -d

# Iniciar e ver logs em tempo real
docker-compose up

# Parar containers
docker-compose down

# Parar e remover volumes (⚠️ APAGA DADOS)
docker-compose down -v

# Reiniciar um serviço específico
docker-compose restart nginx
docker-compose restart wordpress
docker-compose restart db

# Ver status dos containers
docker-compose ps

# Ver logs
docker-compose logs -f
docker-compose logs -f nginx
docker-compose logs -f wordpress
docker-compose logs -f db
```

### Acesso aos Containers

```bash
# Acessar bash do WordPress
docker-compose exec wordpress bash

# Acessar MySQL
docker-compose exec db mysql -u root -p

# Executar WP-CLI
docker-compose exec wordpress wp --info --allow-root
```

### Backup e Restore

```bash
# ========================================
# BACKUP DO BANCO DE DADOS
# ========================================

# Método 1: SQL dump (recomendado)
docker-compose exec db mysqldump -u root -p wordpress_db > backup_$(date +%Y%m%d).sql

# Método 2: Copiar diretório (container deve estar parado)
docker-compose down
cp -r db/data db/data_backup_$(date +%Y%m%d)
docker-compose up -d

# ========================================
# BACKUP DO WORDPRESS
# ========================================

# Backup completo
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz wordpress/data/

# Backup apenas do wp-content (temas, plugins, uploads)
tar -czf wp-content_backup_$(date +%Y%m%d).tar.gz wordpress/data/wp-content/

# ========================================
# RESTORE
# ========================================

# Restore do banco de dados (via SQL)
docker-compose exec -T db mysql -u root -p wordpress_db < backup_20231021.sql

# Restore do WordPress (descompactar)
docker-compose down
rm -rf wordpress/data/*
tar -xzf wordpress_backup_20231021.tar.gz
docker-compose up -d

# ========================================
# BACKUP AUTOMÁTICO (Cron)
# ========================================

# Adicionar ao crontab (backup diário às 2h da manhã)
# crontab -e
# 0 2 * * * cd /home/kauan/Desktop/ss-project && docker-compose exec -T db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress_db > backup_$(date +\%Y\%m\%d).sql
```

### Limpeza

```bash
# Remover containers órfãos
docker-compose down --remove-orphans

# Limpar volumes não utilizados
docker volume prune

# Limpar imagens não utilizadas
docker image prune -a
```

---

## 📝 Notas Adicionais

### Configuração Avançada do WordPress

Para adicionar configurações customizadas ao `wp-config.php`, edite a seção `WORDPRESS_CONFIG_EXTRA` no `docker-compose.yml`.

### Performance

Para ambientes de produção, considere:
- Aumentar recursos alocados (CPU, RAM)
- Configurar cache (Redis, Memcached)
- Otimizar configurações do MySQL
- Usar volumes com drivers otimizados

### Certificado SSL para Produção

Para produção, substitua o certificado autoassinado por um certificado válido:

1. Use **Let's Encrypt** com Certbot
2. Monte os certificados válidos no Nginx
3. Configure renovação automática

---

## 📄 Licença

Este projeto é livre para uso educacional e de desenvolvimento.

---

## 🤝 Contribuições

Sinta-se livre para reportar issues ou sugerir melhorias!

---

## 📞 Suporte

Para problemas relacionados a:
- **Docker**: https://docs.docker.com/
- **WordPress**: https://wordpress.org/support/
- **Nginx**: https://nginx.org/en/docs/
- **MySQL**: https://dev.mysql.com/doc/

---

**Desenvolvido com ❤️ para ambientes de desenvolvimento seguro**
