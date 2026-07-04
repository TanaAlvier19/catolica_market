#!/bin/bash

ARQUIVO_CLIENTES="../data/clientes/clientes.txt"
source /opt/catolica_market/lib/funcoes.sh

adicionar_cliente() {
    local numero_cartao nome nif saldo data_cadastro

    numero_cartao=$(interface --title "Cadastro de cliente" --inputbox "Número de Cartão:" 8 40) || return 1
    nome=$(interface --title "Cadastro de cliente" --inputbox "Nome do Cliente:" 8 40) || return 1
    nif=$(interface --title "Cadastro de cliente" --inputbox "NIF do Cliente:" 8 40) || return 1
    saldo=$(interface --title "Cadastro de cliente" --inputbox "Introduza o saldo do cliente:" 8 40) || return 1	
    data_cadastro=$(date +%d/%m/%Y)

    
    echo "${numero_cartao};${nome};${nif};${saldo};${data_cadastro}" >> "$ARQUIVO_CLIENTES"

    whiptail --title "Sucesso" --msgbox "Cliente '$nome' cadastrado com sucesso!" 8 40
}

listar_clientes() {
    local lista
    lista=$(sudo cut -d";" -f2,3,4,5 "$ARQUIVO_CLIENTES" | tr ';' '\t')
    lista=${lista:-"(nenhum cliente cadastrado)"}

    whiptail --title "Todos os Clientes" \
        --msgbox "$lista" 18 60
}

menu_cliente() {
    local opcao

	while true; do
		opcao=$(interface --title "Gestão de Clientes" \
				--menu "Escolha uma das opções abaixo" 16 50 6 \
				"1" "Cadastrar Clientes" \
				"2" "Listar Clientes" \
				"3" "Eliminar Clientes" \
				"4" "Actualizar Clientes" \
				"5" "Pesquisar por Cliente" \
				"6" "Voltar" \
			) || break

		case $opcao in
			1) 
				adicionar_cliente ;;
			2) 
				listar_clientes ;;
			6) 
				break ;;
		esac
	done
}

