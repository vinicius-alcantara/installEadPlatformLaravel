#!/bin/bash
###########################################
#      @author vinícius alcântara         #
#   @maintainer vinícius alcântara	  #
#  @contact vinicius.redes2011@mgail.com  #
###########################################
###########################################

#### DEFAULTS VARIABLES ####
PROTOCOL="https://";
DOMAIN_MASTER=".nochalks.com";
APP_URL="";
CONTAINER_NAME_PREFIX="NCH3_";
DATABASE_PREFIX="nch3_";
MYSQL_USER_SERVER="root";
MYSQL_PASSWD_SERVER="xxxxxx";
MYSQL_HOST="localhost";
ENV_FILE=".env";
DIR_RAIZ="/root/Nochalksv3-Install";
IP_APPLICATION="";

clear
Menu(){
function submenu(){
   echo "-------------------------------------------"
   echo " Install/Migration nochalksv3 - App client "
   echo "-------------------------------------------"
   echo "[ 1 ] Install"
   echo "[ 2 ] Migrate V2/V3"
   echo "[ 3 ] Sair"
   echo "-------------------------------------------"
   echo
}
   submenu;
   echo -n "Selecione uma das Opções: ";
   read opcao
   case $opcao in
      1) Install ;;
      2) Migrate ;;
      3) exit ;;
      *) clear ; echo "#### Opção Inexistente!!!! :( ####"; sleep 4 ; clear ; echo ; Menu ;;
   esac
}

Install() {

  if [ ! -e $DIR_RAIZ ];then
     mkdir -p $DIR_RAIZ;
     cd $DIR_RAIZ;
  else
     cd $DIR_RAIZ;
  fi;
  
  function qtd_app(){
    
    clear;
    submenu;  
    echo -n "Quantas Aplicações?: ";
    read CONT;
  
    if [ ! -z "${CONT//[0-9]}" ]; then 
       clear ; echo "#### Valor Inválido!!!! :( ####"; sleep 4 ; clear ; echo ; submenu ;
       qtd_app;
    fi
  
  }
  
  qtd_app;

  CLIENT_NUM=0;
 
  for ((i=0; $i < $CONT; i=$i+1))
  do

    let CLIENT_NUM=$CLIENT_NUM+1;

    function option_domain_subdomain(){
    
      clear;
      submenu;
 	  
      echo -n "Cliente[$CLIENT_NUM]: Subdomínio Temporário[1] ou Domínio Permanete[2]?: ";
      read OPTION_DOMAINS;

      if [ ! -z "${OPTION_DOMAINS//[1]}" ] && [ ! -z "${OPTION_DOMAINS//[2]}" ]; then
         clear ; echo "#### Valor Inválido!!!! :( ####"; sleep 4 ; clear ; echo ; submenu ;
         option_domain_subdomain;
      fi
    
    }

    option_domain_subdomain;

    	case $OPTION_DOMAINS in
	     1)
		
		cd $DIR_RAIZ;
		echo -n "Subdomínio temporário do Cliente[$CLIENT_NUM]: ";
		read CLIENT_SUBDOMAIN;

		APP_URL=$(echo "$CLIENT_SUBDOMAIN$DOMAIN_MASTER");
  		CONTAINER_NAME=$(echo "$CLIENT_SUBDOMAIN$DOMAIN_MASTER");
  		CONTAINER_HOSTNAME=$(echo "$CLIENT_SUBDOMAIN$DOMAIN_MASTER");		
		echo $CLIENT_SUBDOMAIN > client_subdomain.txt
	        tr -d "-" < client_subdomain.txt > client_subdomain_database.txt
          	CLIENT_SUBDOMAIN_DATABASE=$(cat client_subdomain_database.txt);
          	MYSQL_USER_PASSWD_CLIENT=$(date +%s | sha256sum | base64 | head -c 32 ; echo);				
	
	create_db_client(){

	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "CREATE DATABASE $DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" 2> stdr.txt;

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "CREATE USER '$DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE'@'$IP_APPLICATION' IDENTIFIED BY '$MYSQL_USER_PASSWD_CLIENT';" 2> stdr.txt;

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE.* TO '$DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE'@'$IP_APPLICATION' WITH GRANT OPTION;" 2> stdr.txt;

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "FLUSH PRIVILEGES;" 2> stdr.txt;

  	}
	
	compose_edit(){
    	
	  mkdir -p conf/clientes/$CONTAINER_NAME;
    	  cp docker-composer-master-template.yml conf/clientes/$CONTAINER_NAME/docker-composer-master.yml;
	  cd conf/clientes/$CONTAINER_NAME
    	  sed -i s/containername_default/$CONTAINER_NAME/g docker-composer-master.yml;
    	  sed -i s/hostname_default/$CONTAINER_NAME/g docker-composer-master.yml;
    	  sed -i s/appurl_default/$APP_URL/g docker-composer-master.yml;
    	  sed -i s/database_default/$DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE/g docker-composer-master.yml;
    	  sed -i s/ip_default/$IP_APPLICATION/g docker-composer-master.yml;
	  sed -i s/domain_default/$CONTAINER_NAME/g docker-composer-master.yml;
	  sed -i s/user_default/$DATABASE_PREFIX$CLIENT_SUBDOMAIN_DATABASE/g docker-composer-master.yml;
          sed -i s/pass_default/$MYSQL_USER_PASSWD_CLIENT/g docker-composer-master.yml;
  	  #docker-compose up -d #via Portainer API

  	}
	
	env_file(){

    	  APP_HOST=$(echo "$CLIENT_SUBDOMAIN");
          echo "APP_ENV=production" >> .env;
    	  echo "APP_HOST=$APP_HOST" >> .env;
	  echo "DB_PASSWORD=$MYSQL_USER_PASSWD_CLIENT" >> .env
	  echo "APP_KEY=base64:OXrDv5PzTDQJy+FyU4Wle54nFBQHVAmrsCZrTQkOezk=" >> .env
          echo "APP_DEBUG=false" >> .env
          echo "APP_LOCALE=br" >> .env
          echo "DB_CONNECTION=mysql" >> .env
          echo "DB_PORT=3306" >> .env
          echo "MAIL_DRIVER=smtp" >> .env
          echo "MAIL_HOST=nochalks1.nochalks.com" >> .env
          echo "MAIL_PORT=587" >> .env
          echo "MAIL_USERNAME=vovo@nochalks.com" >> .env
          echo "MAIL_PASSWORD="AQ!SW@DE#"" >> .env
          echo "MAIL_ENCRYPTION=tls" >> .env

	}

  	nginxconf_edit(){

	  cd $DIR_RAIZ;
    	  cp production-template.conf conf/clientes/$CONTAINER_NAME/production.conf;
	  cd conf/clientes/$CONTAINER_NAME;
    	  sed -i s/nochalks3.io/$CONTAINER_HOSTNAME/g production.conf;

  	}	

	create_volumes_client(){

    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/environments/config/production
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/bin
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/storage
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/nginxconf
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/public/app
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/public/js
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/process/logs
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/bootstrap/cache
    	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/resources/views/emails
	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME/process/bin

    	  mv production.conf /home/nochalks3/www/$CONTAINER_NAME/nginxconf
    	  mv .env  /home/nochalks3/www/$CONTAINER_HOSTNAME/environments/config/production

  	}

	function option_ip(){	
	  
	  echo -n "IP Sugerido[1] ou Definir IP Manualmente[2]: ";
          read OPTION_IP;
	    
	  if [ ! -z "${OPTION_IP//[1]}" ] && [ ! -z "${OPTION_IP//[2]}" ]; then
	     clear ; echo "#### Valor Inválido!!!! :( ####"; sleep 4 ; clear ; echo ; submenu ;
       	     option_ip;
          fi

	}	

	option_ip;

                if [ $OPTION_IP == "1" ]; then

                        IP_LIST=$(docker network inspect nochalks3_network | egrep IPv4Address | cut -d ":" -f2 > list_ip.txt && sed -i 's/"//g' list_ip.txt && cat list_ip.txt | cut -d "/" -f1 list_ip.txt  > list_ip_temp.txt && cut -d "." -f4 list_ip_temp.txt | sort | tail -n 1);
                        CONT_SOMA=1;
                        let IP_DISP="$IP_LIST+$CONT_SOMA";
                        IP_APPLICATION=$(echo "10.88.0.$IP_DISP");
                        echo "Definindo endereço IP da aplicação [$IP_APPLICATION]: ";
			sleep 3;
  			compose_edit;
			env_file;
			nginxconf_edit;
			create_volumes_client;                     
  			create_db_client;
			rm -rf conf/clientes/$CONTAINER_NAME stdr.txt;
			echo "loading..........":
			sleep 2;
			/usr/games/sl;
			clear;
			cd $DIR_RAIZ/conf/clientes/$CONTAINER_NAME
                        bash $DIR_RAIZ/stack_create.sh $CONTAINER_HOSTNAME docker-composer-master.yml;
                        sleep 3;
			#Menu;
			docker container exec -d $CONTAINER_NAME sh deploy/nochalks3-install.sh							              
		else

                        echo -n "Digite o end. IP da aplicação: "
                        read IP_APPLICATION;
			sleep 3;
                        compose_edit;
                        env_file;
                        nginxconf_edit;
                        create_volumes_client; 
			create_db_client;
			rm -rf conf/clientes/$CONTAINER_NAME stdr.txt;
			echo "loading..........":
                        sleep 2;
                        /usr/games/sl;
			clear;
			cd $DIR_RAIZ/conf/clientes/$CONTAINER_NAME
			bash $DIR_RAIZ/stack_create.sh $CONTAINER_HOSTNAME docker-composer-master.yml;
			sleep 3;
			clear;
			#Menu;
			docker container exec -d $CONTAINER_NAME sh deploy/nochalks3-install.sh
                fi
		;;
	
	     2)

		cd $DIR_RAIZ;
		echo -n "Digite o domínio (Proprietário) permanente do Cliente[$CLIENT_NUM]: ";
		read CLIENT_DOMAIN;
		
		clear;
    		submenu;

		echo -n "Deseja registrar o domínio como .com[1] ou .com.br[2] ou customizado[3]?: "
		read CLIENT_DOMAIN_SUFIXO;

		clear;
    		submenu;

		if [ $CLIENT_DOMAIN_SUFIXO -eq 1 ];then
			CLIENT_DOMAIN_SUFIXO=".com";
		elif [ $CLIENT_DOMAIN_SUFIXO -eq 2 ];then
			CLIENT_DOMAIN_SUFIXO=".com.br";
		else
			echo -n "Complete o domínio de forma customizada para [$CLIENT_DOMAIN]: ";
			read CLIENT_DOMAIN_SUFIXO_CUSTOM;
			CLIENT_DOMAIN_SUFIXO=$(echo $CLIENT_DOMAIN_SUFIXO_CUSTOM);
		fi

		APP_URL=$(echo "$CLIENT_DOMAIN");
                CONTAINER_NAME=$(echo "$CLIENT_DOMAIN");
                CONTAINER_HOSTNAME=$(echo "$CLIENT_DOMAIN");
		echo $CLIENT_DOMAIN > client_domain.txt
	        tr -d "-" < client_domain.txt > client_domain_database.txt
        	CLIENT_DOMAIN_DATABASE=$(cat client_domain_database.txt);
          	MYSQL_USER_PASSWD_CLIENT=$(date +%s | sha256sum | base64 | head -c 32 ; echo);

	create_db_client(){

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "CREATE DATABASE $DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" 2> stdr.txt;

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "CREATE USER '$DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE'@'$IP_APPLICATION' IDENTIFIED BY '$MYSQL_USER_PASSWD_CLIENT';" 2> stdr.txt;

    	  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE.* TO '$DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE'@'$IP_APPLICATION' WITH GRANT OPTION;" 2> stdr.txt;

		  mysql -u $MYSQL_USER_SERVER -p$MYSQL_PASSWD_SERVER -h $MYSQL_HOST -e "FLUSH PRIVILEGES;" 2> stdr.txt;

  	} 

	compose_edit(){

          mkdir -p conf/clientes/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO;
          cp docker-composer-master-template.yml conf/clientes/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO/docker-composer-master.yml;
          cd conf/clientes/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO
          sed -i s/containername_default/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO/g docker-composer-master.yml;
          sed -i s/hostname_default/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO/g docker-composer-master.yml;
          sed -i s/appurl_default/$APP_URL$CLIENT_DOMAIN_SUFIXO/g docker-composer-master.yml;
          sed -i s/database_default/$DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE/g docker-composer-master.yml;
          sed -i s/ip_default/$IP_APPLICATION/g docker-composer-master.yml;
	  sed -i s/domain_default/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO/g docker-composer-master.yml;
	  sed -i s/user_default/$DATABASE_PREFIX$CLIENT_DOMAIN_DATABASE/g docker-composer-master.yml;
	  sed -i s/pass_default/$MYSQL_USER_PASSWD_CLIENT/g docker-composer-master.yml;

	  #docker-compose up -d #via Portainer API

        }

        env_file(){

          APP_HOST=$(echo "$CLIENT_DOMAIN")
          echo "APP_ENV=production" >> .env;
          echo "APP_HOST="$APP_HOST >> .env
	  echo "DB_PASSWORD="$MYSQL_USER_PASSWD_CLIENT >> .env
	  echo "APP_KEY=base64:OXrDv5PzTDQJy+FyU4Wle54nFBQHVAmrsCZrTQkOezk=" >> .env
          echo "APP_DEBUG=false" >> .env
          echo "APP_LOCALE=br" >> .env
          echo "DB_CONNECTION=mysql" >> .env
          echo "DB_PORT=3306" >> .env
          echo "MAIL_DRIVER=smtp" >> .env
          echo "MAIL_HOST=nochalks1.nochalks.com" >> .env
          echo "MAIL_PORT=587" >> .env
          echo "MAIL_USERNAME=vovo@nochalks.com" >> .env
          echo "MAIL_PASSWORD="AQ!SW@DE#"" >> .env
          echo "MAIL_ENCRYPTION=tls" >> .env
		
        }

        nginxconf_edit(){
  
          cp $DIR_RAIZ/production-template.conf production.conf
          sed -i s/nochalks3.io/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/g production.conf

        }

	create_volumes_client(){

	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/environments/config/production
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/bin
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/storage
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/nginxconf
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/public/app
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/public/js
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/process/logs
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/bootstrap/cache
          mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/resources/views/emails
	  mkdir -p /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/process/bin

          mv production.conf /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/nginxconf
          mv .env  /home/nochalks3/www/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO/environments/config/production

        }
		clear;
    		submenu;

		echo -n "IP Sugerido[1] ou Definir IP Manualmente[2]: ";
                read OPTION_IP;

                if [ $OPTION_IP == "1" ]; then

                        IP_LIST=$(docker network inspect nochalks3_network | egrep IPv4Address | cut -d ":" -f2 > list_ip.txt && sed -i 's/"//g' list_ip.txt && cat list_ip.txt | cut -d "/" -f1 list_ip.txt  > list_ip_temp.txt && cut -d "." -f4 list_ip_temp.txt | sort | tail -n 1);
                        CONT=1;
                        let IP_DISP="$IP_LIST+$CONT";
                        IP_APPLICATION=$(echo "10.88.0.$IP_DISP");
                        echo "Definindo endereço IP da aplicação [$IP_APPLICATION]: ";
			sleep 3;
                        compose_edit;
                        env_file;
                        nginxconf_edit;
                        create_volumes_client;
                        create_db_client;
                	echo "loading..........":
                        sleep 2;
                        /usr/games/sl;
                        clear;
			cd $DIR_RAIZ/conf/clientes/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO
                        bash $DIR_RAIZ/stack_create.sh $CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO docker-composer-master.yml;
                        sleep 3;
                        clear;
                        #Menu;
			docker container exec -d $CONTAINER_NAME sh deploy/nochalks3-install.sh
		else

                        echo -n "Digite o end. IP da aplicação: ";
                        read IP_APPLICATION;
			sleep 3;
                        compose_edit;
                        env_file;
                        nginxconf_edit;
                        create_volumes_client;
                        create_db_client;
                	echo "loading..........":
                        sleep 2;
                        /usr/games/sl;
                        clear;
			cd $DIR_RAIZ/conf/clientes/$CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO
                        bash $DIR_RAIZ/stack_create.sh $CONTAINER_HOSTNAME$CLIENT_DOMAIN_SUFIXO docker-composer-master.yml;
                        sleep 3;
                        clear;
                        #Menu;
			docker container exec -d $CONTAINER_NAME sh deploy/nochalks3-install.sh
		fi

		cd $DIR_RAIZ && rm -rf client_subdomain.txt client_subdomain_database.txt client_domain_database.txt client_domain.txt list_ip_temp.txt list_ip.txt;
		cd conf/clientes/$CONTAINER_NAME$CLIENT_DOMAIN_SUFIXO && rm -rf stdr.txt;

		;;

		*) clear ; echo "#### Opção Inexistente!!!! :( ####"; sleep 4 ; clear ; echo ; Menu ;;
  	esac
  done
  cd $DIR_RAIZ && rm -rf client_subdomain.txt client_subdomain_database.txt client_subdomain.txt list_ip_temp.txt list_ip.txt 
}

Migrate(){
  echo
  echo "###################################"
  echo "#### Em Desenvolvimento!!!! ;) ####";
  echo "###################################";
  sleep 3;
  clear;
  Menu;
}

Menu

exit 0
