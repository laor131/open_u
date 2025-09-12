--Question  1
create table Users(
uid int primary key,
name varchar(30),
email varchar(50),
password varchar(50),
descr varchar(255),
country varchar(50)
);

create table Post(
pid int primary key,
uid int,
content varchar(255),
imageURL varchar(255),
pdate date,
ptime time,
foreign key (uid) references Users(uid) on delete cascade
);

create table Comment(
pid int,
cdate date,
ctime time,
uid int,
content varchar(255),
foreign key (pid) references Post(pid) on delete cascade,
foreign key (uid) references Users(uid) on delete cascade
);

create table Likes(
uid int,
pid int,
ldate date,
ltime time,
foreign key (pid) references Post(pid) on delete cascade,
foreign key (uid) references Users(uid) on delete cascade
);

create table Follow(
fuid int,
uid int,
primary key (fuid, uid),
foreign key (fuid) references Users(uid) on delete cascade,
foreign key (uid) references Users(uid) on delete cascade,
check (fuid <> uid)
);


--Question 2
create function trigf1()
returns trigger as $$
declare
    post_date date;
    post_time time;
begin
    select pdate, ptime into post_date, post_time
    from post
    where pid = new.pid;

    if new.cdate < post_date or (new.cdate = post_date and new.ctime <= post_time) then
        raise exception 'comment time must be after post time';
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trigger_check_comment_time
before insert on Comment
for each row
execute function trigf1();

--Question 3
insert into Users (uid, name, email, password, descr, country) values
(1, 'Alice', 'alice@example.com', 'pass1', 'photographer', 'israel'),
(2, 'Bob', 'bob@example.com', 'pass2', 'traveler', 'usa'),
(3, 'Carol', 'carol@example.com', 'pass3', 'chef', 'italy'),
(4, 'David', 'david@example.com', 'pass4', 'musician', 'israel'),
(5, 'eve', 'eve@example.com', 'pass5', 'techie', 'canada'),
(6, 'Frank', 'frank@example.com', 'pass6', 'gamed', 'japan'),
(7, 'Grace', 'grace@example.com', 'pass7', 'reader', 'uk'),
(8, 'Hank', 'hank@example.com', 'pass8', 'blogger', 'france');

insert into Post (pid, uid, content, imageurl, pdate, ptime) values
(101, 1, 'sunset in tel aviv', 'sun.jpg', '2025-05-05', '18:30'),
(102, 2, 'hiking the rockies', 'rockies.jpg', '2025-04-20', '10:00'),
(103, 3, 'best pasta recipe', 'pasta.jpg', '2025-04-22', '12:15'),
(104, 4, 'new song release', 'song.jpg', '2025-05-01', '15:45'),
(105, 1, 'morning coffee', 'coffee.jpg', '2025-03-15', '08:20'),
(106, 5, 'tech trends 2025', 'tech.jpg', '2025-05-03', '09:00'),
(107, 6, 'gaming marathon', 'game.jpg', '2025-04-25', '21:40'),
(108, 2, 'cherry blossoms', 'sakura.jpg', '2025-04-04', '07:50'),
(109, 3, 'street food adventures', 'street.jpg', '2025-05-06', '11:00'),
(110, 4, 'guitar tutorial', 'guitar.jpg', '2025-02-18', '17:10'),
(111, 3, 'city tour', 'oldcity.jpg', '2025-03-01', '10:00');

insert into Comment (pid, cdate, ctime, uid, content) values
(101, '2025-05-05', '19:00', 2, 'beautiful!'),
(101, '2025-05-05', '19:05', 3, 'love the colors.'),
(102, '2025-04-21', '14:00', 1, 'awesome hike!'),
(102, '2025-04-22', '16:00', 8, 'nice view.'),
(103, '2025-04-22', '13:00', 5, 'yummy!'),
(104, '2025-05-02', '10:15', 6, 'great beat!'),
(106, '2025-05-03', '11:30', 2, 'interesting insights.'),
(107, '2025-04-26', '22:00', 4, 'good luck!'),
(108, '2025-04-04', '08:10', 3, 'so pretty!'),
(109, '2025-05-06', '12:10', 5, 'delicious.'),
(110, '2025-02-19', '18:00', 1, 'helpful tutorial.');

insert into Likes (uid, pid, ldate, ltime) values
(1, 101, '2025-05-05', '21:00'),
(1, 102, '2025-03-21', '14:05'),
(1, 103, '2025-04-22', '14:10'),
(1, 104, '2025-05-02', '11:00'),
(1, 105, '2025-03-15', '09:05'),
(1, 111, '2025-03-02', '11:00'),
(2, 101, '2025-05-05', '18:50'),
(2, 103, '2025-04-22', '12:30'),
(2, 105, '2025-03-15', '09:00'),
(2, 111, '2025-03-02', '11:05');

insert into Follow (fuid, uid) values
(2, 1),
(3, 1),
(4, 1),
(6, 1),
(1, 2),
(1, 3),
(2, 3),
(4, 2),
(3, 4),
(5, 4),
(2, 6);

--Question 4
select pid, uid, content from Post
where pdate >= '2025-05-01' and pdate <= '2025-05-31';

--Question 5
select uid, name, country
from Users natural join Post
where Post.content ilike '%city%';

--Question 6
select p.pid, p.content
from Post p
join Users u on p.uid = u.uid
join Comment c on p.pid = c.pid
where u.country = 'usa'
group by p.pid, p.content, c.cdate
having count(*) >= 4;

--Question 7
select u.*
from Users u
join Likes l on u.uid = l.uid
join Post p on l.pid = p.pid
left join Follow f on f.fuid = u.uid and f.uid = p.uid
where f.uid is null and u.uid <> p.uid;

--Question 8
select u.uid, u.name
from Users u
left join Comment c on u.uid = c.uid
join Follow f on f.fuid = u.uid
join Users followed on followed.uid = f.uid and followed.country = 'Israel'
where c.uid is null
group by u.uid, u.name
having count(distinct f.uid) >= 3;

--Question 9
with posting_users as (
    select uid
    from Post
    group by uid
    having count(*) >= 3
)
select f.fuid, u.name
from Follow f
join posting_users pu on f.uid = pu.uid
join Users u on u.uid = f.uid
group by f.fuid, u.name
order by count(*) desc
limit 1;

--Question 10
select f.fuid
from Follow f
group by f.fuid
having count(*) = (
    select count(distinct f2.uid)
    from Follow f2
    join Post p on p.uid = f2.uid and p.content ilike '%city%'
    join Likes l on l.pid = p.pid and l.uid = f2.fuid
    where f2.fuid = f.fuid
);
