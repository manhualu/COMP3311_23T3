-- Q2. A new government initiative to get more 
-- young people into work cuts the salary levels of all workers under 25 by 20%. 
-- Write an SQL statement to implement this policy change.
update Employees 
set    salary = salary * 0.8
where  age < 25;

-- Q10. 
-- 1. Disallow the deletion of Departments tuple. Default behaviour.
-- It results from the CREATE TABLE definition. Thus, no change to usual
create table Employees (
    eid     integer,
    ename   text,
    age     integer,
    salary  real,
    primary key (eid)
);

create table Departments (
    did     integer, 
    dname   text, 
    budget  real, 
    manager integer references Employee(eid),
    primary key (did)

);

-- 2. When a Departments tuple is deleted, if any WorksIn tuple refer to it. The WorksIn tuple will also be deleted.
create table WorksIn (
    eid     integer,
    did     integer,
    percent real,
    primary key (eid,did),
    foreign key (eid) references Employees(eid) on delete cascade,
    foreign key (did) references Departments(did) on delete cascade
);


-- 3. For every WorksIn tuple that refers to the deleted dId from Departments, we will set the dId in the WorksIn tuple to a default dId. 
create table WorksIn (
    eid         integer, 
    did         integer default 1, 
    foreign key (eid) references Employees(id),
    foreign key (did) references Departments(did) on delete set default,
    primary key (eid, did)
);


-- Q11. For each of the possible cases in the previous question, 
-- show how deletion of the Engineering department would affect the following database:

-- 1. Disallow. Database would not change. 
-- DBMS would print an error message about referential integrity constraint violation. 

-- 2. On Delete Cascade.
  DID DNAME               BUDGET  MANAGER
----- --------------- ---------- --------
    1 Sales               500000        2
    3 Service             200000        4

  EID   DID  PCT_TIME
----- ----- ---------
    2     1      1.00
    3     1      0.50
    3     3      0.50
    4     3      0.50

-- 3. On Delete Set NULL
  DID DNAME               BUDGET  MANAGER
----- --------------- ---------- --------
    1 Sales               500000        2
    3 Service             200000        4

  EID   DID  PCT_TIME
----- ----- ---------
    1  NULL      1.00
    2     1      1.00
    3     1      0.50
    3     3      0.50
    4  NULL      0.50
    4     3      0.50
    5  NULL      0.75
-- This is not the best behaviour, because when the DID becomes NULL in the WorksIn table
-- affected tuples in the WorksIn table will be invalid as the primary id cannot have NULL.

-- 4. On Delete Set Default dId = 1
  DID DNAME               BUDGET  MANAGER
----- --------------- ---------- --------
    1 Sales               500000        2
    3 Service             200000        4

  EID   DID  PCT_TIME
----- ----- ---------
    1     1      1.00
    2     1      1.00
    3     1      0.50
    3     3      0.50
    4     1      0.50
    4     3      0.50
    5     1      0.75


-- Q12. Find the names of suppliers who supply some red part.
select  s.sname 
from    Suppliers s 
join    Catalog c on (c.sid = s.sid)
join    Parts p on (p.pid = c.pid)
where   p.colour = "red";

-- OR (not recommended method)

select s.sname
from   Suppliers s, Parts p, Catalog c
where  p.colour='red' and c.pid = p.pid and c.sid = s.sid


-- Q13. Find the sids of suppliers who supply some red or green part.
select  s.sid 
from    Suppliers s 
join    Catalog c on (c.sid = s.sid)
join    Parts p on (p.pid = c.pid)
where   p.colour = "red" or p.colour = "green";


-- Q14. Find the sids of suppliers who supply some red part or whose address is 221 Packer Street.
select s.sid
from   Suppliers s
join   Catalog c on (c.sid = s.sid)
join   Parts p on (p.pid = c.pid) 
where  p.colour = "red"      
       or s.address = "221 Packer Street";

-- Q15. Find the sids of suppliers who supply some red part and some green part.

-- SHOW THEM BELOW IS NOT CORRECT, IS A COMMON MISTAKE
-- BECAUSE THE COLOUR OF THE PART CANNOT BE BOTH RED 
-- AND GREEN AT SAME TIME
select  s.sid 
from    Suppliers s 
join    Catalog c on (c.sid = s.sid)
join    Parts p on (p.pid = c.pid)
where   p.colour = "red" and p.colour = "green";

-- SHOW WITH THIS EXAMPLE: 

-- SUPPLIERS 
  SID  SNAME          ADDRESS   
----- --------------- -------- 
    1 John              asdf     
    2 Jane              mksd     
    3 Jack              kdfm    

-- PARTS 
  PID PNAME               COLOUR 
----- --------------- ---------- 
    1 Screwdriver         red        
    2 Screws              yellow        
    3 Chainsaw            green        
    4 Drill               red        

-- CATALOG
  SID   PID  COST 
----- ----- ---------
    1     2      1.00
    2     1      1.00
    3     1      0.50
    3     3      0.50
    1     3      3.00
    3     2      8.50
    3     4      6.20

"John supplies Screws which is yellow"
"Jane supplies Screwdriver which is red"
"Jack supplies Screwdriver which is red"
"Jack supplies Chainsaw which is green"
"John supplies Chainsaw which is green"
"Jack supplies Screws which is yellow"
"Jack supplies Drills which is red"

-- A part cannot be red and green at the same time

-- CORRECT WAY
(
  select c.sid 
  from    Catalog c 
  join    Parts p on (p.pid = c.pid)
  where   p.colour = "red"
)
-- Jack, Jane

intersect 

(
  select  c.sid 
  from    Catalog c 
  join    Parts p on (p.pid = c.pid)
  where   p.colour = "green"
);
-- Jack, John

-- Therefore, supplier that appears in both (intersection) is Jack


-- Q16. Find the sids of suppliers who supply every part.
-- i.e. Find the sids of suppliers whose distinct parts they sell is the same amount as all distinct parts that exist

-- AGGREGATE FUNCTION
-- PUT THESE IN HAVING CLAUSE, NOT WHERE CLAUSE
-- count
-- avg
-- min
-- max
-- concat

select count(*) from Parts; -- count of all parts

select    c.sid
from      Catalog c
group by  c.sid
having    count(distinct c.pid) = (select count(*) from Parts);


-- Q17. Find the sids of suppliers who supply every red part.
select  c1.sid
from    Catalog c1
-- looking for sids that do not return tuples where a red part is not supplied
where   not exists (
                    -- except gets the red parts that are not supplied by this sid 
                    (
                      select  p.pid
                      from    Parts p
                      where   p.colour = 'red'
                    ) -- gets the red parts i.e. Screwdriver, Drill
                    except
                    (
                      select  c2.pid
                      from    Catalog c2
                      where   c1.sid = c2.sid
                    ) -- gets the parts this sid supplies 
                  );


-- Q18. Find the sids of suppliers who supply every red or green part.
select c1.sid
from Catalog c1
where not exists (
                  -- except gets the red parts and green parts that are not supplied by this sid 
                  (
                    select  p.pid
                    from    Parts p
                    where   p.colour = 'red' or p.colour = 'green'
                  )
                    except
                  (
                    select  c2.pid
                    from    Catalog c2
                    where c1.sid = c2.sid
                  )
                );

-- Difference to Q19: Here, you have to supply all red AND green parts. 
-- Is CONFUSING because it says OR, but the supplier actually has to be supplying all the red parts AND all the green parts. 
-- Because the pool in the left Venn diagram consists of all parts that are red and green and is then excepted. 


-- Q19. Find the sids of suppliers who supply every red part or supply every green part.
(
  select  c1.sid
  from    Catalog c1
  where   not exists (
                      (
                        select p.pid
                        from   Parts p
                        where  p.colour = 'red'
                      )
                        except
                      (
                        select  c2.pid
                        from    Catalog c2
                        where   c1.sid = c2.sid
                      )
                    )
)

union 

(
  select  c1.sid
  from    Catalog c1
  where   not exists (
                      (
                        select p.pid
                        from   Parts p
                        where  p.colour = 'green'
                      )
                        except
                      (
                        select  c2.pid
                        from    Catalog c2
                        where   c1.sid = c2.sid
                      )
                    )
);

-- Difference to Q18: Here, you can supply either all the red parts OR all the green parts, 
-- but don’t have to be supplying all the red AND green parts. 
-- Therefore, suppliers from Q18 is a subset of suppliers from Q19.


-- Q20. Find pairs of sids such that the supplier with the first sid charges more for some part than the supplier with the second sid.
    -- First sid charges more than the second side
    -- must be the same part
select  c1.sid, c2.sid
from    Catalog c1, Catalog c2
where   c1.pid = c2.pid and c1.sid <> c2.sid and c1.cost > c2.cost;
-- <> means not equal to

-- Q21. Find the pids of parts that are supplied by at least two different suppliers.
select c1.pid
from   Catalog c1
where  exists (
                select  c2.sid
                from    Catalog c2
                where   c2.pid = c1.pid 
                        and c2.sid != c1.sid
              );


-- [SKIP] 
-- Q22. Find the pids of the most expensive part(s) supplied by suppliers named "Yosemite Sham".
select c.pid
from   Catalog c, Suppliers s
where  s.sname='Yosemite Sham' and c.sid = s.sid and
       c.cost >= all(
                      select  c2.cost
                      from    Catalog c2, Suppliers s2
                      where   s2.sname="Yosemite Sham"
                              and c2.sid = s2.sid
                    );


-- Q23. Find the pids of parts supplied by every supplier at a price less than 200 dollars 
    -- this part is supplied by every supplier 
    -- this part is cheaper than 200 dollar (has a price < 200)
select      c.pid 
from        Catalog c 
where       c.price < 200.00
group by    c.pid
having      count(*) = (select count(*) from Suppliers);
