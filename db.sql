CREATE TABLE Sites (
    site_id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(255) NOT NULL,
    location VARCHAR(255)
);

CREATE TABLE Devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    device_name VARCHAR(255) NOT NULL,
    site_id INT,
    FOREIGN KEY (site_id) REFERENCES Sites(site_id)
);

CREATE TABLE Sensors (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    sensor_type VARCHAR(255) NOT NULL,
    sensor_name VARCHAR(255),
    device_id INT,
    FOREIGN KEY (device_id) REFERENCES Devices(device_id)
);

CREATE TABLE SensorData (
    data_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT,
    timestamp DATETIME,
    value FLOAT,
    FOREIGN KEY (sensor_id) REFERENCES Sensors(sensor_id)
);
