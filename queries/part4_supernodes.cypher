// Крок 1. Знайдіть вузли з аномально великою кількістю ребер:
MATCH (n)
WITH n, COUNT { (n)--() } AS degree
WHERE degree > 10000
RETURN labels(n) AS labels, coalesce(n.title, toString(n.userId)) AS identifier, degree
ORDER BY degree DESC
LIMIT 20
