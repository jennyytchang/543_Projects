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

-- 2. PageRank
-- 2-1. Initialization
-- 2-2. compute outDegree
-- 2-3. compute PageRank
-- 2.4. select top 10 pagerank

CREATE OR ALTER PROCEDURE CalculatePageRank
AS
BEGIN
    -- 2-1 Initialize PageRank
    DECLARE @d FLOAT = 0.85;         -- damping factor
    DECLARE @N FLOAT;                -- total number of papers
    DECLARE @iteration INT = 0;
    DECLARE @diff FLOAT = 99;             -- convergence diff
    DECLARE @endThr FLOAT = 0.01;

    SELECT @N = COUNT(*) FROM nodes;

    IF OBJECT_ID('tempdb..#pagerank') IS NOT NULL DROP TABLE #pagerank;
    CREATE TABLE #pagerank (
        paperID INT,
        rank FLOAT,
        PRIMARY KEY (paperID)
    );

    INSERT INTO #pagerank (paperID, rank)
    SELECT paperID, 1.0 / @N FROM nodes;

    -- 2.2. Precompute outdegree for each node
    IF OBJECT_ID('tempdb..#outdegree') IS NOT NULL DROP TABLE #outdegree;
    CREATE TABLE #outdegree (
        paperID INT,
        outdeg INT,
        PRIMARY KEY (paperID));

    INSERT INTO #outdegree
    SELECT e.paperID, COUNT(DISTINCT e.citedPaperID)
    FROM edges e
    GROUP BY e.paperID;

    -- 2-3. Iterative PageRank Computation
    WHILE (@diff > @endThr)
    BEGIN
        SET @iteration = @iteration + 1;
        PRINT '--- Iteration ' + CAST(@iteration AS VARCHAR(5)) + ' ---';

        IF OBJECT_ID('tempdb..#new_pagerank') IS NOT NULL DROP TABLE #new_pagerank;
        CREATE TABLE #new_pagerank (paperID INT PRIMARY KEY, rank FLOAT);

        -- Step 1: compute total rank from sink nodes (no outgoing edges)
        DECLARE @sinkPR FLOAT = (
            SELECT SUM(p.rank)
            FROM #pagerank p
            WHERE p.paperID NOT IN (SELECT paperID FROM #outdegree)
        );

        -- Step 2: distribute PageRank
        INSERT INTO #new_pagerank (paperID, rank)
        SELECT
            n.paperID,
            (1 - @d) / @N
            + @d * (
                ISNULL(@sinkPR / @N, 0)
                + ISNULL(SUM(pr.rank / od.outdeg), 0)
            ) AS new_rank
        FROM nodes n
        LEFT JOIN edges e ON e.citedPaperID = n.paperID
        LEFT JOIN #pagerank pr ON e.paperID = pr.paperID
        LEFT JOIN #outdegree od ON e.paperID = od.paperID
        GROUP BY n.paperID;

        -- Step 3: compute difference (for convergence check)
        SELECT @diff = SUM(ABS(p.rank - n.rank))
        FROM #pagerank p
        JOIN #new_pagerank n ON p.paperID = n.paperID;

        PRINT 'Iteration diff = ' + CAST(@diff AS VARCHAR(20));

        -- Step 4: update for next iteration
        TRUNCATE TABLE #pagerank;
        INSERT INTO #pagerank
        SELECT * FROM #new_pagerank;

        -- Step 5: optional progress message
        IF @diff <= @endThr
        BEGIN
            PRINT ' Converged after ' + CAST(@iteration AS VARCHAR(5))
                + ' iterations (diff = ' + CAST(@diff AS VARCHAR(20)) + ')';
            BREAK;
        END
    END; -- End While

    -- 2.4. select top 10
    SELECT TOP 10
        p.paperID,
        n.paperTitle,
        p.rank AS pagerankScore
    FROM #pagerank p
    JOIN nodes n ON p.paperID = n.paperID
    ORDER BY p.rank DESC;

    SELECT SUM(p.rank) AS SumCheck
    FROM #pagerank p

    -- Cleanup Persistent Temporary Tables
    DROP TABLE IF EXISTS #pagerank;
    DROP TABLE IF EXISTS #outdegree;
END;
GO
