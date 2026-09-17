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


--7.	Design a stored procedure to update the number of deaths for a specific country and date.
CREATE OR REPLACE PROCEDURE update_deaths(
    p_country_id INT,
    p_date DATE,
    p_deaths INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE covid_case_stats
    SET deaths = p_deaths
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;
CALL update_deaths(1, '2020-01-30', 50);



--8.	Create a view that displays the total number of cases (confirmed, deaths, and recovered) for each country on a specific date.
CREATE OR REPLACE VIEW country_covid_summary AS
SELECT
    c.name AS country,
    g.report_date,
    g.confirmed,
    g.deaths,
    g.recovered
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id;

SELECT *
FROM country_covid_summary
WHERE report_date = DATE '2021-09-30';


--9.Implement a view to show the latest data (confirmed, deaths, recovered) for each country
CREATE OR REPLACE VIEW latest_country_covid AS
SELECT
    c.name AS country,
    g.report_date,
    g.confirmed,
    g.deaths,
    g.recovered
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = (
	SELECT MAX(g2.report_date)
	FROM global_covid_stats g2
	WHERE g2.country_id = g.country_id
);

SELECT *
FROM latest_country_covid
ORDER BY confirmed DESC;


--10.	Write a T-SQL query to calculate the total number of cases (confirmed + deaths + recovered) for each country.
SELECT
    c.name AS country,
    g.confirmed,
    g.deaths,
    g.recovered,
    (g.confirmed + g.deaths + g.recovered) AS total_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = DATE '2021-09-30';



--11.	Use T-SQL to identify the country with the highest number of new cases reported on a specific date.
SELECT
    c.name AS country,
    g.report_date,
    g.new_confirmed
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = DATE '2021-09-30'
ORDER BY g.new_confirmed DESC
LIMIT 1;


--12.	Create a CTE to calculate the percentage increase in confirmed cases for each country over the past week.
WITH weekly_data AS (
    SELECT
        country_id,
        report_date,
        confirmed,
        LAG(confirmed, 7) OVER (
            PARTITION BY country_id
            ORDER BY report_date
        ) AS previous_week_confirmed
    FROM global_covid_stats
)
SELECT
    c.name AS country,
    report_date,
    confirmed,
    previous_week_confirmed,
    ROUND(
        (
            (confirmed - previous_week_confirmed)::NUMERIC
            / NULLIF(previous_week_confirmed, 0)
        ) * 100,
        2
    ) AS percentage_increase
FROM weekly_data w
JOIN country c
    ON w.country_id = c.country_id
WHERE previous_week_confirmed IS NOT NULL;


--13. Use a CTE to find the country with the highest number of active cases at the moment.
WITH latest_data AS (
    SELECT
        g.country_id,
        g.active_cases,
        g.report_date
    FROM global_covid_stats g
    WHERE g.report_date = (
        SELECT MAX(report_date)
        FROM global_covid_stats
    )
)
SELECT
    c.name AS country,
    l.report_date,
    l.active_cases
FROM latest_data l
JOIN country c
    ON l.country_id = c.country_id
ORDER BY l.active_cases DESC
LIMIT 1;




--14. Explain the importance of indexes in optimizing queries for this dataset.
--Indexes reduce the amount of data PostgreSQL needs to scan
--when searching, filtering, joining, or sorting large tables.
--They are especially useful for country_id, state_id,
--report_date, and country name in this COVID dataset.
EXPLAIN ANALYZE
SELECT *
FROM global_covid_stats
WHERE country_id = 1;



--15. Implement an index on the "Country/Region" column to speed up search operations.
CREATE INDEX IF NOT EXISTS idx_country_name
ON country(name);
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'country';

EXPLAIN ANALYZE
SELECT *
FROM country
WHERE name = 'India';




--16. Develop a UDF to calculate the mortality rate (deaths / confirmed cases * 100) for a given country.
CREATE OR REPLACE FUNCTION calculate_mortality_rate(
    p_country_name VARCHAR
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    mortality_rate NUMERIC;
BEGIN
    SELECT
        (
            SUM(g.deaths) * 100.0
            / NULLIF(SUM(g.confirmed), 0)
        )
    INTO mortality_rate
    FROM global_covid_stats g
    JOIN country c
        ON g.country_id = c.country_id
    WHERE c.name = p_country_name;

    RETURN ROUND(mortality_rate, 2);
END;
$$;

SELECT calculate_mortality_rate('India');



--17. Create a UDF to determine the recovery rate (recovered / confirmed cases * 100) for a specific date.
CREATE OR REPLACE FUNCTION calculate_recovery_rate(
    p_country_name VARCHAR,
    p_date DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    recovery_rate NUMERIC;
BEGIN
    SELECT
        (
            SUM(g.recovered) * 100.0
            / NULLIF(SUM(g.confirmed), 0)
        )
    INTO recovery_rate
    FROM global_covid_stats g
    JOIN country c
        ON g.country_id = c.country_id
    WHERE c.name = p_country_name
      AND g.report_date = p_date;

    RETURN ROUND(recovery_rate, 2);
END;
$$;

SELECT calculate_recovery_rate(
    'India',
    '2020-09-30'
);


--18. Group the data by continent and calculate the total number of confirmed cases for each continent.
SELECT
    c.continent,
    SUM(g.confirmed) AS total_confirmed_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY total_confirmed_cases DESC;


--19. Group the data by date and compute the total number of deaths and recoveries for each date. 
SELECT
    g.report_date,
    SUM(g.deaths) AS total_deaths,
    SUM(g.recovered) AS total_recoveries
FROM global_covid_stats g
GROUP BY g.report_date
ORDER BY g.report_date;



--20. Group the data by country and calculate the average number of new cases reported daily for each country.
SELECT
    c.name AS country,
    AVG(g.new_confirmed) AS average_daily_new_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY average_daily_new_cases DESC;


--21. To find out the death percentage locally and globally.
--Global
SELECT
    ROUND(
        (
            SUM(deaths) * 100.0
            / NULLIF(SUM(confirmed), 0)
        )::NUMERIC,
        2
    ) AS global_death_percentage
FROM global_covid_stats;
--Country-wise
SELECT
    c.name AS country,
    ROUND(
        (
            MAX(g.deaths) * 100.0
            / NULLIF(MAX(g.confirmed), 0)
        )::NUMERIC,
        2
    ) AS death_percentage
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY death_percentage DESC;



--22. To find out the infected population percentage locally and globally.
--Global
SELECT
    ROUND(
        (
            SUM(g.confirmed) * 100.0
            / NULLIF(SUM(c.population), 0)
        )::NUMERIC,
        2
    ) AS global_infected_population_percentage
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id;
--Country-wise
SELECT
    c.name AS country,
    ROUND(
        (
            MAX(g.confirmed) * 100.0
            / NULLIF(MAX(c.population), 0)
        )::NUMERIC,
        2
    ) AS death_percentage
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY death_percentage DESC;



--23. To find out the countries with the highest infection rates
SELECT
    c.name AS country,
    c.population,
    MAX(g.confirmed) AS confirmed_cases,
    ROUND(
        (
            MAX(g.confirmed) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS infected_population_percentage
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY
    c.name,
    c.population
ORDER BY infected_population_percentage DESC;



--24. To find out the countries and continents with the highest death counts.
SELECT
    c.name AS country,
    c.population,
    MAX(g.confirmed) AS confirmed_cases,
    ROUND(
        (
            MAX(g.confirmed) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS infection_rate
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY
    c.name,
    c.population
ORDER BY infection_rate DESC;



--25. Average number of deaths by day (Continents and Countries) [Hint: order by, group by clause]
--By Country
SELECT
    c.name AS country,
    AVG(g.new_deaths) AS average_daily_deaths
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY average_daily_deaths DESC;
--By Continent
SELECT
    c.continent,
    AVG(g.new_deaths) AS average_daily_deaths
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY average_daily_deaths DESC;



--26. Average of cases divided by the number of population of each country (TOP 10) [Hint: Limit]
SELECT
    c.name AS country,
    c.population,
    AVG(g.confirmed) AS average_cases,
    ROUND(
        (
            AVG(g.confirmed) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS cases_population_percentage
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY
    c.name,
    c.population
ORDER BY cases_population_percentage DESC
LIMIT 10;



--27. Considering the highest value of total cases, which countries have the highest rate of infection in relation to population? [Hint: Where clause]
SELECT
    c.name AS country,
    c.population,
    MAX(g.confirmed) AS total_cases,
    ROUND(
        (
            MAX(g.confirmed) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS infection_rate
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY
    c.name,
    c.population
HAVING MAX(g.confirmed) > 0
ORDER BY infection_rate DESC;



--28. Countries with the highest number of deaths
SELECT
    c.name AS country,
    MAX(g.deaths) AS total_deaths
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY total_deaths DESC;



--29. Continents with the highest number of deaths
SELECT
    c.continent,
    SUM(g.deaths) AS total_deaths
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY total_deaths DESC;



--30. Total vaccinated with at least 1 dose over time (All countries)
SELECT
    v.date,
    SUM(v.first_dose) AS total_people_vaccinated
FROM vaccination v
GROUP BY v.date
ORDER BY v.date;



--31. Percentage of the population vaccinated with at least the first dose until 30/9/2021 (Top 3)
SELECT
    c.name AS country,
    c.population,
    SUM(v.first_dose) AS people_vaccinated_first_dose,
    ROUND(
        (
            SUM(v.first_dose) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS vaccination_percentage
FROM vaccination v
JOIN state s
    ON v.state_id = s.state_id
JOIN country c
    ON s.country_id = c.country_id
WHERE v.date <= '2021-09-30'
GROUP BY
    c.name,
    c.population
ORDER BY vaccination_percentage DESC
LIMIT 3;



--32. To find out the population vs the number of people vaccinated
SELECT
    c.name AS country,
    c.population,
    SUM(v.first_dose) AS people_vaccinated_first_dose,
    SUM(v.second_dose) AS people_fully_vaccinated
FROM country c
JOIN state s
    ON c.country_id = s.country_id
JOIN vaccination v
    ON s.state_id = v.state_id
GROUP BY
    c.name,
    c.population
ORDER BY people_vaccinated_first_dose DESC;



--33. To find out the percentage of different vaccine taken by people in a country
SELECT
    c.name AS country,
    SUM(v.covaxin) AS covaxin,
    SUM(v.covishield) AS covishield,
    SUM(v.sputnik_v) AS sputnik_v,
    ROUND(
        (
            SUM(v.covaxin) * 100.0
            / NULLIF(
                SUM(v.covaxin)
                + SUM(v.covishield)
                + SUM(v.sputnik_v),
                0
            )
        )::NUMERIC,
        2
    ) AS covaxin_percentage,
    ROUND(
        (
            SUM(v.covishield) * 100.0
            / NULLIF(
                SUM(v.covaxin)
                + SUM(v.covishield)
                + SUM(v.sputnik_v),
                0
            )
        )::NUMERIC,
        2
    ) AS covishield_percentage,
    ROUND(
        (
            SUM(v.sputnik_v) * 100.0
            / NULLIF(
                SUM(v.covaxin)
                + SUM(v.covishield)
                + SUM(v.sputnik_v),
                0
            )
        )::NUMERIC,
        2
    ) AS sputnik_v_percentage
FROM country c
JOIN state s
    ON c.country_id = s.country_id
JOIN vaccination v
    ON s.state_id = v.state_id
GROUP BY c.name
ORDER BY c.name;



--34. To find out percentage of people who took both the doses
SELECT
    c.name AS country,
    c.population,
    SUM(v.second_dose) AS people_fully_vaccinated,
    ROUND(
        (
            SUM(v.second_dose) * 100.0
            / NULLIF(c.population, 0)
        )::NUMERIC,
        2
    ) AS fully_vaccinated_percentage
FROM country c
JOIN state s
    ON c.country_id = s.country_id
JOIN vaccination v
    ON s.state_id = v.state_id
GROUP BY
    c.name,
    c.population
ORDER BY fully_vaccinated_percentage DESC;



--35. Total State-wise Confirmed Cases
SELECT
    s.name AS state,
    SUM(cs.confirmed) AS total_confirmed_cases
FROM covid_case_stats cs
JOIN state s
    ON cs.state_id = s.state_id
GROUP BY s.name
ORDER BY total_confirmed_cases DESC;



--36. Maximum Active cases State-wise till date
SELECT
    s.name AS state,
    MAX(cs.active_cases) AS maximum_active_cases
FROM covid_case_stats cs
JOIN state s
    ON cs.state_id = s.state_id
GROUP BY s.name
ORDER BY maximum_active_cases DESC;


--37. Max Per Day Confirmed cases in States
SELECT
    s.name AS state,
    MAX(cs.new_confirmed) AS maximum_daily_confirmed_cases
FROM covid_case_stats cs
JOIN state s
    ON cs.state_id = s.state_id
GROUP BY s.name
ORDER BY maximum_daily_confirmed_cases DESC;



--38. Max Per Day Death cases in States
SELECT
    s.name AS state,
    MAX(cs.new_deaths) AS maximum_daily_deaths
FROM covid_case_stats cs
JOIN state s
    ON cs.state_id = s.state_id
GROUP BY s.name
ORDER BY maximum_daily_deaths DESC;



--39. State-wise Mortality Rate
SELECT
    s.name AS state,
    SUM(cs.confirmed) AS confirmed_cases,
    SUM(cs.deaths) AS deaths,
    ROUND(
        (
            SUM(cs.deaths) * 100.0
            / NULLIF(SUM(cs.confirmed), 0)
        )::NUMERIC,
        2
    ) AS mortality_rate
FROM covid_case_stats cs
JOIN state s
    ON cs.state_id = s.state_id
GROUP BY s.name
ORDER BY mortality_rate DESC;



--40. Daily Mumbai COVID data
SELECT
    report_date,
    SUM(new_confirmed) AS new_cases,
    SUM(new_deaths) AS new_deaths,
    SUM(active_cases) AS active_cases
FROM mumbai_covid_waves
GROUP BY report_date
ORDER BY report_date;
--Mumbai 7-day moving average
WITH daily_cases AS (
    SELECT
        report_date,
        SUM(new_confirmed) AS new_cases
    FROM mumbai_covid_waves
    GROUP BY report_date
),
moving_average AS (
    SELECT
        report_date,
        new_cases,
        ROUND(
            AVG(new_cases) OVER (
                ORDER BY report_date
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS seven_day_average
    FROM daily_cases
)
SELECT
    report_date,
    new_cases,
    seven_day_average
FROM moving_average
ORDER BY report_date;