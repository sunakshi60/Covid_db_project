-- 1.	Which country has the highest number of confirmed cases on a specific date?
SELECT
    c.name AS country,
    g.report_date,
    g.confirmed
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = DATE '2021-09-30'
ORDER BY g.confirmed DESC
LIMIT 1;

--2.	Show the total number of deaths in each country, including provinces/states, for a given date.
SELECT
    c.name AS country,
    g.report_date,
    SUM(g.deaths) AS total_deaths
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = DATE '2021-09-30'
GROUP BY c.name, g.report_date
ORDER BY total_deaths DESC;


--3.	List the continents along with the total number of confirmed cases, deaths, and recoveries.
SELECT
    c.continent,
    SUM(g.confirmed) AS total_confirmed,
    SUM(g.deaths) AS total_deaths,
    SUM(g.recovered) AS total_recovered
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY total_confirmed DESC;


--4.	Calculate the average number of new deaths per day across all countries.
SELECT 
    AVG(daily_deaths) AS average_new_deaths_per_day
FROM (
    SELECT 
        report_date,
        SUM(new_deaths) AS daily_deaths
    FROM covid_case_stats
    GROUP BY report_date
) AS daily_data;


--5.	Find the maximum number of active cases recorded in any country on a specific date
SELECT
    c.name AS country,
    g.report_date,
    g.active_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = DATE '2021-09-30'
ORDER BY g.active_cases DESC
LIMIT 1;


--6.	Create a stored procedure that returns the total number of recovered cases for a given country and date
CREATE OR REPLACE PROCEDURE get_total_recovered(
    p_country_id INT,
    p_date DATE,
    OUT total_recovered INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(SUM(recovered), 0)
    INTO total_recovered
    FROM covid_case_stats
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;
CALL get_total_recovered(1, '2020-01-30', NULL);