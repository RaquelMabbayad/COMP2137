#!/bin/bash

#Source the function file
source ./function_reports.sh

#Check if a report was specified on the command line
if [ -n "$1" ]; then
	report_choice=$1
else
	#Prompt user to select a report if not specified
	echo "Please select a report to run:"
	echo "1) Hardware Summary Report"
	echo "2) Storage Management Report"
	echo "3) Network Configuration Information Report"
	read -p "Enter the number of your choice: " report_choice
fi

#Run the selected report
case $report_choice in
	1 | "hardware")
		hardware_summary_report
		;;
	2 | "storage")
		storage_management_report
		;;
	3 | "network")
		network_configuration_report
		;;
	*)
		echo "Invalid choice. Please select 1,2, or 3."
		;;
esac


