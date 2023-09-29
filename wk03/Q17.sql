create table Employees (
    ssn         integer, 
    birthdate   date, 
    name        varchar(30),
    worksFor    varchar(30) not null,
    primary key (ssn),
    -- foreign key (worksFor) references Departments(name) is added later,
);

create table Departments (
    name        varchar(30),
    phone       varchar(20),
    location    varchar(30),
    manager     integer not null,
    primary key (name),
    foreign key (manager) references Employees(ssn),
);

-- This had to be added after Departments was made because of 
-- the mutually dependent/recursive relationship between Employees and Departments
alter table Employees add 
    foreign key (worksFor)
    references  Departments(name);

create table Projects (
    pnum        integer, 
    title       varchar(50),
    primary key (pnum)
);

create table Dependent ( -- a weak entity
    ssn         integer not null,
    name        varchar(30),
    birthdate   date,
    relation    varchar(10) check (relation in ('spouse', 'child')),
    primary key (ssn, name), -- remember the primary key of a weak entity is its strong entity's primary key (ssn) and its own discriminator (name)
    foreign key (ssn) references Employees(ssn),
);

create table Participation (
    ssn         integer, 
    pnum        integer, 
    time        integer, 
    primary key (ssn, pnum),
    foreign key (ssn) references Employees(ssn),
    foreign key (pnum) references Departments(name),
);
