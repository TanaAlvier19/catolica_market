#!/bin/bash

ARQUIVO_FUNCIONARIOS="/opt/catolica_market/data/funcionarios/funcionarios.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_funcionario()
{
    local operador_actual="$1"
    local id nome cargo grupo utilizador_linux senha filial data_cadastro

    id=$(interface --title "Cadastro de Funcionário" --inputbox "ID do Funcionário (ex: 1008):" 8 50) || return 1
    nome=$(interface --title "Cadastro de Funcionário" --inputbox "Nome Completo:" 8 50) || return 1
    cargo=$(interface --title "Cadastro de Funcionário" --inputbox "Cargo / Função:" 8 50) || return 1
    grupo=$(interface --title "Cadastro de Funcionário" --inputbox "Grupo de Sistema (ex: cm_atendentes):" 8 50) || return 1
    utilizador_linux=$(interface --title "Cadastro de Funcionário" --inputbox "Utilizador Linux (Sistemas):" 8 50) || return 1
    senha=$(interface --title "Cadastro de Funcionário" --passwordbox "Senha de Acesso:" 8 50) || return 1
    filial=$(interface --title "Cadastro de Funcionário" --inputbox "Filial (ex: filiar_luanda):" 8 50) || return 1
    
    data_cadastro=$(date +%d/%m/%Y)

    sudo mkdir -p "$(dirname "$ARQUIVO_FUNCIONARIOS")"
    sudo touch "$ARQUIVO_FUNCIONARIOS"

    echo "${id};${grupo};${nome};${filial};${senha};${utilizador_linux};${cargo};${data_cadastro};${operador_actual}" | sudo tee -a "$ARQUIVO_FUNCIONARIOS" > /dev/null

    whiptail --title "Sucesso" --msgbox "Funcionário '$nome' cadastrado com sucesso!" 8 50
}

menu_funcionario()
{
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Gestão de Funcionários" \
                --menu "Escolha uma das opções abaixo" 16 50 6 \
                "1" "Cadastrar Funcionário" \
                "2" "Listar Funcionários" \
                "3" "Eliminar Funcionário" \
                "4" "Actualizar Funcionário" \
                "5" "Pesquisar por Funcionário" \
                "6" "Voltar" \
            ) || break

        case $opcao in
           1)
               cadastrar_funcionario "$operador_actual" ;;
           6|*) 
               break ;;
        esac
    done
}

