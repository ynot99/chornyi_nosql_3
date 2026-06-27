/****************
* Базові запити *
****************/
// Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0:
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE 'Thriller' IN m.genres AND r.rating > 4.0
RETURN m;

// Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам:
MATCH (u:User)-[r:RATED {rating: 5}]->(m:Movie)
WITH u, count(r) AS ratingCount
WHERE ratingCount > 50
RETURN u;

/**************************
* Запити середнього рівня *
**************************/
// Запит 3. Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4):
MATCH
  (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4.0 AND r2.rating >= 4.0
RETURN m;

// Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок:
MATCH (u:User)-[r:RATED]->(m:Movie)
UNWIND m.genres AS genre
WITH genre, avg(r.rating) AS avgRating, count(r) AS ratingsCount
RETURN genre, ratingsCount, avgRating
ORDER BY ratingsCount DESC, avgRating DESC;

/*****************
* Складні запити *
*****************/
// Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача знайти фільми, які він ще не дивився, але високо оцінили користувачі з подібними смаками:
// Взяти користувача та фільми які він високо оцінив, та знайти інших користувачів
// зі схожими смаками.
MATCH (u:User {userId: 1})-[r:RATED]->(m:Movie)
WHERE r.rating >= 4
MATCH (m)<-[r2:RATED]-(similar:User)
WHERE similar <> u AND r2.rating >= 4
WITH u, similar, count(m) AS sharedMovies
ORDER BY sharedMovies DESC
LIMIT 50
// Та знайти фільми для цього ж користувача, але які він ще не дивився,
// але високо оцінили користувачі зі схожими смаками.
MATCH (similar)-[r3:RATED]->(rec:Movie)
WHERE r3.rating >= 4 AND NOT EXISTS { (u)-[:RATED]->(rec) }
RETURN
  rec.title AS recommendation,
  count(DISTINCT similar) AS recommendedBy,
  avg(r3.rating) AS avgRating
ORDER BY recommendedBy DESC, avgRating DESC
LIMIT 20;

// Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми:
MATCH
  path =
    SHORTESTPATH ((u1:User {userId: 1})-[:RATED*..10]-(u2:User {userId: 2}))
RETURN path, length(path) AS hops;
