#!/bin/bash

ARQUIVO_VENDAS="/opt/catolica_market/data/vendas/vendas.txt"
ARQUIVO_PRODUTO="/opt/catolica_market/data/produtos/produtos.txt"
source /opt/catolica_market/lib/funcoes.sh

CARTAO_CLIENTE=""

tipo_de_cliente()
{
    local opcao
    CARTAO_CLIENTE="NORMAL"

    opcao=$(interface --title "Escolha o tipo de cliente" \
            --menu "Selecione o metodo de pagamento:" 15 50 5 \
            "1" "Sem Cartão" \
            "2" "Com Cartão") || return 1

    if [ "$opcao" = "2" ]; then
        CARTAO_CLIENTE=$(interface --title "Cartão de Fidelidade" \
            --inputbox "Introduza o número de cartão do cliente VIP:" 8 45) || return 1
    fi
} 

buscar_produto()
{
    local produto="$1"
    local registro preco


    registro=$(grep "^${produto};" "$ARQUIVO_PRODUTO") || return 1
    preco=$(awk -F';' '{print $4}' <<< "$registro")
    
    echo "$preco" | xargs
}

adicionar_vendas()
{
    local operador_actual="$1"
    local numero_caixa produto_id qtd preco_unitario 
    local total valor_em_akz troco_final desconto_aplicado data_cadastro

    numero_caixa=$(interface --title "Registro de Vendas" --inputbox "Número do Caixa:" 8 40) || return 1
    
    produto_id=$(interface --title "Registro de Vendas" --inputbox "Código do Produto:" 8 45) || return 1
    
    preco_unitario=$(buscar_produto "$produto_id")
    if [ -z "$preco_unitario" ]; then
        interface --title "Erro" --msgbox "Produto não encontrado no inventário!" 8 45
        return 1
    fi

    qtd=$(interface --title "Registro de Vendas" --inputbox "Quantidade:" 8 40) || return 1
    tipo_de_cliente || return 1
    total=$(( qtd * preco_unitario ))
    desconto_aplicado=0

    if [ "$CARTAO_CLIENTE" != "NORMAL" ]; then
        desconto_aplicado=$(( total * 10 / 100 ))
        total=$(( total - desconto_aplicado ))
        interface --title "Desconto VIP" --msgbox "Cliente VIP detetado!\nDesconto de 10% 
                          aplicado: $desconto_aplicado AKZ\nNovo Total: $total AKZ" 9 45
    fi

    valor_em_akz=$(interface --title "Registro de Vendas" --inputbox "Total a pagar: $total AKZ\nIntroduza o valor entregue pelo cliente (AKZ):" 9 50) || return 1
    if [ "$CARTAO_CLIENTE" = "NORMAL" ]; then

        troco_final=$(( valor_em_akz - total ))
        if [ "$troco_final" -lt 0 ]; then
            interface --title "Erro" --msgbox "Dinheiro insuficiente! Faltam $(( total - valor_em_akz )) AKZ." 8 45
            return 1
        fi

        if [ "$troco_final" -gt 0 ]; then
            interface --title "Troco" --msgbox "Troco a devolver: $troco_final AKZ" 8 40
        fi
    fi
    
    data_cadastro=$(date +%d/%m/%Y)

    sudo mkdir -p "$(dirname "$ARQUIVO_VENDAS")"
    sudo touch "$ARQUIVO_VENDAS"

    echo "${numero_caixa};${operador_actual};${CARTAO_CLIENTE};${produto_id};${qtd};${total};${data_cadastro}" | sudo tee -a "$ARQUIVO_VENDAS" > /dev/null

    interface --title "Sucesso" --msgbox "Venda registrada com sucesso!\nTotal final: $total AKZ" 8 45
}

listar_vendas()
{
    local lista
    sudo touch "$ARQUIVO_VENDAS"
    
    lista=$(sudo cut -d";" -f2,3,4,5,6,7 "$ARQUIVO_VENDAS" | tr ';' '\t')
    lista=${lista:-"(nenhuma venda registrada)"}

    interface --title "Todas as Vendas" \
        --msgbox "$lista" 18 70
}

menu_vendas()
{
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Gestão de Vendas" \
                --menu "Escolha uma das opções abaixo" 16 55 6 \
                "1" "Registrar uma Venda" \
                "2" "Listar Vendas Realizadas" \
                "3" "Eliminar Registro de Venda" \
                "4" "Actualizar Venda" \
                "5" "Pesquisar por Venda" \
                "6" "Voltar") || break

        case $opcao in
           1) adicionar_vendas "$operador_actual" ;;
           2) listar_vendas ;;
           6) break ;;
        esac
    done
}
