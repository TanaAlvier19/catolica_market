#!/bin/bash

ARQUIVO_FUNCIONARIOS="../data/funcionarios/funcionarios.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_funcionario()
{
    local operador_actual="$1"
    local id nome cargo grupo utilizador_linux senha filial data_cadastro

    id=$(interface --title "Cadastro de Funcionário" --inputbox "ID do Funcionário (ex: 1008):" 8 50) || return 1

    sudo mkdir -p "$(dirname "$ARQUIVO_FUNCIONARIOS")"
    sudo touch "$ARQUIVO_FUNCIONARIOS"

    if grep -q "^${id};" "$ARQUIVO_FUNCIONARIOS" 2>/dev/null; then
        whiptail --title "Erro" --msgbox "Já existe um funcionário cadastrado com o ID '$id'." 8 50
        return 1
    fi

    nome=$(interface --title "Cadastro de Funcionário" --inputbox "Nome Completo:" 8 50) || return 1
    grupo=$(interface --title "Cadastro de Funcionário" --inputbox "Grupo de Sistema (ex: cm_atendentes, cm_admin):" 8 50) || return 1
    filial=$(interface --title "Cadastro de Funcionário" --inputbox "Filial (ex: filiar_luanda, ou 'central'):" 8 50) || return 1
    senha=$(interface --title "Cadastro de Funcionário" --passwordbox "Senha de Acesso:" 8 50) || return 1

    data_cadastro=$(date +%d/%m/%Y)

    echo "${id};${grupo};${nome};${filial};${senha}" | sudo tee -a "$ARQUIVO_FUNCIONARIOS" > /dev/null

    whiptail --title "Sucesso" --msgbox "Funcionário '$nome' cadastrado com sucesso!" 8 50
}

listar_funcionarios()
{
    local lista
    sudo touch "$ARQUIVO_FUNCIONARIOS"

    lista=$(awk -F';' '{printf "%s\t%s\t%s\t%s\n",$1,$3,$2,$4}' "$ARQUIVO_FUNCIONARIOS")
    lista=${lista:-"(nenhum funcionário cadastrado)"}

    whiptail --title "Todos os Funcionários (ID / Nome / Grupo / Filial)" \
        --msgbox "$lista" 18 65
}

pesquisar_funcionario()
{
    local termo resultado
    termo=$(interface --title "Pesquisar Funcionário" --inputbox "ID ou Nome do funcionário:" 8 50) || return 1

    sudo touch "$ARQUIVO_FUNCIONARIOS"
    resultado=$(awk -F';' -v t="$termo" '$1==t || $3==t {printf "%s\t%s\t%s\t%s\n",$1,$3,$2,$4}' "$ARQUIVO_FUNCIONARIOS")

    if [ -z "$resultado" ]; then
        whiptail --title "Pesquisar Funcionário" --msgbox "Nenhum funcionário encontrado para '$termo'." 8 50
        return 1
    fi

    whiptail --title "Resultado da Pesquisa" --msgbox "$resultado" 12 65
}

editar_funcionario()
{
    local id registo nome grupo filial senha

    id=$(interface --title "Actualizar Funcionário" --inputbox "ID do Funcionário a editar:" 8 50) || return 1

    registo=$(grep "^${id};" "$ARQUIVO_FUNCIONARIOS") || {
        whiptail --title "Erro" --msgbox "Funcionário com ID '$id' não encontrado." 8 50
        return 1
    }

    grupo=$(interface --title "Actualizar Funcionário" --inputbox "Grupo:" 8 50 "$(awk -F';' '{print $2}' <<< "$registo")") || return 1
    nome=$(interface --title "Actualizar Funcionário" --inputbox "Nome:" 8 50 "$(awk -F';' '{print $3}' <<< "$registo")") || return 1
    filial=$(interface --title "Actualizar Funcionário" --inputbox "Filial:" 8 50 "$(awk -F';' '{print $4}' <<< "$registo")") || return 1
    senha=$(interface --title "Actualizar Funcionário" --passwordbox "Nova Senha (deixe como está se não quiser mudar):" 8 50 "$(awk -F';' '{print $5}' <<< "$registo")") || return 1

    awk -F';' -v OFS=';' -v id="$id" -v g="$grupo" -v n="$nome" -v f="$filial" -v s="$senha" '
        $1==id { $2=g; $3=n; $4=f; $5=s }
        { print }
    ' "$ARQUIVO_FUNCIONARIOS" | sudo tee "${ARQUIVO_FUNCIONARIOS}.tmp" > /dev/null && sudo mv "${ARQUIVO_FUNCIONARIOS}.tmp" "$ARQUIVO_FUNCIONARIOS"

    whiptail --title "Sucesso" --msgbox "Funcionário '$id' actualizado com sucesso!" 8 50
}

eliminar_funcionario()
{
    local id registo

    id=$(interface --title "Eliminar Funcionário" --inputbox "ID do Funcionário a eliminar:" 8 50) || return 1

    registo=$(grep "^${id};" "$ARQUIVO_FUNCIONARIOS") || {
        whiptail --title "Erro" --msgbox "Funcionário com ID '$id' não encontrado." 8 50
        return 1
    }

    whiptail --title "Confirmar Eliminação" --yesno "Eliminar o funcionário:\n$(awk -F';' '{printf "%s\t%s\t%s\t%s",$1,$3,$2,$4}' <<< "$registo")?" 10 60 || return 1

    awk -F';' -v id="$id" '$1!=id' "$ARQUIVO_FUNCIONARIOS" | sudo tee "${ARQUIVO_FUNCIONARIOS}.tmp" > /dev/null && sudo mv "${ARQUIVO_FUNCIONARIOS}.tmp" "$ARQUIVO_FUNCIONARIOS"

    whiptail --title "Sucesso" --msgbox "Funcionário '$id' eliminado." 8 50
}

menu_funcionario()
{
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Gestão de Funcionários" \
                --menu "Escolha uma das opções abaixo" 16 55 6 \
                "1" "Cadastrar Funcionário" \
                "2" "Listar Funcionários" \
                "3" "Eliminar Funcionário" \
                "4" "Actualizar Funcionário" \
                "5" "Pesquisar por Funcionário" \
                "6" "Voltar" \
            ) || break

        case $opcao in
           1) cadastrar_funcionario "$operador_actual" ;;
           2) listar_funcionarios ;;
           3) eliminar_funcionario ;;
           4) editar_funcionario ;;
           5) pesquisar_funcionario ;;
           6|*) break ;;
        esac
    done
}
