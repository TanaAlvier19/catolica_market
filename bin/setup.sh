#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

ARQUIVO_FUNCIONARIOS="../data/funcionarios/funcionarios.txt"
ARQUIVO_FILIAIS="../data/filiais/filiais.txt"
MARCADOR_LOCAL="../filial.conf"
ATUALIZAR_IP_SCRIPT="$CONFIG_DIR/atualizar_ip.sh"

#Sincronização com a central (só define/chama sincronizar_com_central)
source "$CONFIG_DIR/filiais.sh"

# lib/funcoes.sh só existe depois de a partilha estar montada
source /opt/catolica_market/lib/funcoes.sh

# Funções de agendamento (confCron / confCronIP)
source "$CONFIG_DIR/cron.sh"

msg_ok()  { whiptail --title "Sucesso" --msgbox "$1" 9 60; }
msg_err() { whiptail --title "Erro"   --msgbox "$1" 9 60; }

verificar_sincronizacao()
{
    if [ ! -f "$ARQUIVO_FUNCIONARIOS" ] || [ ! -f "$ARQUIVO_FILIAIS" ]; then
        msg_err "Não foi possível sincronizar com a central.\nVerifique a ligação de rede e tente novamente."
        return 1
    fi
    return 0
}

#Login manual, validado com os dados da central 
autenticar_operador()
{
    local id senha registro senha_registada

    id=$(interface --title "Acesso ao Sistema" --inputbox "ID:" 8 40) || return 1
    senha=$(interface --title "Acesso ao Sistema" --passwordbox "Senha:" 8 40) || return 1

    registro=$(grep "^${id};" "$ARQUIVO_FUNCIONARIOS") || {
        msg_err "Operador não encontrado."
        return 1
    }

    GRUPO=$(awk -F';' '{print $2}' <<< "$registro")
    NOME=$(awk -F';' '{print $3}' <<< "$registro")
    FILIAL_OPERADOR=$(awk -F';' '{print $4}' <<< "$registro")
    senha_registada=$(awk -F';' '{print $5}' <<< "$registro")

    if [ "$senha_registada" != "$senha" ]; then
        msg_err "Senha incorreta."
        return 1
    fi

    if [ -z "$FILIAL_OPERADOR" ] || [ "$FILIAL_OPERADOR" = "central" ]; then
        msg_err "Esta credencial pertence à central e não pode ser usada\npara inicializar uma filial."
        return 1
    fi

    msg_ok "Bem-vindo, $NOME!"
    return 0
}

# 3. Activação da filial (só acontece no primeiro login, feito pelo ADM)
activar_filial()
{
    local estado_actual

    estado_actual=$(awk -F';' -v n="$FILIAL_OPERADOR" '$2==n {print $7; exit}' "$ARQUIVO_FILIAIS")

    if [ -z "$estado_actual" ]; then
        msg_err "A filial '$FILIAL_OPERADOR' não está cadastrada na central.\nContacte o administrador central."
        return 1
    fi

    awk -F';' -v OFS=';' -v n="$FILIAL_OPERADOR" '
        $2==n { $7="ativo" }
        { print }
    ' "$ARQUIVO_FILIAIS" | sudo tee "${ARQUIVO_FILIAIS}.tmp" > /dev/null && sudo mv "${ARQUIVO_FILIAIS}.tmp" "$ARQUIVO_FILIAIS"

    sudo mkdir -p "$(dirname "$MARCADOR_LOCAL")"
    echo "FILIAL_NOME=$FILIAL_OPERADOR" | sudo tee "$MARCADOR_LOCAL" > /dev/null

    sudo chmod +x "$ATUALIZAR_IP_SCRIPT"
    bash "$ATUALIZAR_IP_SCRIPT"
    confCronIP "$ATUALIZAR_IP_SCRIPT"

    msg_ok "Filial '$FILIAL_OPERADOR' activada com sucesso!\nEstado: ativo\nActualização de IP agendada (2 em 2 minutos)."
}


verificar_sincronizacao || exit 1
autenticar_operador || exit 1

if [ ! -f "$MARCADOR_LOCAL" ]; then
    if [ "$GRUPO" = "cm_admin" ]; then
        activar_filial || exit 1
    else
        msg_err "Esta filial ainda não foi inicializada.\nPeça ao ADM da filial para fazer o primeiro login."
        exit 1
    fi
fi

Arranca o sistema para o operador autenticado
source ../bin/menu_principal.sh
menu_principal "$GRUPO" "$NOME"
