-- ==========================================================
-- CSV Data Import Script (MySQL)
-- Adjust filepath as per local path (e.g. 'D:/covid_db_project/data/...')
-- Ensure `local_infile = 1` is enabled if using LOAD DATA LOCAL INFILE
-- ==========================================================

USE covid_db;

-- 1. Load Countries
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/countries.csv'
INTO TABLE country
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(country_id, name, continent, population);

-- 2. Load States
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/states.csv'
INTO TABLE state
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(state_id, name, population, country_id);

-- 3. Load Districts
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/districts.csv'
INTO TABLE district
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(district_id, state_id, name);

-- 4. Load State Covid Cases
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/covid_case_stats.csv'
INTO TABLE covid_case_stats
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(case_id, country_id, state_id, report_date, report_time, confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases);

-- 5. Load Vaccination
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/vaccination.csv'
INTO TABLE vaccination
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(vaccine_id, state_id, date, total_doses, first_dose, second_dose, covaxin, covishield, sputnik_v, precaution_dose);

-- 6. Load Testing
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/testing.csv'
INTO TABLE testing
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(testing_id, state_id, date, total_samples, @positive_cases, @negative_cases)
SET 
  positive_cases = NULLIF(@positive_cases, ''),
  negative_cases = NULLIF(@negative_cases, '');

-- 7. Load Global Covid Stats
LOAD DATA LOCAL INFILE 'D:/covid_db_project/data/global_covid_stats.csv'
INTO TABLE global_covid_stats
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(global_stat_id, country_id, report_date, confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases, people_vaccinated_1dose, people_fully_vaccinated);
