/*
Trigger oblicza  kwotę ubezpieczenia emerytalnego
*/
create or replace trigger emerytalne 
before insert or update
on ROZLICZENIE
for each row
 
 begin
 
if (:new.InformacjaPracodawca='TAK') or (:new.EmerytalneRentowe='TAK') then 

  :new.UbezEmerytalnePracownika:=:new.WynagrodzenieBrutto*0.0976;

else

:new.UbezEmerytalnePracownika:=0;

end if;

:new.UbezEmerytalnePracodawcy:= :new.UbezEmerytalnePracownika;

end;