use portfolio1;

select * from coviddeath
order by date;

select continent
from coviddeath
Group by continent;
/* Continent contain empty spaces . to insert null values*/

UPDATE coviddeath
SET continent = null
where continent = '';

/* some continent contains empty spaces and are 
fixed in the location column i.e. the location assigned to the empty continent 
 is filled with the continent name this skew the result. 
 Hence we include (where continent is not null) for accuracy*/

select location,population, date, total_cases, new_cases, total_deaths
from coviddeath
order by 1,3;

/* total_cases vs total_deaths- liklihood of dying if you contact covid*/
select location,population, date, total_cases, total_deaths, ((total_deaths / total_cases) * 100) as 'Death Percentage'
from coviddeath
order by 1,3;

select location,population, date, total_cases, total_deaths, ((total_deaths / total_cases) * 100) as deathPercentage
from coviddeath
where location like ('%states%')
order by 1,3;

select location,population, date, total_cases, total_deaths, ((total_deaths / total_cases) * 100) as deathPercentage
from coviddeath
where location = 'canada'
order by 1,3;

/*Total_cases vs Population*/
/* % of population that has got covid i.e. percentage infected*/

select location,population, date, total_cases, ((total_cases / population) * 100) as Percentageinfected
from coviddeath
where continent is not null
order by 1,3;

select location,population, date, total_cases, ((total_cases / population) * 100) as Percentageinfected
from coviddeath
where location = 'canada' and continent is not null
order by 1,3;

/*Countries with highest infection rate compared to population*/
select location,population, max(total_cases) as highestCases,  (max(total_cases / population) * 100) as percentagePopulationInfected
from coviddeath
where continent is not null
Group by location, population
order by percentagePopulationInfected desc;

/* countries with the highest deathcount per population*/

select location,population, max(total_deaths) as TotalDeaths, (max(total_deaths/ population) * 100) as PercentagePopulationDeath
from coviddeath
where continent is not null
Group by location, population
order by percentagePopulationDeaths, totalDeaths desc;

select location,population, max(total_deaths) as totalDeaths
from coviddeath
where continent is not null
Group by location, population
order by totalDeaths desc; /* this does not give accurate result because of the 
							data type of Total deaths  is in text*/

/* to convert the datatype of total_deaths from text to integer*/

select location,population, max(cast(total_deaths as unsigned)) as totalDeaths 
/* 'as int' didn't work used 'as unsigned*/
from coviddeath
where continent is not null 
Group by location, population
order by totalDeaths desc;

/* looking into continent*/
/*continent with highest death count*/
select continent, max(cast(total_deaths as unsigned)) as totalDeaths
from coviddeath
where continent is not null 
Group by continent
order by totalDeaths desc;

/* Global numbers*/

select  date, sum(new_cases) as totalnew_cases, sum(cast(new_deaths as unsigned)) as totalnew_deaths, (sum(new_deaths)/sum(new_cases)*100) as deathPercent
from coviddeath
where continent is not null
Group by date
order by 1, 2;

/* dath percent over the world*/
select  sum(new_cases) as totalnew_cases, sum(cast(new_deaths as unsigned)) as totalnew_deaths, (sum(new_deaths)/sum(new_cases)*100) as deathPercent
from coviddeath
where continent is not null
/*Group by date*/
order by 1, 2;

/*covid Vaccination*/

SELECT 
    *
FROM
    covidvaccination;

/*Joins*/

Select * From coviddeath death
join covidvaccination vac
 on death.location = vac.location
 and
 death.date = vac.date;
 
 /* total population vs vacination*/

Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
From coviddeath death
join covidvaccination vac
 on death.location = vac.location
 and
 death.date = vac.date
 where death.continent is not null
 order by 1,2,3;
 
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVaccinnated
/* rollingPeople vaccinated gives the total population per country vaccinated*/
From coviddeath death
join covidvaccination vac
 on death.location = vac.location
 and
 death.date = vac.date
 where death.continent is not null
 order by 2,3;
 
 /* Percentage vaccinated per country poputation using the 
 ((max of Rolling People Vaccinated)/Population * 100)*/
 /* using CTE*/

WITH PopulationvsVaccination(continent, location, date,population,new_vaccination, RollingPeopleVaccinated)  As
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVaccinnated
From coviddeath death
join covidvaccination vac
on death.location = vac.location
and
death.date = vac.date
where death.continent is not null)
Select*, (RollingPeopleVaccinated/population) * 100 As percentVaccinatedPopulation
from PopulationvsVaccination;

/*Highest vaccinated continent*/

WITH PopulationvsVaccination(continent, location, date,population,new_vaccination, RollingPeopleVaccinated)  As
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVaccinnated
From coviddeath death
join covidvaccination vac
on death.location = vac.location
and
death.date = vac.date
where death.continent is not null)
Select continent,population,RollingPeopleVaccinated, max(RollingPeopleVaccinated) As MaximumVaccinatedPopulation
from PopulationvsVaccination
where continent is not null
Group by continent
order by max(RollingPeopleVaccinated) desc;

 
 /* Temp Table*/
 
Drop temporary table if exists PercentagePopulationVaccinated;

 CREATE temporary table PercentagePopulationVaccinated
 (continent varchar(255), 
 location varchar(255),
 Date datetime,
 population numeric,
 new_vaccination numeric,
 RollingPeopleVaccinated int
 ); 
insert ignore into PercentagePopulationVaccinated
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVaccinnated
From coviddeath death
join covidvaccination vac
on death.location = vac.location
and
death.date = vac.date
where death.continent is not null);

Select*, (RollingPeopleVaccinated/Population * 100) 
 from PercentagePopulationVaccinated;

/*CREATE VIEWS TO STORE DATA FOR VISUALIZATION*/

Create view HighestVaccinatedContinent as
WITH PopulationvsVaccination(continent, location, date,population,new_vaccination, RollingPeopleVaccinated)  As
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVaccinnated
From coviddeath death
join covidvaccination vac
on death.location = vac.location
and
death.date = vac.date
where death.continent is not null)
Select continent,population,RollingPeopleVaccinated, max(RollingPeopleVaccinated) As MaximumVaccinatedPopulation
from PopulationvsVaccination
where continent is not null
Group by continent
order by max(RollingPeopleVaccinated) desc;

Select*From HighestVaccinatedContinent;


CREATE VIEW RollingPeopleVaccinated As
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER 
(Partition by death.location order by death.location, death.date) as RollingPeopleVacinnated
/* rollingPeople vaccinated gives the total population per country vaccinated*/
From coviddeath death
join covidvaccination vac
 on death.location = vac.location
 and
 death.date = vac.date
 where death.continent is not null
 order by 2,3;
 
 Select*From RollingPeopleVaccinated;