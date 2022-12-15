SELECT *
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent is NOT null

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'COVIDdeaths'

--ALTER TABLE dbo.COVIDdeaths
--ALTER COLUMN total_deaths float


--SELECT *
--FROM dbo.COVIDvaccinations
--order by 3,4


-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent is NOT null
order by 1,2


--Total Cases vs. Total Deaths
--Shows likelihood of dying if contracting COVID in USA

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfolio Project].[dbo].[CovidDeaths]
where location like '%states%' 
AND continent is NOT null
order by 1,2


--Looking at Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 as PopulationPercentageInfected
FROM [Portfolio Project].[dbo].[CovidDeaths]
where location like '%states%'
AND continent is NOT null
order by 1,2


--Looking at Countries with Highest Infection Rate Compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationPercentageInfected
FROM [Portfolio Project].[dbo].[COVIDdeaths]
--where location like '%states%'
--AND continent is NOT null
group by Location, population
order by 4 DESC


--Showing Countries with Highest Death Count Per Population

SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM [Portfolio Project].[dbo].[COVIDdeaths]
--where location like '%states%'
WHERE continent is NOT null
group by Location
order by HighestDeathCount DESC


--Let's break things up by continent


--Showing continents with highest death counts

SELECT continent, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM [Portfolio Project].[dbo].[COVIDdeaths]
--where location like '%states%'
WHERE continent is NOT null
group by continent
order by HighestDeathCount DESC



--Global Numbers

SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project].[dbo].[CovidDeaths]
--where location like '%states%' 
WHERE continent is NOT null
group by date
order by 1,2



--Global Numbers (if you remove the date)

SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project].[dbo].[CovidDeaths]
--where location like '%states%' 
WHERE continent is NOT null
--group by date
order by 1,2



--COVID Vacc table

SELECT *
FROM [Portfolio Project].[dbo].[COVIDvaccinations]




--Join the death and vacc table together

SELECT *
FROM [Portfolio Project].[dbo].[CovidDeaths] dea
JOIN [Portfolio Project].[dbo].[COVIDvaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date




-- Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM [Portfolio Project].[dbo].[CovidDeaths] dea
JOIN [Portfolio Project].[dbo].[COVIDvaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
order by 2,3




-- USE CTE (option 1)

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
--can't have a newly created function beside another newly created function, so create temp table.
FROM [Portfolio Project].[dbo].[CovidDeaths] dea
JOIN [Portfolio Project].[dbo].[COVIDvaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--order by 2,3
--can't have order by in a nested temp table
)

SELECT *,(RollingPeopleVaccinated/population)*100
--here I put the new function on the temp table
FROM PopvsVac




--TEMP TABLE (option 2)

DROP Table if exists #PercentPopulationVaccinated
--Run drop table so every time you execute this, it'll drop the old table and replace with new
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM [Portfolio Project].[dbo].[CovidDeaths] dea
JOIN [Portfolio Project].[dbo].[COVIDvaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--order by 2,3

SELECT *,(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated



--Creating View to store data for later

Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM [Portfolio Project].[dbo].[CovidDeaths] dea
JOIN [Portfolio Project].[dbo].[COVIDvaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--order by 2,3


SELECT *
FROM PercentPopulationVaccinated
