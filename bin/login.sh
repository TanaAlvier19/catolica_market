#!/bin/bash

ARQUIVO_USUARIOS="/opt/catolica_market/data/funcionarios/funcionarios.txt"
source ./menu_principal.sh
source /opt/catolica_market/lib/funcoes.sh

autenticar_operador() {
    local id senha registro

    id=$(interface --title "Acesso ao Sistema" --inputbox "ID:" 8 40)    || return 1
    senha=$(interface --title "Acesso ao Sistema" --passwordbox "Senha:" 8 40) || return 1

    registro=$(grep "^${id};" "$ARQUIVO_USUARIOS") || {
        whiptail --title "Erro" --msgbox "Operador não encontrado." 8 40
        return 1
    }

    nome=$(awk -F';' '{print $3}' <<< "$registro")
    grupo=$(awk -F';' '{print $2}' <<< "$registro")

    if [ "$(awk -F';' '{print $5}' <<< "$registro")" = "$senha" ]; then
        whiptail --title "Sucesso" --msgbox "Bem-vindo, $nome!" 8 40
	echo "$nome"       
 	return 0
    else
        whiptail --title "Erro" --msgbox "Senha incorreta." 8 40
        return 1
    fi
}

if autenticar_operador; then
    echo "Login aceito. $nome"
    menu_principal $grupo
else
    echo "Login falhou ou foi cancelado."
fi
