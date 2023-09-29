create table Suppliers (
    supplierName    varchar(30),
    city            varchar(30),
    primary key     (name)
);

create table Parts (
    numberOfPart    integer, 
    colour          varchar(30),
    primary key     (number)
);

create table Supply (
    supplier        varchar(30),
    part            integer, 
    quantity        integer, 
    primary key     (supplier,part),
    foreign key     (supplier) references Suppliers(supplierName),
    foreign key     (part) references Parts(numberOfPart)
);

-- All of the elements from the ER design appear in the relational model and this SQL
