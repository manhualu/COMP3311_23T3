-- Q2
Employee(id:integer, name:text, works_in:integer, salary:integer, ...)
Department(id:integer, name:text, manager:integer, ...)

-- write an assertion to ensure that no employee in a department earns more than the manager of their department.
create assertion employee_manager_salary check (
    not exists (
        -- Cases where the employees salary is more than the manager
        select  * 
        from    Employee emp  
        join    Department d on (d.id = emp.works_in)
        join    Employee mgr on (d.manager = mgr.id)
        where   emp.salary > mgr.salary 
    )
);


-- Q6
create table R(
    a int, 
    b int, 
    c text,
    primary key(a,b)
);

-- State how you could use triggers to implement the following constraint checking:
-- a. primary key constraint on relation R

-- The constraints for primary key(a,b) is:
    -- a or b cannot be null
    -- pk needs to be unique i.e. (a,b) must not already exist in the any of R's rows

-- We would want to check the pk BEFORE:
    -- INSERT a row
    -- UPDATE a row

create or replace function pk_check_R() returns trigger 
as $$ 
begin 
    -- Constraint 1: a or b cannot be null
    if (NEW.a is null or NEW.b is null) then 
        raise exception 'Primary key cannot be null!';
    end if;

    -- If updating and the new row's pk is identical to the updated one, 
    -- end function as pk has not been changed and no need to do pk uniqueness check
    if (TG_OP = 'UPDATE' and OLD.a = NEW.a and OLD.b = NEW.b) then 
        return NEW;
    end if; 

    -- Constraint 2: pk needs to be unique 
    select  * 
    from    R  
    where   R.a = NEW.a 
            and R.b = NEW.b; 

    if (FOUND) then
        raise exception 'Primary key must be unique!!! :((';
    end if; 

    return NEW;
end;
$$ language plpgsql

create trigger pk_trigger_R 
before insert or update 
on R 
for each row 
execute procedure pk_check_R();


-- b. foreign key constraint between T.j and S.x
create table S(
    x int primary key,
    y int
);
create table T(
    j int primary key,
    k int references S(x)
);

-- Constraints on foreign key (referential integrity): 
    -- 1. When updating/inserting row to T, we need to check T.k refers to a key in S 
    -- 2. When deleting/updating row to S, we need to make sure no T.k refers to that S 
    --    (this can be handled with on delete cascade, but we will assume there are no delete cascade semantics)

-- Will be easiest to split it into two triggers
-- because we are looking at separate tables

-- Trigger 1: 
    --  When updating/inserting row to T, we need to check T.k refers to a key in S 
create or replace function fk_check_T() returns trigger 
as $$ 
begin 
    -- Foreign key NEW.k must refer to a key in S 
    select  * 
    from    S 
    where   S.x = NEW.k;

    if (not FOUND) then 
        raise exception 'Non-existent S.x key being referenced by T!';
    end if; 

    return NEW; 
end;
$$ language plpgsql

create trigger fk_trigger_T
before insert or update 
on T 
for each row 
execute procedure fk_check_T();

-- Trigger 2: 
    -- When deleting/updating row to S, we need to make sure no T.k refers to that S 
create or replace function ref_check_S() returns trigger 
as $$ 
begin 
    -- If updating, ignore if the updated new tuple has the same primary key x 
    if (TG_OP = 'UPDATE' and OLD.x = NEW.x) then 
        return; 
    end if;

    -- When deleting/updating S, check if any T row has a reference to S.x 
    select  * 
    from    T
    where   T.k = OLD.x 

    if (FOUND) then 
        raise exception 'References to S.x from T!';
    end if; 
end;
$$ language plpgsql

create trigger ref_trigger_S
before delete or update 
on S 
for each row 
execute procedure ref_check_S();


-- Q7. 
create table S(
    x int primary key,
    y int
);
-- Explain the difference between these triggers
-- Assuming that S contains PK (1,2,3,4,5,6,7,8,9)
create trigger updateS1 after update on S
for each row execute procedure updateS();

create trigger updateS2 after update on S
for each statement execute procedure updateS();

-- a. 
update S set y = y + 1 where x = 5;
-- We are updating a single record 
-- For each row/ For each statement -> do the same thing (as we are only updating one row i.e. where x = 5)

-- b. 
update S set y = y + 1 where x > 5;
-- updateS1 trigger:
-- Records with x that are 6, 7, 8, 9 are updating
-- update 6 -> call updateS1
-- update 7 -> call updateS1
-- update 8 -> call updateS1
-- update 9 -> call updateS1
-- For each row calls the trigger function after every changed row

-- updateS2 trigger: 
-- For each statement
-- SQL statement updates 6,7,8,9
-- UpdateS2 is then called
-- For each statement calls the trigger ONCE after the rows have been changed


-- Q14.
-- Imagine that PostgreSQL did not have an avg() aggregate to compute the mean of a column of numeric values.
-- How could you implement it using a PostgreSQL user-defined aggregation definition (called mean)?
-- Assume that it ignores null values. If the column is empty (has no values) return null.

-- Step 1. What do you need to calculate average?
    -- sum of all numbers
    -- count of all numbers

-- Step 2. Make the sType (values to carry throughout calculation)
create type AvgState as (sum numeric, count integer);

-- Step 3. Initial condition for the state:
initcond = '(0,0)' -- string type, weirdly it just is

-- Step 4. sfunc, what I do to update the state 
create or replace function mean_iterator(s AvgState, v numeric) returns AvgState
as $$ 
begin 
    -- Skip update state if v is null as you cannot ad null to sum (a numeric)
    if (v is not null) then 
        s.sum := s.sum + v; 
        s.count := s.count + 1;
    end if; 
    
    return s; 
end;
$$ language plpgsql 

-- Step 5. What kind of function do I need to return the average from the final state? 
-- i.e. what will my finalfunc be?
create or replace function mean_final(s AvgState) returns numeric 
as $$ 
begin 
    
    -- If there were no rows, return null. 
    if (s.count = 0) then 
        return null;
    end if;

    -- Calculate the average
    return s.sum::numeric/s.count; -- type cast is important due to / doing integer division by default
end;
$$ language plpgsql 

-- Step 6. FINALLY create our aggregate mean function!
create aggregate mean(numeric) (
    stype = AvgState,
    initcond = '(0, 0)', -- string type, weirdly it just is
    sfunc = mean_iterator,
    finalfunc = mean_final
);

-- You would use your new aggregate in the following way: 
select  mean(e.salary)
from    Employees e;
