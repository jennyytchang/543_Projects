-- CREATE DATABASE yc222db
-- USE yc222db
-- SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'

-- CREATE TABLE nodes (
-- paperID INTEGER,
-- paperTitle VARCHAR (100));
--
-- CREATE TABLE edges (
-- paperID INTEGER,
-- citedPaperID INTEGER);
-- The entire code should be wrapped in a stored procedure

-- 2.1 Task 1 Connected Components
--   1. create undirected graph
--   2  create table for query later
--   3. BFS
--   4. compute size 5-10
--   5. print

CREATE OR ALTER PROCEDURE FindConnectedComponents
AS
BEGIN
    -- 1. Create Undirected Graph View
    IF OBJECT_ID('undirectedGraph', 'V') IS NOT NULL DROP VIEW undirectedGraph;
    EXEC('
        CREATE VIEW undirectedGraph AS
        SELECT paperID AS n1, citedPaperID AS n2 FROM edges
        UNION ALL
        SELECT citedPaperID AS n1, paperID AS n2 FROM edges
    ');

    -- 2. create table for query later
    DROP TABLE IF EXISTS #components;
    DROP TABLE IF EXISTS #visited_nodes;
    DROP TABLE IF EXISTS #component_sizes;

    CREATE TABLE #components (
        componentID INT,
        paperID INT,
        PRIMARY KEY (paperID)
    );

    CREATE TABLE #visited_nodes (
        paperID INT,
        PRIMARY KEY (paperID)
    );

    CREATE TABLE #component_sizes (
        componentID INT,
        size INT,
        PRIMARY KEY (componentID)
    );

    DROP TABLE IF EXISTS #frontier;
    DROP TABLE IF EXISTS #next;
    CREATE TABLE #frontier (paperID INT,
                            PRIMARY KEY (paperID)
                           );
    CREATE TABLE #next (paperID INT,
                        PRIMARY KEY (paperID)
                       );

    -- 3. BFS Variables and Initial Count
    DECLARE @componentID INT = 0;
    DECLARE @startNode INT;
    DECLARE @totalNodes INT;
    DECLARE @processedNodes INT = 0;
    DECLARE @lowThr INT = 5;
    DECLARE @highThr INT = 10;

    SELECT @totalNodes = COUNT(*) FROM nodes;
    PRINT 'Total nodes to process: ' + CAST(@totalNodes AS VARCHAR(20));

    -- 3. Outer Loop: Start BFS for unvisited nodes (new components)
    WHILE EXISTS (SELECT 1 FROM nodes WHERE paperID NOT IN (SELECT paperID FROM #visited_nodes))
    BEGIN
        SELECT TOP 1 @startNode = paperID
        FROM nodes
        WHERE paperID NOT IN (SELECT paperID FROM #visited_nodes);

        SET @componentID = @componentID + 1;

        -- Clear Frontier for the new component
        TRUNCATE TABLE #frontier;
        INSERT INTO #frontier VALUES (@startNode);
        INSERT INTO #visited_nodes VALUES (@startNode);

        -- Inner Loop: The actual BFS
        WHILE EXISTS (SELECT 1 FROM #frontier)
        BEGIN
            TRUNCATE TABLE #next; -- Clear next for the new step

            -- Find neighbors of the current frontier that haven't been visited
            INSERT INTO #next
            SELECT DISTINCT e.n2
            FROM #frontier f
            JOIN undirectedGraph e ON e.n1 = f.paperID
            WHERE e.n2 NOT IN (SELECT paperID FROM #visited_nodes);

            -- Add current frontier nodes to the final component list (to avoid duplicates from #next)
            INSERT INTO #components (componentID, paperID)
            SELECT @componentID, paperID
            FROM #frontier;

            -- Mark the new nodes as visited
            INSERT INTO #visited_nodes
            SELECT paperID FROM #next;

            -- The new frontier is the #next set
            TRUNCATE TABLE #frontier;
            INSERT INTO #frontier
            SELECT paperID FROM #next;

        END; -- End of single component BFS

        SET @processedNodes = (SELECT COUNT(*) FROM #visited_nodes);

    END; -- End of all components loop

    -- 4. COMPUTE COMPONENT SIZES
    TRUNCATE TABLE #component_sizes;

    INSERT INTO #component_sizes (componentID, size)
    SELECT componentID, COUNT(*) AS size
    FROM #components
    GROUP BY componentID;

    -- 5. PRINT COMPONENTS WITH 5–10 PAPERS
    PRINT '---- COMPONENTS WITH SIZE ' +
          CAST(@lowThr AS VARCHAR(10)) +
          '-' +
          CAST(@highThr AS VARCHAR(10)) +
          ' ----';

    SELECT c.componentID AS Cluster,
           c.paperID,
           n.paperTitle
    FROM #components c
    JOIN #component_sizes s ON c.componentID = s.componentID
    JOIN nodes n ON c.paperID = n.paperID
    WHERE s.size BETWEEN @lowThr AND @highThr
    ORDER BY c.componentID, c.paperID;

    -- 5. Clean up temporary resources (optional for session-level temp tables)
    DROP TABLE IF EXISTS #components;
    DROP TABLE IF EXISTS #visited_nodes;
    DROP TABLE IF EXISTS #component_sizes;
    DROP TABLE IF EXISTS #frontier;
    DROP TABLE IF EXISTS #next;

END;
GO