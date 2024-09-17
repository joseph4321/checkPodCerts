#!/bin/bash

filterNamespaces="customer-prod|customer1-prod|customer2-prod|customer3-prod|customer4-prod|customer5-prod
filterPods="api|val|router"
IFS=$'\n'
CSV="namespace,pod,container,expiration date,days until expiration,region,account,cluster\n"
UATEKS=(
"aws eks update-kubeconfig --region us-west-2 --name customer-us-west-2-cluster"
"aws eks update-kubeconfig --region us-east-1 --name customer-us-east-1-cluster"
"aws eks update-kubeconfig --region us-east-2 --name customer-us-east-2-cluster"
"aws eks update-kubeconfig --region us-east-2 --name ferdinand-testnet-cluster"
)
PRODEKS=(
"aws eks update-kubeconfig --region us-west-2 --name customer-us-west-2-cluster"
"aws eks update-kubeconfig --region us-east-1 --name customer-us-east-1-cluster"
"aws eks update-kubeconfig --region us-east-2 --name customer-us-east-2-cluster"
)




echo "Select environment to check:"
echo "[1] Testnet/UAT"
echo "[2] Prod"
read -p "Select: " selection
if [[ $selection = "1" ]]; then
	eksContext=(${UATEKS[*]})
elif [[ $selection = "2" ]]; then
	eksContext=(${PRODEKS[*]})
else
	echo "Could not understand selection.  Exiting..."
	exit
fi
echo 

read -p "Proceed? (Y/N): " proceed

if [ $proceed = "Y" ]; then
	echo "Proceeding..."
	echo
else
	echo "Exiting..."
	exit
fi

for z in "${eksContext[@]}"
do

	echo "[+] Switching context..."
	contextOutput=$(eval $z)
	echo ${contextOutput}
	identity=$(echo "$contextOutput"|awk '{print $3}')
	region=$(echo "$identity"|awk -F':' '{print $4}')
	account=$(echo "$identity"|awk -F':' '{print $5}')
	cluster=$(echo "$identity"|awk -F':' '{print $6}')
	echo
	if [[ "$contextOutput" != *"Updated context"* ]]; then
		echo "[+] Something looks off, exiting"
		exit
	fi	

	availNamespaces=( $(kubectl get pods --all-namespaces|awk '{print $1}'|uniq|grep -E "$filterNamespaces") )
	echo "[+] Found:"
	echo
	for i in "${availNamespaces[@]}"
	do
		echo $i
	done

	echo

	echo "[+] Proceeding with command execution, filter is '$filterPods'"
	echo
	for i in "${availNamespaces[@]}"
	do
		pods=( $(kubectl get pods --namespace $i|grep -v "NAME"|grep -E "$filterPods"|awk '{print $1}') )
		for j in "${pods[@]}"
		do
			containers=( $(kubectl get pods $j --namespace $i -o jsonpath='{.spec.containers[*].name}') )
			for k in "${containers[@]}"
			do
				echo "$i - $j - $k"
				echo "-----------------------------------------"
				cmdOut=$(kubectl exec -i -t -n $i $j -c  $k -- sh -c 'cat /axenterprise/conf/tls.crt'|openssl x509 -text -noout|grep "Not After\|Subject:")
				if [[ "$contextOutput" == *"Unauthorized"* ]]; then
					echo "[+] Looks like you need to authenticate again ... exiting"
					exit
				fi

				expire=$(echo "$cmdOut"|grep "Not After"|sed 's/^[ \t]*Not After \: //')
				epoch1=$(date -j -f "%b %d %T %Y %Z" "$expire" +'%s')
				epoch2=$(date +'%s')
				difference=$((epoch1-epoch2))
				oneday=86400
				diffdays=$(($difference/$oneday))
				if [ $diffdays -lt 0 ]; then
					echo -e "\033[1;31m--- WARNING: Cert expired ${diffdays#-} days ago \033[0m"
				elif [ $diffdays -lt 15 ]; then
					echo -e "\033[1;31m--- WARNING: Cert will expire in ${diffdays#-} days \033[0m"
				else
					echo "Cert will expire in ${diffdays#-} days"
				fi
				echo
				CSV+="$i,$j,$k,$expire,$diffdays,$region,$account,$cluster\n"
			done
		done
	done
done

echo
echo "Hope you had fun, csv is:"
echo -e "$CSV"	

