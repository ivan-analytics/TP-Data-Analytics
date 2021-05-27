-- Посчитать количество матчей, в которых first_blood_time больше 1 минуты, но меньше 3х минут;
select count(*) as match_count
from match
where first_blood_time between 60 and 60*3;

-- Вывести идентификаторы участников (исключая анонимные аккаунты где айдишник равен нулю),
-- которые участвовали в матчах, в которых победили силы Света и
-- количество позитивных отзывов зрителей было больше чем количество негативных;
select account_id
from players p left join match m on p.match_id = m.match_id
where account_id != 0
  and m.radiant_win = 'True'
  and m.positive_votes > m.negative_votes;

-- Получить идентификатор игрока и среднюю продолжительность его матчей;
select p.account_id, avg(m.duration)
from players p left join match m on p.match_id = m.match_id
group by p.account_id;

-- Получить суммарное количество потраченного золота, уникальное количество использованных персонажей,
-- среднюю продолжительность матчей (в которых участвовали данные игроки) для анонимных игроков;
select sum(gold_spent) as gold_spent_sum,
       count(distinct hero_id) as unique_heros_use_count,
       round(avg(m.duration), 0) as avg_match_duration
from players p left join match m on p.match_id = m.match_id
where account_id = 0;

-- для каждого героя (hero_name) вывести:
-- количество матчей в которых был использован,
-- среднее количество убийств, минимальное количество смертей,
-- максимальное количество потраченного золота,
-- суммарное количество позитивных отзывов зрителей,
-- суммарное количество негативных отзывов.
select h.localized_name as hero_name,
       count(m.match_id) as match_count,
       round(avg(p.kills), 2) as avg_kills,
       min(p.deaths) as min_deaths,
       max(p.gold_spent) as max_gold_spent,
       sum(m.positive_votes) as total_positive_votes,
       sum(m.negative_votes) as total_negative_votes
from hero_names h
    left join players p on h.hero_id = p.hero_id
    left join match m on p.match_id = m.match_id
group by h.localized_name;

-- вывести матчи в которых: хотя бы одна покупка item_id = 42
-- состоялась позднее 100 секунды с начала матча;
select distinct m.match_id
from purchase_log p
    left join match m on p.match_id = m.match_id
where p.item_id = 42 and p.time > 100

-- получить первые 20 строк из всех данных из таблиц с матчами и оплатами (purchase_log);
-- не до конца понял какие данные от меня здесь хотят, поэтому вот 2 варианта решения
-- 1й вариант решения
select * from match limit 20;
select * from purchase_log limit 20;

-- 2й вариант решения
select * from match m
    left join purchase_log pl on m.match_id = pl.match_id
limit 20