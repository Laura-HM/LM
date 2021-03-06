--Used PostgreSQL

/*
 Что нужно сделать:
1. Написать update запросы для предотвращения возможных ограничений и оптимизации изначальных таблиц. В комментариях укажите почему такие изменения нужны.

Ответы:
1. Так как Update является DML командой (используется для обновления существующих записей в таблице в базе данных, которых у нас нет на данный момент),
 то с помощью нее нельзя изменять DDL объекты. Для того, чтобы изменить какие-либо ограничения (Constraints),необходимо использовать DDL команду ALTER.
  Например:
 
 */
 ALTER TABLE client ALTER COLUMN country DROP NOT NULL; -- можно сделать необязательным заполнение данного атрибута

 ALTER TABLE rentbook RENAME COLUMN date TO rent_date;--лучше использовать другое название клонки, так date употребляется как тип данных
 
 ALTER TABLE rentbook RENAME COLUMN time TO rent_time;--лучше использовать другое название клонки, так time употребляется как тип времени

 ALTER TABLE rentbook ALTER COLUMN rent_date SET DEFAULT CURRENT_DATE;--можно упростить заполнение даты, если нужно указать текущую дату

 ALTER TABLE servicebook ALTER COLUMN date SET DEFAULT CURRENT_DATE;--можно упростить заполнение даты, если нужно указать текущую дату

 ALTER TABLE servicebook RENAME COLUMN date TO service_date;--лучше использовать другое название клонки, так date употребляется как тип данных

 ALTER TABLE staff RENAME COLUMN date TO start_date;--лучше использовать другое название клонки, так date употребляется как тип данных

 ALTER TABLE staff ALTER COLUMN passport DROP NOT NULL;-- можно сделать необязательным заполнение данного атрибута

 ALTER TABLE staff ALTER COLUMN start_date SET DEFAULT CURRENT_DATE;--можно упростить заполнение даты, если нужно указать текущую дату

 ALTER TABLE detail RENAME COLUMN type TO detail_type;--лучше использовать другое название клонки, так date употребляется как тип данных
 
 -- также можно методоми выше поменять название колонок Name
/* 2. Разбить таблицы на меры и измерения.
 * Ответ: Данные таблицы можно разбить на таблицы измерения и фактовую таблицу, которая в свою очередь содержит меры.
 * Фактовая таблицы: rentbook, servicebook
 * Таблицы измерения: staff, client, detail, bicycle, а detailforbicycle - это связующая таблица между таблицами detail и bicycle, так как у них связь
 * между собой много ко многому.
 */
 
-- 3. Написать MDX скрипт создания OLAP куба из представленных таблиц.
--1)
 SELECT r.id, r.rent_date, r.rent_time, r.paid, r.bicycleid, b.brand, b.rentprice,
 r.clientid, c."name" AS client_name, c.passport AS client_passport, c.country AS client_country,
 r.staffid, s."name" AS staff_name, s.passport AS staff_passport, s.start_date AS staff_start_date
 FROM rentbook r  
 JOIN bicycle b ON r.bicycleid = b.id 
 JOIN client c ON r.clientid = c.id 
 JOIN staff s ON r.staffid = s.id;

--2)
 SELECT b.brand AS bicycle_brand, sum(s.price) AS service_price, d."name" AS detail_name, st."name" AS staff_name
 FROM servicebook s  
 JOIN bicycle b ON s.bicycleid = b.id 
 JOIN detail d ON s.detailid = d.id 
 JOIN staff st ON s.staffid = st.id
 WHERE s.price > 2000
 GROUP BY b.brand, d."name", st."name";


/*4. Написать 5 MDX произвольных запросов на отображение сводных данных. Как минимум два запроса должны затрагивать данные из четырех таблиц.
*/

--1)
SELECT * 
FROM client c   
WHERE c.country IN ('USA', 'Australia')

--2)
SELECT * 
FROM rentbook r  
WHERE r.rent_date = 2

--2)
SELECT st."name" AS staff_name, st.passport AS staff_passport, st.start_date AS staff_start_date
FROM staff s
WHERE st.start_date BETWEEN '2020-01-01' AND '2020-12-31'

--3)
 SELECT r.rent_date, r.rent_time, r.paid, b.rentprice, c."name" AS client_name, s."name" AS staff_name
 FROM rentbook r  
 JOIN bicycle b ON r.bicycleid = b.id 
 JOIN client c ON r.clientid = c.id 
 JOIN staff s ON r.staffid = s.id
 WHERE r.paid = 0;

--4)

 SELECT b.brand AS bicycle_brand, d.detail_type, d."name" AS detail_name, d.price AS detail_price,
 s.staffid, st."name" AS staff_name, st.passport AS staff_passport, st.start_date AS staff_start_date
 FROM servicebook s  
 JOIN bicycle b ON s.bicycleid = b.id 
 JOIN detail d ON s.detailid = d.id 
 JOIN staff st ON s.staffid = st.id;



-- создаем таблицы ниже

CREATE TABLE Bicycle

(

Id int GENERATED BY DEFAULT AS IDENTITY NOT NULL,

Brand varchar(50) NOT NULL,

RentPrice int NOT NULL, -- цена аренды

primary key(Id)

);

CREATE TABLE Client

(

Id int GENERATED BY DEFAULT AS IDENTITY NOT NULL,

Name varchar(10) NOT NULL,

Passport varchar(50) NOT NULL,

Country varchar(50) NOT NULL,

primary key(Id)

);

CREATE TABLE Staff

(

Id int GENERATED BY DEFAULT AS IDENTITY NOT NULL,

Name varchar(10) NOT NULL,

Passport varchar(50) NOT NULL,

Date date NOT NULL, -- дата начала работы

primary key(Id)

);

CREATE TABLE Detail -- запчасти велосипеда

(

Id int GENERATED BY DEFAULT AS IDENTITY NOT NULL,

Brand varchar(50) NOT NULL,

Type varchar(50) NOT NULL, -- тип детали (цепь, звезда, etc.)

Name varchar(50) NOT NULL, -- название детали

Price int NOT NULL,

primary key(Id)

);

CREATE TABLE DetailForBicycle -- список деталей подходящих к велосипедам

(

BicycleId int NOT NULL,

DetailId int NOT NULL,

FOREIGN KEY (BicycleId) REFERENCES Bicycle (Id), FOREIGN KEY (DetailId) REFERENCES Detail (Id)
);

CREATE TABLE ServiceBook -- сервисное обслуживание велосипедов

(

BicycleId int NOT NULL,

DetailId int NOT NULL,

Date date NOT NULL,

Price int NOT NULL, -- цена работы

StaffId int NOT NULL,

FOREIGN KEY (BicycleId) REFERENCES Bicycle (Id), FOREIGN KEY (StaffId) REFERENCES Staff (Id), FOREIGN KEY (DetailId) REFERENCES Detail (Id) 
);

CREATE TABLE RentBook -- аренда велосипеда клиентом

(

Id int GENERATED BY DEFAULT AS IDENTITY NOT NULL,

Date date NOT NULL, -- дата аренды

Time int NOT NULL, -- время на сколько взята аренда в часах

Paid bit NOT NULL, -- 1 оплатил; 0 не оплатил

BicycleId int NOT NULL,

ClientId int NOT NULL,

StaffId int NOT NULL,

FOREIGN KEY (BicycleId) REFERENCES Bicycle (Id), FOREIGN KEY (StaffId) REFERENCES Staff (Id), FOREIGN KEY (ClientId) REFERENCES Client (Id) );
