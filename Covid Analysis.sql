--Global Covid position to date
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
order by 1,2;

-- disease positivity count sorted by countries having the highest positive to date
Select location, population, MAX(total_cases) positivetodate
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location,population
order by positivetodate desc;

-- disease positivity count and positivity % in population sorted by countries having the highest positivity % in population to date
Select location, population, MAX(total_cases) positivetodate,(max(total_cases)/population)*100 perecentpopinfected
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location,population
order by perecentpopinfected desc;

-- disease death count sorted by countries having the highest deaths to date
select location, population, MAX(cast(Total_deaths as int)) totaldeathcount
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location,population
order by totaldeathcount desc;

-- disease death count and death percentage in population sorted by countries having the highest death percentage to date
select location, population, MAX(cast(Total_deaths as int)) totaldeathcount, (MAX(cast(Total_deaths as int))/population)*100 deathpercentage
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location,population
order by deathpercentage desc;

--likelihood of dying after contracting covid
select location,population, max(total_cases) totalpositive, max(total_deaths) totaldeaths, (max(total_deaths)/MAX(total_cases))*100 deathpercent
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location, population
order by deathpercent desc;

--positivity ratio for past 7 days in each country
With xyz as
(select location, date, sum(new_cases) over (partition by location order by date rows between 7 preceding and current row) cases_7daystotal,
sum(cast(new_tests as int)) over (partition by location order by date rows between 7 preceding and current row) tests_7daystotal
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null)

select *,(cases_7daystotal/tests_7daystotal)*100 positivity_ratio
from xyz

--highest positivity ratio all times globally
select location,sum(new_cases)total_cases, sum(cast(new_tests as int))total_test,(sum(new_cases)/sum(cast(new_tests as int)))*100 positivity_ratio
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location
order by positivity_ratio desc

--correlation between test per case and positivity ratio
with abc as (select (cast(new_tests as int)/nullif(new_cases,0))testspercase,(new_cases/nullif(cast(new_tests as int),0))positivity_ratio
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null)

SELECT (Avg(testspercase * positivity_ratio) - (Avg(testspercase) * Avg(positivity_ratio))) / (StDevP(testspercase) * StDevP(positivity_ratio)) Pearsons_r
from abc

--cumulative vaccination count date wise in each country
select location, date, population, SUM(cast(new_vaccinations as int)) over (partition by location order by date) cummulative_vaccination
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
order by cummulative_vaccination desc;

--perecent population vaccinated date wise in each country
select *,(cummulative_vaccination/population)*100 percent_population_vaccinated
from (select location, date, population, SUM(cast(new_vaccinations as int)) over (partition by location order by date) cummulative_vaccination
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null) sub

--Correlation between reproduction rate and vaccination 
with reproduction_vaccination as 
(select CAST(reproduction_rate as float) reproduction, cast(new_vaccinations as bigint) vaccination
From [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null)

select(Avg(reproduction * vaccination) - (Avg(reproduction) * Avg(vaccination))) / (StDevP(reproduction) * StDevP(vaccination)) Pearsons_r
from reproduction_vaccination

--Comparison of positivity ratio and avg reproduction rate in group of countries doing vaccine booster shots and those not
select (sum(new_cases)/sum(cast(new_tests as int)))*100 positivity_ratio,AVG(cast(reproduction_rate as float)) avg_reproduction,case when total_boosters is null then 'no booster'
else 'booster' end booster_state
from [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by case when total_boosters is null then 'no booster'
else 'booster' end

--Positivity ratio and icu admission in total hospitalisation ratio in countries 
select location,(sum(new_cases)/sum(cast(new_tests as int)))*100 positivity_ratio,(sum(cast(icu_patients as int))/nullif(sum(cast(hosp_patients as int)),0))*100 icupatients_ratio
from [Covid Analaysis].dbo.['owid-covid-data$']
where continent is not null
group by location
order by icupatients_ratio desc

