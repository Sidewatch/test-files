// Neo4j: who worked with whom on the same project, ranked by shared projects.
CREATE (ada:Person {name: 'Ada', joined: 2019}),
       (lin:Person {name: 'Linus', joined: 2021}),
       (p:Project {name: 'Sidewatch', budget: 120000.0});

MATCH (a:Person), (b:Person), (p:Project)
WHERE a.name = 'Ada' AND b.name = 'Linus' AND p.name = 'Sidewatch'
MERGE (a)-[:WORKED_ON {role: 'lead'}]->(p)
MERGE (b)-[:WORKED_ON {role: 'engineer'}]->(p);

MATCH (a:Person)-[:WORKED_ON]->(p:Project)<-[:WORKED_ON]-(b:Person)
WHERE a <> b AND p.budget > 100000
WITH a, b, count(DISTINCT p) AS shared
ORDER BY shared DESC
LIMIT 10
RETURN a.name AS person, collect(b.name) AS colleagues, shared;
