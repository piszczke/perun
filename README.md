# PERUN
Perun project - Home data gathering system for future metric analysis 

## Overview

Complete Hardware-Software solution Based on raspberry pi server and ESP nodes for gathering environmental data like temperature, humidity, soil humidity in flower pots, mini brine graduation tower, dor sensors, light sensors and ore for simple house management.  
Additionally functionality for further projects 
## Hardware Components

## Software Components 

### System Setup 

System instal and configuration 

#### basic updates

```bash
sudo apt-get update
sudo apt-get upgrade
```

#### SSH

install and enable ssh

```bash
sudo systemctl enable ssh
```
By default, firewall will block ssh access. Therefore, you must enable ufw and open ssh port
Open ssh tcp port 22 using ufw firewall

```bash 
sudo systemctl enable ssh
sudo ufw allow ssh
```

Display ip address of node
```hostname -I```


#### sudo password

Set sudo password
```bash
passwd
```

#### Packages to install  

```bash
sudo apt install tmux htop nano vsftpd mpg123 vlc mcrypt php wget pip python3-pip git python3-dev
```
#### Timezone

setup timezone 
```bash=
timedatectl
timedatectl list-timezones
sudo timedatectl set-timezone Europe/Warsaw
```

### Apache

install
```bash
sudo apt install apache2
```

setup

To be able to make changes to the files within the /var/www/html without using root we need to setup some permissions.

Firstly, we add the user pi (our user) to the www-data group, the default group for Apache2.

Secondly, we give ownership to all the files and folders in the /var/www/html directory to the www-data group.
```bash
sudo usermod -a -G www-data pi
sudo chown -R -f www-data:www-data /var/www/html
```

### PiHole
https://github.com/pi-hole/pi-hole/#curl--ssl-httpsinstallpi-holenet--bash

`curl -sSL https://install.pi-hole.net | bash`
### Database


#### mariadb-server install
```bash
sudo apt install mariadb-server
```

setup
```bash
sudo mysql_secure_installation
sudo mysql --user=root --password
> create user admin@localhost identified by 'password';
> grant all privileges on *.* to admin@localhost;
> FLUSH PRIVILEGES;
> exit;
```

### phpmyadmin

install
```bash
apt-get install phpmyadmin
```

setup
```bash
sudo phpenmod mysqli
sudo service apache2 restart
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
```

### Gradana

install & setup
```bash
sudo apt install -y software-properties-common
sudo apt install -y gnupg2 curl
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt install grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server
```

Access the Grafana web interface:

Open your web browser and navigate to http://<your-raspberry-pi-ip>:3000. The default port for Grafana is 3000.

Log in to Grafana:

The default login credentials are:

Username: admin
Password: admin
After the first login, you will be prompted to change the default password.

That's it! You now have Grafana installed and running on your Raspbian system.

Setup
```bash
mysql --user=root --password
CREATE USER 'grafanaReader' IDENTIFIED BY 'password';
GRANT SELECT ON mydatabase.mytable TO 'grafanaReader';

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server

sudo systemctl enable grafana-server.service

```

```web
go to server address :3000 (e.g. 192.168.1.5:3000)
nu: admin
ps:admin 
and set new password
```

Grafana querrys

```mysql
SELECT
  MAX(humidity) as 'Przedpokój 1 maksymalna wilgotność w %',
  MIN(humidity) as 'Przedpokój 1 minimalna wilgotność w %'
FROM
  rod.sensor_data
WHERE
  `sensor_name` LIKE 'Sensor1';

```

### Setup script as a service using systemd


`sudo nano /etc/systemd/system/my_script.service`

Add the following content to the unit file:
```bash
[Unit]
Description=My Python Script

[Service]
ExecStart=/usr/bin/python3 /path/to/your/script.py
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
```

Reload systemd to read the new service unit
Enable the service to start on boot
Start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable my_script.service
sudo systemctl start my_script.service
```



## Looging in pyhon app 

https://betterstack.com/community/guides/logging/python/python-logging-best-practices/

avaiable log types right away 

* **DEBUG**: This level shows detailed information, typically of interest only when diagnosing problems in the application. For example, you can use the debug log level to log the data that is being acted on in a function:

* **INFO**: This level depicts general information about the application to ensure that it is running as expected.

* **WARNING**: This level shows information that indicates that something unexpected happened or there is a possibility of problem in future, e.g. ‘disk space low’. This is not an error and the application still works fine but requires your attention.

* **ERROR**: This level shows an error or failure to perform some task or functions. For example, you might use error logging to track database errors or HTTP request failures. Here's an example:

* **CRITICAL**: This level shows errors that are very serious and require urgent attention or the application itself may be unable to continue running.


logger = logging.getLogger(name-of-module)

e.g. `logger.info("An info")`

Loging info 
https://betterstack.com/community/guides/logging/python/python-logging-best-practices/


example of proper loging 
```python 
  def connect_to_database():
      try:
          # connect here
      except Exception as e:
          logger.critical("Failed to connect to database: %s", e,  exc_info=True)
          exit(1)
      return conn

```


### Tips

* **Be clear and concise**: Log messages should be easy to understand and to the point. Avoid using technical jargon or complex sentences.

* **Provide context**: Include information about the context of the log message. This could include the function or module where the log message was generated, the user who initiated the action, input parameters, or any relevant data that will help understand the message.

* **Be consistent**: Use a consistent format for log messages across your application. This makes it easier to read and understand them, especially when you have many log messages such as in a production environment.

* **Use placeholders**: Use placeholders for values that will be dynamically inserted into the log message. This makes it easier to read and understand the message, and also prevents sensitive data from being logged.
