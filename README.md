# checkPodCerts
This script will use a defined filter to log in to each cluster, namespace and pod that matches the filter, and check the defined certificate for upcoming expirations.  Since these certs are not exposed externally, this is the only way to verify upcoming cert expirations across multiple contexts/namespaces/pods.  A csv is provided at the end for easier consumption

Example output:
% ./checkPodCerts.sh
Select environment to check:
[1] Testnet/UAT
[2] Prod
Select: 2
 
Proceed? (Y/N): Y
Proceeding...
 
[+] Switching context...
Updated context arn:aws:eks:us-west-2:$account:cluster/$cluster in /Users/joseph/.kube/config
 
[+] Found:
 
customer-prod
customer1-prod
customer2-prod
customer3-prod
customer4-prod
 
[+] Proceeding with command execution, filter is 'api|val'
 
customer-prod - customer-api2-d954874b5-pgmgt - api2
-----------------------------------------
Cert will expire in 378 days
 
customer-prod - customer-val2-0 - val2
-----------------------------------------
Cert will expire in 378 days
 
customer1-prod - customer1-api2-b8b965556-j4vmk - api2
-----------------------------------------
Cert will expire in 91 days
 
customer1-prod - customer1-val2-0 - val2
-----------------------------------------
Cert will expire in 91 days

... etc ...

[+] Switching context...
Updated context arn:aws:eks:us-east-2:$account:cluster/$cluster in /Users/joseph/.kube/config
 
[+] Found:
 
customer-prod
customer1-prod
customer2-prod
customer3-prod
customer4-prod
 
[+] Proceeding with command execution, filter is 'api|val'
 
customer-prod - customer-api0-56f9c9dcd9-ml9zj - api0
-----------------------------------------
Cert will expire in 378 days
 
vcustomer-prod - customer-val0-0 - val0
-----------------------------------------
Cert will expire in 378 days
 
customer1-prod - customer1-api0-5c86fbd64f-ks6p2 - api0
-----------------------------------------
Cert will expire in 91 days

... etc ...
