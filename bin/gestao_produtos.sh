#!/bin/bash

ARQUIVO_PRODUTO="/opt/catolica_market/data/produtos/produtos.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_produto()
{
	local operador_actual="$1"
	local codigo nome categoria preco quantidade estoque_minimo data_cadastro

	codigo=$(interface --title "Cadastro" --inputbox "Código do produto:" 8 40)||return 1

	sudo mkdir -p "$(dirname "$ARQUIVO_PRODUTO")"
	sudo touch "$ARQUIVO_PRODUTO"

	if grep -q "^${codigo};" "$ARQUIVO_PRODUTO" 2>/dev/null; then
		whiptail --title "Erro" --msgbox "Já existe um produto cadastrado com o código '$codigo'." 8 50
		return 1
	fi

	nome=$(interface --title "Cadastro" --inputbox "Nome do produto:" 8 40)||return 1
	categoria=$(interface --title "Cadastro" --inputbox "Categora  do produto:" 8 40)||return 1
	quantidade=$(interface --title "Cadastro" --inputbox "quantidade do produto:" 8 40)||return 1
	preco=$(interface --title "Cadastro" --inputbox "preço do produto:" 8 40)||return 1
	estoque_minimo=$(interface --title "Cadastro" --inputbox "Estoque Mínimo do produto:" 8 40)||return 1

	data_cadastro=$(date +%d/%m/%Y)
	echo "${codigo};${nome};${categoria};${preco};${quantidade};${estoque_minimo};${data_cadastro};${operador_actual}" | sudo tee -a "$ARQUIVO_PRODUTO" > /dev/null
	whiptail --title "Sucesso" --msgbox "Produto '$nome' cadastrado com sucesso!" 8 40
}

listar_produtos() {

    local lista
    sudo touch "$ARQUIVO_PRODUTO"
    lista=$(sudo cut -d";" -f1,2,3,4,5 "$ARQUIVO_PRODUTO" | tr ';' '\t')
    lista=${lista:-"(nenhum produto cadastrado)"}

    whiptail --title "Todos os Produtos (Código / Nome / Categoria / Preço / Qtd)" \
        --msgbox "$lista" 18 65
}

pesquisar_produto()
{
    local termo resultado
    termo=$(interface --title "Pesquisar Produto" --inputbox "Código ou Nome do produto:" 8 45) || return 1

    sudo touch "$ARQUIVO_PRODUTO"
    resultado=$(awk -F';' -v t="$termo" '$1==t || $2==t {printf "%s\t%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,$5,$6}' "$ARQUIVO_PRODUTO")

    if [ -z "$resultado" ]; then
        whiptail --title "Pesquisar Produto" --msgbox "Nenhum produto encontrado para '$termo'." 8 50
        return 1
    fi

    whiptail --title "Resultado da Pesquisa" --msgbox "$resultado" 12 65
}

editar_produto()
{
    local codigo registo nome categoria preco quantidade estoque_minimo

    codigo=$(interface --title "Actualizar Produto" --inputbox "Código do Produto a editar:" 8 45) || return 1

    registo=$(grep "^${codigo};" "$ARQUIVO_PRODUTO") || {
        whiptail --title "Erro" --msgbox "Produto com código '$codigo' não encontrado." 8 50
        return 1
    }

    nome=$(interface --title "Actualizar Produto" --inputbox "Nome:" 8 45 "$(awk -F';' '{print $2}' <<< "$registo")") || return 1
    categoria=$(interface --title "Actualizar Produto" --inputbox "Categoria:" 8 45 "$(awk -F';' '{print $3}' <<< "$registo")") || return 1
    preco=$(interface --title "Actualizar Produto" --inputbox "Preço:" 8 45 "$(awk -F';' '{print $4}' <<< "$registo")") || return 1
    quantidade=$(interface --title "Actualizar Produto" --inputbox "Quantidade:" 8 45 "$(awk -F';' '{print $5}' <<< "$registo")") || return 1
    estoque_minimo=$(interface --title "Actualizar Produto" --inputbox "Estoque Mínimo:" 8 45 "$(awk -F';' '{print $6}' <<< "$registo")") || return 1

    awk -F';' -v OFS=';' -v c="$codigo" -v n="$nome" -v cat="$categoria" -v p="$preco" -v q="$quantidade" -v em="$estoque_minimo" '
        $1==c { $2=n; $3=cat; $4=p; $5=q; $6=em }
        { print }
    ' "$ARQUIVO_PRODUTO" | sudo tee "${ARQUIVO_PRODUTO}.tmp" > /dev/null && sudo mv "${ARQUIVO_PRODUTO}.tmp" "$ARQUIVO_PRODUTO"

    whiptail --title "Sucesso" --msgbox "Produto '$codigo' actualizado com sucesso!" 8 45
}

eliminar_produto()
{
    local codigo registo

    codigo=$(interface --title "Eliminar Produto" --inputbox "Código do Produto a eliminar:" 8 45) || return 1

    registo=$(grep "^${codigo};" "$ARQUIVO_PRODUTO") || {
        whiptail --title "Erro" --msgbox "Produto com código '$codigo' não encontrado." 8 50
        return 1
    }

    whiptail --title "Confirmar Eliminação" --yesno "Eliminar o produto:\n$(tr ';' '\t' <<< "$registo")?" 10 60 || return 1

    awk -F';' -v c="$codigo" '$1!=c' "$ARQUIVO_PRODUTO" | sudo tee "${ARQUIVO_PRODUTO}.tmp" > /dev/null && sudo mv "${ARQUIVO_PRODUTO}.tmp" "$ARQUIVO_PRODUTO"

    whiptail --title "Sucesso" --msgbox "Produto '$codigo' eliminado." 8 45
}

menu_produto()
{
	local operador_actual="$1"
 	local opcao
	while true; do
		opcao=$(interface --title "Gestão de produto" \
				--menu "Escolha uma das opções abaixo" 16 55 6 \
				"1" "Cadastrar Produtos" \
				"2" "Listar Produtos" \
				"3" "Eliminar Produto" \
				"4" "Actualizar Produto" \
				"5" "Pesquisar por produto" \
				"6" "Voltar"\
			) || break
		case $opcao in
		1)
			cadastrar_produto "$operador_actual";;
		2)
			listar_produtos;;
		3)
			eliminar_produto;;
		4)
			editar_produto;;
		5)
			pesquisar_produto;;
		6|*)
			break;;
		esac
	done

}
