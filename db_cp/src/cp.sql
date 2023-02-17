--  JEFT JOIN (У игрока KennyS нет команды в данный момент)
--  1. Для кажого игрока вывести его нынешнюю команду
SELECT Players.name AS "Игрок", Teams.name AS "Команда"
  FROM Players LEFT JOIN Teams
    ON Players.fk_Players_Teams = Teams.id
  ORDER BY Players.name;


--  RIGHT JOIN (В топе мирового рейтинга нет игроков из команды NIP)
--  2. Для кажой команды вывести ее игроков, которые находятся в топе мирового рейтинга
SELECT Teams.name AS "Команда", Players.name AS "Игрок"
  FROM Teams LEFT JOIN Players
    ON Teams.id = Players.fk_Players_Teams
  ORDER BY Teams.name;



--  FULL JOIN
--  3. Все матчи указанного турнира
SELECT Matches.id AS "Матч", a.name AS "Команда 1", b.name AS "Команда 2"
  FROM Matches
    FULL JOIN Teams AS a
      ON Matches.fk_team1 = a.id 
    FULL JOIN Teams AS b
      ON Matches.fk_team2 = b.id 
    FULL JOIN Tournaments
      ON Matches.fk_tournament = Tournaments.id
    WHERE Tournaments.name = 'iem-rio-major-2022';


-- CROSS JOIN 
-- 4. Все игроки и тернеры представляющие Данию 
SELECT Teams.name AS "Команда", Players.name AS "Игрок"
  FROM Teams
    CROSS JOIN Players 
      WHERE Teams.country = 'Denmark' AND Players.fk_Players_Teams = Teams.id;


 CASE
--  5. Оценка интересности матча в зависимости от играющих команд
SELECT Matches.id AS "Матч", a.name AS "Команда 1", b.name AS "Команда 2",
  
  CASE WHEN a.id <= 3  AND b.id <= 3 THEN '5'
    WHEN a.id <= 5  AND b.id <= 5 THEN '4'
    WHEN a.id <= 7  AND b.id <= 7 THEN '3'
    WHEN a.id <= 10  AND b.id <= 10 THEN '2'
      ELSE '1'
  END
  
  FROM Matches
    FULL JOIN Teams AS a
      ON Matches.fk_team1 = a.id 
    FULL JOIN Teams AS b
      ON Matches.fk_team2 = b.id
    FULL JOIN Tournaments
      ON Matches.fk_tournament = Tournaments.id
    WHERE Tournaments.name = 'iem-rio-major-2022';


--  ROLLUP
--  6. Подсчет количества игроков из каждой страны и их общего числа
SELECT country AS "Страна", COUNT(*) AS "Количество"
  FROM Players
  GROUP BY ROLLUP(country);


--  GROUPING SETS
--  7. Подсчет количества игроков по отдельности и в командах
SELECT Players.name AS "Игрок", Teams.name AS "Команда", count(*) 
  FROM Players 
    INNER JOIN Teams
      ON Players.fk_Players_Teams = Teams.id
  GROUP BY GROUPING SETS(Players.name, Teams.name);


--  CUBE
--  8. Суммарный рейтинг команд, исходя из среднего рейтинга ее игроков
SELECT Teams.name AS "Команда", Players.name AS "Игрок", avg(Players.rating) AS "Рейтинг"
  FROM Teams
    INNER JOIN Players
      ON Players.fk_Players_Teams = Teams.id
  GROUP BY CUBE(Teams.name, Players.name)
  ORDER BY Teams.name, Players.name;




-- Разработка процедур на PL/SQL
--  Функция выводит всех игроков указанной команды
CREATE OR REPLACE FUNCTION team_composition(team_name VARCHAR)
  returns table (
  	name                 VARCHAR(40),
  	KD                   DOUBLE PRECISION,
  	ADR                  DOUBLE PRECISION,
  	rating               DOUBLE PRECISION,
  	country              VARCHAR(40),
  	team                 VARCHAR(40)
  )
  LANGUAGE PLPGSQL    
  AS $$

DECLARE
  error_text TEXT;
BEGIN
    IF NOT EXISTS(SELECT FROM Teams WHERE Teams.name = team_name) THEN
    -- IF team_name NOT IN(SELECT Teams.name FROM Teams) THEN
    	RAISE EXCEPTION 'Team name specified with an error: %', team_name;
    END IF;
    
    RETURN QUERY
    SELECT Players.name, Players.KD, Players.ADR, Players.rating, Players.country, Teams.name
    FROM Players, Teams 
      WHERE Teams.id = Players.fk_Players_Teams AND Teams.name = team_name;
END;
$$;

SELECT * FROM team_composition('C9');

--  Процедура переводит призовой фонд турнира на баланс победившей команде
SELECT Teams.name AS "Команда", Teams.balance AS "Баланс" FROM Teams WHERE Teams.name = 'Heroic';
SELECT Tournaments.name AS "Команда", Tournaments.prize_pool AS "Призовой фонд", Tournaments.winner AS "Победитель"
  FROM Tournaments 
  WHERE Tournaments.name = 'iem-rio-major-2022';

CREATE OR REPLACE PROCEDURE prizepool_giveaway(tournament_name VARCHAR)
LANGUAGE PLPGSQL    
AS $$

DECLARE
    old_team_balance BIGINT;
    new_team_balance BIGINT;
    team_winner VARCHAR;
    team_prize BIGINT;
    error_text TEXT;
BEGIN
    IF NOT EXISTS(SELECT FROM Tournaments WHERE Tournaments.name = tournament_name) THEN
    	RAISE EXCEPTION 'Tournament name specified with an error: %', tournament_name;
    END IF;
    
    SELECT winner INTO team_winner FROM Tournaments WHERE Tournaments.name = tournament_name;
    SELECT prize_pool INTO team_prize FROM Tournaments WHERE Tournaments.name = tournament_name;
    
    SELECT balance INTO old_team_balance FROM Teams WHERE Teams.name = team_winner;
    
    UPDATE Teams SET balance = balance + team_prize WHERE Teams.name = team_winner;
    
    SELECT balance INTO new_team_balance FROM Teams WHERE Teams.name = team_winner;
    
    IF (new_team_balance - old_team_balance <> team_prize) THEN
    	RAISE EXCEPTION 'The transaction was wrong';
    END IF;
END;
$$;

CALL prizepool_giveaway('iem-rio-major-2022');

SELECT Teams.name AS "Команда", Teams.balance AS "Баланс" FROM Teams WHERE Teams.name = 'Heroic';



--  Если рейтинг игрока изменяется, то копия данных об игроке (со старым рейтингом) добавляется в таблицу Players_Backup
CREATE OR REPLACE FUNCTION log_rating_changes() 
RETURNS TRIGGER 
LANGUAGE PLPGSQL
AS $$

BEGIN
	IF NEW.rating <> OLD.rating THEN
		 INSERT INTO Players_Backup(name, KD, ADR, rating, country, fk_Players_Teams)
		 VALUES(OLD.name, OLD.KD, OLD.ADR, OLD.rating, OLD.country, OLD.fk_Players_Teams);
	END IF;

	RETURN NEW;
END;
$$;

CREATE TRIGGER player_rating_changes
  BEFORE UPDATE
  ON Players
  FOR EACH ROW
  EXECUTE PROCEDURE log_rating_changes();

SELECT Players.name AS "Игрок", Players.rating AS "Рейтинг" 
  FROM Players WHERE Players.name = 'Simple';


UPDATE Players SET rating = 0.01 WHERE name = 'Simple';


SELECT Players.name AS "Игрок", Players.rating AS "Рейтинг" 
  FROM Players WHERE Players.name = 'Simple';
SELECT Players_Backup.name AS "Игрок", Players_Backup.rating AS "Рейтинг" 
  FROM Players_Backup WHERE Players_Backup.name = 'Simple';


