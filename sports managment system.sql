-- DATABASE CREATION

CREATE DATABASE SPORTS_TEAMS;
USE SPORTS_TEAMS;


--  TABLE CREATION


-- [1] LEAGUE TABLE
CREATE TABLE Leagues (
    league_id INT PRIMARY KEY AUTO_INCREMENT,
    league_name VARCHAR(100) NOT NULL
);

-- [2] TEAMS TABLE
CREATE TABLE Teams (
    team_id INT PRIMARY KEY AUTO_INCREMENT,
    team_name VARCHAR(100) NOT NULL,
    league_id INT,
    FOREIGN KEY (league_id) REFERENCES Leagues(league_id)
);

-- [3] PLAYERS TABLE
CREATE TABLE Players (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    player_name VARCHAR(100),
    age INT,
    position VARCHAR(50),
    team_id INT,
    FOREIGN KEY (team_id) REFERENCES Teams(team_id)
);

-- [4] MATCHES TABLE
CREATE TABLE Matches (
    match_id INT PRIMARY KEY AUTO_INCREMENT,
    league_id INT,
    match_date DATE,
    team1_id INT,
    team2_id INT,
    winner_team_id INT,
    FOREIGN KEY (league_id) REFERENCES Leagues(league_id),
    FOREIGN KEY (team1_id) REFERENCES Teams(team_id),
    FOREIGN KEY (team2_id) REFERENCES Teams(team_id)
);

-- [5] SCORES TABLE
CREATE TABLE Scores (
    score_id INT PRIMARY KEY AUTO_INCREMENT,
    match_id INT,
    team_id INT,
    goals INT,
    FOREIGN KEY (match_id) REFERENCES Matches(match_id),
    FOREIGN KEY (team_id) REFERENCES Teams(team_id)
);


--  INSERT NEW SAMPLE DATA


-- LEAGUES
INSERT INTO Leagues (league_name)
VALUES 
('National Football League'),
('Super Cup'),
('Coastal Championship');

-- TEAMS
INSERT INTO Teams (team_name, league_id)
VALUES 
('Mumbai Titans', 1),
('Delhi Warriors', 1),
('Bangalore Blazers', 2),
('Hyderabad Hawks', 2),
('Goa Mariners', 3),
('Kochi Kings', 3);

-- PLAYERS
INSERT INTO Players (player_name, age, position, team_id)
VALUES 
('Rohan Sharma', 25, 'Forward', 1),
('Vikas Patel', 27, 'Defender', 1),
('Amit Verma', 23, 'Goalkeeper', 2),
('Rahul Singh', 30, 'Midfielder', 2),
('Karthik Nair', 22, 'Forward', 3),
('Sanjay Iyer', 24, 'Defender', 3),
('Arjun Rao', 29, 'Winger', 4),
('Naveen Kumar', 26, 'Striker', 4),
('Manoj Das', 28, 'Midfielder', 5),
('Ravi Pillai', 21, 'Forward', 6);

-- MATCHES
INSERT INTO Matches (league_id, match_date, team1_id, team2_id, winner_team_id)
VALUES 
(1, '2025-09-28', 1, 2, 1),
(2, '2025-10-03', 3, 4, 4),
(3, '2025-10-10', 5, 6, 6);

-- SCORES
INSERT INTO Scores (match_id, team_id, goals)
VALUES 
(1, 1, 2),
(1, 2, 1),
(2, 3, 0),
(2, 4, 3),
(3, 5, 1),
(3, 6, 2);


--  JOINS (MATCH DETAILS)

SELECT 
    m.match_id,
    l.league_name,
    t1.team_name AS Team1,
    t2.team_name AS Team2,
    w.team_name AS Winner,
    m.match_date
FROM Matches m
JOIN Leagues l ON m.league_id = l.league_id
JOIN Teams t1 ON m.team1_id = t1.team_id
JOIN Teams t2 ON m.team2_id = t2.team_id
JOIN Teams w ON m.winner_team_id = w.team_id;


--  VIEW (TEAM PERFORMANCE)

CREATE VIEW TeamPerformance AS
SELECT 
    t.team_name,
    l.league_name,
    COUNT(m.match_id) AS matches_played,
    SUM(CASE WHEN m.winner_team_id = t.team_id THEN 1 ELSE 0 END) AS matches_won
FROM Teams t
JOIN Matches m ON (t.team_id = m.team1_id OR t.team_id = m.team2_id)
JOIN Leagues l ON t.league_id = l.league_id
GROUP BY t.team_name, l.league_name;

SELECT * FROM TeamPerformance;


--  SUBQUERY (LATEST WINNING TEAM’S PLAYER)

SELECT player_name
FROM Players
WHERE team_id = (
    SELECT winner_team_id
    FROM Matches
    ORDER BY match_date DESC
    LIMIT 1
);


-- TRIGGER (UPDATE WINNER AFTER SCORE INSERTION)

DELIMITER //
CREATE TRIGGER update_winner_after_score
AFTER INSERT ON Scores
FOR EACH ROW
BEGIN
    DECLARE team1 INT;
    DECLARE team2 INT;
    DECLARE score1 INT;
    DECLARE score2 INT;

    SELECT team1_id, team2_id INTO team1, team2
    FROM Matches WHERE match_id = NEW.match_id;

    SELECT goals INTO score1 FROM Scores WHERE match_id = NEW.match_id AND team_id = team1;
    SELECT goals INTO score2 FROM Scores WHERE match_id = NEW.match_id AND team_id = team2;

    IF score1 > score2 THEN
        UPDATE Matches SET winner_team_id = team1 WHERE match_id = NEW.match_id;
    ELSEIF score2 > score1 THEN
        UPDATE Matches SET winner_team_id = team2 WHERE match_id = NEW.match_id;
    ELSE
        UPDATE Matches SET winner_team_id = NULL WHERE match_id = NEW.match_id;
    END IF;
END //
DELIMITER ;

--  STORED PROCEDURE (PLAYER COUNT BY TEAM)

DELIMITER //
CREATE PROCEDURE GetPlayerCountByTeam()
BEGIN
    SELECT 
        t.team_name,
        COUNT(p.player_id) AS player_count
    FROM Teams t
    LEFT JOIN Players p ON t.team_id = p.team_id
    GROUP BY t.team_name;
END //
DELIMITER ;

CALL GetPlayerCountByTeam();

--  INDEXES (PERFORMANCE IMPROVEMENT)

CREATE INDEX idx_teams_league_id ON Teams(league_id);
CREATE INDEX idx_players_team_id ON Players(team_id);
CREATE INDEX idx_matches_league_id ON Matches(league_id);
CREATE INDEX idx_matches_team1_id ON Matches(team1_id);
CREATE INDEX idx_matches_team2_id ON Matches(team2_id);
CREATE INDEX idx_matches_match_date ON Matches(match_date);
CREATE INDEX idx_scores_match_id ON Scores(match_id);
CREATE INDEX idx_scores_team_id ON Scores(team_id);


--  CTE (LAST 30 DAYS MATCHES)

WITH cte AS (
    SELECT 
        m.match_id,
        m.match_date,
        m.league_id,
        s.team_id,
        s.goals
    FROM Matches m
    JOIN Scores s ON m.match_id = s.match_id
    WHERE m.match_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT 
    cte.match_id,
    t.team_name,
    l.league_name,
    cte.match_date,
    cte.goals
FROM cte
JOIN Teams t ON cte.team_id = t.team_id
JOIN Leagues l ON t.league_id = l.league_id
ORDER BY cte.match_date DESC, cte.goals DESC;