# perun
Perun project - Home data gathering system for future metric analysis 


# Raspberry pi server instructionset

###### TAG 

:::info
First part is based on this note: 
https://hackmd.io/idIXARJRRBSJU1DxgwZzxg
:::


## Basic system confiuration 

### Update & Upgrade

```bash
sudo apt-get update
sudo apt-get upgrade
```

### SSH

(install and) enable ssh
(`sudo apt-get install openssh-client
`)
```bash
sudo systemctl enable ssh
```
By default, firewall will block ssh access. Therefore, you must enable ufw and open ssh port
Open ssh tcp port 22 using ufw firewall

```bash 
sudo systemctl enable ssh
sudo ufw allow ssh
```
:::success
Display ip addrees of node

`hostname -I`

:::

### sudo password

Set sudo password
```bash
passwd
```

## Pacages to install 


### Basic

:::info
Install list of basic packages 
:::

```bash
sudo apt install tmux htop nano vsftpd mpg123 vlc mcrypt php wget pip python3-pip git python3-dev
```
### Timezon
setup timezone 
```bash=
timedatectl
timedatectl list-timezones
sudo timedatectl set-timezone Europe/Warsaw
```
### Alias

```bash
alias ll="ls -l"    
```



### Apache

based on `https://pimylifeup.com/raspberry-pi-apache/`

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

based on `https://pimylifeup.com/raspberry-pi-mysql/`

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

#### phpmyadmin

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

#### Gradana

install
```bash
sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get install grafana
```

setup
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
##### SETUP

sample querry 
```mysql
SELECT temperature, timestamp FROM `sensor_data` WHERE `sensor_name` LIKE 'Sensor2' ;
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

```mysql
SELECT
  MAX(humidity) as 'Przedpokój 2 maksymalna wilgotność w %',
  MIN(humidity) as 'Przedpokój 2 minimalna wilgotność w %'
FROM
  rod.sensor_data
WHERE
  `sensor_name` LIKE 'Sensor2';
```

## Sensor data gathering 

### Pacages to install

Install required libraries
```bash
pip install adafruit-circuitpython-dht mysql-connector-python
pip3 install adafruit-circuitpython-dht
sudo python3 -m pip install --upgrade pip setuptools wheel
sudo pip3 install Adafruit_DHT

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



## Program do kolekcji danych

```python  
import Adafruit_DHT
import requests
import time
import mysql.connector

# DHT22 sensor configurations
DHT_SENSOR_1 = Adafruit_DHT.DHT22
DHT_PIN_1 = 4

DHT_SENSOR_2 = Adafruit_DHT.DHT22
DHT_PIN_2 = 24

DHT_SENSOR_3 = Adafruit_DHT.DHT22
DHT_PIN_3 = 18

DELAY_TIME = 20 #Time betwien data collection in seconds

def read_sensor_data(sensor, pin):
    humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)
    return humidity, temperature

def insert_data_to_db(cursor, sensor_name, temperature, humidity, status=None):
    insert_query = "INSERT INTO sensor_data (sensor_name, temperature, humidity, status, timestamp) VALUES (%s, %s, %s, %s, NOW())"
    data = (sensor_name, temperature, humidity, status)
    print (data)
    cursor.execute(insert_query, data)

def main():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="dom",
            password="domdom",
            database="rod"
        )
        cursor = conn.cursor()

        while True:
            humidity1, temperature1 = read_sensor_data(DHT_SENSOR_1, DHT_PIN_1)
            humidity2, temperature2 = read_sensor_data(DHT_SENSOR_2, DHT_PIN_2)
            humidity3, temperature3 = read_sensor_data(DHT_SENSOR_3, DHT_PIN_3)

            if humidity1 is not None and temperature1 is not None:
                if humidity1 > 100:
                    insert_data_to_db(cursor, "Sensor1", temperature1, humidity1, "Humidity too high")
                else:
                    insert_data_to_db(cursor, "Sensor1", temperature1, humidity1)

            if humidity2 is not None and temperature2 is not None:
                if humidity2 > 100:
                    insert_data_to_db(cursor, "Sensor2", temperature2, humidity2, "Humidity too high")
                else:
                    insert_data_to_db(cursor, "Sensor2", temperature2, humidity2)

            if humidity3 is not None and temperature3 is not None:
                if humidity3 > 100:
                    insert_data_to_db(cursor, "Sensor3", temperature3, humidity3, "Humidity too high")
                else:
                    insert_data_to_db(cursor, "Sensor3", temperature3, humidity3)

            conn.commit()
            time.sleep(DELAY_TIME)

    except KeyboardInterrupt:
        print("Data collection stopped by the user.")
    except Exception as e:
        print("Error:", e)
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    main()

```

## Program do kolekcji danyc II


```python

import Adafruit_DHT
import requests
import time
import mysql.connector
import logging

# Configure the logging
logging.basicConfig(filename='sensor_data.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s: %(message)s')

# DHT22 sensor configurations
DHT_SENSOR_1 = Adafruit_DHT.DHT22
DHT_PIN_1 = 4

DHT_SENSOR_2 = Adafruit_DHT.DHT22
DHT_PIN_2 = 24

DHT_SENSOR_3 = Adafruit_DHT.DHT22
DHT_PIN_3 = 18

# New Sensor
DHT_SENSOR_4 = Adafruit_DHT.DHT22
DHT_PIN_4 = 25

# Delay time
DELAY_TIME = 20

def read_sensor_data(sensor, pin):
    humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)
    return humidity, temperature

def insert_data_to_db(cursor, sensor_name, temperature, humidity, status=None):
    insert_query = "INSERT INTO sensor_data (sensor_name, temperature, humidity, status, timestamp) VALUES (%s, %s, %s, %s, NOW())"
    data = (sensor_name, temperature, humidity, status)
    cursor.execute(insert_query, data)
    logging.info(f"{sensor_name}: Data inserted")

def main():
    conn = None
    cursor = None

    try:
        while True:
            if conn is None:
                conn = mysql.connector.connect(
                    host="your_mysql_host",
                    user="your_mysql_username",
                    password="your_mysql_password",
                    database="your_mysql_database"
                )
                cursor = conn.cursor()

            # Read and insert data for each sensor
            for sensor_name, sensor_pin in [
                ("Sensor1", DHT_PIN_1),
                ("Sensor2", DHT_PIN_2),
                ("Sensor3", DHT_PIN_3),
                ("Sensor4", DHT_PIN_4)
            ]:
                humidity, temperature = read_sensor_data(Adafruit_DHT.DHT22, sensor_pin)
                if humidity is not None and temperature is not None:
                    if humidity > 100:
                        insert_data_to_db(cursor, sensor_name, temperature, humidity, "Humidity too high")
                    else:
                        insert_data_to_db(cursor, sensor_name, temperature, humidity)

            conn.commit()

            # Close the database connection
            cursor.close()
            conn.close()
            conn = None
            cursor = None

            time.sleep(DELAY_TIME)

    except KeyboardInterrupt:
        logging.info("Data collection stopped by the user.")
        print("Data collection stopped by the user.")
    except Exception as e:
        logging.error(f"Error: {e}")
        print("Error:", e)
    finally:
        if conn is not None:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    main()

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
