// Крок 1. Знайдіть вузли з аномально великою кількістю ребер:
MATCH (n)
WITH n, COUNT { (n)--() } AS degree
WHERE degree > 1000
RETURN labels(n), n.name, degree
ORDER BY degree DESC
LIMIT 20;
