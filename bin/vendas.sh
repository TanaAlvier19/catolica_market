#!/bin/bash
# vendas.sh - Registo de vendas (adaptado à sua estrutura)

# Determinar o diretório base do projecto (assumindo que este script está em $PROJECTO/bin/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Ficheiros de dados
PROD_FILE="$BASE_DIR/data/produtos/produtos.csv"
CLI_FILE="$BASE_DIR/data/clientes/clientes.csv"
VENDAS_FILE="$BASE_DIR/data/vendas/vendas.csv"
ITENS_FILE="$BASE_DIR/data/vendas/itens_venda.csv"

# Função para gerar ID de venda
gerar_id_venda() {
    local ultimo=$(tail -n +2 "$VENDAS_FILE" 2>/dev/null | cut -d'|' -f1 | grep "^VND-" | sed 's/VND-//' | sort -n | tail -1)
    printf "VND-%05d" $((10#${ultimo:-0}+1))
}

echo "***** CAIXA DO SUPERMERCADO *****"
read -p "Número do caixa: " num_caixa
operador=$(whoami)
data=$(date '+%Y-%m-%d')
hora=$(date '+%H:%M:%S')
echo "Operador: $operador  Caixa: $num_caixa  Data: $data"

declare -A carrinho
total_bruto=0

while true; do
    read -p "Código do produto (PRD-xxxxx) ou FIM: " cod
    [[ "$cod" == "FIM" ]] && break
    linha=$(grep "^$cod|" "$PROD_FILE")
    if [ -z "$linha" ]; then
        echo "Produto não encontrado"
        continue
    fi
    IFS='|' read -r c nome cat preco qtd min d <<< "$linha"
    read -p "Quantidade: " qtd_compra
    if [ $qtd_compra -gt $qtd ]; then
        echo "Estoque insuficiente (disp: $qtd)"
        continue
    fi
    subtotal=$(echo "$preco * $qtd_compra" | bc)
    total_bruto=$(echo "$total_bruto + $subtotal" | bc)
    carrinho["$cod"]="$qtd_compra|$nome|$preco|$subtotal"
    echo "Adicionado: $qtd_compra x $nome = $subtotal Kz"
done

[ $total_bruto == 0 ] && echo "Venda vazia" && exit 0

# Cartão de cliente
cartao=""
desconto=0
read -p "Cliente tem cartão? (s/N): " tem
if [[ "$tem" =~ [sS] ]]; then
    read -p "Número do cartão: " cartao
    cli=$(grep "^$cartao|" "$CLI_FILE")
    if [ -n "$cli" ]; then
        saldo=$(echo "$cli" | cut -d'|' -f6)
        if (( $(echo "$saldo >= 5000" | bc -l) )); then
            desconto=10
        elif (( $(echo "$saldo >= 2000" | bc -l) )); then
            desconto=5
        fi
        echo "Desconto de $desconto% aplicado"
    else
        echo "Cartão inválido"
        cartao=""
    fi
fi

total_liquido=$(echo "$total_bruto * (100 - $desconto) / 100" | bc)
echo "Total bruto: $total_bruto Kz"
echo "Total a pagar: $total_liquido Kz"
read -p "Confirmar venda? (s/N): " conf
[[ ! "$conf" =~ [sS] ]] && echo "Cancelada" && exit 0

id_venda=$(gerar_id_venda)
echo "$id_venda|$data|$hora|func_placeholder|$operador|$num_caixa|$cartao|$total_bruto|$desconto|$total_liquido" >> "$VENDAS_FILE"

for cod in "${!carrinho[@]}"; do
    IFS='|' read -r qtd nome preco subtotal <<< "${carrinho[$cod]}"
    echo "$id_venda|$cod|$nome|$qtd|$preco|$subtotal" >> "$ITENS_FILE"
    # Atualizar estoque
    linha_prod=$(grep "^$cod|" "$PROD_FILE")
    qtd_atual=$(echo "$linha_prod" | cut -d'|' -f5)
    nova_qtd=$((qtd_atual - qtd))
    sed -i "s/^$cod|.*/$(echo "$linha_prod" | awk -F'|' -v nq=$nova_qtd 'BEGIN{OFS="|"} {$5=nq; print}')/" "$PROD_FILE"
done

echo "Venda registada com sucesso. Recibo:"
echo "-----------------------------------"
echo "Católica Market - $data $hora  Caixa $num_caixa"
for cod in "${!carrinho[@]}"; do
    IFS='|' read -r qtd nome preco subtotal <<< "${carrinho[$cod]}"
    echo "$qtd x $nome = $subtotal Kz"
done
echo "Total: $total_liquido Kz"
echo "-----------------------------------"