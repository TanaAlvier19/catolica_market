ARQUIVO_Filiais="/opt/catolica_market/data/filiais/filiais.txt"
source /opt/catolica_market/lib/funcoes.sh

cadastrar_filial()
{
    local operador_actual="$1"
    local id nome endereco telefone responsavel ip data_cadastro estado

    id=$(interface --title "Cadastro de Filial" --inputbox "ID da Filial (ex: 1008):" 8 50) || return 1
    nome=$(interface --title "Cadastro de Filial" --inputbox "Nome :" 8 50) || return 1
    endereco=$(interface --title "Cadastro de Filial" --inputbox "Endereço" 8 50) || return 1
    telefone=$(interface --title "Cadastro de Filial" --inputbox "Telefone" 8 50) || return 1
    responsavel=$(interface --title "Cadastro de Filial" --inputbox "Nome do responsavel" 8 50) || return 1

    ip=$(obter_ip_disponivel "$nome")

    if [ -z "$ip" ]; then
        whiptail --title "Erro" --msgbox "Não existem IPs disponíveis." 8 50
        return 1
    fi

    data_cadastro=$(date +%d/%m/%Y)
    estado="inativo"

    sudo mkdir -p "$(dirname "$ARQUIVO_Filiais")"
    sudo touch "$ARQUIVO_Filiais"

    echo "${id};${nome};${endereco};${telefone};${responsavel};${ip};${estado};${data_cadastro};" | sudo tee -a "$ARQUIVO_Filiais" > /dev/null

    whiptail --title "Sucesso" --msgbox "Filial '$nome' cadastrada com sucesso!\nIP atribuído: $ip" 8 60
}

menu_funcionario()
{
    local operador_actual="$1"
    local opcao

    while true; do
        opcao=$(interface --title "Gestão de Funcionários" \
                --menu "Escolha uma das opções abaixo" 16 50 6 \
                "1" "Cadastrar Funcionário" \
                "2" "Listar Funcionários" \
                "3" "Eliminar Funcionário" \
                "4" "Actualizar Funcionário" \
                "5" "Pesquisar por Funcionário" \
                "6" "Voltar" \
            ) || break

        case $opcao in
           1)
               cadastrar_filial "$operador_actual" ;;
           6|*) 
               break ;;
        esac
    done
}


obter_ip_disponivel() {
ARQUIVO_IPS="/opt/catolica_market/data/ips/ips.txt"
    local filial="$1"

    local ip
    ip=$(awk -F';' '$2=="disponivel" { print $1; exit }' "$ARQUIVO_IPS")

    [ -z "$ip" ] && return 1

    awk -F';' -v OFS=';' -v ip="$ip" -v filial="$filial" '
        $1==ip && $2=="disponivel" {
            $2="indisponivel"
            $3=filial
        }
        { print }
    ' "$ARQUIVO_IPS" > "${ARQUIVO_IPS}.tmp" &&
    mv "${ARQUIVO_IPS}.tmp" "$ARQUIVO_IPS"

    echo "$ip"
}
