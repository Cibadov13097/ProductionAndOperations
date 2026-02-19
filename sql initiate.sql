
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS students;


CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    firstname VARCHAR(20),
    lastname VARCHAR(20)
);


CREATE TABLE activities (
    student_id INTEGER,
    activity VARCHAR(25),
    level VARCHAR(10)
);



INSERT INTO students (id, firstname, lastname) VALUES
(1, 'James', 'Reyes'),
(2, 'Tiffany', 'Wolf'),
(3, 'David', 'Palmer');


INSERT INTO activities (student_id, activity, level) VALUES
(1, 'Tennis', 'Advanced'),
(1, 'Literature', 'Beginner'),
(1, 'Tennis', 'Advanced'),
(2, 'Football', 'Beginner'),
(3, 'Music', 'Advanced'),
(3, 'Chess', 'Beginner'),
(2, 'Tennis', 'Beginner'),
(1, 'Chemistry', 'Beginner'),
(3, 'Music', 'Advanced');
