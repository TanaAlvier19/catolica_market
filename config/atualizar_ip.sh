#!/bin/bash
# Actualiza, no ficheiro central data/filiais/filiais.txt, o IP actual desta filial

ARQUIVO_FILIAIS="../data/filiais/filiais.txt"
MARCADOR_LOCAL="/etc/catolica_market/filial.conf"

if [ ! -f "$MARCADOR_LOCAL" ]; then
    echo "$(date '+%d/%m/%Y %H:%M:%S') - filial ainda não inicializada (sem $MARCADOR_LOCAL). A ignorar."
    exit 1
fi

# Define FILIAL_NOME
source "$MARCADOR_LOCAL"

if [ -z "$FILIAL_NOME" ]; then
    echo "$(date '+%d/%m/%Y %H:%M:%S') - FILIAL_NOME não definido em $MARCADOR_LOCAL."
    exit 1
fi

if [ ! -f "$ARQUIVO_FILIAIS" ]; then
    echo "$(date '+%d/%m/%Y %H:%M:%S') - $ARQUIVO_FILIAIS inacessível (sem ligação à central?)."
    exit 1
fi

ip_actual=$(hostname -I | awk '{print $1}')

if [ -z "$ip_actual" ]; then
    echo "$(date '+%d/%m/%Y %H:%M:%S') - não foi possível determinar o IP local."
    exit 1
fi

awk -F';' -v OFS=';' -v nome="$FILIAL_NOME" -v ip="$ip_actual" '
    $2==nome { $6=ip }
    { print }
' "$ARQUIVO_FILIAIS" | sudo tee "${ARQUIVO_FILIAIS}.tmp" > /dev/null && sudo mv "${ARQUIVO_FILIAIS}.tmp" "$ARQUIVO_FILIAIS"

echo "$(date '+%d/%m/%Y %H:%M:%S') - IP da filial '$FILIAL_NOME' actualizado para $ip_actual."
