#!/bin/bash
mkdir -p logs

rm -f logs/dc.log

dc_shell -64bit -f dc.tcl > logs/dc.log 2>&1 