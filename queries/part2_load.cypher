/*
# Завантаження вузлів

Завантажте вузли в базу даних. Всі запити збережіть у файл part2_load.cypher. У README поясніть кожен запит: що він робить і чому написаний саме так.

Використовуйте MERGE замість CREATE — це захист від дублювання при повторному запуску скрипту:
*/
// 1. Користувачі
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET
  u.gender = row.gender,
  u.age = toInteger(row.age),
  u.occupation = toInteger(row.occupation);

// 2. Фільми
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title, m.genres = split(row.genres, '|');

/*
# Індекси

Створіть індекси до завантаження ребер — це прискорить пошук вузлів при створенні зв’язків:
*/
CREATE INDEX user_id_index IF NOT EXISTS
FOR (u:User)
ON (u.userId);
CREATE INDEX movie_id_index IF NOT EXISTS
FOR (m:Movie)
ON (m.movieId);

/*
# Завантаження ребер (оцінок)

Завантажте ребра в базу даних. Швидше за все, ребер у вас буде досить багато, тому їх не можна завантажувати однією транзакцією — вона впаде через таймаут або пам’ять. Використовуйте apoc.periodic.iterate, який розбиває роботу на батчі:
*/
CALL
  apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
    "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toInteger(row.rating), r.timestamp = toInteger(row.timestamp)",
    {batchSize: 10000, parallel: false}
  );

// Перевірте результат:
MATCH (u:User)
RETURN count(u) AS users;
MATCH (m:Movie)
RETURN count(m) AS movies;
MATCH ()-[r:RATED]->()
RETURN count(r) AS ratings;
