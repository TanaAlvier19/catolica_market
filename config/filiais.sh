#!/bin/bash

PASTA_MONTAGEM="/mnt/catolica_market"

echo "Instalando ferramentas cliente..."

sudo apt update
sudo apt install -y cifs-utils samba-client

sudo mkdir -p "$PASTA_MONTAGEM"

echo "A procurar servidor automaticamente..."

SERVIDOR=$(nmblookup catolica-market 2>/dev/null | awk '/^[0-9]/{print $1}' | head -n 1)

if [ -z "$SERVIDOR" ]; then
    echo "Servidor não encontrado automaticamente."
    echo "A usar nome NetBIOS..."
    SERVIDOR="catolica-market"
fi

echo "Servidor: $SERVIDOR"

echo "Montando partilha com permissões de escrita..."

sudo mount -t cifs //$SERVIDOR/catolica_market "$PASTA_MONTAGEM" \
    -o guest,rw,file_mode=0777,dir_mode=0777

if [ $? -eq 0 ]; then
    echo "Montagem concluída com escrita total!"
else
    echo "Erro ao montar partilha."
fi
