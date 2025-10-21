#!/bin/bash

# ==============================================
# Script para Geração de Certificado SSL Autoassinado
# ==============================================
# 
# Este script cria um certificado SSL autoassinado para uso
# em ambiente de desenvolvimento/teste local.
#
# ATENÇÃO: Não use certificados autoassinados em produção!
# ==============================================

set -e

echo "🔐 Gerando Certificado SSL Autoassinado..."
echo ""

# Diretório de destino
SSL_DIR="./nginx/ssl"

# Verificar se o diretório existe
if [ ! -d "$SSL_DIR" ]; then
    echo "❌ Erro: Diretório $SSL_DIR não encontrado!"
    echo "Execute este script a partir do diretório raiz do projeto."
    exit 1
fi

# Gerar chave privada e certificado autoassinado em um único comando
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/self-signed.key" \
    -out "$SSL_DIR/self-signed.crt" \
    -subj "/C=BR/ST=State/L=City/O=Development/OU=IT/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Verificar se os arquivos foram criados
if [ -f "$SSL_DIR/self-signed.crt" ] && [ -f "$SSL_DIR/self-signed.key" ]; then
    echo ""
    echo "✅ Certificado SSL gerado com sucesso!"
    echo ""
    echo "📁 Arquivos criados:"
    echo "   - $SSL_DIR/self-signed.crt (Certificado)"
    echo "   - $SSL_DIR/self-signed.key (Chave Privada)"
    echo ""
    echo "ℹ️  Validade: 365 dias"
    echo "ℹ️  Common Name (CN): localhost"
    echo ""
    echo "⚠️  AVISO: Seu navegador irá alertar que o certificado não é confiável."
    echo "   Isso é normal para certificados autoassinados. Aceite a exceção para continuar."
    echo ""
else
    echo "❌ Erro ao gerar certificado SSL!"
    exit 1
fi
