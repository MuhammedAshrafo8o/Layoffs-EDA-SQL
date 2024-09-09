-- 1. Create the `layoffs_staging` table with the specified columns.
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
    row_num INT
);
-- Type: Data Structuring
-- Description: Creating a table to store data temporarily for processing and cleaning.

-- 2. Insert data into `layoffs_staging`, adding a row number for each row using the `ROW_NUMBER()` function.
INSERT INTO layoffs_staging
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
       `location`,
       `industry`,
       `total_laid_off`,
       `percentage_laid_off`,
       `date`,
       `stage`,
       `country`,
       `funds_raised_millions`,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs;
-- Type: De-duplication
-- Description: Adds row numbers to the data based on partitioning by company and other fields. This helps in identifying duplicate rows later.

-- 3. Select rows where the row number is greater than 1 (indicating potential duplicates).
SELECT * FROM layoffs_staging WHERE row_num > 1;
-- Type: Duplicate Detection
-- Description: This query fetches rows that are considered duplicates based on the `ROW_NUMBER()` function.

-- 4. Delete rows where `row_num` is 2 or higher (removing duplicates).
DELETE FROM world_layoffs.layoffs_staging WHERE row_num >= 2;
-- Type: Duplicate Removal
-- Description: Deletes duplicate rows, keeping only the first occurrence of each group of duplicates.

-- 5. Select distinct industries to get a clean list of industries without duplicates.
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging
ORDER BY industry;
-- Type: Standardization
-- Description: This query retrieves a unique list of industries, ordered alphabetically.

-- 6. Select rows where the `industry` is either `NULL` or blank.
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL  
OR industry = ''
ORDER BY industry;
-- Type: Null/Blank Detection
-- Description: Identifies rows where the `industry` column is either `NULL` or an empty string.

-- 7. Update the `industry` column, setting it to `NULL` where it is an empty string.
UPDATE layoffs_staging 
SET industry = NULL 
WHERE industry = '';
-- Type: Standardization (Null Handling)
-- Description: Converts blank `industry` values into `NULL` for consistency.

-- 8. Update rows where the `industry` is `NULL` by filling in missing `industry` values from matching records with the same `company` but a non-null `industry`.
UPDATE layoffs_staging t1
JOIN layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
-- Type: Missing Data Imputation
-- Description: Fills missing `industry` values based on other records from the same company.

-- 9. Select all rows for the company 'Airbnb' to verify the cleaning process.
SELECT * FROM layoffs_staging WHERE company = 'Airbnb';
-- Type: Data Verification
-- Description: This query checks if the cleaning and updates have worked as expected for a specific company.

-- 10. Standardize `industry` values by ensuring that all values starting with 'Crypto' are updated to exactly 'Crypto'.
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
-- Type: Standardization (Normalization)
-- Description: Ensures that variations of the industry starting with 'Crypto' are standardized to 'Crypto'.

-- 11. Trim trailing periods (.) from the `country` column.
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);
-- Type: Cleaning (Whitespace/Formatting)
-- Description: Removes unnecessary trailing periods from country names to maintain consistency.

-- 12. Update the `date` column by converting it from a string in 'MM/DD/YYYY' format to a proper date format using `STR_TO_DATE`.
UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
-- Type: Data Type Conversion (Date Parsing)
-- Description: Converts the `date` column from a string format to an actual `DATE` type for better handling of date operations.

-- 13. Modify the `date` column's data type to `DATE` to ensure consistency.
ALTER TABLE layoffs_staging MODIFY COLUMN `date` DATE;
-- Type: Data Type Enforcement
-- Description: Changes the column type to `DATE` to ensure proper storage and handling of date values.
