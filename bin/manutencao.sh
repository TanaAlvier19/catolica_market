#!/bin/bash

DATA_DIR="/opt/catolica_market/data"
LOG_DIR="/opt/catolica_market/data/logs"
BACKUP_DIR="/home/labex/project/backup"
RELATORIOS_DIR="/opt/catolica_market/data/relatorios"

source /opt/catolica_market/lib/funcoes.sh

# Limpeza de logs antigos 
limpar_logs_antigos() 
{
    local dias removidos

    dias=$(interface --title "Limpeza de Logs" \
        --inputbox "Remover logs com mais de quantos dias?" 8 50) || return 1

    sudo mkdir -p "$LOG_DIR"
    removidos=$(sudo find "$LOG_DIR" -type f -name "*.log" -mtime +"$dias" -print -delete 2>/dev/null | wc -l)

    whiptail --title "Limpeza de Logs" \
        --msgbox "Operação concluída.\nFicheiros de log removidos: $removidos" 8 50
}

# Limpeza de backups antigos 
limpar_backups_antigos() {
    local dias removidos

    dias=$(interface --title "Limpeza de Backups" \
        --inputbox "Remover backups com mais de quantos dias?" 8 50) || return 1

    sudo mkdir -p "$BACKUP_DIR"
    removidos=$(sudo find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +"$dias" -print -delete 2>/dev/null | wc -l)

    whiptail --title "Limpeza de Backups" \
        --msgbox "Operação concluída.\nBackups removidos: $removidos" 8 50
}

# Limpeza de ficheiros temporários gerados pelo sistema
limpar_temporarios() 
{
    local removidos

    removidos=$(sudo find "$DATA_DIR" -type f -name "*.tmp" -print -delete 2>/dev/null | wc -l)

    whiptail --title "Limpeza de Temporários" \
        --msgbox "Ficheiros temporários removidos: $removidos" 8 50
}

# Verifica a integridade dos ficheiros de dados essenciais
verificar_integridade() 
{
    local arquivos=(
        "$DATA_DIR/clientes/clientes.txt"
        "$DATA_DIR/produtos/produtos.txt"
        "$DATA_DIR/funcionarios/funcionarios.txt"
        "$DATA_DIR/vendas/vendas.txt"
    )
    local resultado=""
    local arq

    for arq in "${arquivos[@]}"; do
        if sudo test -f "$arq"; then
            resultado+="OK\t$arq\n"
        else
            resultado+="FALTA\t$arq\n"
        fi
    done

    whiptail --title "Verificação de Integridade" \
        --msgbox "$(echo -e "$resultado")" 14 65
}

verificar_espaco_disco() {
    local info

    info=$(df -h / "$DATA_DIR" 2>/dev/null)

    whiptail --title "Espaço em Disco" \
        --msgbox "$info" 14 70
}

auditoria_seguranca() 
{
    local info

    info=$(sudo find "$DATA_DIR" -type f \( -name "*.txt" -o -name "*.json" \) -exec ls -l {} \; 2>/dev/null)
    info=${info:-"Nenhum ficheiro encontrado."}

    whiptail --title "Auditoria de Segurança - Permissões" \
        --msgbox "$info" 18 70
}

menu_manutencao() 
{
    local opcao

    while true; do
        opcao=$(interface --title "Manutenção do Sistema" \
                --menu "Escolha uma operação de manutenção" 18 60 7 \
                "1" "Limpar Logs Antigos" \
                "2" "Limpar Backups Antigos" \
                "3" "Limpar Ficheiros Temporários" \
                "4" "Verificar Integridade dos Dados" \
                "5" "Verificar Espaço em Disco" \
                "6" "Executar Backup Manual" \
                "7" "Auditoria de Segurança" \
                "8" "Voltar") || break

        case $opcao in
           1) limpar_logs_antigos ;;
           2) limpar_backups_antigos ;;
           3) limpar_temporarios ;;
           4) verificar_integridade ;;
           5) verificar_espaco_disco ;;
           6) executar_backup_manual ;;
           7) auditoria_seguranca ;;
           8) break ;;
        esac
    done
}
menu_manutencao