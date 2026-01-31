/*
 * Projekt: Engeto SQL Project
 * Autor: Patrik Zehle
 * Datum: 2026-01-30
 * Popis: Analýza dostupnosti potravin, vývoje mezd a HDP v ČR.
 */

-- ============================================================================
-- 1. ČÁST: PŘÍPRAVA DAT (DDL)
-- ============================================================================

-- Odstranění tabulek, pokud existují, pro čistý start skriptu
DROP TABLE IF EXISTS t_patrik_zehle_project_SQL_primary_final;
DROP TABLE IF EXISTS t_patrik_zehle_project_SQL_secondary_final;

/*
 * Vytvoření tabulky t_patrik_zehle_project_SQL_primary_final
 * Obsahuje data o mzdách a cenách potravin pro ČR sjednocená podle roků.
 *
 * Poznámka k filtraci NULL:
 * V datech se mohou vyskytovat chybějící hodnoty (NULL), které by mohly zkreslit
 * průměry. Proto je vhodné data filtrovat, případně JOIN zajistí,
 * že se spojí jen ty roky, které existují v obou sadách.
 */
CREATE TABLE t_patrik_zehle_project_SQL_primary_final AS
SELECT
    pay.payroll_year,
    pay.industry_branch_code,
    pay.industry_name,
    pay.avg_wage,
    price.category_code,
    price.category_name,
    price.avg_price
FROM (
    SELECT
        pl.payroll_year,
        pl.industry_branch_code,
        ib.name AS industry_name,
        -- Převedení na numeric pro přesné zaokrouhlení na 2 desetinná místa
        ROUND(AVG(pl.value)::numeric, 2) AS avg_wage
    FROM czechia_payroll pl
    JOIN czechia_payroll_industry_branch ib ON pl.industry_branch_code = ib.code
    WHERE pl.value_type_code = 5958 
      AND pl.calculation_code = 100
      AND pl.value IS NOT NULL -- Eliminace případných chybějících hodnot mezd
    GROUP BY pl.payroll_year, pl.industry_branch_code, ib.name
) pay
JOIN (
    SELECT
        EXTRACT(YEAR FROM date_from)::int AS price_year,
        category_code,
        cpc.name AS category_name,
        -- Konzistentní zaokrouhlování na 2 desetinná místa
        ROUND(AVG(value)::numeric, 2) AS avg_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
    WHERE value IS NOT NULL -- Eliminace chybějících cen
    GROUP BY EXTRACT(YEAR FROM date_from), category_code, cpc.name
) price
    ON pay.payroll_year = price.price_year;


/*
 * Vytvoření tabulky t_patrik_zehle_project_SQL_secondary_final
 * Obsahuje makroekonomická data (HDP, Gini, populace) pro evropské státy.
 */
CREATE TABLE t_patrik_zehle_project_SQL_secondary_final AS
SELECT
    c.country,
    c.continent,
    e.year,
    e.GDP,
    e.gini,
    e.population
FROM economies e
JOIN countries c ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN 2006 AND 2018
  AND e.GDP IS NOT NULL -- Pro analýzu HDP potřebujeme jen záznamy, kde je HDP vyplněno
ORDER BY c.country, e.year;


-- ============================================================================
-- 2. ČÁST: ANALYTICKÉ DOTAZY (DQL)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ÚKOL 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- ----------------------------------------------------------------------------
SELECT
    industry_name,
    payroll_year,
    avg_wage,
    LAG(avg_wage) OVER (PARTITION BY industry_name ORDER BY payroll_year) AS prev_year_wage,
    avg_wage - LAG(avg_wage) OVER (PARTITION BY industry_name ORDER BY payroll_year) AS difference
FROM t_patrik_zehle_project_SQL_primary_final
ORDER BY difference ASC;


-- ----------------------------------------------------------------------------
-- ÚKOL 2: Kolik je možné si koupit litrů mléka a kilogramů chleba 
-- za první a poslední srovnatelné období?
-- ----------------------------------------------------------------------------
SELECT
    category_name,
    payroll_year,
    ROUND(AVG(avg_wage)::numeric, 2) AS global_avg_wage,
    avg_price,
    -- Výpočet kupní síly (mzda / cena)
    ROUND((AVG(avg_wage) / avg_price)::numeric, 0) AS amount_to_buy
FROM t_patrik_zehle_project_SQL_primary_final
WHERE category_name IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
  AND payroll_year IN (2006, 2018)
GROUP BY category_name, payroll_year, avg_price
ORDER BY category_name, payroll_year;


-- ----------------------------------------------------------------------------
-- ÚKOL 3: Která kategorie potravin zdražuje nejpomaleji 
-- (je u ní nejnižší percentuální meziroční nárůst)?
-- ----------------------------------------------------------------------------
WITH price_change AS (
    SELECT
        category_name,
        avg_price,
        payroll_year
    FROM t_patrik_zehle_project_SQL_primary_final
    WHERE payroll_year IN (2006, 2018)
    GROUP BY category_name, payroll_year, avg_price
)
SELECT
    a.category_name,
    a.avg_price AS price_2006,
    b.avg_price AS price_2018,
    -- Výpočet procentuálního nárůstu: ((nová - stará) / stará) * 100
    ROUND(((b.avg_price - a.avg_price) / a.avg_price * 100)::numeric, 2) AS price_increase_percent
FROM price_change a
JOIN price_change b ON a.category_name = b.category_name
WHERE a.payroll_year = 2006 AND b.payroll_year = 2018
ORDER BY price_increase_percent ASC;


-- ----------------------------------------------------------------------------
-- ÚKOL 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin 
-- výrazně vyšší než růst mezd (větší než 10 %)?
-- ----------------------------------------------------------------------------
WITH totals AS (
    SELECT
        payroll_year,
        ROUND(AVG(avg_wage)::numeric, 2) AS total_avg_wage,
        ROUND(AVG(avg_price)::numeric, 2) AS total_avg_price
    FROM t_patrik_zehle_project_SQL_primary_final
    GROUP BY payroll_year
),
growth AS (
    SELECT
        payroll_year,
        total_avg_wage,
        LAG(total_avg_wage) OVER (ORDER BY payroll_year) AS prev_wage,
        total_avg_price,
        LAG(total_avg_price) OVER (ORDER BY payroll_year) AS prev_price
    FROM totals
)
SELECT
    payroll_year,
    -- Procentuální růst mezd
    ROUND(((total_avg_wage - prev_wage) / prev_wage * 100)::numeric, 2) AS wage_growth_pct,
    -- Procentuální růst cen
    ROUND(((total_avg_price - prev_price) / prev_price * 100)::numeric, 2) AS price_growth_pct,
    -- Rozdíl (Ceny % - Mzdy %)
    ROUND(((total_avg_price - prev_price) / prev_price * 100)::numeric, 2) -
    ROUND(((total_avg_wage - prev_wage) / prev_wage * 100)::numeric, 2) AS difference_points
FROM growth
WHERE prev_wage IS NOT NULL
ORDER BY difference_points DESC;


-- ----------------------------------------------------------------------------
-- ÚKOL 5: Má výška HDP vliv na změny ve mzdách a cenách potravin?
-- ----------------------------------------------------------------------------
WITH cz_gdp AS (
    SELECT
        year,
        GDP,
        LAG(GDP) OVER (ORDER BY year) AS prev_gdp
    FROM t_patrik_zehle_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
),
totals AS (
    SELECT
        payroll_year,
        AVG(avg_wage) AS total_avg_wage,
        AVG(avg_price) AS total_avg_price
    FROM t_patrik_zehle_project_SQL_primary_final
    GROUP BY payroll_year
)
SELECT
    t.payroll_year,
    ROUND(((g.GDP - g.prev_gdp) / g.prev_gdp * 100)::numeric, 2) AS gdp_growth_pct,
    ROUND(((t.total_avg_wage - LAG(t.total_avg_wage) OVER (ORDER BY t.payroll_year)) / LAG(t.total_avg_wage) OVER (ORDER BY t.payroll_year) * 100)::numeric, 2) AS wage_growth_pct,
    ROUND(((t.total_avg_price - LAG(t.total_avg_price) OVER (ORDER BY t.payroll_year)) / LAG(t.total_avg_price) OVER (ORDER BY t.payroll_year) * 100)::numeric, 2) AS price_growth_pct
FROM totals t
JOIN cz_gdp g ON t.payroll_year = g.year
ORDER BY t.payroll_year;
