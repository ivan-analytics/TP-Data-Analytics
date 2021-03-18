-- выбираем топ 10% процентов игроков по скиллу
-- смотрим какие герои популярны среди скилловых игроков

-- выделяется Dazzle, который не очень популярен у общей массы,
-- но на 4м месте по популярности среди скилловых игроков
with ninety_percent_skill as (
    select percentile_cont(0.90) within group (order by trueskill_mu asc) as skill
    from player_ratings
)
select hn.localized_name, count(*)
from players p left join player_ratings pr on p.account_id = pr.account_id
               left join hero_names hn on p.hero_id = hn.hero_id
where trueskill_mu > (select skill from ninety_percent_skill)
group by p.hero_id, hn.localized_name
order by count(*) desc
limit 10;

-- популярность героев среди всех игроков
select hn.localized_name, count(*)
from players left join hero_names hn on players.hero_id = hn.hero_id
group by hn.localized_name
order by count(*) desc

-- стоит обратить внимание на самых скиллованых и на тех у кого при высоком среднем скиле очень много боев
-- Beastmaster, Shadow Fiend, Dazzle


with acc_skill_by_heros as (
    -- герои, по среднему скиллу игроков которые за них играют
    select hn.localized_name,
       round(avg(pr.trueskill_mu), 1) as skill_mu,
       sum(pr.total_matches) as matches
    from players p
        left join player_ratings pr on p.account_id = pr.account_id
        left join hero_names hn on p.hero_id = hn.hero_id
    group by p.hero_id, hn.localized_name
    order by skill_mu desc
)

-- межквартильный размах по среднему скиллу игроков, сгруппированному по героям
select round(cast((percentile_cont(0.75) within group ( order by skill_mu asc ) -
       percentile_cont(0.25) within group ( order by skill_mu asc )) as numeric), 2) as iqr
from acc_skill_by_heros
union all
-- межквартильный размах по скиллу среди игроков
select percentile_cont(0.75) within group (order by trueskill_mu) -
       percentile_cont(0.25) within group (order by trueskill_mu) as iqr
from player_ratings;



-- скилл по регионам
    with cte as (
        select c.region,
           count(*) as matches_count,
           round(avg(pr.trueskill_mu), 1) as avg_player_skill
        from players p left join match m on p.match_id = m.match_id
            left join cluster_regions c on m.cluster = c.cluster
            left join player_ratings pr on p.account_id = pr.account_id
        group by c.region

    )
    select * from cte
    where matches_count > 500
    order by avg_player_skill desc;

-- популярные герои по регионам
with region_group as (
    select cr.region as region,
       hn.localized_name as name,
       count(p.hero_id) as hero_count
from players p left join hero_names hn on p.hero_id = hn.hero_id
               left join match m on p.match_id = m.match_id
               left join cluster_regions cr on m.cluster = cr.cluster
group by cr.region, hn.localized_name
), region_hero_popularity_ranking as (
    select *,
       row_number() over (partition by region order by hero_count desc) as popularity_rank
from region_group
)
select region, name, hero_count
from region_hero_popularity_ranking
where popularity_rank <= 3 and hero_count > 50
order by region, hero_count desc;



-- Разбил матчи на 10 групп, по длительности и посмотрел,
-- есть ли зависимость между длительностью матчей и скиллом игроков
with duration_groups as (
    select
        match_id,
        duration,
        ntile(10) over (order by duration desc) as duration_group
    from match
),
    agregated_groups as (
        select duration_group,
           round(avg(duration), 0) as avg_duration,
           round(avg(pp.xp_per_min), 0) as avg_xp_per_min,
           round(avg(trueskill_mu), 2) as avg_acc_skill
        from duration_groups p left join players pp on p.match_id = pp.match_id
            left join player_ratings pr on pp.account_id = pr.account_id
        group by duration_group
    )
select *,
       round(
           (avg_xp_per_min - lead(avg_xp_per_min) over (order by avg_duration desc)) /
           lead(avg_xp_per_min) over (order by avg_duration desc), 2
           ) * 100 as xp_per_min_diff_percent
from agregated_groups
order by avg_duration desc;