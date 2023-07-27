SELECT *
FROM PorfolioProject..CovidDeaths
ORDER BY location, date

--SELECT *
--FROM PorfolioProject..CovidVaccinations
--ORDER BY location, date

-- Explore cases and deaths data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PorfolioProject..CovidDeaths
ORDER BY location, date

-- Look at total_cases vs total_deaths
-- Shows likelihood of dying if infected in a particular country

SELECT location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 as DeathPercentage
FROM PorfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date

-- Look at total cases vs population
-- Shows infection rate in a particular country

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
FROM PorfolioProject..CovidDeaths
ORDER BY location, date

-- Look at countries with highest infection rate
SELECT location, MAX(total_cases) as HighestInfectionCount, population, (MAX(total_cases)/population)*100 as HighestInfectionPercentage
FROM PorfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY HighestInfectionPercentage DESC

-- Look at countries with highest death counts
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PorfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Look at continents with highest death counts
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PorfolioProject..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Use PARTITION BY
-- Look at total population vs total vaccinations
-- Calculate rolling total new vaccinations of each country on each day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location
		ORDER BY dea.location, dea.date) as TotalNewVaccinationsToDate
FROM PorfolioProject..CovidDeaths as dea
JOIN PorfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY location, date

-- Use CTE
-- Calculate the percentage of new vaccinations vs the total population of each country each day

WITH PopvsVac(Continent, Location, Date, Population, NewVaccinations,
	TotalNewVaccinationsToDate) as (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (
			PARTITION BY dea.location
			ORDER BY dea.location, dea.date) as TotalNewVaccinationsToDate
	FROM PorfolioProject..CovidDeaths as dea
	JOIN PorfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not NULL
)
SELECT *, (TotalNewVaccinationsToDate/Population)*100 as NewlyVaccinatedRate
FROM PopvsVac

-- Use Temp Table
-- Calculate the percentage of new vaccinations vs the total population of each country each day

DROP TABLE IF EXISTS #NewVaccinationRate	
CREATE TABLE #NewVaccinationRate(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
NewVaccinations numeric,
TotalNewVaccinationsToDate numeric
)

INSERT INTO #NewVaccinationRate
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location
		ORDER BY dea.location, dea.date) as TotalNewVaccinationsToDate
FROM PorfolioProject..CovidDeaths as dea
JOIN PorfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY location, date

SELECT *, (TotalNewVaccinationsToDate/Population)*100 as NewlyVaccinatedRate
FROM #NewVaccinationRate

--CREATE VIEW

CREATE VIEW TotalNewVaccinationsToDateView AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location
		ORDER BY dea.location, dea.date) as TotalNewVaccinationsToDate
FROM PorfolioProject..CovidDeaths as dea
JOIN PorfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
