-- 1. Changing the delimiter to `$$` to define the stored procedures.
DELIMITER $$

-- 2. Stored procedure `top_5`: Returns the top 10 companies with the most layoffs for a specified year.
CREATE PROCEDURE top_5 (IN input_year YEAR)
BEGIN
    SELECT company, industry, SUM(total_laid_off)
    FROM layoffs_staging
    WHERE YEAR(`date`) = input_year 
    GROUP BY company, industry
    ORDER BY SUM(total_laid_off) DESC
    LIMIT 10;
END $$
-- Purpose: Helps analyze the largest layoffs by company and industry for a given year, providing insight into which companies were most affected.

-- 3. Execute `top_5` for the year 2020.
CALL top_5 (2020);
-- Executes the procedure for 2020 to get the top 10 companies with the most layoffs.

-- 4. Stored procedure `top_industries`: Returns total layoffs per industry for a specified year, ordered by total layoffs.
CREATE PROCEDURE top_industries (IN yeardate YEAR)
BEGIN
    SELECT industry, SUM(total_laid_off) AS total_laid_off_sum
    FROM layoffs_staging
    WHERE YEAR(`date`) = yeardate
    GROUP BY industry
    ORDER BY total_laid_off_sum DESC;
END $$
-- Purpose: Helps understand which industries were hit hardest by layoffs for a particular year, aiding in industry-specific analysis.

-- 5. Execute `top_industries` for the year 2023.
CALL top_industries(2023);
-- Retrieves industries with the highest layoffs in 2023.

-- 6. Stored procedure `top_ranks`: Returns companies ranked by total layoffs within each year, based on a specified rank.
CREATE PROCEDURE top_ranks (IN ranks INT)
BEGIN
    WITH cte_ranking AS (
        SELECT company, industry, YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off_sum,
               DENSE_RANK() OVER (PARTITION BY YEAR(`date`) ORDER BY SUM(total_laid_off) DESC) AS ranking
        FROM layoffs_staging
        GROUP BY company, industry, YEAR(`date`)
    )
    SELECT company, industry, year, total_laid_off_sum, ranking
    FROM cte_ranking
    WHERE ranking = ranks AND year IS NOT NULL
    ORDER BY total_laid_off_sum DESC;
END $$
-- Purpose: Provides ranked data on layoffs for companies, helping to identify companies with high layoffs for a specified rank.

-- 7. Execute `top_ranks` to retrieve the 3rd-ranked companies by layoffs.
CALL top_ranks(3);
-- Retrieves companies ranked 3rd for layoffs for each year.

-- 8. Resetting the delimiter back to default.
DELIMITER ;
