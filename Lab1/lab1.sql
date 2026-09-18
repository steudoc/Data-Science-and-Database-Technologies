--1) Seleziona il reddito annuo per ogni tariffa telefonica, il reddito totale per ogni tariffa telefonica, il reddito annuo totale e il reddito totale.
SELECT CODTAR, ANNO, SUM(PREZZO) AS Reddito_Annuo, 
    SUM(SUM(PREZZO)) OVER (PARTITION BY CODTAR) AS Tot_Tariffa,
    SUM(SUM(PREZZO)) OVER (PARTITION BY ANNO) AS Tot_Anno,
    SUM(SUM(PREZZO)) OVER () AS TOTALE
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO
GROUP BY CODTAR, ANNO
ORDER BY CODTAR, ANNO;

--2) Seleziona il numero mensile di chiamate e il reddito mensile. Associa il RANK() a ogni mese in base al suo reddito (1 per il mese con il reddito più alto, 2 per il secondo, ecc., l'ultimo mese è quello con il reddito più basso).
SELECT MESE, COUNT(*) AS NUM_CHIAMATE, SUM(PREZZO), 
    RANK() OVER (ORDER BY SUM(PREZZO) DESC) AS RANK_MESE
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO
GROUP BY MESE
ORDER BY MESE;

--3) Per ogni mese del 2023, selezionare il numero totale di chiamate. Associa il RANK() a ciascun mese in base al suo numero totale di chiamate (1 per il mese con il maggior numero di chiamate, 2 per il secondo, ecc., l'ultimo mese è quello con il minor numero di chiamate).
SELECT MESE, COUNT(*) AS NUM_CHIAMATE, 
    RANK() OVER (ORDER BY COUNT(*) DESC) AS RANK_MESE
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO AND ANNO = 2023
GROUP BY MESE;

--4) Per ogni giorno del mese di luglio 2023, selezionare il reddito totale e il reddito medio degli ultimi 3 giorni.
SELECT T.DATA, SUM(PREZZO) AS TOT,
    AVG(SUM(PREZZO)) OVER (ORDER BY T.DATA
                        ROWS 3 PRECEDING) AS BO
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO AND MESE = '7-2023'
GROUP BY T.DATA;

--5) Seleziona il reddito mensile e il reddito mensile cumulativo dall'inizio dell'anno.
SELECT MESE, SUM(PREZZO) AS RED_MENSILE,
    SUM(SUM(PREZZO)) OVER (ORDER BY ANNO, MESE
                          ROWS UNBOUNDED PRECEDING) AS RED_CUMULATIVO
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO
GROUP BY MESE;

--6) Consideriamo l'anno 2023. Separatamente per tariffa telefonica e mese, analizza (i) il totale delle entrate, (ii) la percentuale di entrate rispetto alle entrate totali considerando tutte le tariffe telefoniche, (iii) la percentuale delle entrate rispetto alle entrate totali considerando tutti i mesi.
SELECT CODTAR, MESE, SUM(PREZZO) AS REDD_TOT, 
    100*SUM(PREZZO)/(SUM(SUM(PREZZO)) OVER ()) AS TAR_PERC,
    100*SUM(PREZZO)/(SUM(SUM(PREZZO)) OVER (PARTITION BY MESE)) AS MESE_PERC
FROM FATTI F, TEMPO T
WHERE F.CODTEMPO = T.CODTEMPO AND ANNO = 2023
GROUP BY CODTAR, MESE;

--7) Per ogni regione del chiamante, selezionare il numero mensile di chiamate e il numero cumulativo di chiamate mensili dall'inizio dell'anno.
SELECT L.REGIONE, MESE, COUNT(*) AS NUM_CHIAMATE,
    SUM(COUNT(*)) OVER (PARTITION BY L.REGIONE ORDER BY ANNO, MESE
                       ROWS UNBOUNDED PRECEDING) AS NUM_CUMULATIVO
FROM FATTI F, TEMPO T, LUOGO L
WHERE F.CODTEMPO = T.CODTEMPO AND F.CODLUOGO_CHIAMANTE = L.CODLUOGO
GROUP BY L.REGIONE, MESE;



--8) Consideriamo l'anno 2023. Analizza il reddito totale per (i) separatamente per ogni mese e (ii) separatamente per ogni mese, tariffa telefonica e regione del chiamante e (iii) separatamente per ogni mese, tariffa telefonica e regione del destinatario.
SELECT MESE, SUM(PREZZO) AS REDD_MESE,
    SUM(SUM(PREZZO)) OVER (PARTITION BY MESE) AS REDD_MESE_TAR_REG_SRC,
    SUM(SUM(PREZZO)) OVER (PARTITION BY MESE, CODTAR, L1.REGIONE) AS REDD_MESE_TAR_REG_DEST
FROM FATTI F, TEMPO T, LUOGO L1, LUOGO L2
WHERE F.CODTEMPO = T.CODTEMPO AND ANNO = 2023 AND F.CODLUOGO_CHIAMANTE = L1.CODLUOGO AND F.CODLUOGO_DESTINATARIO = L2.CODLUOGO
GROUP BY MESE, CODTAR, L1.REGIONE;