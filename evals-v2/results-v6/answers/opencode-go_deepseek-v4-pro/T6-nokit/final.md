Done. I grouped the reading log by author so each author's books now appear together under an author header.

`BookListScreen.kt:10-12` derives the grouping at the presentation boundary (per the MVI guidance), sorting authors alphabetically and each author's books by title. Each book line now omits the repeated author name since it's the section header.

Compiles clean (`:feature:notes:compileKotlinJvm` BUILD SUCCESSFUL).