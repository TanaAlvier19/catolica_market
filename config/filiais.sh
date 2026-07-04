#!/bin/bash

PASTA_MONTAGEM="/mnt/catolica_market"

sincronizar_com_central()
{
    echo "A preparar sincronização com a central..."
    sudo apt-get update -qq
    sudo apt-get install -y cifs-utils samba-client >/dev/null 2>&1

    sudo mkdir -p "$PASTA_MONTAGEM"

    if mountpoint -q "$PASTA_MONTAGEM"; then
        echo "Partilha da central já está montada em $PASTA_MONTAGEM."
        return 0
    fi

    echo "A procurar o servidor da central automaticamente..."
    SERVIDOR=$(nmblookup catolica-market 2>/dev/null | awk '/^[0-9]/{print $1}' | head -n 1)

    if [ -z "$SERVIDOR" ]; then
        echo "Servidor não encontrado automaticamente. A usar nome NetBIOS 'catolica-market'."
        SERVIDOR="catolica-market"
    fi

    echo "Servidor: $SERVIDOR"
    echo "A montar partilha da central com permissões de escrita..."

    sudo mount -t cifs "//$SERVIDOR/catolica_market" "$PASTA_MONTAGEM" \
        -o guest,rw,file_mode=0777,dir_mode=0777

    if [ $? -eq 0 ]; then
        echo "Sincronização com a central concluída (montada em $PASTA_MONTAGEM)."
        return 0
    else
        echo "Erro ao sincronizar com a central."
        return 1
    fi
}

sincronizar_com_central
