#!/bin/bash
backup_source="../data/"

backup_dest="/mnt/backup"

data_log=$(date +%Y-%m-%d-%H:%M:%S )
data=$(date +%Y-%m-%d--%H-%M-%S)
nome_arq="backup-$data.tar.gz"
backup_log="/opt/catolica_market/data/logs/log.log"

if ! mountpoint -q -- $backup_dest; then
	printf "$data_log Dispositivo não montado\n" >> $backup_log
	exit 1
else	
	if tar -czSpf "$backup_dest/$nome_arq" "$backup_source" >> $backup_log; then
		printf "$data_log Backup bem sucedido\n" >> $backup_log
	else
	 	printf "$data_log Erro ao fazer backup\n" >> $backup_log
	 fi	
fi
