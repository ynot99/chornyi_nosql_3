/*
5.1. PageRank на графі фільмів

Побудуємо граф, де фільми пов’язані через користувачів, які оцінили обидва фільми високо. Далі запустіть алгоритм PageRank на отриманому графі, проаналізуйте результати та дайте відповіді на питання в кінці секції.
*/
// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE
  size([(m1)<-[:RATED]-() | 1 ]) > 20 AND size([(m2)<-[:RATED]-() | 1 ]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL
  gds.graph.project(
    'movieGraph',
    'Movie',
    {CO_RATED: {orientation: 'UNDIRECTED', properties: 'weight'}}
  )
  YIELD graphName, nodeCount, relationshipCount;

// Крок 3: запускаємо PageRank, враховуючи вагу CO_RATED (кількість спільних користувачів)
CALL
  gds.pageRank.stream(
    'movieGraph',
    {relationshipWeightProperty: 'weight'}
  )
  YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS movie, score
ORDER BY score DESC
LIMIT 20;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-()
DELETE co;

/*
5.2. Виявлення спільнот (Louvain)
*/
// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: створюємо проєкцію
CALL
  gds.graph.project(
    'userSimilarity',
    'User',
    {SIMILAR: {orientation: 'UNDIRECTED', properties: 'weight'}}
  )
  YIELD graphName, nodeCount, relationshipCount;

// Крок 3: запускаємо Louvain і записуємо id спільноти кожному User
CALL
  gds.louvain.write(
    'userSimilarity',
    {relationshipWeightProperty: 'weight', writeProperty: 'communityId'}
  )
  YIELD communityCount, modularity;

// Крок 4а: 10 найбільших спільнот за кількістю користувачів
MATCH (u:User)
WHERE u.communityId IS NOT NULL
WITH u.communityId AS community, count(u) AS size
RETURN community, size
ORDER BY size DESC
LIMIT 10;

// Крок 4б: топ-3 жанри (за фільмами, оціненими на 4+) у кожній з 10 найбільших спільнот
MATCH (u:User)
WHERE u.communityId IS NOT NULL
WITH u.communityId AS community, count(u) AS size
ORDER BY size DESC
LIMIT 10
WITH collect(community) AS topCommunities
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE u.communityId IN topCommunities AND r.rating >= 4
UNWIND m.genres AS genre
WITH u.communityId AS community, genre, count(*) AS genreCount
ORDER BY community, genreCount DESC
WITH community, collect({genre: genre, count: genreCount})[0..3] AS topGenres
RETURN community, topGenres
ORDER BY community;

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-()
DELETE sim;

/*
5.3. Найкоротший шлях між користувачами
*/
// Проєкція потрібна та сама, що і для Louvain — пересотворіть, якщо видалили
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL
  gds.graph.project(
    'userGraph',
    'User',
    {SIMILAR: {orientation: 'UNDIRECTED', properties: 'weight'}}
  )
  YIELD graphName, nodeCount, relationshipCount;

// Крок 3: алгоритм Дейкстри між обраною парою користувачів (userId: 1 -> userId: 2)
MATCH (source:User {userId: 1})
MATCH (target:User {userId: 2})
CALL
  gds.shortestPath.dijkstra.stream(
    'userGraph',
    {sourceNode: source, targetNode: target}
  )
  YIELD totalCost, nodeIds, costs
RETURN
  totalCost,
  [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS pathUserIds,
  size(nodeIds) - 2 AS intermediateNodes;

CALL gds.graph.drop('userGraph');
