
# Layoffs Data Exploratory Data Analysis (EDA)

## Overview
This project focuses on the analysis of a dataset related to layoffs, aiming to explore trends, patterns, and insights through Exploratory Data Analysis (EDA). The raw data was cleaned and processed using SQL to ensure accuracy and reliability.

## Data Cleaning Process
The following steps were undertaken to clean and prepare the dataset:

### 1. Data Structuring
- **Created a staging table (`layoffs_staging`)** to store data temporarily for processing and cleaning.
  ```sql
  CREATE TABLE `world_layoffs`.`layoffs_staging` (
      `company` TEXT,
      `location` TEXT,
      `industry` TEXT,
      `total_laid_off` INT,
      `percentage_laid_off` TEXT,
      `date` TEXT,
      `stage` TEXT,
      `country` TEXT,
      `funds_raised_millions` INT,
      `row_num` INT
  );
  ```

### 2. Duplicate Handling
- **Added row numbers** to each row, partitioning by multiple fields to identify duplicate entries.
  ```sql
  INSERT INTO layoffs_staging
  SELECT `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`,
         ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
  FROM layoffs;
  ```

- **Removed duplicates**, keeping only the first occurrence in each group.
  ```sql
  DELETE FROM world_layoffs.layoffs_staging WHERE row_num >= 2;
  ```

### 3. Standardizing Data
- **Standardized industry values**, ensuring all variations starting with 'Crypto' were updated to 'Crypto'.
  ```sql
  UPDATE layoffs_staging
  SET industry = 'Crypto'
  WHERE industry LIKE 'Crypto%';
  ```

- **Removed trailing periods** from the `country` column to maintain consistency.
  ```sql
  UPDATE layoffs_staging
  SET country = TRIM(TRAILING '.' FROM country);
  ```

### 4. Handling Missing Values
- **Detected null or blank values** in the `industry` column.
  ```sql
  SELECT * FROM world_layoffs.layoffs_staging WHERE industry IS NULL OR industry = '';
  ```

- **Imputed missing `industry` values** by filling them in based on the same company’s existing non-null records.
  ```sql
  UPDATE layoffs_staging t1
  JOIN layoffs_staging t2 ON t1.company = t2.company
  SET t1.industry = t2.industry
  WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
  ```

### 5. Date Standardization
- **Converted `date` values** from text format (`MM/DD/YYYY`) to a proper date format.
  ```sql
  UPDATE layoffs_staging
  SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
  ```

- **Enforced proper date format** by altering the data type of the `date` column.
  ```sql
  ALTER TABLE layoffs_staging MODIFY COLUMN `date` DATE;
  ```

---

## Post-Cleaning: Stored Procedures for Analysis

After cleaning the data, we created several stored procedures to analyze layoffs data by company and industry.

### 1. Top 10 Companies by Layoffs
- **Procedure: `top_5`**  
Returns the top 10 companies with the most layoffs for a specified year.
  ```sql
  CREATE PROCEDURE top_5 (IN input_year YEAR)
  BEGIN
      SELECT company, industry, SUM(total_laid_off)
      FROM layoffs_staging
      WHERE YEAR(`date`) = input_year 
      GROUP BY company, industry
      ORDER BY SUM(total_laid_off) DESC
      LIMIT 10;
  END $$

  CALL top_5(2020);
  ```
  Purpose: Helps analyze the largest layoffs by company and industry for a given year.

### 2. Layoffs by Industry
- **Procedure: `top_industries`**  
Returns total layoffs per industry for a specified year.
  ```sql
  CREATE PROCEDURE top_industries (IN yeardate YEAR)
  BEGIN
      SELECT industry, SUM(total_laid_off) AS total_laid_off_sum
      FROM layoffs_staging
      WHERE YEAR(`date`) = yeardate
      GROUP BY industry
      ORDER BY total_laid_off_sum DESC;
  END $$

  CALL top_industries(2023);
  ```
  Purpose: Understand which industries were hit hardest by layoffs for a particular year.

### 3. Ranking Companies by Layoffs
- **Procedure: `top_ranks`**  
Returns companies ranked by total layoffs within each year, based on a specified rank.
  ```sql
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

  CALL top_ranks(3);
  ```
  Purpose: Provides ranked data on layoffs for companies, helping to identify companies with high layoffs for a specified rank.

---

## Conclusion
The dataset was successfully cleaned and processed, ensuring data quality and consistency for further analysis. Stored procedures were created to allow detailed insights into company and industry layoffs, based on specified parameters such as year and rank.
