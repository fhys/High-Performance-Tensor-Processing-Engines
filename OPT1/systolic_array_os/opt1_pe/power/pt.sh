#!/bin/bash

mkdir -p logs

rm -f logs/ptpx.log

pt_shell -f ptpx.tcl > logs/ptpx.log 2>&1 
