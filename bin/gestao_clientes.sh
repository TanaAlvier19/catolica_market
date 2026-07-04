#!/bin/bash

ARQUIVO_CLIENTES="../data/clientes/clientes.txt"
source /opt/catolica_market/lib/funcoes.sh

# Estrutura do registo: numero_cartao;nome;nif;saldo;data_cadastro

adicionar_cliente() {
    local numero_cartao nome nif saldo data_cadastro

    numero_cartao=$(interface --title "Cadastro de cliente" --inputbox "Número de Cartão:" 8 40) || return 1

    sudo mkdir -p "$(dirname "$ARQUIVO_CLIENTES")"
    sudo touch "$ARQUIVO_CLIENTES"

    if grep -q "^${numero_cartao};" "$ARQUIVO_CLIENTES" 2>/dev/null; then
        whiptail --title "Erro" --msgbox "Já existe um cliente cadastrado com o cartão '$numero_cartao'." 8 55
        return 1
    fi

    nome=$(interface --title "Cadastro de cliente" --inputbox "Nome do Cliente:" 8 40) || return 1
    nif=$(interface --title "Cadastro de cliente" --inputbox "NIF do Cliente:" 8 40) || return 1
    saldo=$(interface --title "Cadastro de cliente" --inputbox "Introduza o saldo do cliente:" 8 40) || return 1
    data_cadastro=$(date +%d/%m/%Y)

    echo "${numero_cartao};${nome};${nif};${saldo};${data_cadastro}" | sudo tee -a "$ARQUIVO_CLIENTES" > /dev/null

    whiptail --title "Sucesso" --msgbox "Cliente '$nome' cadastrado com sucesso!" 8 40
}

listar_clientes() {
    local lista
    sudo touch "$ARQUIVO_CLIENTES"
    lista=$(sudo cut -d";" -f1,2,3,4 "$ARQUIVO_CLIENTES" | tr ';' '\t')
    lista=${lista:-"(nenhum cliente cadastrado)"}

    whiptail --title "Todos os Clientes (Cartão / Nome / NIF / Saldo)" \
        --msgbox "$lista" 18 65
}

pesquisar_cliente() {
    local termo resultado
    termo=$(interface --title "Pesquisar Cliente" --inputbox "Número de Cartão ou Nome:" 8 45) || return 1

    sudo touch "$ARQUIVO_CLIENTES"
    resultado=$(awk -F';' -v t="$termo" '$1==t || $2==t {printf "%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,$5}' "$ARQUIVO_CLIENTES")

    if [ -z "$resultado" ]; then
        whiptail --title "Pesquisar Cliente" --msgbox "Nenhum cliente encontrado para '$termo'." 8 50
        return 1
    fi

    whiptail --title "Resultado da Pesquisa" --msgbox "$resultado" 12 65
}

editar_cliente() {
    local numero_cartao registo nome nif saldo

    numero_cartao=$(interface --title "Actualizar Cliente" --inputbox "Número de Cartão do cliente a editar:" 8 50) || return 1

    registo=$(grep "^${numero_cartao};" "$ARQUIVO_CLIENTES") || {
        whiptail --title "Erro" --msgbox "Cliente com cartão '$numero_cartao' não encontrado." 8 55
        return 1
    }

    nome=$(interface --title "Actualizar Cliente" --inputbox "Nome:" 8 45 "$(awk -F';' '{print $2}' <<< "$registo")") || return 1
    nif=$(interface --title "Actualizar Cliente" --inputbox "NIF:" 8 45 "$(awk -F';' '{print $3}' <<< "$registo")") || return 1
    saldo=$(interface --title "Actualizar Cliente" --inputbox "Saldo:" 8 45 "$(awk -F';' '{print $4}' <<< "$registo")") || return 1

    awk -F';' -v OFS=';' -v c="$numero_cartao" -v n="$nome" -v nf="$nif" -v s="$saldo" '
        $1==c { $2=n; $3=nf; $4=s }
        { print }
    ' "$ARQUIVO_CLIENTES" | sudo tee "${ARQUIVO_CLIENTES}.tmp" > /dev/null && sudo mv "${ARQUIVO_CLIENTES}.tmp" "$ARQUIVO_CLIENTES"

    whiptail --title "Sucesso" --msgbox "Cliente '$numero_cartao' actualizado com sucesso!" 8 50
}

eliminar_cliente() {
    local numero_cartao registo

    numero_cartao=$(interface --title "Eliminar Cliente" --inputbox "Número de Cartão do cliente a eliminar:" 8 50) || return 1

    registo=$(grep "^${numero_cartao};" "$ARQUIVO_CLIENTES") || {
        whiptail --title "Erro" --msgbox "Cliente com cartão '$numero_cartao' não encontrado." 8 55
        return 1
    }

    whiptail --title "Confirmar Eliminação" --yesno "Eliminar o cliente:\n$(tr ';' '\t' <<< "$registo")?" 10 60 || return 1

    awk -F';' -v c="$numero_cartao" '$1!=c' "$ARQUIVO_CLIENTES" | sudo tee "${ARQUIVO_CLIENTES}.tmp" > /dev/null && sudo mv "${ARQUIVO_CLIENTES}.tmp" "$ARQUIVO_CLIENTES"

    whiptail --title "Sucesso" --msgbox "Cliente '$numero_cartao' eliminado." 8 50
}

menu_cliente() {
    local operador_actual="$1"
    local opcao

	while true; do
		opcao=$(interface --title "Gestão de Clientes" \
				--menu "Escolha uma das opções abaixo" 16 55 6 \
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
			3)
				eliminar_cliente ;;
			4)
				editar_cliente ;;
			5)
				pesquisar_cliente ;;
			6|*)
				break ;;
		esac
	done
}
