CREATE DATABASE source_db;
use source_db;
CREATE TABLE source_table
(
	id BIGINT NOT NULL AUTO_INCREMENT,
	timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	log_text VARCHAR(32765) NOT NULL,
	event_data float DEFAULT NULL,
	PRIMARY KEY (id)
	
);
DELIMITER $$
CREATE PROCEDURE simulate_data()
BEGIN
	DECLARE i INT DEFAULT 0;
	WHILE i < 15 DO
		INSERT INTO source_table (log_text, event_data) VALUES (CONCAT("This is log line number ", i ),ROUND(RAND()*15000,2));
		SET i = i + 1;
	END WHILE;
	

END$$
DELIMITER ;
CALL simulate_data();

drop PROCEDURE simulate_data;