#!/bin/bash

# Agenda a execução diária (às 18h) de um script de manutenção
confCron()
{
    local script_path="$1"
    local cronConf="0 18 * * * $script_path"

    echo "A adicionar ao cron: $cronConf"
    (crontab -l 2>/dev/null | grep -Fv "$script_path"; echo "$cronConf") | crontab -
    echo "Código de retorno: $?"
}

# Agenda a actualização do IP da filial a cada 2 minutos.
confCronIP()
{
    local script_path="$1"
    local log="../data/logs/ip_update.log"
    local cronConf="*/2 * * * * $script_path >> $log 2>&1"

    (crontab -l 2>/dev/null | grep -Fv "$script_path"; echo "$cronConf") | crontab -
    echo "Cron de actualização de IP configurado (a cada 2 minutos)."
}
