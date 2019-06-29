CREATE TABLE Osoba
  (
    osobaPESEL NCHAR(12) NOT NULL,
    imie NVARCHAR2(50) NOT NULL,
    nazwisko NVARCHAR2(50) NOT NULL,
    CONSTRAINT Osoba_PK PRIMARY KEY(osobaPESEL)
  );
CREATE TABLE Umowa
  (
    umowaNr NVARCHAR2(15) NOT NULL,
    dataRozpoczecia DATE NOT NULL,
    dataZakonczenia DATE NOT NULL,
    dataZawarcia     DATE NOT NULL,
    AdresPrzyjmujacego NCHAR(200) NOT NULL,
    AdresZlecajacego NCHAR(200) NOT NULL,
    agentNIP NVARCHAR2(12),
    wykonawcaPESEL NCHAR(12),
    zamawiajacyFirmaNIP NVARCHAR2(12),
    zamawiajacyOsobaPESEL NCHAR(12),
    zleceniobiorcaPESEL NCHAR(12),
    ZleceniodawcaAgencyjnaNIP NVARCHAR2(12),
    ZleceniodawcaZlecenieNIP NVARCHAR2(12),
    CONSTRAINT Umowa_PK PRIMARY KEY(umowaNr)
  );
CREATE TABLE Firma
  (
    firmaNIP NVARCHAR2(12) NOT NULL,
    nazwa NVARCHAR2(120) NOT NULL,
    regon NVARCHAR2(9) NOT NULL,
    CONSTRAINT Firma_PK PRIMARY KEY(firmaNIP)
  );
CREATE TABLE Rozliczenie
  (
    rozliczenieNr NVARCHAR2(20) NOT NULL,
    czyFGSP NVARCHAR2(4) CHECK (czyFGSP IN (N'TAK', N'NIE')) NOT NULL,
    czyFP NVARCHAR2(4) CHECK (czyFP       IN (N'TAK', N'NIE')) NOT NULL,
    dataRozliczenia DATE NOT NULL,
    dobrowolneChorobowe NVARCHAR2(4) CHECK (dobrowolneChorobowe IN (N'TAK', N'NIE')) NOT NULL,
    dochod NUMBER(6,2) NOT NULL,
    emerytalneRentowe NVARCHAR2(4) CHECK (emerytalneRentowe IN (N'TAK', N'NIE')) NOT NULL,
    FGSP NUMBER(6,2) NOT NULL,
    FP    NUMBER(6,2) NOT NULL,
    informacjaPracodawca NVARCHAR2(4) CHECK (informacjaPracodawca IN (N'TAK', N'NIE')) NOT NULL,
    kosztyUzysPrzychodu  NUMBER(6,2) NOT NULL,
    podatek              NUMBER(6,2) NOT NULL,
    stawkaPodatku        NUMBER(6,2) CHECK (stawkaPodatku IN (0.18, 0.32)) NOT NULL,
    stawkaUbezpWypadkowe NUMBER(6,4) NOT NULL,
    stawKosztyUP         NUMBER(6,2) CHECK (stawKosztyUP   IN (0.2, 0.5, 0)) NOT NULL,
    tylkoZdrowotne NVARCHAR2(4) CHECK (tylkoZdrowotne      IN (N'TAK', N'NIE')) NOT NULL,
    typWynagrodzenia NVARCHAR2(15) CHECK (typWynagrodzenia IN (N'ryczaltowe', N'kosztorysowe')) NOT NULL,
    ubezpieczenieChorobowe            NUMBER(6,2) NOT NULL,
    ubezpieczenieEmerytalnePracodawcy NUMBER(6,2) NOT NULL,
    ubezpieczenieEmerytalnePracownika NUMBER(6,2) NOT NULL,
    ubezpieczenieRentowePracodawcy    NUMBER(6,2) NOT NULL,
    ubezpieczenieRentowePracownika    NUMBER(6,2) NOT NULL,
    ubezpieczenieSpolPracownka        NUMBER(6,2) NOT NULL,
    ubezpieczenieWypadkowe            NUMBER(6,2) NOT NULL,
    umowaNr NVARCHAR2(15) NOT NULL,
    wynagrodzenieBrutto NUMBER(6,2) NOT NULL,
    wynagrodzenieNetto  NUMBER(6,2) NOT NULL,
    zdrowotnaOdliczona  NUMBER(6,2) NOT NULL,
    zdrowotnaPobrana    NUMBER(6,2) NOT NULL,
    CONSTRAINT Rozliczenie_PK PRIMARY KEY(rozliczenieNr)
  );
  
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK1 FOREIGN KEY (zleceniobiorcaPESEL) REFERENCES Osoba (osobaPESEL) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK2 FOREIGN KEY (zamawiajacyOsobaPESEL) REFERENCES Osoba (osobaPESEL) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK3 FOREIGN KEY (wykonawcaPESEL) REFERENCES Osoba (osobaPESEL) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK4 FOREIGN KEY (ZleceniodawcaZlecenieNIP) REFERENCES Firma (firmaNIP) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK5 FOREIGN KEY (zamawiajacyFirmaNIP) REFERENCES Firma (firmaNIP) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK6 FOREIGN KEY (agentNIP) REFERENCES Firma (firmaNIP) ;
ALTER TABLE Umowa ADD CONSTRAINT Umowa_FK7 FOREIGN KEY (ZleceniodawcaAgencyjnaNIP) REFERENCES Firma (firmaNIP) ;
ALTER TABLE Rozliczenie ADD CONSTRAINT Rozliczenie_FK FOREIGN KEY (umowaNr) REFERENCES Umowa (umowaNr) ;