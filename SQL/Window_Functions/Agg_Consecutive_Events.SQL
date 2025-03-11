WITH RankedBooks AS (
    SELECT 
        LB.LibraryBranch,
        LB.Section,
        LB.BookID,
        LB.Title,
        LB.Author,
        LB.Genre,
        ROW_NUMBER() OVER (ORDER BY LB.Section, LB.CheckOutDate) -
        ROW_NUMBER() OVER (PARTITION BY LB.LibraryBranch, LB.Section, LB.BookID, LB.Title, LB.Author, LB.Genre ORDER BY LB.Section, LB.CheckOutDate) 
             AS GroupID,
        LB.CheckOutDate,
        LB.ReturnDate,
        LB.Duration,
        LB.FineAmount
    FROM 
        [LibraryDatabase].[dbo].[BookSummaryView] LB
    WHERE 
        LB.CheckOutDate > '2025-01-01'
),
BookCounts AS (
    SELECT 
        LibraryBranch,
        Section,
        BookID,
        Title,
        Author,
        Genre,
        GroupID,
        COUNT(*) AS Count,
        MIN(CheckOutDate) AS CheckOutDate,
        MAX(ReturnDate) AS ReturnDate,
        SUM(Duration) AS Duration,
        SUM(FineAmount) AS FineAmount
    FROM 
        RankedBooks
    GROUP BY 
        LibraryBranch,
        Section,
        BookID,
        Title,
        Author,
        Genre,
        GroupID
),
RankedBooksCounts AS (
    SELECT 
        LibraryBranch,
        Section,
        BookID,
        Title,
        Author,
        Genre,
        GroupID,
        Count,
        CheckOutDate,
        ReturnDate,
        Duration,
        FineAmount,
        ROW_NUMBER() OVER (PARTITION BY LibraryBranch, Section, BookID, Title, Author, Genre, GroupID ORDER BY Count DESC) AS Rank
    FROM 
        BookCounts
),
CONSEC_BOOKS AS ( 
    SELECT 
        RB.LibraryBranch,
        RB.Section,
        RB.BookID,
        RB.Title,
        RB.Author,
        RB.Genre,
        RB.GroupID,
        MAX(RB.CheckOutDate) AS CheckOutDate,
        MIN(RB.ReturnDate) AS ReturnDate,
        SUM(RB.Duration) AS Duration,
        SUM(RB.FineAmount) AS FineAmount
    FROM
        RankedBooks AS RB
    GROUP BY
        RB.LibraryBranch,
        RB.Section,
        RB.BookID,
        RB.Title,
        RB.Author,
        RB.Genre,
        RB.GroupID
)
SELECT 
    CB.LibraryBranch,
    CB.Section,
    CB.BookID,
    CB.Title,
    CB.Author,
    CB.Genre,
    RC.CheckOutDate,
    CB.ReturnDate,
    CB.Duration,
    CB.FineAmount
FROM 
    CONSEC_BOOKS CB
JOIN
    (SELECT * FROM RankedBooksCounts WHERE Rank = 1) RC 
ON 
    CB.LibraryBranch = RC.LibraryBranch 
AND 
    CB.Section = RC.Section 
AND
    CB.BookID = RC.BookID
AND 
    CB.Title = RC.Title
AND 
    CB.GroupID = RC.GroupID
AND 
    CB.Genre = RC.Genre;
