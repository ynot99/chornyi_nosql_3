/*
5.1. PageRank на графі фільмів
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

// !!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-()
DELETE co;

/*
5.2. Виявлення спільнот (Louvain)
*/
// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
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

// !!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-()
DELETE sim;

/*
5.3. Найкоротший шлях між користувачами
*/
// Проєкція потрібна та сама, що і для Louvain — пересотворіть, якщо видалили
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
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

// !!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!

CALL gds.graph.drop('userGraph');
