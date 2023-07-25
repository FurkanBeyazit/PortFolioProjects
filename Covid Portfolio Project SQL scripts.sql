select *
From PortfolioProject..CovidDeaths order by 3,4
--select *
--From PortfolioProject..CovidVaccinations order by 3,4

**--select data that we are going to use**
select location,date,total_cases,new_cases,total_deaths,population from PortfolioProject..CovidDeaths order by 1,2

--Looking at Total Cases vs Total Deaths 

select location,date,total_cases,total_deaths, (total_deaths / total_cases)*100 as DeathPercentage 
from PortfolioProject..CovidDeaths where location like '%Turkey%' order by 1,2

--Lokking at Total Cases vs Population

select location,date,population,total_cases, (total_deaths / population)*100 as PositivePercentage 
from PortfolioProject..CovidDeaths where location like '%Turkey%' order by 1,2

select location,population,max(total_cases) as HighestCases, Max((total_cases/population))*100 as PercentageInfected
from PortfolioProject..CovidDeaths
Group by location,population
order  by PercentageInfected desc

-- Showing Countries with Highest Death Count 

select location,max(total_deaths) as TotalDeath 
from PortfolioProject..CovidDeaths
where continent is not null
Group by location
order  by TotalDeath desc


-- BY Continent location is null also more accurate

select continent,max(total_deaths) as TotalDeath 
from PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order  by TotalDeath desc


--GLOBAL  NUMBERS


SELECT date, 
       SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths, 
       (SUM(new_deaths) * 100.0) / NULLIF(SUM(new_cases), 0) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY DeathPercentage desc

--GLOBAL Sum

SELECT  
       SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths, 
       (SUM(new_deaths) * 100.0) / NULLIF(SUM(new_cases), 0) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 

ORDER BY DeathPercentage desc

-- JOIN two tables


Select * 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac 
on dea.location =vac.location
and dea.date = vac.date

--looking at total population vs vaccinations

select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location ,dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 
on dea.location =vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--FINDINg Population vs Vaccination Using CTE

with PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated) as 
(
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location ,dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 

	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * ,(RollingPeopleVaccinated/population)*100
from PopvsVac



--TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

insert into #PercentPopulationVaccinated
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location ,dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 

	on dea.location =vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
select * ,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--Creating view to store data for later visulazations

Create View PercentPopulationVaccinated as 
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location ,dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 

	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select *
From PercentPopulationVaccinated
