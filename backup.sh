#!/bin/bash

# ==============================================
# Script de Backup Automático
# ==============================================
#
# Este script faz backup completo do ambiente WordPress:
#   - Banco de dados MySQL (SQL dump)
#   - Arquivos do WordPress (tar.gz)
#   - Configurações do Nginx
#
# ==============================================

set -e

# Configurações
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "🔄 Iniciando Backup do WordPress"
echo "========================================"
echo ""

# Criar diretório de backup se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    echo "📁 Criando diretório de backup..."
    mkdir -p "$BACKUP_DIR"
fi

# Verificar se o Docker Compose está rodando
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Aviso: Containers não estão rodando. Iniciando...${NC}"
    docker-compose up -d
    sleep 10
fi

# ========================================
# BACKUP DO BANCO DE DADOS
# ========================================
echo "📊 Fazendo backup do banco de dados..."

DB_BACKUP_FILE="$BACKUP_DIR/db_backup_${DATE}.sql"

# Carregar variáveis do .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

docker-compose exec -T db mysqldump \
    -u root \
    -p${MYSQL_ROOT_PASSWORD} \
    ${MYSQL_DATABASE} > "$DB_BACKUP_FILE"

if [ -f "$DB_BACKUP_FILE" ]; then
    # Compactar SQL
    gzip "$DB_BACKUP_FILE"
    echo -e "${GREEN}✅ Backup do banco de dados criado: ${DB_BACKUP_FILE}.gz${NC}"
    DB_SIZE=$(du -h "${DB_BACKUP_FILE}.gz" | cut -f1)
    echo "   Tamanho: $DB_SIZE"
else
    echo -e "${RED}❌ Erro ao criar backup do banco de dados!${NC}"
    exit 1
fi

# ========================================
# BACKUP DOS ARQUIVOS DO WORDPRESS
# ========================================
echo ""
echo "📁 Fazendo backup dos arquivos do WordPress..."

WP_BACKUP_FILE="$BACKUP_DIR/wordpress_backup_${DATE}.tar.gz"

tar -czf "$WP_BACKUP_FILE" \
    --exclude='wordpress/data/.gitkeep' \
    wordpress/data/ 2>/dev/null || true

if [ -f "$WP_BACKUP_FILE" ]; then
    echo -e "${GREEN}✅ Backup do WordPress criado: ${WP_BACKUP_FILE}${NC}"
    WP_SIZE=$(du -h "$WP_BACKUP_FILE" | cut -f1)
    echo "   Tamanho: $WP_SIZE"
else
    echo -e "${RED}❌ Erro ao criar backup do WordPress!${NC}"
    exit 1
fi

# ========================================
# BACKUP DAS CONFIGURAÇÕES
# ========================================
echo ""
echo "⚙️  Fazendo backup das configurações..."

CONFIG_BACKUP_FILE="$BACKUP_DIR/config_backup_${DATE}.tar.gz"

tar -czf "$CONFIG_BACKUP_FILE" \
    docker-compose.yml \
    nginx/conf/ \
    .env.example 2>/dev/null || true

if [ -f "$CONFIG_BACKUP_FILE" ]; then
    echo -e "${GREEN}✅ Backup das configurações criado: ${CONFIG_BACKUP_FILE}${NC}"
    CONFIG_SIZE=$(du -h "$CONFIG_BACKUP_FILE" | cut -f1)
    echo "   Tamanho: $CONFIG_SIZE"
fi

# ========================================
# CRIAR BACKUP COMPLETO (OPCIONAL)
# ========================================
echo ""
read -p "Criar backup completo em um único arquivo? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo "📦 Criando backup completo..."
    
    FULL_BACKUP_FILE="$BACKUP_DIR/full_backup_${DATE}.tar.gz"
    
    tar -czf "$FULL_BACKUP_FILE" \
        "${DB_BACKUP_FILE}.gz" \
        "$WP_BACKUP_FILE" \
        "$CONFIG_BACKUP_FILE" 2>/dev/null
    
    if [ -f "$FULL_BACKUP_FILE" ]; then
        echo -e "${GREEN}✅ Backup completo criado: ${FULL_BACKUP_FILE}${NC}"
        FULL_SIZE=$(du -h "$FULL_BACKUP_FILE" | cut -f1)
        echo "   Tamanho: $FULL_SIZE"
        
        # Remover backups individuais
        read -p "Remover backups individuais? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[SsYy]$ ]]; then
            rm -f "${DB_BACKUP_FILE}.gz" "$WP_BACKUP_FILE" "$CONFIG_BACKUP_FILE"
            echo "🗑️  Backups individuais removidos"
        fi
    fi
fi

# ========================================
# LIMPEZA DE BACKUPS ANTIGOS
# ========================================
echo ""
read -p "Limpar backups com mais de 30 dias? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo "🧹 Removendo backups antigos..."
    find "$BACKUP_DIR" -name "*.tar.gz" -o -name "*.sql.gz" -mtime +30 -delete
    echo -e "${GREEN}✅ Backups antigos removidos${NC}"
fi

# ========================================
# RESUMO
# ========================================
echo ""
echo "========================================"
echo -e "${GREEN}✅ Backup Concluído com Sucesso!${NC}"
echo "========================================"
echo ""
echo "📁 Backups salvos em: $BACKUP_DIR/"
echo ""
echo "Arquivos criados:"
ls -lh "$BACKUP_DIR" | grep "$DATE" | awk '{print "   - " $9 " (" $5 ")"}'
echo ""
echo "📊 Espaço total usado por backups:"
du -sh "$BACKUP_DIR"
echo ""
echo "========================================"

# Opcional: Enviar para armazenamento remoto
# rsync -avz "$BACKUP_DIR/" user@remote:/backups/wordpress/
# rclone copy "$BACKUP_DIR/" remote:backups/wordpress/
