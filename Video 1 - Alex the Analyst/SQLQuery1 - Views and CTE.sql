SELECT * 
FROM portfolioproj..coviddeaths
ORDER BY 3,4

-- SELECT DATA WE'RE USING
SELECT Location, date, total_cases, new_cases,  total_deaths, population
FROM portfolioproj..coviddeaths
ORDER BY 1, 2

-- Comparing Total Deaths and Total Cases
-- Shows likelihood of dying of covid per country
SELECT location, date, total_deaths, total_cases, (100 * total_deaths/total_cases) AS "DeathPercentage"
FROM portfolioproj..coviddeaths
WHERE location LIKE '%State%'
ORDER BY 1,2

-- Comparing total cases to the population size per country
-- Shows what percentage of the population got COVID, dead and alive
SELECT location, date, total_cases, population, (100 * total_cases/population) AS "CasePercentage", 
(100 * new_cases / (total_cases - total_deaths)) AS "CurrCasePercentage"
FROM portfolioproj..coviddeaths
WHERE location LIKE '%state%'
ORDER BY 1,2

-- Looking at countries with the highest infection rates
SELECT location, date, total_cases, population, (100 * total_cases/population) AS PercentPopInfected
FROM portfolioproj..coviddeaths
ORDER BY CasePercentage DESC

-- LOoking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((100 * total_cases/population)) AS PercentPopulationInfected
FROM portfolioproj..coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Looking at countries with highest average infection rate compared to population
SELECT location, population, AVG(total_cases) AS AvgInfectionCount, AVG((100 * total_cases/population)) AS AvgPercentPopInfected
FROM portfolioproj..coviddeaths
GROUP BY location, population
ORDER BY 1, 2

-- Countries with the highest death count per population
SELECT location, population, MAX(cast(total_deaths AS int)) AS NumberOfDeaths
FROM portfolioproj..coviddeaths
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY NumberOfDeaths DESC

-- Countries with highest death count per population percentage
SELECT location, population, MAX(total_deaths), MAX((100 * total_deaths/population)) AS PercentPopulationDied
FROM portfolioproj..coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationDied desc

-- Continents with highest death count per population
SELECT continent, MAX(cast(total_deaths AS int)) AS NumberOfDeaths
FROM portfolioproj..coviddeaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY NumberOfDeaths DESC

-- GLOBAL PROBS
SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM portfolioproj..coviddeaths
WHERE continent IS NOT null
ORDER BY DeathPercentage DESC

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths,
(SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage--total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM portfolioproj..coviddeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY TotalCases DESC

-- Compare total population vs total vaccination
-- Use CTE to reference RollingPeopleVaccinated in SELECT without typing out the equation again
WITH PopVsVac  (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
	(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
		-- ,(RollingPeopleVac/population)*100
	FROM portfolioproj..coviddeaths dea
	JOIN portfolioproj..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT null
	--ORDER BY 2,3
	)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPplVaccinatedPercentage
FROM PopVsVac

-- TEMP TABLE
-- Important: Include Drop Table statements
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
			-- ,(RollingPeopleVac/population)*100
		FROM portfolioproj..coviddeaths dea
		JOIN portfolioproj..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
		WHERE dea.continent IS NOT null
		--ORDER BY 2,3
	
SELECT *, 100*(RollingPeopleVaccinated / Population) AS PercentPeopleVaccinated
FROM #PercentPopulationVaccinated

-- Create views for data visualizations
USE portfolioproj

GO

CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
			-- ,(RollingPeopleVac/population)*100
		FROM portfolioproj..coviddeaths dea
		JOIN portfolioproj..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
		WHERE dea.continent IS NOT null
		--ORDER BY 2,3

CREATE VIEW PercentPopulationDeathRate AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated_per_hundred, 
	vac.people_fully_vaccinated, vac.new_vaccinations, vac.total_vaccinations, vac.diabetes_prevalence, 
	vac.cardiovasc_death_rate, vac.median_age, dea.weekly_hosp_admissions, dea.weekly_icu_admissions, 
	sum(CAST(dea.new_cases AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCases, 
	sum(CAST(dea.new_deaths AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingDeaths

	FROM portfolioproj..coviddeaths AS dea
	JOIN portfolioproj..covidvaccinations AS vac ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT null