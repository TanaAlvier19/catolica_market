#!/bin/bash

ARQUIVO_VENDAS="/opt/catolica_market/data/vendas/vendas.txt"
ARQUIVO_PRODUTO="/opt/catolica_market/data/produtos/produtos.txt"
ARQUIVO_CLIENTES="/opt/catolica_market/data/clientes/clientes.txt"
ARQUIVO_FUNCIONARIOS="/opt/catolica_market/data/funcionarios/funcionarios.txt"
RELATORIOS_DIR="/opt/catolica_market/data/relatorios"

source /opt/catolica_market/lib/funcoes.sh

# Garante que o diretório de relatórios existe
sudo mkdir -p "$RELATORIOS_DIR" 2>/dev/null

relatorio_vendas_diario() {
    local data hoje total_dia qtd_vendas lista

    hoje=$(date +%d/%m/%Y)
    sudo touch "$ARQUIVO_VENDAS"

    lista=$(grep ";${hoje}$" "$ARQUIVO_VENDAS" 2>/dev/null)

    if [ -z "$lista" ]; then
        whiptail --title "Relatório de Vendas Diário" \
            --msgbox "Não foram registadas vendas no dia $hoje." 8 50
        return
    fi

    qtd_vendas=$(echo "$lista" | wc -l)
    total_dia=$(echo "$lista" | awk -F';' '{soma+=$6} END {print soma}')

    whiptail --title "Relatório de Vendas Diário ($hoje)" \
        --msgbox "Total de vendas: $qtd_vendas\nValor total faturado: ${total_dia:-0} AKZ" 10 50

    echo "$lista" | tr ';' '\t' | sudo tee "$RELATORIOS_DIR/vendas_${hoje//\//-}.txt" > /dev/null
}

relatorio_vendas_por_operador() {
    local operador relatorio total_op qtd_op

    operador=$(interface --title "Relatório por Operador" --inputbox "ID do Caixa/Operador:" 8 45) || return 1

    sudo touch "$ARQUIVO_VENDAS"
    relatorio=$(awk -F';' -v op="$operador" '$2==op' "$ARQUIVO_VENDAS")

    if [ -z "$relatorio" ]; then
        whiptail --title "Relatório por Operador" \
            --msgbox "Nenhuma venda encontrada para o operador '$operador'." 8 50
        return
    fi

    qtd_op=$(echo "$relatorio" | wc -l)
    total_op=$(echo "$relatorio" | awk -F';' '{soma+=$6} END {print soma}')

    whiptail --title "Relatório do Operador $operador" \
        --msgbox "Vendas realizadas: $qtd_op\nTotal arrecadado: ${total_op:-0} AKZ" 10 50
}

relatorio_fecho_caixa() {
    local numero_caixa relatorio total_caixa qtd_caixa data_relatorio arquivo_saida

    numero_caixa=$(interface --title "Fecho de Caixa" --inputbox "Número do Caixa:" 8 45) || return 1

    sudo touch "$ARQUIVO_VENDAS"
    relatorio=$(awk -F';' -v cx="$numero_caixa" '$1==cx' "$ARQUIVO_VENDAS")

    if [ -z "$relatorio" ]; then
        whiptail --title "Fecho de Caixa" \
            --msgbox "Nenhum registo encontrado para o caixa $numero_caixa." 8 50
        return
    fi

    qtd_caixa=$(echo "$relatorio" | wc -l)
    total_caixa=$(echo "$relatorio" | awk -F';' '{soma+=$6} END {print soma}')
    data_relatorio=$(date +%d-%m-%Y_%H%M)
    arquivo_saida="$RELATORIOS_DIR/fecho_caixa_${numero_caixa}_${data_relatorio}.txt"

    {
        echo "Fecho de Caixa - Caixa $numero_caixa"
        echo "Data: $(date +%d/%m/%Y\ %H:%M)"
        echo "Número de transações: $qtd_caixa"
        echo "Total arrecadado: ${total_caixa:-0} AKZ"
        echo "----------------------------------------"
        echo "$relatorio" | tr ';' '\t'
    } | sudo tee "$arquivo_saida" > /dev/null

    whiptail --title "Fecho de Caixa - Caixa $numero_caixa" \
        --msgbox "Transações: $qtd_caixa\nTotal arrecadado: ${total_caixa:-0} AKZ\n\nRelatório guardado em:\n$arquivo_saida" 12 60
}

relatorio_stock_baixo() {
    local lista

    sudo touch "$ARQUIVO_PRODUTO"
    lista=$(awk -F';' '$5 < $6 {printf "%s\t%s\tQtd:%s\tMin:%s\n", $1, $2, $5, $6}' "$ARQUIVO_PRODUTO")

    if [ -z "$lista" ]; then
        whiptail --title "Relatório de Stock" \
            --msgbox "Nenhum produto está abaixo do estoque mínimo." 8 50
        return
    fi

    whiptail --title "Produtos com Stock Baixo" \
        --msgbox "$lista" 18 65
}

relatorio_clientes_cadastrados() {
    local total

    sudo touch "$ARQUIVO_CLIENTES"
    total=$(wc -l < "$ARQUIVO_CLIENTES")

    whiptail --title "Relatório de Clientes" \
        --msgbox "Total de clientes com cartão de fidelidade: $total" 8 50
}

relatorio_auditoria_funcionarios() {
    local lista

    sudo touch "$ARQUIVO_FUNCIONARIOS"
    lista=$(sudo cut -d";" -f1,3,7,9 "$ARQUIVO_FUNCIONARIOS" | tr ';' '\t')
    lista=${lista:-"(nenhum funcionário cadastrado)"}

    whiptail --title "Auditoria de Funcionários (ID / Nome / Cargo / Cadastrado por)" \
        --msgbox "$lista" 18 70
}

menu_relatorios() {
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Relatórios Gerenciais" \
                --menu "Escolha um relatório" 18 60 7 \
                "1" "Vendas do Dia" \
                "2" "Vendas por Operador" \
                "3" "Fecho de Caixa por Operador" \
                "4" "Produtos com Stock Baixo" \
                "5" "Clientes Cadastrados" \
                "6" "Auditoria de Funcionários" \
                "7" "Voltar") || break

        case $opcao in
           1) relatorio_vendas_diario ;;
           2) relatorio_vendas_por_operador ;;
           3) relatorio_fecho_caixa ;;
           4) relatorio_stock_baixo ;;
           5) relatorio_clientes_cadastrados ;;
           6) relatorio_auditoria_funcionarios ;;
           7) break ;;
        esac
    done
}
menu_relatorios