#!/bin/bash

ARQUIVO_VENDAS="../data/vendas/vendas.txt"
ARQUIVO_PRODUTO="../data/produtos/produtos.txt"
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

    lista=$(awk -F';' '{printf "%d)\t%s\t%s\t%s\t%s\t%s AKZ\t%s\n",NR,$1,$2,$4,$5,$6,$7}' "$ARQUIVO_VENDAS")
    lista=${lista:-"(nenhuma venda registrada)"}

    interface --title "Todas as Vendas (Nº / Caixa / Operador / Produto / Qtd / Total / Data)" \
        --msgbox "$lista" 18 75
}

pesquisar_venda()
{
    local termo resultado
    termo=$(interface --title "Pesquisar Venda" --inputbox "Número do Caixa ou Código do Produto:" 8 50) || return 1

    sudo touch "$ARQUIVO_VENDAS"
    resultado=$(awk -F';' -v t="$termo" '$1==t || $4==t {printf "%d)\t%s\t%s\t%s\t%s\t%s AKZ\t%s\n",NR,$1,$2,$4,$5,$6,$7}' "$ARQUIVO_VENDAS")

    if [ -z "$resultado" ]; then
        whiptail --title "Pesquisar Venda" --msgbox "Nenhuma venda encontrada para '$termo'." 8 50
        return 1
    fi

    whiptail --title "Resultado da Pesquisa" --msgbox "$resultado" 14 75
}

editar_venda()
{
    local linha registo produto_id qtd preco_unitario total

    listar_vendas

    linha=$(interface --title "Actualizar Venda" --inputbox "Nº da venda a editar (ver na listagem):" 8 55) || return 1

    registo=$(sed -n "${linha}p" "$ARQUIVO_VENDAS")
    if [ -z "$registo" ]; then
        whiptail --title "Erro" --msgbox "Não existe nenhuma venda com o número '$linha'." 8 50
        return 1
    fi

    produto_id=$(awk -F';' '{print $4}' <<< "$registo")
    preco_unitario=$(buscar_produto "$produto_id")
    if [ -z "$preco_unitario" ]; then
        whiptail --title "Erro" --msgbox "Produto '$produto_id' desta venda já não existe no inventário." 8 55
        return 1
    fi

    qtd=$(interface --title "Actualizar Venda" --inputbox "Nova Quantidade:" 8 45 "$(awk -F';' '{print $5}' <<< "$registo")") || return 1
    total=$(( qtd * preco_unitario ))

    awk -F';' -v OFS=';' -v ln="$linha" -v q="$qtd" -v tot="$total" '
        NR==ln { $5=q; $6=tot }
        { print }
    ' "$ARQUIVO_VENDAS" | sudo tee "${ARQUIVO_VENDAS}.tmp" > /dev/null && sudo mv "${ARQUIVO_VENDAS}.tmp" "$ARQUIVO_VENDAS"

    whiptail --title "Sucesso" --msgbox "Venda nº $linha actualizada!\nNova quantidade: $qtd\nNovo total: $total AKZ" 9 55
}

eliminar_venda()
{
    local linha registo

    listar_vendas

    linha=$(interface --title "Eliminar Venda" --inputbox "Nº da venda a eliminar (ver na listagem):" 8 55) || return 1

    registo=$(sed -n "${linha}p" "$ARQUIVO_VENDAS")
    if [ -z "$registo" ]; then
        whiptail --title "Erro" --msgbox "Não existe nenhuma venda com o número '$linha'." 8 50
        return 1
    fi

    whiptail --title "Confirmar Eliminação" --yesno "Eliminar a venda:\n$(tr ';' '\t' <<< "$registo")?" 10 65 || return 1

    sudo sed -i "${linha}d" "$ARQUIVO_VENDAS"

    whiptail --title "Sucesso" --msgbox "Venda nº $linha eliminada." 8 45
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
           3) eliminar_venda ;;
           4) editar_venda ;;
           5) pesquisar_venda ;;
           6|*) break ;;
        esac
    done
}
