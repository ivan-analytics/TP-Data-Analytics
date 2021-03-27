-- info
-- данные о пользовании клиентами ситимобила за 2 недели (просмотры и поездки на такси)

-- задание #1
select tariff,
       count(idhash_view) as view,
       countIf(order_dttm, order_dttm > toDateTime('1970-02-02 00:00:00')) as order,
       count(da_dttm) as driver_found,
       count(rfc_dttm) as car_arrived,
       count(cc_dttm) as client_in_car,
       count(finish_dttm) as trip_finished
from views v left join orders o on v.idhash_order = o.idhash_order
group by v.tariff;
-- Больше всего клиентов теряется на первом шаге воронки - этапе заказа, что логично.
-- На втором месте второй шаг воронки - ожидание назначение водителя.
-- На 3 шаге - ожидание приезда машины, клиентов теряется немного меньшее, чем на этапе назначения водителя,
-- но все еще значимое количество


-- задание #2
select client_id, groupArray(concat(toString(tariff), ': ', toString(rides))), count(tariff) as tariffs_used
from (
      select v.idhash_client as client_id, v.tariff as tariff, count(finish_dttm) as rides
      from views v
               inner join orders o on v.idhash_order = o.idhash_order
      group by v.idhash_client, v.tariff
      order by v.idhash_client, rides desc
         )
where rides > 0
group by client_id

-- задание #3
select geoToH3(longitude, latitude, 7) as h3, count(o.finish_dttm) as rides
from views v inner join orders o on v.idhash_order = o.idhash_order
where o.finish_dttm is not null and
      toHour(o.order_dttm) >= 7 or toHour(o.order_dttm) < 10
group by h3
order by rides desc
limit 10
union all
select geoToH3(del_longitude, del_latitude, 7) as h3, count(o.finish_dttm) as rides
from views v inner join orders o on v.idhash_order = o.idhash_order
where o.finish_dttm is not null and
      toHour(o.order_dttm) >= 18 or toHour(o.order_dttm) < 20
group by h3
order by rides desc
limit 10


-- задание #4
select quantile(0.5)(da_dttm - order_dttm) as driver_search_median_in_seconds,
       round(quantile(0.95)(da_dttm - order_dttm)) as driver_search_95_percentile_in_seconds
from orders
where order_dttm > toDateTime('1970-02-02 00:00:00') and da_dttm is not null
