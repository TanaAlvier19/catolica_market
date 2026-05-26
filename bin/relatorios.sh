#!/bin/bash
# relatorios.sh - Geração de relatórios

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

VENDAS_FILE="$BASE_DIR/data/vendas/vendas.csv"
PROD_FILE="$BASE_DIR/data/produtos/produtos.csv"

echo "--- Relatórios ---"
echo "1) Vendas do dia"
echo "2) Fecho de caixa (por data e número)"
echo "3) Estoque crítico"
read -p "Opção: " opt

case $opt in
    1)
        hoje=$(date '+%Y-%m-%d')
        total=$(grep "|$hoje|" "$VENDAS_FILE" | awk -F'|' '{sum+=$10} END {print sum}')
        echo "Total vendido hoje: ${total:-0} Kz"
        ;;
    2)
        read -p "Número do caixa: " caixa
        read -p "Data (AAAA-MM-DD): " dt
        total_cx=$(grep "|$dt|.*|$caixa|" "$VENDAS_FILE" | awk -F'|' '{sum+=$10} END {print sum}')
        echo "Total do caixa $caixa em $dt: ${total_cx:-0} Kz"
        ;;
    3)
        echo "Produtos abaixo do estoque mínimo:"
        tail -n +2 "$PROD_FILE" | awk -F'|' '$5 < $6 {print $1, $2, "Estoque:", $5, "Mínimo:", $6}'
        ;;
    *)
        echo "Opção inválida"
        ;;
esac