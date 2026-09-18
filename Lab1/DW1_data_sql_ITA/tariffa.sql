CREATE TABLE TARIFFA (
  CodTar INTEGER  NOT NULL PRIMARY KEY,
  Tipo_Tariffa VARCHAR(12) NOT NULL
);
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (1, 'Notte');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (2, 'Giorno');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (3, 'Mattino');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (4, '24 ore su 24');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (5, 'CartaNatale');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (6, 'Festivi');
INSERT INTO TARIFFA (CodTar, Tipo_Tariffa) VALUES (7, 'Business');
