#!/bin/bash

ARQUIVO_FUNCIONARIO="/opt/catolica_market/data/funcionarios/funcionarios.txt"
source /opt/catolica_market/lib/funcoes.sh
readonly TITLE="Católica Market — Gestão de Funcionários"

readonly GRUPOS=("cm_atendentes" "Operador de Caixa" "cm_gerentes" "Gerente / Supervisor"
 "cm_logistica" "Estoque e Inventário"
  "cm_admin" "Administrador")

readonly FILIARES=("filiar_luanda" "Luanda" "filiar_huambo" "Huambo"
 "filiar_benguela" "Benguela"
)


# Mensagens de feedback
msg_ok()  { whiptail --title "Sucesso" --msgbox "$1" 8 55; }
msg_err() { whiptail --title "Erro"   --msgbox "$1" 8 55; }

adicionar_funcionario() {
    local usuario grupo senha

    usuario=$(interface --title "Novo Funcionário" \
        --inputbox "Nome de utilizador Linux:" 8 50) || return

    [[ -z "$usuario" ]] && { msg_err "Nome de utilizador não pode estar vazio."; return; }

    grupo=$(interface --title "Perfil / Grupo" \
        --menu "Selecione o grupo do utilizador:" 15 60 4 "${GRUPOS[@]}") || return

    filiar=$(interface --title "Filiar" \
        --menu "Selecione a filiar do utilizador:" 15 60 4 "${FILIARES[@]}") || return
        
    senha=$(interface --title "Password" \
        --passwordbox "Password inicial para '$usuario':" 8 50) || return

    [[ -z "$senha" ]] && { msg_err "A password não pode estar vazia."; return; }
    if ! getent group "$grupo" >/dev/null; then
        sudo groupadd "$grupo"
    fi

    if sudo useradd -m -s /bin/bash -g "$grupo" "$usuario" 2>/dev/null; then
        echo "$usuario:$senha" | sudo chpasswd
        id_gerado=$(id -u "$usuario")
        echo "${id_gerado};${grupo};${usuario};${filiar};${senha}">>"$ARQUIVO_FUNCIONARIO"
        msg_ok "Utilizador '$usuario' criado no grupo '$grupo'."
    else
        msg_err "Falha ao criar '$usuario'. Verifique se já existe."
    fi
}



listar_funcionarios() {
    local grupo membros


    lista=$(sudo cut -d";" -f3,2,4 "$ARQUIVO_FUNCIONARIO" | tr ';' '\t')

    whiptail --title "Todos os Funcionários" \
        --msgbox "$lista" 18 60
}

menu_funcionarios() {
    local opcao
    while true; do
        opcao=$(interface --title "$TITLE" \
            --menu "Escolha uma operação:" 15 60 4 \
            "1" "Adicionar Funcionário" \
            "2" "Remover Funcionário" \
            "3" "Listar por Grupo" \
            "4" "Voltar") || break

        case $opcao in
            1) adicionar_funcionario ;;
            2) listar_funcionarios   ;;
            3) break                 ;;
        esac
    done
}

