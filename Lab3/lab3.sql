CREATE MATERIALIZED VIEW MW1
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE AS
    SELECT Mese, Tipo_Tariffa, Anno, SUM(Prezzo) AS IncassoTotale, SUM(NumChiamate) AS ChiamateTotali
    FROM FATTI F
    JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
    JOIN TARIFFA TA ON TA. CodTar = F.CodTar 
    GROUP BY Mese, Tipo_Tariffa, Anno;

CREATE MATERIALIZED VIEW MW2
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE AS
    SELECT Mese, Tipo_Tariffa, Anno, LC.Regione AS Regione_Chiamante, LR.Regione AS Regione_Chiamato, SUM(Prezzo) AS IncassoTotale, SUM(NumChiamate) AS ChiamateTotali
    FROM FATTI F
    JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
    JOIN TARIFFA TA ON TA. CodTar = F.CodTar 
    JOIN LUOGO LC ON LC.CodLuogo = F.CodLuogo_Chiamante
    JOIN LUOGO LR ON LR.CodLuogo = F.CodLuogo_Chiamato
    GROUP BY Mese, Tipo_Tariffa, Anno, LC.Regione, LR.Regione;

INSERT INTO FATTI(CodTempo, CodTar, CodLuogo_Chiamante, CodLuogo_Chiamato, Prezzo, NumChiamate)
VALUES(8,1,558,752,150,40000);

INSERT INTO FATTI(CodTempo, CodTar, CodLuogo_Chiamante, CodLuogo_Chiamato, Prezzo, NumChiamate)
VALUES(1,6,558,752,100,100);

BEGIN
    DBMS_SNAPSHOT.REFRESH('MW1');
END;

BEGIN
    DBMS_SNAPSHOT.REFRESH('MW2');
END;

CREATE MATERIALIZED VIEW LOG ON FATTI
WITH ROWID, SEQUENCE 
(
    CodTempo,
    CodTar,
    CodLuogo_Chiamante,
    CodLuogo_Chiamato,
    PREZZO,
    NumChiamate
)
INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON TEMPO
WITH ROWID, SEQUENCE 
(
    CodTempo,
    DATA,
    GIORNO,
    MESE,
    ANNO
)
INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON TARIFFA
WITH ROWID, SEQUENCE 
(
    CodTar,
    TIPO_TARIFFA
)
INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON LUOGO
WITH ROWID, SEQUENCE 
(
    CodLuogo,
    CITTA,
    PROVINCIA,
    REGIONE
)
INCLUDING NEW VALUES;

--ESERCIZIO 3
CREATE TABLE VM1 (
    Mese VARCHAR2(20),
    Tipo_Tariffa VARCHAR2(20),
    Anno NUMBER,
    IncassoTotale NUMBER,
    ChiamateTotali NUMBER
);

CREATE TABLE VM2 (
    Mese VARCHAR2(20),
    Tipo_Tariffa VARCHAR2(20),
    Anno NUMBER,
    Regione_Chiamante VARCHAR2(50),
    Regione_Chiamato VARCHAR2(50),
    IncassoTotale NUMBER,
    ChiamateTotali NUMBER
);

INSERT INTO VM1 (Mese, Tipo_Tariffa, Anno, IncassoTotale, ChiamateTotali)
SELECT Mese, Tipo_Tariffa, Anno, SUM(Prezzo) AS IncassoTotale, SUM(NumChiamate) AS ChiamateTotali
FROM FATTI F
JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
JOIN TARIFFA TA ON TA. CodTar = F.CodTar
GROUP BY Mese, Tipo_Tariffa, Anno;

INSERT INTO VM2 (Mese, Tipo_Tariffa, Anno, Regione_Chiamante, Regione_Chiamato, IncassoTotale, ChiamateTotali)
SELECT Mese, Tipo_Tariffa, Anno, LC.Regione AS Regione_Chiamante, LR.Regione AS Regione_Chiamato, SUM(Prezzo) AS IncassoTotale, SUM(NumChiamate) AS ChiamateTotali
FROM FATTI F
JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
JOIN TARIFFA TA ON TA. CodTar = F.CodTar
JOIN LUOGO LC ON LC.CodLuogo = F.CodLuogo_Chiamante
JOIN LUOGO LR ON LR.CodLuogo = F.CodLuogo_Chiamato
GROUP BY Mese, Tipo_Tariffa, Anno, LC.Regione, LR.Regione;

CREATE OR REPLACE TRIGGER vm1_after_insert
AFTER INSERT ON FATTI
FOR EACH ROW
DECLARE
    v_Mese VARCHAR2(20);
    v_Anno NUMBER;
    v_Tipo_Tariffa VARCHAR2(20);
    v_IncassoTotale NUMBER;
    v_ChiamateTotali NUMBER;
    v_count NUMBER;
BEGIN
    SELECT Mese, Anno INTO v_Mese, v_Anno
    FROM TEMPO
    WHERE CodTempo = :NEW.CodTempo;

    SELECT Tipo_Tariffa INTO v_Tipo_Tariffa
    FROM TARIFFA
    WHERE CodTar = :NEW.CodTar;

    SELECT SUM(Prezzo), SUM(NumChiamate) INTO v_IncassoTotale, v_ChiamateTotali
    FROM FATTI F
    JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
    JOIN TARIFFA TA ON TA. CodTar = F.CodTar
    WHERE TE.Mese = v_Mese AND TE.Anno = v_Anno AND TA.Tipo_Tariffa = v_Tipo_Tariffa
    GROUP BY TE.Mese, TE.Anno, TA.Tipo_Tariffa;

    SELECT COUNT(*) INTO v_count
    FROM VM1
    WHERE Mese = v_Mese AND Anno = v_Anno AND Tipo_Tariffa = v_Tipo_Tariffa;

    IF v_count > 0 THEN
        UPDATE VM1
        SET IncassoTotale = IncassoTotale + :NEW.Prezzo,
            ChiamateTotali = ChiamateTotali + :NEW.NumChiamate
        WHERE Mese = v_Mese AND Anno = v_Anno AND Tipo_Tariffa = v_Tipo_Tariffa;
    ELSE
        INSERT INTO VM1 (Mese, Tipo_Tariffa, Anno, IncassoTotale, ChiamateTotali)
        VALUES (v_Mese, v_Tipo_Tariffa, v_Anno, v_IncassoTotale, v_ChiamateTotali);
    END IF;
END;

CREATE OR REPLACE TRIGGER vm2_after_insert
AFTER INSERT ON FATTI
FOR EACH ROW
DECLARE
    v_Mese VARCHAR(20);
    v_Anno NUMBER;
    v_Tipo_Tariffa VARCHAR(20);
    v_Regione_Chiamante VARCHAR(50);
    v_Regione_Chiamato VARCHAR(50);
    v_IncassoTotale NUMBER;
    v_ChiamateTotali NUMBER;
    v_count NUMBER;
BEGIN
    SELECT Mese, Anno INTO v_Mese, v_Anno
    FROM TEMPO
    WHERE CodTempo = :NEW.CodTempo;

    SELECT Tipo_Tariffa INTO v_Tipo_Tariffa
    FROM TARIFFA
    WHERE CodTar = :NEW.CodTar;

    SELECT Regione INTO v_Regione_Chiamante
    FROM LUOGO
    WHERE CodLuogo = :NEW.CodLuogo_Chiamante;
    
    SELECT Regione INTO v_Regione_Chiamato
    FROM LUOGO
    WHERE CodLuogo = :NEW.CodLuogo_Chiamato;

    SELECT SUM(Prezzo), SUM(NumChiamate) INTO v_IncassoTotale, v_ChiamateTotali
    FROM FATTI F   
    JOIN TEMPO TE ON TE.CodTempo = F.CodTempo
    JOIN TARIFFA TA ON TA. CodTar = F.CodTar
    JOIN LUOGO LC ON LC.CodLuogo = F.CodLuogo_Chiamante
    JOIN LUOGO LR ON LR.CodLuogo = F.CodLuogo_Chiamato
    WHERE TE.Mese = v_Mese AND TE.Anno = v_Anno AND TA.Tipo_Tariffa = v_Tipo_Tariffa
          AND LC.Regione = v_Regione_Chiamante AND LR.Regione = v_Regione_Chiamato
    GROUP BY TE.Mese, TE.Anno, TA.Tipo_Tariffa, LC.Regione, LR.Regione;

    SELECT COUNT(*) INTO v_count
    FROM VM2
    WHERE Mese = v_Mese AND Anno = v_Anno AND Tipo_Tariffa = v_Tipo_Tariffa
          AND Regione_Chiamante = v_Regione_Chiamante AND Regione_Chiamato = v_Regione_Chiamato;
    
    IF v_count > 0 THEN
        UPDATE VM2
        SET IncassoTotale = IncassoTotale + :NEW.Prezzo,
            ChiamateTotali = ChiamateTotali + :NEW.NumChiamate
        WHERE Mese = v_Mese AND Anno = v_Anno AND Tipo_Tariffa = v_Tipo_Tariffa
              AND Regione_Chiamante = v_Regione_Chiamante AND Regione_Chiamato = v_Regione_Chiamato;
    ELSE
        INSERT INTO VM2 (Mese, Tipo_Tariffa, Anno, Regione_Chiamante, Regione_Chiamato, IncassoTotale, ChiamateTotali)
        VALUES (v_Mese, v_Tipo_Tariffa, v_Anno, v_Regione_Chiamante, v_Regione_Chiamato, v_IncassoTotale, v_ChiamateTotali);
    END IF;
END;

INSERT INTO FATTI(CodTempo, CodTar, CodLuogo_Chiamante, CodLuogo_Chiamato, Prezzo, NumChiamate)
VALUES(8,2,558,752,150, 40000);

INSERT INTO FATTI(CodTempo, CodTar, CodLuogo_Chiamante, CodLuogo_Chiamato, Prezzo, NumChiamate)
VALUES(1,7,558,752,100,100);