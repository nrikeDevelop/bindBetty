#!/bin/bash
#
# nrikeDevlelo
# Script create to fast configuration
#

#FUNCTIONS
#get public ip 
IP_PUBLIC=$(wget -qO- ipinfo.io/ip)
IP_PRIVATE="$(hostname -I)"
#IP_LAN=$(nmcli device show | grep IP4.ADDRESS | head -n1 | tr -s " " " " | cut -d " " -f 2 | cut -d "/" -f 1)
IP_LAN=`echo $(hostname -I | cut -d"." -f1,2,3).0/24 `

FILE_EXTERNAL_VIEW="db.exteral.conf"
FILE_INTERNAL_VIEW="db.internal.conf"
PATH_VIEWS="/etc/bind/views/"

function logo(){
cat << "EOF" 

            BINDBETTY
  (_,d888888888b,8888888888b_)
   d888888888888/888888888888b_)
(_8888888P'""'`Y8Y`'""'"Y88888b
  Y8888P.-'     `      '-.Y8888b_)
 ,_Y88P (_(_(        )_)_) d88Y_,
  Y88b,  (o  )      (o  ) d8888P
  `Y888   '-'        '-'  `88Y`
  ,d/O\         c         /O\b,
    \_/'.,______w______,.'\_/
       .-`             `-.
      /   , d88b  d88b_   \
     /   / 88888bd88888`\  \
    /   / \ Y88888888Y   \  \
    \  \   \ 88888888    /  /
     `\ `.  \d8888888b, /\\/
       `.//.d8888888888b; |
         |/d888888888888b/
         d8888888888888888b
       d88888888888888888888b
           Bind9 + Nginx
     d888888888888888888888888b
    
EOF
}

##print with color
NC='\033[0m' # No Color
function echo_e(){
	case $1 in 
		red)	echo -e " \033[0;31m $2 ${NC} " ;;
		green) 	echo -e " \033[0;32m $2 ${NC} " ;;
		yellow) echo -e " \033[0;33m $2 ${NC} " ;;
		blue)	echo -e " \033[0;34m $2 ${NC} " ;;
		purple)	echo -e " \033[0;35m $2 ${NC} " ;;
		cyan) 	echo -e " \033[0;36m $2 ${NC} " ;;
		*) echo $1;;
	esac
}

function is_root(){

if [ $(id -u) = 0 ]
then
	logo
else
	echo "You must be root to acces"
	exit 1
fi 
}

function is_installed(){
	PACKAGE=$1

	dpkg -s $1 &> /dev/null

	if [ $? -eq 0 ]; then
		echo_e green "[+]  $PACKAGE  is installed"
	else
		echo_e red "[-] $PACKAGE  not installed..."
		apt-get install -y $PACKAGE
		echo_e green "[+]  $PACKAGE  is installed"
	fi

}

function yes_or_not(){
	case "$1" in 
	y|Y ) return 0;;
	* ) return 1;;
	esac
}

#MAIN SUB_FUNCTIONS

function die(){
	exit 0;
}

function init_menu(){
if [ $# -eq 1 ]
then
case $1 in
	"--help"|"-h")
	echo "bindbetty [OPTIONS]"
	echo "		--remove-nginx"
	echo "		--remove-backups"
	echo "		--remove-views"
	echo "		--remove-all"
	echo "		--install "	
	die ;;	
	"--install")
	if [ -f /usr/local/bin/bindbetty ]
	then
		echo_e yellow "[+] bindbetty already installed"	
	else
		echo_e yellow "[+] Installing in /usr/local/bin/"
		cp ./bindbetty.sh /usr/local/bin/bindbetty
		echo_e green "[+] Installed"
	fi
	die ;;

	"--remove-nginx")
	echo -ne "[+] Are you sure? (y/n): "
	read OPTION
	if yes_or_not $OPTION
	then
		if [ $(ls /etc/nginx/sites-enabled | wc -l ) -gt 0 ] ; then rm /etc/nginx/sites-enabled/*; fi
		if [ $(ls /etc/nginx/sites-available | wc -l ) -gt 0 ] ; then rm /etc/nginx/sites-available/*; fi
		if [ $(ls /var/www/html | wc -l ) -gt 0 ] ; then rm -r /var/www/html/*; fi
		echo_e red " [+] Nginx droped"
	fi

	die ;;
	"--remove-backups")
	echo -ne "[+] Are you sure? (y/n): "
	read OPTION
	if yes_or_not $OPTION
	then
		if [ -d /etc/bind/backups ] ; then rm -r /etc/bind/backups; fi
		echo_e red " [+] Backups droped"
	fi
	die ;;

	"--remove-views")
	echo -ne "[+] Are you sure? (y/n): "
	read OPTION
	if yes_or_not $OPTION
	then
		if [ -d /etc/bind/views ] ; then rm -r /etc/bind/views; fi 
		echo_e red " [+] Views droped"
	fi
	die ;;

	"--remove-all")
	echo_e yellow "
	[?] rm -r /etc/bind/views
	[?] rm -r /etc/bind/backups
	[?] rm  /etc/nginx/sites-enabled/*
	[?] rm  /etc/nginx/sites-available/*
	[?] rm -r /var/www/html/*
	"
	echo -ne "[+] Are you sure? (y/n): "
	read OPTION
	if yes_or_not $OPTION
	then
		if [ -d /etc/bind/views ] ; then rm -r /etc/bind/views; fi 
		if [ -d /etc/bind/backups ] ; then rm -r /etc/bind/backups; fi
		if [ $(ls /etc/nginx/sites-enabled | wc -l ) -gt 0 ] ; then rm /etc/nginx/sites-enabled/*; fi
		if [ $(ls /etc/nginx/sites-available | wc -l ) -gt 0 ] ; then rm /etc/nginx/sites-available/*; fi
		if [ $(ls /var/www/html | wc -l ) -gt 0 ] ; then rm -r /var/www/html/*; fi
		echo ""
		echo_e red " [+] All droped"
		echo ""
	fi
	die ;;
esac
fi
}

function add_cname_nginx(){
    CNAME=$1
    CURRENT_DOMAIN=$(cat /etc/bind/views/db.exteral.conf | grep ORIGIN | cut -d " " -f2 | sed -e 's/.$//')

    echo_e green "[+] Current domain: $CURRENT_DOMAIN" 

    echo_e yellow "[+] Configurating ..."

    echo $CNAME'	IN	CNAME   ns1' >>$PATH_VIEWS$FILE_EXTERNAL_VIEW
    echo_e yellow "[+] $CNAME.$CURRENT_DOMAIN added to $FILE_EXTERNAL_VIEW"

    echo $CNAME'	IN	CNAME	ns1' >>$PATH_VIEWS$FILE_INTERNAL_VIEW
    echo_e yellow "[+] $CNAME.$CURRENT_DOMAIN added to $FILE_INTERNAL_VIEW"

    mkdir -p /var/www/html/$CNAME

    echo '
    <h2>BindBetty</h2>
    <p>
    Copy web to web_folder: /var/www/html/'$CNAME'
    <p>
    '>> /var/www/html/$CNAME/index.html

    echo_e yellow "[+] Created /var/www/html/$CNAME"

    NGINX_FILE="/etc/nginx/sites-available/"$CNAME

		echo '
		server {
			## Listen 80 (HTTP)
			listen   80; 
			root '/var/www/html/$CNAME';
			index index.php index.html index.html;
			server_name '$CNAME'.'$CURRENT_DOMAIN';
		}
		'>>$NGINX_FILE

	ln -s /etc/nginx/sites-available/$CNAME /etc/nginx/sites-enabled/
	service nginx stop
	service bind9 stop
	service bind9 start
	service nginx start
	
	echo_e green "[+] Configurated nginx"
	echo_e green "[+] http://$CNAME.$CURRENT_DOMAIN"


	echo -ne  "  [+] Do you want implement letsencrypt SSL ? (y/n): "
	read OPTION
	if yes_or_not $OPTION
	then 
		echo_e yellow "  [+] Choose option 2 to safetly mode"
		sleep 2
		certbot --authenticator webroot --installer nginx --webroot-path /var/www/html/$CNAME/ -d $CNAME.$CURRENT_DOMAIN

		echo_e green "[+] Configurated nginx"
		echo_e green "[+] http://$CNAME.$CURRENT_DOMAIN"
	fi
		
}

#MAIN

##CHECK ROOT
is_root

#CHECK PACKAGE 
is_installed curl
is_installed bind9
is_installed nginx
is_installed letsencrypt
is_installed python-certbot-nginx

#CHECK INIT MENU OPTIONS
init_menu $1

#RUN MAIN
if [ -f $PATH_VIEWS$FILE_EXTERNAL_VIEW ]
then
	echo_e green "[+]  $PATH_VIEWS  exist" 
	echo ""
    echo -ne "  [?] Do you want add CNAME entry? (y/n) : "
    read OPTION
    if yes_or_not $OPTION
    then
        echo ""
        echo -ne "Enter CNAME : "
        read CNAME
            add_cname_nginx $CNAME
        exit 0
    fi
	echo -ne "  [?] Do you want remove configuration? (y/n) : "
	read OPTION
	if yes_or_not $OPTION
	then
		backup_date=$(date | tr -s " " "_")
		
		echo -ne "  [?] Do you want to make a backup? (y/n) : "
		read OPTION
		if yes_or_not $OPTION
		then
			mkdir -p /etc/bind/backups/$backup_date

			echo ""

			cp -r /etc/bind/views /etc/bind/backups/$backup_date/views
			echo_e yellow "[+] Backup  /etc/bind/backups/$backup_date/views "
			
			cp -r /etc/bind/named.conf /etc/bind/backups/$backup_date 
			echo_e yellow "[+] Backup  /etc/bind/backups/$backup_date/named.conf "

			cp -r /etc/bind/named.conf.local /etc/bind/backups/$backup_date 
			echo_e yellow "[+] Backup  /etc/bind/backups/$backup_date/named.conf.local "

			echo ""	

			echo_e green "[*] Backup complete"
			echo_e green "[*] Stored in /etc/bind/backups/$backup_date"
			echo ""

		fi
		rm -r /etc/bind/views
		echo_e yellow "[*] reboot bind_generator"
		sudo service bind9 stop
	fi
else
	echo ""
	echo "Yout private network is "$IP_LAN
	echo "Your public IP is "$IP_PUBLIC
	echo -ne "Use this public ip ? (y/n) :"
	read option 
	if ! yes_or_not $option
	then 
		echo ""
		echo -ne "Introduce your public ip :"
		read NEW_IP
	        IP_PUBLIC=$NEW_IP
	fi

	echo ""
	echo -ne "Enter your domain name : "
	read DOMAIN
	echo ""

	echo_e yellow "[+]  $PATH_VIEWS  creating..." 
	mkdir -p $PATH_VIEWS

	cd $PATH_VIEWS

	echo '$ORIGIN '$DOMAIN'.'							>>$FILE_EXTERNAL_VIEW
	echo '$TTL	86400'									>>$FILE_EXTERNAL_VIEW
	echo '@	IN	SOA	ns1. root.localhost. ('				>>$FILE_EXTERNAL_VIEW
	echo 			'1		; Serial'					>>$FILE_EXTERNAL_VIEW
	echo 			'604800		; Refresh'				>>$FILE_EXTERNAL_VIEW
	echo 			'86400		; Retry'				>>$FILE_EXTERNAL_VIEW
	echo 			'2419200		; Expire'			>>$FILE_EXTERNAL_VIEW
	echo 			'86400 )	; Negative Cache TTL'	>>$FILE_EXTERNAL_VIEW
	echo ';'											>>$FILE_EXTERNAL_VIEW
	echo '@	IN	NS	ns1'								>>$FILE_EXTERNAL_VIEW
	echo 'ns1	IN	A	'$IP_PUBLIC						>>$FILE_EXTERNAL_VIEW
	echo_e green "[+]  $FILE_EXTERNAL_VIEW  created" 

	echo '$ORIGIN '$DOMAIN'.'							>>$FILE_INTERNAL_VIEW
	echo '$TTL	86400'									>>$FILE_INTERNAL_VIEW
	echo '@	IN	SOA	ns1. root.localhost. ('				>>$FILE_INTERNAL_VIEW
	echo 			'1		; Serial'					>>$FILE_INTERNAL_VIEW
	echo 			'604800		; Refresh'				>>$FILE_INTERNAL_VIEW
	echo 			'86400		; Retry'				>>$FILE_INTERNAL_VIEW
	echo 			'2419200		; Expire'			>>$FILE_INTERNAL_VIEW
	echo 			'86400 )	; Negative Cache TTL'	>>$FILE_INTERNAL_VIEW
	echo ';'											>>$FILE_INTERNAL_VIEW
	echo '@	IN	NS	ns1'								>>$FILE_INTERNAL_VIEW
	echo 'ns1	IN	A	'$IP_PRIVATE					>>$FILE_INTERNAL_VIEW
	echo_e green "[+]  $FILE_INTERNAL_VIEW  created"

	PATH_NAMEDCONFLOCAL="/etc/bind/named.conf.local"
	rm -r $PATH_NAMEDCONFLOCAL

	echo '
	view "external" {
    match-clients { any; };
    allow-recursion { any; };
	recursion no;
        zone "'$DOMAIN'" {
                type master;
                file "'$PATH_VIEWS$FILE_EXTERNAL_VIEW'";
        };
        include "/etc/bind/named.conf.default-zones";
	};

	acl interna { 
		'$IP_LAN'; 
		localhost; 
	};

	view internal {
		match-clients { interna; };
		allow-recursion { any; };   

			zone "'$DOMAIN'"{
					type master;
					file "'$PATH_VIEWS$FILE_INTERNAL_VIEW'";
			};
		include "/etc/bind/named.conf.default-zones";

	};  
	' >>$PATH_NAMEDCONFLOCAL

	PATH_NAMEDCONF="/etc/bind/named.conf"
	rm -r $PATH_NAMEDCONF

	echo 'include "/etc/bind/named.conf.options";'	>>$PATH_NAMEDCONF
	echo 'include "/etc/bind/named.conf.local";'	>>$PATH_NAMEDCONF

	chattr -i /etc/resolv.conf
	rm -rf /etc/resolv.conf
	echo "nameserver 127.0.0.1">> /etc/resolv.conf
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf 


	
	#resolv=`cat /etc/resolv.conf | grep 127.0.0.1`
	#if [[ ! $resolv = "nameserver 127.0.0.1" ]];
	#then
	#	echo "nameserver 127.0.0.1" >>/etc/resolv.conf
	#	chattr +i /etc/resolv.conf
	#	echo_e green "[+] 	127.0.0.1 added to resolv.conf" 
 	#fi

	echo_e green "[+] 	Configuration finished" 



	echo ""
	sudo service bind9 stop
	sudo service bind9 start

	echo_e yellow "[?] 	Check your domain ns1.$DOMAIN" 
	echo_e yellow "[?] 	ex: dig ns1.$DOMAIN @127.0.0.1" 
fi
