--Below queries are simply to verify that the data tables we are looking to use are in fact populated

select * from CovidProject..covid_deaths;

select * from CovidProject..covid_vaccinations;

-- Looking at total cases vs total deaths (death_rate)

select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as death_rate
from covid_deaths
order by 1, 2


-- Looking at death_rate in the US
-- Shows liklihood of dying if diagnosed w/ Covid

select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as death_rate
from covid_deaths
where location = 'United States'
order by 1, 2

-- Looking at total_cases vs population in the US.
-- Shows percentage of population diagnosed w/ covid

select location, date, total_cases, total_deaths, population, (total_cases / population) * 100 as infection_rate
from covid_deaths
where location = 'United States'
order by 1, 2

-- What countries have the highest infection_rate?

select location, max(total_cases) as current_infection_count, population, max((total_cases / population) * 100) as infection_rate
from covid_deaths
group by location, population
order by infection_rate desc;


-- Looking at countries w/ the highest death_count compared to population

select location, max(cast(total_deaths as int)) as death_count
from covid_deaths
where continent is not null
group by location, population
order by death_count desc;


-- THE NEXT SET OF QUERIES IS TO BREAK THINGS DOWN BY CONTINENT

-- What continents have the highest infection_rate?

select continent, max(total_cases) as current_infection_count, max((total_cases / population) * 100) as infection_rate
from covid_deaths
group by continent
order by infection_rate desc;


-- Looking at continents w/ the highest death_count compared to population

select continent, max(cast(total_deaths as int)) as death_count
from covid_deaths
where continent is not null
group by continent
order by death_count desc;



-- NEXT SET OF QUERIES IS LOOKING AT GLOBAL NUMBERS

-- Looking at global death_rate day by day

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths
from covid_deaths
where continent is not null
group by date
order by 1, 2

select * from covid_deaths

-- Looking at global death_rate overall

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int)) / sum(new_cases)* 100 as death_rate
from covid_deaths
where continent is not null
order by 1, 2

select *
from covid_deaths deaths
join covid_deaths vaccs
on deaths.location = vaccs.location
and deaths.date = vaccs.date


-- Looking at total population vs total vaccinations

select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
sum(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccs_count
from covid_deaths deaths
join covid_vaccinations as vaccs
on deaths.location = vaccs.location
and deaths.date = vaccs.date
where deaths.continent is not null
order by 2, 3

-- USING CTE

with PopvsVaccs (Continent, Location, Date, Population, new_vaccinations, rolling_vaccs_count)
as 
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
sum(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccs_count
from covid_deaths deaths
join covid_vaccinations as vaccs
on deaths.location = vaccs.location
and deaths.date = vaccs.date
where deaths.continent is not null 

)

select *, (rolling_vaccs_count / population) * 100 as percentage_pop_vaccinated
from PopvsVaccs

--Temp Table

drop table if exists PercentPopVaccinated
Create Table PercentPopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccs_count numeric
)

insert into PercentPopVaccinated
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
sum(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccs_count
from covid_deaths deaths
join covid_vaccinations as vaccs
on deaths.location = vaccs.location
and deaths.date = vaccs.date
where deaths.continent is not null 

select *, (rolling_vaccs_count / population) * 100 as percentage_pop_vaccinated
from PercentPopVaccinated



--Creating views for visualization

create view PercentPopulationVaccinated as 
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
sum(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccs_count
from covid_deaths deaths
join covid_vaccinations as vaccs
on deaths.location = vaccs.location
and deaths.date = vaccs.date
where deaths.continent is not null 


create view GlobalDailyDeaths as
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths
from covid_deaths
where continent is not null
group by date

create view DeathTollByCountry as 
select date, location, sum(new_cases) as total_cases, total_deaths
from covid_deaths
where continent is not null
group by date, location, total_deaths


create view VaccsCountByCountryByDay as
select date, location, total_vaccinations
from covid_vaccinations




