-- select data that will be used
SELECT LOCATION, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
order by 1, 2

-- total cases vs total deaths
-- likelihood of dying if you contract covid in US
SELECT LOCATION, DATE, total_cases, total_deaths, (cast(total_deaths as FLOAT)/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE LOCATION LIKE '%states%'
order by 1, 2


-- Total cases vs population
-- The percentage of population got Covid
SELECT LOCATION, DATE, total_cases, population, cast(total_cases as FLOAT)/population*100 as PctPopInfected
FROM CovidDeaths
-- WHERE location = 'United States'
ORDER BY 1, 2


-- country with highest infection rate compare to population
SELECT LOCATION, population, MAX(total_cases) as HighestInfectionCount, cast(MAX(total_cases) as FLOAT)/population*100 as PctPopInfected
FROM CovidDeaths
group by LOCATION, population
ORDER BY PctPopInfected DESC


-- countries with highest death count
SELECT location, population, max(total_deaths) as CountryHighestDeath
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY LOCATION, population
ORDER BY CountryHighestDeath DESC


-- continents with highest death count
SELECT continent, MAX(total_deaths) as ContinentHighestDeath
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY ContinentHighestDeath DESC


-- global numbers 
-- sum of new cases, sum of deaths, and CFR each date in the world
-- CFR(case fatality rate): The proportion of people who die from a specified disease among all individuals diagnosed with the disease over a certain period of time. 
--                          Used as a measure of disease severity and is often used for prognosis (predicting disease course or outcome)
SELECT Date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, sum(cast(new_deaths as FLOAT))/sum(new_cases)*100 as CFR
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY DATE
ORDER BY DATE


-- total population vs vaccination

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
FROM CovidDeaths cd
    JOIN CovidVaccinations cv
    ON cd.LOCATION = cv.LOCATION AND cd.date = cv.date
where cd.continent is not NULL and cd.location = 'Algeria' and cv.new_vaccinations is not null
order by 2, 3

-- total_vaccination of location
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
    sum(cv.new_vaccinations) OVER (PARTITION by cd.location) as total_vaccinations
FROM CovidDeaths cd 
    JOIN CovidVaccinations cv 
    ON cd.location = cv.location and cd.date = cv.date 
WHERE cd.continent is not NULL
ORDER BY cd.location, cd.date


-- roll up the number of people vaccinated by locations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
    sum(cv.new_vaccinations) OVER (PARTITION by cd.location order by cd.date) as RollingPeopleVaccinated
FROM CovidDeaths cd 
    JOIN CovidVaccinations cv 
    ON cd.location = cv.location and cd.date = cv.date 
WHERE cd.continent is not NULL
ORDER BY cd.location, cd.date

-- percentage people vaccinated in each country

/*
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
    sum(cv.new_vaccinations) OVER (PARTITION by cd.location order by cd.date) as RollingPeopleVaccinated
    -- max(RollingPeopleVaccinated)/cd.population as pctVaccinated   -- invalid col name --> cte
FROM CovidDeaths cd 
    JOIN CovidVaccinations cv 
    ON cd.location = cv.location and cd.date = cv.date 
WHERE cd.continent is not NULL
ORDER BY cd.location, cd.date
*/

WITH cte(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as (
    SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
        sum(cv.new_vaccinations) OVER (PARTITION by cd.location order by cd.date) as RollingPeopleVaccinated
    FROM CovidDeaths cd 
        JOIN CovidVaccinations cv 
        ON cd.location = cv.location and cd.date = cv.date 
    WHERE cd.continent is not NULL
)
select *, cast(RollingPeopleVaccinated as FLOAT)/population * 100 as PctVaccinated
FROM cte

-- temp table
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT into #PercentagePopulationVaccinated
SELECT dea.continent,
     dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION by dea.location order by dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea 
    JOIN CovidVaccinations vac 
    ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null 
order by dea.location, dea.date

select *, RollingPeopleVaccinated/population*100 as PctVaccinated
FROM #PercentagePopulationVaccinated




-- create view to store data for later visualizations
CREATE VIEW PercentagePopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION by dea.location order by dea.date) as RollingPeopleVaccinated
From CovidDeaths dea 
    JOIN CovidVaccinations vac 
    ON dea.location = vac.location and dea.date = vac.date 
where dea.continent is not NULL


SELECT * 
FROM PercentagePopulationVaccinated