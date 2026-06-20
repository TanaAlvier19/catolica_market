#!/bin/bash

ARQUIVO_PRODUTO="/opt/catolica_market/data/produtos/produtos.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_produto()
{
	local operador_actual="$1"
	local codigo nome categoria preco quantidade estoque_minimo data_cadastro
	codigo=$(interface --title "Cadastro" --inputbox "Código do produto:" 8 40)||return 1
	nome=$(interface --title "Cadastro" --inputbox "Nome do produto:" 8 40)||return 1
	categoria=$(interface --title "Cadastro" --inputbox "Categora  do produto:" 8 40)||return 1
	quantidade=$(interface --title "Cadastro" --inputbox "quantidade do produto:" 8 40)||return 1
	preco=$(interface --title "Cadastro" --inputbox "preço do produto:" 8 40)||return 1
	estoque_minimo=$(interface --title "Cadastro" --inputbox "Estoque Mínimo do produto:" 8 40)||return 1

	data_cadastro=$(date +%d/%m/%Y)
	echo "${codigo};${nome};${categoria};${preco};${quantidade};${estoque_minimo};${data_cadastro};${operador_actual}" >> "$ARQUIVO_PRODUTO"
	whiptail --title "Sucesso" --msgbox "Produto '$nome' cadastrado com sucesso!" 8 40
}

listar_produtos() {

    local lista
    lista=$(sudo cut -d";" -f2,3,4,5 "$ARQUIVO_PRODUTO" | tr ';' '\t')
    lista=${lista:-"(nenhum produto cadastrado)"}

    whiptail --title "Todos os Produto" \
        --msgbox "$lista" 18 60
}


menu_produto()
{
	local operador_actual="$1"
 	local opcao
	while true; do
		opcao=$(interface --title "Gestão de produto" \
				--menu "Escolha uma das opções abaixo" 15 50 5 \
				"1" "Cadastrar Produtos" \
				"2" "Listar Produtos" \
				"3" "Eliminar Produto" \
				"4" "Actualizar Produto" \
				"5" "Pesquisar por produto" \
				"6" "Voltar"\
			)
		case $opcao in
		1)
			cadastrar_produto "$operador_atual";;
		2)  
			listar_produtos;;
		6)  	
				break;;
			
		esac
	done

}
