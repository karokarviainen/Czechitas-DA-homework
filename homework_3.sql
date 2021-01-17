SELECT * FROM NETFLIX_IMDB_POM;


/*
Vaším úkolem bude vytvořit novou finální tabulku (CREATE TABLE), 
ve které nebudou duplicity a ve které budou dva nové sloupce (netflix_date_added, movie_duration_min). 
Můžete vše udělat v jednom kroku nebo si to rozdělit na více kroků. 
Použijte postup, který vám nejvíce vyhovuje (vytváření pomocných tabulek, vnořené selecty, destruktivní príkazy...)

1. duplicity: Zkontrolujte duplicity pomocí sloupců title, release_year, type. 
Co podle vás duplicity způsobilo? Rozhodněte, jaké řádky chcete ponechat a jaké byste smazaly. 
Vymažte duplicity pomocí ROW_NUMBER().

2. netflix_date_added: Ze sloupečku date_added vytvořte nový sloupeček netflix_date_added, 
ve kterém bude datum ve Snowflake formátu (=bude mít datový typ datum). 
Napovím, že se vám bude hodit funkce TRIM().

3. movie_duration_min: Vytvořte nový sloupeček movie_duration_min, 
do kterého vložíte číselnou hodnotu ze sloupce duration - pozor pouze pro typ Movie 
(u TV Show bude null hodnota, použijte CASE WHEN). 
Vzpomeňte si na první sobotu (lekce 2 na selektuju.cz) a na funkci SPLIT_PART(). 
Nezapomeňte převést na číslo (pomocí funkce CAST(nazev_sloupce as int) nebo nazev_sloupce::int).
*/

------------------------


-- Zkontroluju duplicity na zaklade sloupcu title, release_year, type
/*
SELECT title, release_year, type, COUNT(*) AS pocet
FROM NETFLIX_IMDB_POM
GROUP BY title, release_year, type
HAVING pocet > 1
ORDER BY pocet DESC; -- Vidim, ze 5 zaznamu se opakuje --> vymazu je tak, aby mi kazdy zustal jenom jednou (v dalsim kroku)
*/

-- 1. Duplicity: pouziju filtraci QUALIFY a vyfiltruju si zaznamy, ktere se vyskytuji jenom jednou 
-- (druhe vyskyty uz v tabulce NETFLIX_IMDB_POM_COPY mit nebudu)
CREATE TABLE NETFLIX_IMDB_POM_COPY AS
SELECT *
    , ROW_NUMBER() OVER (PARTITION BY title, release_year, type ORDER BY title, release_year, type) AS row_num
FROM NETFLIX_IMDB_POM
QUALIFY row_num = 1;



-- 2. Datum: nazvy mesicu prevedu na cisla, vytvorim si tri pomocne sloupecky (rok, mesic, den)
CREATE OR REPLACE TABLE NETFLIX_IMDB_POM_COPY AS
SELECT *
    , RIGHT(TRIM(DATE_ADDED), 4) AS YEAR_ADDED
    , CASE WHEN TRIM(DATE_ADDED) LIKE 'January%' THEN 01
           WHEN TRIM(DATE_ADDED) LIKE 'February%' THEN 02
           WHEN TRIM(DATE_ADDED) LIKE 'March%' THEN 03
           WHEN TRIM(DATE_ADDED) LIKE 'April%' THEN 04
           WHEN TRIM(DATE_ADDED) LIKE 'May%' THEN 05
           WHEN TRIM(DATE_ADDED) LIKE 'June%' THEN 06
           WHEN TRIM(DATE_ADDED) LIKE 'July%' THEN 07
           WHEN TRIM(DATE_ADDED) LIKE 'August%' THEN 08
           WHEN TRIM(DATE_ADDED) LIKE 'September%' THEN 09
           WHEN TRIM(DATE_ADDED) LIKE 'October%' THEN 10
           WHEN TRIM(DATE_ADDED) LIKE 'November%' THEN 11
           WHEN TRIM(DATE_ADDED) LIKE 'December%' THEN 12
    END AS MONTH_ADDED
    , SPLIT_PART(SPLIT_PART(TRIM(DATE_ADDED), ',', 1), ' ', 2) AS DAY_ADDED
    FROM NETFLIX_IMDB_POM_COPY;
    
-- Spojim udaje z pomocnych sloupecku a vytvorim tim sloupec netflix_date_added
CREATE OR REPLACE TABLE NETFLIX_IMDB_POM_COPY AS
SELECT * 
    , DATE_FROM_PARTS(YEAR_ADDED, MONTH_ADDED, DAY_ADDED) AS netflix_date_added
FROM NETFLIX_IMDB_POM_COPY;
    


-- 3. Doba trvani: Vytvorim sloupec s dobou trvani, zatim jako varchar
CREATE OR REPLACE TABLE NETFLIX_IMDB_POM_COPY AS
SELECT *
    , CASE WHEN TYPE = 'Movie' THEN SPLIT_PART(DURATION, ' ', 1)
           WHEN TYPE = 'TV Show' THEN NULL
    END AS movie_dur_min
FROM NETFLIX_IMDB_POM_COPY;


-- Vytvorim sloupec, kde bude trvani prevedene na cislo:
CREATE OR REPLACE TABLE NETFLIX_IMDB_POM_COPY AS
SELECT *, CAST(movie_dur_min as int) AS movie_duration_min FROM NETFLIX_IMDB_POM_COPY;


-- Odstranim vsechny pomocne sloupce z prehchozich kroku:
ALTER TABLE NETFLIX_IMDB_POM_COPY DROP COLUMN ROW_NUM, YEAR_ADDED, MONTH_ADDED, DAY_ADDED, MOVIE_DUR_MIN;
