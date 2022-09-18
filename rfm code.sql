use retail;

select top 10 * from retail_response;
select top 10 * from retail_transactions;
select max (trans_date) from retail_transactions;
select distinct trans_date 
from retail_transactions
order by trans_date;
select day(trans_date) from retail_transactions;

--cte
with retail_status as  --lay thong tin khach hang co tuong tac
    (select a.*
    from 
        retail_transactions a 
    inner join 
    retail_response b
    on a.customer_id = b.customer_id 
    where b.response = 1)
, rfm as  --tinh chi so rfm, theo tung khach hang
    (select customer_id, 
    datediff(day, max(trans_date), '2016-01-01') recency, 
    count (distinct day(trans_date)) frequency, 
    sum(tran_amount) monetary
    from retail_status
    group by customer_id)
, rfm_percent_rank as --quy dai gia tri cua tung r, f, m thanh dai [0;1]
    (select customer_id, recency, frequency, monetary, 
    percent_rank() over (order by recency asc) r_rank,
    percent_rank() over (order by frequency desc) f_rank,
    percent_rank() over (order by monetary desc) m_rank
    from rfm)
, rfm_group as --gom nhom diem r, f, m
    (select customer_id, 
    r_rank, 
    f_rank, 
    m_rank, 
    case when r_rank >= 0.75 then 4
        when r_rank >= 0.5 then 3 
        when r_rank >= 0.25 then 2 
        else 1
        end r_group, 
    case when f_rank >= 0.75 then 4
        when f_rank >= 0.5 then 3 
        when f_rank >= 0.25 then 2 
        else 1
        end f_group, 
    case when m_rank >= 0.75 then 4
        when m_rank >= 0.5 then 3 
        when m_rank >= 0.25 then 2 
        else 1
        end m_group 
    from rfm_percent_rank) 
, rfm_final as
    (select customer_id, r_group, f_group, m_group, 
    concat(r_group, f_group, m_group) rfm_score
    from rfm_group)
, rfm_segment as 
(select customer_id, rfm_score, 
    case when rfm_score = 111 then 'best customers'
        when rfm_score like '[3-4][3-4][1-4]' then 'lost bad customers'
        when rfm_score like '[3-4]2[3-4]' then 'lost customers'
        when rfm_score like '21[1-4]' then 'almost lost'
        when rfm_score like '11[2-4]' then 'loyal customers'
        when rfm_score like '[1-2][1-3]1' then 'big spenders'
        when rfm_score like '[1-2]4[1-4]' then 'new customers'
        when rfm_score like '[3-4]1[1-4]' then 'hibernating'
        else 'potential loyalists' 
        end customer_segment
    from rfm_final)
select customer_segment, count (customer_id) slkh 
from rfm_segment
group by customer_segment; 



--với từng nhóm r, f, m thì có thể mô tả đặc điểm khách hàng như thế
--naming (đặt tên) - khái quát hoá đặc điểm bằng tên gọi cho từng đặc tính khách hàng 
--search các tài liệu nghiên cứu về sử dụng nhóm chỉ số rfm 
-- mục tiêu: có các ý tưởng và gợi ý về việc chia nhóm từ kết quả rfm trả ra.

--chon thoi diem de tinh recency => thoi diem phan tich, theo doi sl kinh doanh
--phan chia segment, dat ten segment => research 