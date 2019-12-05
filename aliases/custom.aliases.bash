alias gotocode='cd /Users/japan.bankimnaik/Documents/nbn/code'
alias gotop='export AWS_PROFILE="awsprod"'
alias gotonp='export AWS_PROFILE="awsnonprod"'
alias gotol='export AWS_PROFILE="awslrn"'
# Kube aliases
alias mykcip='export KUBECONFIG=/Users/japan.bankimnaik/.kube/configs/cicd_prod.kubeconfig'
alias mykcinp='export KUBECONFIG=/Users/japan.bankimnaik/.kube/configs/cicd_staging.kubeconfig'
alias mykmsp='export KUBECONFIG=/Users/japan.bankimnaik/.kube/configs/mseu-k8s-prod2.kubeconfig'

export PATH=~/Library/Python/3.7/bin:$PATH

############
# AWS 
############

function myssh() {

	ssh -i /Users/japan.bankimnaik/Documents/nbn/JB.pem $1
}

function awslogin() {

    echo "Loggin into AWS Learning Sandpit..."
	saml2aws -p awslrn -a AWSLRN login > /dev/null
	echo "Loggin into AWS NonProd..."
	saml2aws -p awsnonprod -a AWS-NonProd -r arn:aws:iam::2013293xxxx:role/continuous-delivery-developer-role login > /dev/null
	echo "Loggin into AWS Prod..."
	saml2aws -p awsprod -a AWS-Prod -r arn:aws:iam::439177xxxx:role/continuous-delivery-developer-role login > /dev/null
    echo "-----Done-----"
	export AWS_PROFILE='awsnonprod'
	echo "You are in AWS NonProd profile"
	echo "To switch env, use: gotop (Prod), gotol (Learning), gotonp (NonProd)"
	echo "--------------"
}

export AWS_DEFAULT_REGION='ap-southeast-2'
export AWS_PROFILE='saml'
export AWS_ACCOUNT_NAME="AWS-NonProd"
export SAML2AWS_USERNAME='' # Username
export SAML2AWS_PASSWORD='' # PW

function display_aws_profile() {
	RED='\033[0;31m'
	YELLOW='\033[1;33m'
	NC='\033[0m' # No Color
	COLOUR="$YELLOW"
	if [ $AWS_PROFILE = "awsprod" ]
	then
	COLOUR="$RED"
	fi
	printf "AWS Profile is : ${COLOUR}$AWS_PROFILE${NC}\n"
}

function getinfo() {
	display_aws_profile
	
	if [ "$2" == "running" ]
	then
	aws ec2 describe-instances --output table \
		--filters "Name=tag:Name,Values=*$1*" \
		"Name=instance-state-name,Values=running" \
		--query 'Reservations[].Instances[].{A_Name: Tags[?Key==`Name`] | [0].Value, B_IP: PrivateIpAddress, C_Key: KeyName, D_LaunchTime: LaunchTime, E_State: State.Name}'
	exit 0
	fi

	aws ec2 describe-instances --output table \
		--filters "Name=tag:Name,Values=*$1*" \
		--query 'Reservations[].Instances[].{A_Name: Tags[?Key==`Name`] | [0].Value, B_IP: PrivateIpAddress, C_Key: KeyName, D_LaunchTime: LaunchTime, E_State: State.Name}'
}

function getssh() {
	KeysPath="/Users/japan.bankimnaik/Documents/nbn/keys"
    awscmd_out=`aws ec2 describe-instances --output text \
    	--filters "Name=tag:Name,Values=*$1*" "Name=instance-state-name,Values=running" \
    	--query 'Reservations[].Instances[].[Tags[?Key==\`Name\`] | [0].Value, PrivateIpAddress, KeyName]'`
    InstanceName=`echo $awscmd_out | cut -d' ' -f1 `
    PrivateIP=`echo $awscmd_out | cut -d' ' -f2 `
    KeyNameWithDate=`echo $awscmd_out | cut -d' ' -f3 `
    
    echo "-----------------------"
    echo "Instance:        $InstanceName"
    echo "PrivateIP:       $PrivateIP"
    echo "KeyNameWithDate: $KeyNameWithDate"
    
    if [ $AWS_PROFILE = "awsprod" ] || [[ $KeyNameWithDate =~ "gocd" ]]
    then KeyName=`echo ${KeyNameWithDate%-*}`
    else KeyName=$KeyNameWithDate
    fi
    
    echo "KeyName:         $KeyName"
	PemFile="$KeysPath/$KeyName.pem"
    echo "Key Path:    $PemFile"
    
    if [ ! "$PrivateIP" ];then
       echo "No Instance running matching your search...!!!"
       exit 1
    fi
    
    echo "*******************"
    echo "Preparing key......"
    echo "*******************"
    unicreds -r ap-southeast-2 -p $AWS_PROFILE get $KeyName > $PemFile
	chmod 600 $PemFile
    echo "Key stored as $PemFile"

    echo "**********************************************"
    echo "Following string has been copied to clipboard,"
    echo "just paste it and login to server....Enjoy !!!"
    echo "**********************************************"
    printf "${COLOUR}ssh -i $PemFile ec2-user@$PrivateIP${NC}\n"
    printf "ssh -i $PemFile ec2-user@$PrivateIP" | pbcopy
}

###########
### K8s ###
###########

function initConfigVar () {
    if [[ $(ls ~/.kube/configs | grep kubeconfig | wc -l) != 0 ]]; then
            for f in `ls ~/.kube/configs/ | grep kubeconfig`
            do 
            export KUBECONFIG="$HOME/.kube/configs/$f:$KUBECONFIG" 
            done
            export KUBECONFIG=$(echo $KUBECONFIG | sed 's/:$//')
    fi
    
    kubectl config get-contexts
}
initConfigVar
#[[ -d $HOME/.kube/configs && initConfigVar ]] \
#|| { mkdir $HOME/.kube/configs; echo "No config directory. Put kubeconfigs in $HOME/.kube/configs/ and source this profile to load.";}

##########
