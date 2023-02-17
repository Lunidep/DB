--  1.	Все команды, участвовавшие в iem-rio-major-2022
SELECT Teams.name AS "Название команды", Tournaments.name AS "Название турнира"
  FROM Tournaments 
    INNER JOIN Tournaments_Teams 
      ON Tournaments_Teams.tournament_id = Tournaments.id 
    INNER JOIN Teams 
      ON Tournaments_Teams.team_id = Teams.id 
    WHERE Tournaments.name = 'iem-rio-major-2022';
   

-- 2.	Все игроки, выступающие за команду 'NaVi'
SELECT Players.name AS "Игрок", Players.rating AS "Рейтинг", Teams.name AS "Команда"
  FROM Players, Teams 
  WHERE Teams.id = Players.fk_Players_Teams AND
  Teams.name = 'NaVi';
 

-- 3.	Команды из Дании и Германии
SELECT Teams.name AS "Название команды" FROM Teams
  WHERE country in ('Denmark', 'Germany');
 

-- 4.	Команды, имеющие процент WR от 60 до 80
SELECT Teams.name AS "Название команды" FROM Teams
  WHERE WR BETWEEN 60 AND 80;
 

-- 5.	Турниры, в названии которых есть указание 2022 года проведения
SELECT Tournaments.name AS "Название турнира" FROM Tournaments
  WHERE name LIKE '%-2022';
 

-- 6.	Общий призовой фонд всех указанных турниров 
SELECT SUM(prize_pool) AS "Призовой фонд" FROM Tournaments;


-- 7.	Сортировка списка игроков по стране, за которую он выступают
SELECT name AS "Игрок", country AS "Страна" 
FROM Players 
ORDER BY country;
 

-- 8.	Подсчет количества игроков из каждой страны
SELECT country AS "Страна", COUNT(*) AS "Количество"
  FROM Players
  GROUP BY country
  ORDER BY COUNT(*) DESC;


-- 9.	Найти игроков, у которых KD совпадает с рейтингом других игроков 
SELECT a.name AS "Игрок 1", a.KD AS "KD игрока 1",
  b.name AS "Игрок 2", b.rating AS "rating игрока 2"
  FROM Players AS a INNER JOIN Players AS b
  ON a.KD = b.rating;
 

-- 10.	Все игроки, выступающие за команду 'NaVi'
SELECT Players.name AS "Игрок", Players.rating AS "Рейтинг"
  FROM Players
  WHERE Players.name = ANY(
    SELECT Players.name
    FROM Players, Teams 
      WHERE Teams.id = Players.fk_Players_Teams AND
      Teams.name = 'NaVi'
  );
 
-- 11.	Турниры, в которых участвует > 10 команд

SELECT * FROM Tournaments AS a
WHERE 10 < (
  SELECT COUNT(*)
    FROM Tournaments AS b
      INNER JOIN Tournaments_Teams 
        ON Tournaments_Teams.tournament_id = b.id 
      INNER JOIN Teams 
        ON Tournaments_Teams.team_id = Teams.id 
      WHERE b.name = a.name
);

 
-- 12.	Команды – победители каждого турнира
SELECT Tournaments.name AS "Название турнира", Tournaments.winner AS "Победитель"
  FROM Tournaments
  WHERE EXISTS 
    (SELECT *
      FROM Teams
        WHERE Tournaments.winner = Teams.name);

 
-- 13.	Сортируем игроков Vitality: сначала те, у кого страна совпадает со страной команды, затем те, у кого не совпадает
SELECT Players.name AS "Игрок", Players.country AS "Страна игрока", Teams.name AS "Команда", Teams.country AS "Страна команды"
  FROM Players CROSS JOIN Teams
  WHERE Players.fk_Players_Teams = Teams.id AND Teams.name = 'Vitality' AND Players.country = Teams.country
UNION ALL
SELECT Players.name AS "Игрок", Players.country AS "Страна игрока", Teams.name AS "Команда", Teams.country AS "Страна команды"
  FROM Players CROSS JOIN Teams
  WHERE Players.fk_Players_Teams = Teams.id AND Teams.name = 'Vitality' AND Players.country != Teams.country;


-- 14.	Все турниры, где призовой фонд был 1000000 и победили FaZe
SELECT Tournaments.name AS "Название турнира", Tournaments.winner AS "Победитель", Tournaments.prize_pool AS "Призовой фонд"
FROM Tournaments 
  WHERE Tournaments.winner = 'FaZe'
INTERSECT
SELECT Tournaments.name AS "Название турнира", Tournaments.winner AS "Победитель", Tournaments.prize_pool AS "Призовой фонд"
FROM Tournaments 
  WHERE Tournaments.prize_pool = 1000000;

 
-- 15.	Все турниры, где призовой фонд был не равен 1000000 и победили FaZe
SELECT Tournaments.name AS "Название турнира", Tournaments.winner AS "Победитель", Tournaments.prize_pool AS "Призовой фонд"
FROM Tournaments 
  WHERE Tournaments.winner = 'FaZe'
EXCEPT
SELECT Tournaments.name AS "НАзвание турнира", Tournaments.winner AS "Победитель", Tournaments.prize_pool AS "Призовой фонд"
FROM Tournaments 
  WHERE Tournaments.prize_pool = 1000000;

 
-- 16.	Все игроки, выступающие за команду 'NaVi'
SELECT Players.name AS "Игрок", Players.rating AS "Рейтинг"
  FROM Players
  WHERE Players.name = SOME(
    SELECT Players.name
    FROM Players, Teams 
      WHERE Teams.id = Players.fk_Players_Teams AND
      Teams.name = 'NaVi'
  );
 
-- 17.	Переводим всех игроков команды NaVi в BIG
UPDATE Players SET 
  fk_Players_Teams = 11 WHERE fk_Players_Teams = 1;
SELECT Players.name AS "Игрок", Teams.name AS "Команда"
  FROM Players, Teams 
  WHERE Teams.id = Players.fk_Players_Teams AND
  Teams.name = 'BIG';

