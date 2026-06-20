#!/bin/bash
source /opt/catolica_market/lib/funcoes.sh
source /opt/catolica_market/bin/gestao_funcionarios.sh
source /opt/catolica_market/bin/gestao_produtos.sh
source /opt/catolica_market/bin/gestao_clientes.sh
source /opt/catolica_market/bin/vendas.sh

menu_atendente()
{
    local operador="$1"
 	local opcao
	opcao=$(interface --title "CATÓLICA MARKET  MENU PRINICIPAL" \
        	--menu "Escolha uma das opções abaixo" 15 50 5 \
        	"1" "Registrar Venda ou Abrir o caixa" \
        	"2" "Consultar Cliente ou Cartão de Fidelidade" \
        	)
    case $opcao in
        1) menu_vendas "$operador" ;;
        2) menu_cliente "$operador" ;;
    esac

}

menu_logistica()
{
    local operador="$1"
 	local opcao
	opcao=$(interface --title "CATÓLICA MARKET  MENU PRINICIPAL" \
        	--menu "Escolha uma das opções abaixo" 15 50 5 \
        	"1" "Consultar Stock de Produtos" \
        	"2" "Actualizar Inventário" \
        	)
    case $opcao in
        1) menu_produto "$operador" ;;
        2) menu_inventario "$operador" ;;
    esac
}

menu_gerentes()
{
    local operador="$1"
 	local opcao
	opcao=$(interface --title "CATÓLICA MARKET  MENU PRINICIPAL" \
        	--menu "Escolha uma das opções abaixo" 15 50 5 \
        	"1" "Módulo de Vendas" \
        	"2" "Gestão de Stock" \
            "3" "Clientes" \
        	"4" "Relatórios Gerenciais e Fecho de Caixa" \
        	"5" "Executar Auditoria de Segurança" \
        	)
    case $opcao in
        1) menu_vendas "$operador" ;;
        2) menu_produto "$operador" ;;
        3) menu_cliente "$operador" ;;
    esac
}

menu_admin()
{
 	local opcao
	opcao=$(interface --title "CATÓLICA MARKET  MENU PRINICIPAL" \
        	--menu "Escolha uma das opções abaixo" 15 50 5 \
        	"1" "Menu Operacional" \
        	"2" "Menu de Gerencia" \
        	"3" "Backups" \
        	"4" "Manutenção" \
        	)
            case $opcao in
                1) menu_atendente "$operador";;
                2) menu_gerentes "$operador" ;;
                3) menu_produto "$operador" ;;
                4) menu_cliente "$operador" ;;
            esac
}

menu_principal()
{
    local grupo="$1"
    local operador="$2"

    case $grupo in
       cm_atendentes)
            menu_atendente "$operador" ;;
       cm_logistica)
            menu_logistica "$operador" ;;
       cm_gerentes)
            menu_gerentes "$operador" ;;
       cm_admin)
            menu_admin "$operador" ;;
    esac 
}

menu_principal