/* 
1)
Vypište vývoj po dnech v roce 2014 v zemích Iraq a Somalia, tabulka by měla obsahovat počet útoků, počet zabitých obětí, 
počet zabitých teroristů a počet zraněných na daný den a danou zemi. Omezte výsledek pouze na dny, kdy bylo v dané zemi provedeno alespoň 5 útoků.
*/

SELECT
     country_txt
    ,DATE_FROM_PARTS(iyear, imonth, iday) AS datum
    ,COUNT(DISTINCT eventid) AS pocet_utoku
    ,SUM(nkill) AS pocet_zabitych
    ,SUM(nkillter) AS pocet_zabitych_teroristu
    ,SUM(nwound) AS pocet_zranenych
FROM teror
WHERE country_txt IN ('Iraq', 'Somalia') AND iyear = 2014
GROUP BY country_txt, datum
HAVING pocet_utoku >= 5
ORDER BY country_txt, datum;



/*
2)
Vypočítejte vzdálenost útoků od Prahy (latitude = 50.0755, longitude = 14.4378) a tuto hodnotu kategorizujte a spočítejte počty útoků. 
Kategorie: '0-99 km', '100-499 km', '500-999 km', '1000+ km', 'exact location unknown'. Seřaďte podle počtu útoků sestupně. 
*/

SELECT 
    CASE WHEN ROUND(HAVERSINE(50.0755, 14.4378, latitude, longitude)) < 100 THEN '0-99 km'
         WHEN ROUND(HAVERSINE(50.0755, 14.4378, latitude, longitude)) < 500 THEN '100-499 km'
         WHEN ROUND(HAVERSINE(50.0755, 14.4378, latitude, longitude)) < 1000 THEN '500-999 km'
         WHEN ROUND(HAVERSINE(50.0755, 14.4378, latitude, longitude)) >= 1000 THEN '1000+ km'
         ELSE 'exact location unknown'
         END AS vzdalenost_od_Prahy
    ,COUNT(DISTINCT eventid) AS pocet_utoku
FROM teror
GROUP BY vzdalenost_od_Prahy
ORDER BY pocet_utoku DESC;



/*
3)
Zobrazte 10 útoků s největším počtem mrtvých ze zemí Syria, Nigeria, Afghanistan. 
Z výsledku odfiltrujte targtype1_txt ‘Military’, pro gname ‘Islamic State of Iraq and the Levant (ISIL)’tato výjimka neplatí 
(u této skupiny vypište i útoky s targtype1_txt Military). 
Vypište pouze sloupečky eventid, iyear, country_txt, city, attacktype1_txt, targtype1_txt, gname,weaptype1_txt, nkill.
*/
SELECT eventid
       ,iyear
       ,country_txt
       ,city, attacktype1_txt
       ,targtype1_txt
       ,gname,weaptype1_txt
       ,nkill
FROM teror
WHERE country_txt IN ('Syria', 'Nigeria', 'Afghanistan') 
      AND nkill IS NOT NULL
      AND (gname = 'Islamic State of Iraq and the Levant (ISIL)' OR targtype1_txt <> 'Military')
ORDER BY nkill DESC
LIMIT 10;