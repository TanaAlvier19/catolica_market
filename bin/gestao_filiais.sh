#!/bin/bash

ARQUIVO_Filiais="/opt/catolica_market/data/filiais/filiais.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_filial()
{
    local operador_actual="$1"
    local id nome endereco telefone responsavel data_cadastro estado

    id=$(interface --title "Cadastro de Filial" --inputbox "ID da Filial (ex: 1008):" 8 50) || return 1

    sudo mkdir -p "$(dirname "$ARQUIVO_Filiais")"
    sudo touch "$ARQUIVO_Filiais"

    if grep -q "^${id};" "$ARQUIVO_Filiais" 2>/dev/null; then
        whiptail --title "Erro" --msgbox "Já existe uma filial cadastrada com o ID '$id'." 8 50
        return 1
    fi

    nome=$(interface --title "Cadastro de Filial" --inputbox "Nome (ex: filiar_huambo):" 8 50) || return 1
    endereco=$(interface --title "Cadastro de Filial" --inputbox "Endereço" 8 50) || return 1
    telefone=$(interface --title "Cadastro de Filial" --inputbox "Telefone" 8 50) || return 1
    responsavel=$(interface --title "Cadastro de Filial" --inputbox "Nome do responsavel" 8 50) || return 1

    data_cadastro=$(date +%d/%m/%Y)
    estado="inativo"

    echo "${id};${nome};${endereco};${telefone};${responsavel};pendente;${estado};${data_cadastro}" | sudo tee -a "$ARQUIVO_Filiais" > /dev/null

    whiptail --title "Sucesso" --msgbox "Filial '$nome' cadastrada com sucesso!\nIP: pendente (será definido automaticamente pela rede\nassim que a filial se ligar)\nEstado inicial: inativo\n(passa a activo quando o ADM da filial fizer o primeiro login via setup.sh)" 12 65
}

listar_filiais()
{
    local lista
    sudo touch "$ARQUIVO_Filiais"

    lista=$(awk -F';' '{printf "%s\t%s\t%s\t%s\n",$1,$2,$6,$7}' "$ARQUIVO_Filiais")
    lista=${lista:-"(nenhuma filial cadastrada)"}

    whiptail --title "Todas as Filiais (ID / Nome / IP / Estado)" \
        --msgbox "$lista" 18 65
}

pesquisar_filial()
{
    local termo resultado
    termo=$(interface --title "Pesquisar Filial" --inputbox "ID ou Nome da filial:" 8 50) || return 1

    sudo touch "$ARQUIVO_Filiais"
    resultado=$(awk -F';' -v t="$termo" '$1==t || $2==t {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,$5,$6,$7,$8}' "$ARQUIVO_Filiais")

    if [ -z "$resultado" ]; then
        whiptail --title "Pesquisar Filial" --msgbox "Nenhuma filial encontrada para '$termo'." 8 50
        return 1
    fi

    whiptail --title "Resultado da Pesquisa" --msgbox "$resultado" 12 70
}

editar_filial()
{
    local id registo nome endereco telefone responsavel

    id=$(interface --title "Actualizar Filial" --inputbox "ID da Filial a editar:" 8 50) || return 1

    registo=$(grep "^${id};" "$ARQUIVO_Filiais") || {
        whiptail --title "Erro" --msgbox "Filial com ID '$id' não encontrada." 8 50
        return 1
    }

    nome=$(interface --title "Actualizar Filial" --inputbox "Nome:" 8 50 "$(awk -F';' '{print $2}' <<< "$registo")") || return 1
    endereco=$(interface --title "Actualizar Filial" --inputbox "Endereço:" 8 50 "$(awk -F';' '{print $3}' <<< "$registo")") || return 1
    telefone=$(interface --title "Actualizar Filial" --inputbox "Telefone:" 8 50 "$(awk -F';' '{print $4}' <<< "$registo")") || return 1
    responsavel=$(interface --title "Actualizar Filial" --inputbox "Responsável:" 8 50 "$(awk -F';' '{print $5}' <<< "$registo")") || return 1

    awk -F';' -v OFS=';' -v id="$id" -v n="$nome" -v e="$endereco" -v t="$telefone" -v r="$responsavel" '
        $1==id { $2=n; $3=e; $4=t; $5=r }
        { print }
    ' "$ARQUIVO_Filiais" | sudo tee "${ARQUIVO_Filiais}.tmp" > /dev/null && sudo mv "${ARQUIVO_Filiais}.tmp" "$ARQUIVO_Filiais"

    whiptail --title "Sucesso" --msgbox "Filial '$id' actualizada com sucesso!" 8 50
}

eliminar_filial()
{
    local id registo

    id=$(interface --title "Eliminar Filial" --inputbox "ID da Filial a eliminar:" 8 50) || return 1

    registo=$(grep "^${id};" "$ARQUIVO_Filiais") || {
        whiptail --title "Erro" --msgbox "Filial com ID '$id' não encontrada." 8 50
        return 1
    }

    whiptail --title "Confirmar Eliminação" --yesno "Eliminar a filial:\n$(tr ';' '\t' <<< "$registo")?" 10 60 || return 1

    awk -F';' -v id="$id" '$1!=id' "$ARQUIVO_Filiais" | sudo tee "${ARQUIVO_Filiais}.tmp" > /dev/null && sudo mv "${ARQUIVO_Filiais}.tmp" "$ARQUIVO_Filiais"

    whiptail --title "Sucesso" --msgbox "Filial '$id' eliminada." 8 55
}

alternar_estado_filial()
{
    local id registo estado_actual novo_estado

    id=$(interface --title "Activar/Desactivar Filial" --inputbox "ID da Filial:" 8 50) || return 1

    registo=$(grep "^${id};" "$ARQUIVO_Filiais") || {
        whiptail --title "Erro" --msgbox "Filial com ID '$id' não encontrada." 8 50
        return 1
    }

    estado_actual=$(awk -F';' '{print $7}' <<< "$registo")
    if [ "$estado_actual" = "ativo" ]; then
        novo_estado="inativo"
    else
        novo_estado="ativo"
    fi

    awk -F';' -v OFS=';' -v id="$id" -v est="$novo_estado" '
        $1==id { $7=est }
        { print }
    ' "$ARQUIVO_Filiais" | sudo tee "${ARQUIVO_Filiais}.tmp" > /dev/null && sudo mv "${ARQUIVO_Filiais}.tmp" "$ARQUIVO_Filiais"

    whiptail --title "Sucesso" --msgbox "Estado da filial '$id' alterado para: $novo_estado" 8 55
}

menu_filial()
{
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Gestão de Filiais" \
                --menu "Escolha uma das opções abaixo" 18 55 7 \
                "1" "Cadastrar Filial" \
                "2" "Listar Filiais" \
                "3" "Eliminar Filial" \
                "4" "Actualizar Filial" \
                "5" "Pesquisar por Filial" \
                "6" "Activar/Desactivar Filial" \
                "7" "Voltar" \
            ) || break

        case $opcao in
           1) cadastrar_filial "$operador_actual" ;;
           2) listar_filiais ;;
           3) eliminar_filial ;;
           4) editar_filial ;;
           5) pesquisar_filial ;;
           6) alternar_estado_filial ;;
           7|*) break ;;
        esac
    done
}
