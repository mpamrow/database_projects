--------------------------TWORZENIE TABEL---------------------------------------

CREATE TABLE Orders(
	Order_id	INTEGER NOT NULL,
	Customer_id	INTEGER NOT NULL UNIQUE,
	Total	NUMERIC(8,2),
	Status	VARCHAR(15),
	Order_date	date NOT NULL,
	CONSTRAINT	pk_Order PRIMARY KEY (Order_id)
);

CREATE TABLE Order_details(
	Order_id	INTEGER NOT NULL,
	Position	INTEGER NOT NULL,
	Product_id	INTEGER NOT NULL,
	Quantity	INTEGER,
	CONSTRAINT	pk_Order_details PRIMARY KEY (Order_id,Position)
);

CREATE TABLE Customer(
	Customer_id	INTEGER NOT NULL,
	First_name	VARCHAR(15) NOT NULL,
	Last_name	VARCHAR(20) NOT NULL,
	Street_no	VARCHAR(25) NOT NULL,
	City	VARCHAR(30) NOT NULL,
	ZIP	VARCHAR(8) NOT NULL,
	Region	VARCHAR(25),
	Country	VARCHAR(30) NOT NULL,
	PhoneNo	VARCHAR(12) NOT NULL,
	Email	VARCHAR(20),
	Cust_category	VARCHAR(15),
	CONSTRAINT	pk_Customer PRIMARY KEY (Customer_id)
);

CREATE TABLE Product(
	Product_id	INTEGER NOT NULL,
	Title	VARCHAR(30) NOT NULL,
	Category	VARCHAR(15) NOT NULL,
	Plot_desc	VARCHAR(500),
	Prod_country	VARCHAR(20) NOT NULL,
	Prod_Year	VARCHAR(8) NOT NULL,
  Price	NUMERIC(8,2),
	Rating	VARCHAR(8),
	Format	VARCHAR(8),
	CONSTRAINT	pk_Product PRIMARY KEY (Product_id)
);

CREATE TABLE Cust_category(
	Name	VARCHAR(15) NOT NULL,
	Cust_Cat_desc	VARCHAR(50),
	CONSTRAINT	pk_Cust_category PRIMARY KEY (Name)
);

CREATE TABLE Category(
	Name	VARCHAR(8) NOT NULL,
	Cat_desc	VARCHAR(50),
	CONSTRAINT	pk_Category PRIMARY KEY (Name)
);

CREATE TABLE Rating(
	Name	VARCHAR(8) NOT NULL,
	Rating_desc	VARCHAR(200),
	CONSTRAINT	pk_Rating PRIMARY KEY (Name)
);


ALTER TABLE Product ADD CONSTRAINT fk1_Product_to_Rating FOREIGN KEY(Rating) REFERENCES Rating(Name);


ALTER TABLE Product ADD CONSTRAINT fk2_Product_to_Category FOREIGN KEY(Category) REFERENCES Category(Name);


ALTER TABLE Order_details ADD CONSTRAINT fk1_Order_details_to_Product FOREIGN KEY(Product_id) REFERENCES Product(Product_id);


ALTER TABLE Customer ADD CONSTRAINT fk1_Customer_to_Cust_category FOREIGN KEY(Cust_category) REFERENCES Cust_category(Name);


ALTER TABLE Order_details ADD CONSTRAINT fk2_Order_details_to_Order FOREIGN KEY(Order_id) REFERENCES Orders(Order_id) ;


ALTER TABLE Orders ADD CONSTRAINT fk1_Order_to_Customer FOREIGN KEY(Customer_id) REFERENCES Customer(Customer_id);


CREATE TABLE CURRENT_ORDER_temp
   (	ORDER_ID number(12)
   );
   
   
----------------------------TRIGGERY--------------------------------------------

--nowe warto�ci order_id w tabeli ORDERS
CREATE OR REPLACE TRIGGER orders_bir before
INSERT ON orders 
FOR EACH row 
DECLARE 
v_order_id orders.order_id%type;
BEGIN
  SELECT MAX(order_id) INTO v_order_id FROM orders;
  IF v_order_id   IS NULL THEN
    :new.order_id := 1;
  ELSE
    :new.order_id := v_order_id+1;
  END IF;
  :new.status := 'OPENED';
  UPDATE current_order_temp SET order_id = :new.order_id;
END;
/
show errors
  
  
--////////////////////////////////////////////////////////////////////////////
CREATE OR REPLACE TRIGGER order_details_biur before
  INSERT OR UPDATE ON order_details 
  FOR EACH row 
  DECLARE 
  v_order_id orders.order_id%type;
  v_position order_details.position%type;
  v_price product.price%type;
  
  BEGIN

--przy INSERT pobiera warto�� bie��cego zam�wienia order_id z tabeli current_order_temp
    IF INSERTING THEN
      SELECT order_id INTO v_order_id FROM current_order_temp;
      IF v_order_id   IS NULL THEN
        :new.order_id := 1;
        v_order_id    := 1;
      ELSE
        :new.order_id := v_order_id;
      END IF;

-- obsluga ilo�ci i kolejno�ci pozycji dla zam�wienia
      SELECT COUNT(*)
      INTO v_position
      FROM order_details
      WHERE order_id   = v_order_id;
      
      IF v_position    = 0 THEN
        :new.position := 1;
      ELSE
        :new.position := v_position+1;
      END IF;
      
   --pobranie ceny   
      SELECT price INTO v_price FROM product WHERE product_id = :new.product_id;
      
      UPDATE orders SET total = NVL(total,0) + (v_price * :new.quantity)
      WHERE order_id = :new.order_id;
      
    END IF;
    

    IF UPDATING THEN
--pobranie nowej ceny 
      SELECT price INTO v_price FROM product WHERE product_id = :new.product_id;
--aktualizacja ORDERS 
      UPDATE orders
      SET total      = total - (v_price * :old.quantity)
      WHERE order_id = :old.order_id;
      UPDATE orders
      SET total      = total + (v_price * :new.quantity)
      WHERE order_id = :new.order_id;
    END IF;
  END;
  /
  show errors
  
--////////////////////////////////////////////////////////////////////////////////
CREATE OR REPLACE TRIGGER order_details_cd 
FOR DELETE ON order_details 
COMPOUND TRIGGER 
v_order_id orders.order_id%type;
v_price product.price%type;

  AFTER EACH ROW
IS

BEGIN
  
  select price into v_price from product where product_id=:old.product_id;
  
  UPDATE orders
  SET total      = total - (v_price * :old.quantity)
  WHERE order_id = :old.order_id;
  v_order_id    := :old.order_id;
  
END AFTER EACH ROW;

AFTER STATEMENT
IS
BEGIN
  UPDATE order_details SET position = rownum WHERE order_id = v_order_id;
END AFTER STATEMENT;

END;
/
show errors

------------------------GENERATOR DANYCH----------------------------------------

CREATE OR REPLACE PACKAGE package_moviestore
IS
  FUNCTION fun_klient
    RETURN INTEGER;
  FUNCTION fun_produkt
    RETURN INTEGER;
  PROCEDURE procedure_generuj_rach;
  PROCEDURE procedure_generuj_rach(
      in_startdate DATE,
      in_enddate   DATE,
      counter      INTEGER);
  PROCEDURE procedure_generuj_rach(
      in_startdate DATE,
      in_enddate   DATE);
END;

CREATE OR REPLACE PACKAGE BODY PACKAGE_MOVIESTORE
AS
--losowanie nr klienta
  FUNCTION fun_klient
    RETURN INTEGER
  AS
    v_max INTEGER;
  BEGIN
    SELECT MAX(customer_id) INTO v_max FROM customer;
    RETURN dbms_random.value(1, v_max);
  END fun_klient;

--losowanie nr produktu
  FUNCTION fun_produkt
    RETURN INTEGER
  AS
    v_max INTEGER;
  BEGIN
    SELECT MAX(product_id) INTO v_max FROM product;
    RETURN dbms_random.value(1, v_max);
  END fun_produkt;
  
--*****************generacja pojedynczego rachunku wielopozycyjnego**************************
  PROCEDURE procedure_generuj_rach
  AS
    v_rach orders.order_id%TYPE;
    v_klient orders.customer_id%TYPE;
    v_produkt order_details.product_id%TYPE;
    v_ilosc INTEGER;
    v_cena product.price%TYPE;
    v_total orders.total%TYPE;
    v_pozycje ORDER_DETAILS.POSITION%TYPE;
    v_curr_pos ORDER_DETAILS.POSITION%TYPE;
  BEGIN
    --kolejny numer rachunku, np: sekwencja, autoinkrementacja, max+1
    SELECT MAX(order_id)
    INTO v_rach
    FROM orders;
    IF v_rach IS NULL THEN
      SELECT 1 INTO v_rach FROM dual;
    ELSE
      v_rach:=v_rach+1;
    END IF;
    
    --data_rachunku: sysdate
    --nr klienta: losowo przez funkcję
    SELECT fun_klient()
    INTO v_klient
    FROM dual;
    INSERT INTO orders VALUES
      (v_rach, v_klient, 0, 'OPENED', sysdate
      );
    --losowanie ilości pozycji dla rachunku
    SELECT ROUND(dbms_random.value(1, 5), 0)
    INTO v_pozycje
    FROM dual;
    
    --tworzenie wylosowanej ilości pozycji
    FOR i IN 1..v_pozycje
    LOOP
      --kolejny numer pozycji
      SELECT MAX(position)
      INTO v_curr_pos
      FROM order_details
      WHERE order_id =v_rach;
      
      IF v_curr_pos IS NULL THEN
        SELECT 1 INTO v_curr_pos FROM dual;
      ELSE
        v_curr_pos:=v_curr_pos+1;
      END IF;
      
      --nr produktu: losowo przez funkcję
      SELECT fun_produkt()
      INTO v_produkt
      FROM dual;
      
      --ilosc: losowanie przez funkcję 1...n
      SELECT ROUND(dbms_random.value(1, 5), 0)
      INTO v_ilosc
      FROM dual;
      
      --cena zakupu: =cena produktu
      SELECT price
      INTO v_cena
      FROM product
      WHERE PRODUCT_ID=v_produkt;
      
      INSERT
      INTO order_details VALUES
        (
          v_rach,
          v_curr_pos,
          v_produkt,
          v_ilosc
        );
    END LOOP;
    
    --wartosc rachunku: policzyć cena*ilosc
    SELECT SUM(v_cena*QUANTITY)
    INTO v_total
    FROM order_details
    WHERE ORDER_ID=v_rach
    GROUP BY order_id;
    UPDATE orders SET total=v_total WHERE order_id=v_rach;
    COMMIT;
  END procedure_generuj_rach;
  
  
--*************************generacja zadanej ilości rachunków według daty***************
  PROCEDURE procedure_generuj_rach(
      in_startdate DATE,
      in_enddate   DATE,
      counter      INTEGER)
  AS
    v_rach orders.order_id%TYPE;
    v_klient orders.customer_id%TYPE;
    v_produkt order_details.product_id%TYPE;
    v_ilosc INTEGER;
    v_cena product.price%TYPE;
    v_total orders.total%TYPE;
    v_pozycje ORDER_DETAILS.POSITION%TYPE;
    v_curr_pos ORDER_DETAILS.POSITION%TYPE;
    v_startdate DATE:=in_startdate;
    
  BEGIN
    WHILE v_startdate<in_enddate
    LOOP
      FOR i IN 1..counter
      LOOP
      
        --kolejny numer rachunku, np: sekwencja, autoinkrementacja, max+1
        SELECT MAX(order_id)
        INTO v_rach
        FROM orders;
        IF v_rach IS NULL THEN
          SELECT 1 INTO v_rach FROM dual;
        ELSE
          v_rach:=v_rach+1;
        END IF;
        
        --data_rachunku: sysdate
        --nr klienta: losowo przez funkcję
        SELECT fun_klient()
        INTO v_klient
        FROM dual;
        
        --losowanie ilości pozycji dla rachunku
        SELECT ROUND(dbms_random.value(1, 5), 0)
        INTO v_pozycje
        FROM dual;
        INSERT INTO orders VALUES
          (v_rach, v_klient, 0, 'OPENED', v_startdate
          );
          
        --tworzenie wylosowanej ilości pozycji
        FOR i IN 1..v_pozycje
        LOOP
          --kolejny numer pozycji
          SELECT MAX(position)
          INTO v_curr_pos
          FROM order_details
          WHERE order_id =v_rach;
          IF v_curr_pos IS NULL THEN
            SELECT 1 INTO v_curr_pos FROM dual;
          ELSE
            v_curr_pos:=v_curr_pos+1;
          END IF;
          
          --nr produktu: losowo przez funkcję
          SELECT fun_produkt()
          INTO v_produkt
          FROM dual;
          --ilosc: losowanie przez funkcję 1...n
          SELECT ROUND(dbms_random.value(1, 5), 0)
          INTO v_ilosc
          FROM dual;
          --cena zakupu: =cena produktu
          SELECT price
          INTO v_cena
          FROM product
          WHERE PRODUCT_ID=v_produkt;
          INSERT
          INTO order_details VALUES
            (
              v_rach,
              v_curr_pos,
              v_produkt,
              v_ilosc
            );
        END LOOP;
        
        --wartosc rachunku: policzyć cena*ilosc
        SELECT SUM(v_cena*quantity)
        INTO v_total
        FROM order_details
        WHERE ORDER_ID=v_rach
        GROUP BY order_id;
        UPDATE orders SET total=v_total WHERE order_id=v_rach;
        COMMIT;
      END LOOP;
      v_startdate:=v_startdate+1;
    END LOOP;
  END procedure_generuj_rach;
  
  
--*************************generacja losowej ilości rachunków według daty***************
  PROCEDURE procedure_generuj_rach(
      in_startdate DATE,
      in_enddate   DATE)
  AS
    v_rach orders.order_id%TYPE;
    v_klient orders.customer_id%TYPE;
    v_produkt order_details.product_id%TYPE;
    v_ilosc INTEGER;
    v_cena product.price%TYPE;
    v_total orders.total%TYPE;
    v_pozycje ORDER_DETAILS.POSITION%TYPE;
    v_curr_pos ORDER_DETAILS.POSITION%TYPE;
    v_startdate DATE   :=in_startdate;
    v_counter   INTEGER:=ROUND(dbms_random.value(1, 15),0);
  BEGIN
    WHILE v_startdate<in_enddate
    LOOP
      FOR i IN 1..v_counter
      LOOP
        --kolejny numer rachunku, np: sekwencja, autoinkrementacja, max+1
        SELECT MAX(order_id)
        INTO v_rach
        FROM orders;
        IF v_rach IS NULL THEN
          SELECT 1 INTO v_rach FROM dual;
        ELSE
          v_rach:=v_rach+1;
        END IF;
        --data_rachunku: sysdate
        --nr klienta: losowo przez funkcję
        SELECT fun_klient()
        INTO v_klient
        FROM dual;
        --losowanie ilości pozycji dla rachunku
        SELECT ROUND(dbms_random.value(1, 5), 0)
        INTO v_pozycje
        FROM dual;
        INSERT INTO orders VALUES
          (v_rach, v_klient, 0, 'OPENED', v_startdate
          );
        --tworzenie wylosowanej ilości pozycji
        FOR i IN 1..v_pozycje
        LOOP
          --kolejny numer pozycji
          SELECT MAX(position)
          INTO v_curr_pos
          FROM order_details
          WHERE order_id =v_rach;
          IF v_curr_pos IS NULL THEN
            SELECT 1 INTO v_curr_pos FROM dual;
          ELSE
            v_curr_pos:=v_curr_pos+1;
          END IF;
          --nr produktu: losowo przez funkcję
          SELECT fun_produkt()
          INTO v_produkt
          FROM dual;
          --ilosc: losowanie przez funkcję 1...n
          SELECT ROUND(dbms_random.value(1, 5), 0)
          INTO v_ilosc
          FROM dual;
          --cena zakupu: =cena produktu
          SELECT price
          INTO v_cena
          FROM product
          WHERE PRODUCT_ID=v_produkt;
          INSERT
          INTO order_details VALUES
            (
              v_rach,
              v_curr_pos,
              v_produkt,
              v_ilosc
            );
        END LOOP;
        --wartosc rachunku: policzyć cena*ilosc
        SELECT SUM(v_cena*quantity)
        INTO v_total
        FROM order_details
        WHERE ORDER_ID=v_rach
        GROUP BY order_id;
        UPDATE orders SET total=v_total WHERE order_id=v_rach;
      END LOOP;
      v_startdate:=v_startdate+1;
    END LOOP;
  END procedure_generuj_rach;
END PACKAGE_MOVIESTORE;

