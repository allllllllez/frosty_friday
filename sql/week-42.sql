/*

https://frostyfriday.org/blog/2023/04/21/week-42-intermediate/

**With the recent release of Individual Task Observability, we’re celebrating with a Task focussed challenge!**

This new feature provides a level of visibility and insight into individual tasks that were previously unavailable and presents both opportunities and potential obstacles for those seeking to optimize their workflow. As people begin to explore the benefits and limitations of Individual Task Observability, they will need to navigate this new terrain with care and creativity, in order to maximize their productivity and achieve their goals. In this context, it is worth exploring the implications of this new feature, and considering strategies for using it effectively in various contexts and settings.

What we want you to create is built as a puzzle, meant to give you some constraints.

Create tasks representing 3 kids : Joan, Maggy and Jason.
Joan gets out of bed every 3 minutes and stays up for 2 minute
Maggy gets out of bed every 5 minutes and stays up for 1 minute
Jason gets out of bed every 13 minutes and stays up for 1 minute

Create a table called kids_out_of_bed with a column for :
– Time
– Joan
– Maggy
– Jason

The default is that all the kids columns should be FALSE

Create a Task structure to keep track of when kids get out of bed. For the minutes that a kid is out of bed , change the minute value to TRUE.
The child task should keep running while the kids are awake
The important constraint here however that we’re not just using a calculation but actual timestamps!
Example : Joan starts at 01.00 , the task runs, and notes that on 01.03 01.04 , she was awake. So we’re changing those values to TRUE.

If dad_task notices that all the kids are out of bed (which he checks every second), he freaks out , gets mad and everything stops. Make sure to include this in your tasks!

What is your end time for this task tree? Let us know!

---

**最近リリースされた「Individual Task Observability」を祝して、タスクに焦点を当てたチャレンジ!**
※ [2023年03月に公開](https://docs.snowflake.com/en/release-notes/2023-03)された「Individual Task Observability（個別タスクの可観測性）」のこと。
   Snowsight のタスク表示画面が強化され、グラフビューで個々のタスクの実行時間やスキップされたなどのステータスを確認できるようになりました。
   このチャレンジは 2023-04-21 に公開されました。

この新機能は、以前は利用できなかった個々のタスクの可視性と洞察のレベルを提供し、ワークフローを最適化しようとする人々に機会と潜在的な障害の両方を提示します。人々が個々のタスクの観察可能性の利点と限界を探求し始めると、生産性を最大化し、目標を達成するために、注意と創造性をもってこの新しい領域をナビゲートする必要があります。この文脈では、この新機能の意味を探り、さまざまな文脈や設定で効果的に使用するための戦略を検討する価値があります。

私たちがあなたに作ってもらいたいものは、パズルのように作られており、あなたにいくつかの制約を与えることを意味しています。

Joan、Maggy、Jasonの3人の子供を表すタスクを作成します。
- Joanは3分ごとにベッドから出て、2分間起きている。
- Maggyは5分ごとにベッドから出て、1分間起きている。
- Jasonは13分ごとにベッドから起き出し、1分間起きている。

kids_out_of_bed というテーブルを作成：

– Time
– Joan
– Maggy
– Jason

デフォルトでは、子供のカラムはすべてFALSEになっています。
子供がいつベッドを出たかを追跡するタスク構造を作成する。子供がベッドから出ている分については、minuteの値をTRUEに変更する。
子供が起きている間、子タスクは実行し続けなければならない。
しかし、ここでの重要な制約は、単なる計算ではなく、実際のタイムスタンプを使うことである！
例：Joanが01.00に開始し、タスクが実行され、01.03 01.04に彼女が起きていたことを記録する。そこで、これらの値をTRUEに変更する。

もし dad_task が、子供たちが全員ベッドから出ていることに気づいたら（毎秒チェックしている）、彼はパニックになり、怒って、すべてが止まってしまう。これをタスクに含めるようにする！
このタスクツリーの終了時間がわかりましたか？では教えてください！

*/

------------------------------------------------------------
-- 
-- 準備
-- Frosty_friday 用に環境(いつもの)
-- 
------------------------------------------------------------
 
use role SYSADMIN;
create or replace database M_KAJIYA_FROSTY_FRIDAY;
use database M_KAJIYA_FROSTY_FRIDAY;
use schema PUBLIC;

-- 問題のテーブル作成
create or replace table m_kajiya_frosty_friday.public.kids_out_of_bed (
    "Time" timestamp_ltz,
    "Joan" boolean,
    "Maggy" boolean,
    "Jason" boolean
);

------------------------------------------------------------
-- 
-- 解答. SQL で解いてみよう
-- 
------------------------------------------------------------ 

-- まずは「Joanは3分ごとにベッドから出て、2分間起きている」をどうやって表現するか考えよう
-- 6分間のデータを入れてみる
insert into
    m_kajiya_frosty_friday.public.kids_out_of_bed (
        "Time",
        "Joan",
        "Maggy",
        "Jason"
    ) values
        ('2025-01-01 00:01:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 00:02:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 00:03:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 00:04:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 00:05:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 00:06:00'::timestamp_ltz , false, false, false)
;
table m_kajiya_frosty_friday.public.kids_out_of_bed;

-- 「Joanは3分ごとにベッドから出て、2分間起きている」なので、
-- 5分ごとに起点とする時間から4分後・5分後に true となっていればよい
-- そこで、開始時間からの差分を 5 で割った余りを使ってみる
select
    kids_out_of_bed."Time",
    timediff('minute', init_bed."Time", kids_out_of_bed."Time") % 5 in (3, 4) as joan_is_out_of_bed 
from
    m_kajiya_frosty_friday.public.kids_out_of_bed,
    ( -- 開始時のベッドの状態
        select top 1
            "Time",
            "Joan",
            "Maggy",
            "Jason"
        from
            m_kajiya_frosty_friday.public.kids_out_of_bed
        order by
            "Time" asc
    ) as init_bed
;
-- joan_is_out_of_bed 列を確認すると、4分後・5分後に true となっているので、「Joanは3分ごとにベッドから出て、2分間起きている」が表現できていそう

-- テストデータを削除しておく
truncate m_kajiya_frosty_friday.public.kids_out_of_bed;


-- 子どもたちタスクを起動するルートタスク
create or replace task m_kajiya_frosty_friday.public.root_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    allow_overlapping_execution = true -- 同時実行を許す
    -- CONFIG と SYSTEM$GET_TASK_GRAPH_CONFIG で時間渡したほうが良いかな
    schedule = '1 MINUTES'
as
    insert into m_kajiya_frosty_friday.public.kids_out_of_bed (
        "Time",
        "Joan",
        "Maggy",
        "Jason"
    ) values
        (date_trunc('minute', current_timestamp()) , false, false, false)
;

--まずは Joan のタスクを作る
create or replace task m_kajiya_frosty_friday.public.joan_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    after m_kajiya_frosty_friday.public.root_task
as
    begin
        -- 最新のベッドの記録時間を取得して、Joanが起きている時間か判定する。起きている時間なら "Joan" = true に update
        update m_kajiya_frosty_friday.public.kids_out_of_bed as bed 
        set
            "Joan" = true
        from
            ( -- 最初の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" asc
            ) as init_bed,
            ( -- 最新の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" desc
            ) as latest_bed,
        where
            bed."Time" = latest_bed."Time"
            -- 「Joanは3分ごとにベッドから出て、2分間起きている」で、起きているか判定
            and timediff('minute', init_bed."Time", latest_bed."Time") % 5 in (3, 4)
        ;
        
        -- 最後の DML ステートメントによって影響を受けた行の数をとる
        -- cf. https://docs.snowflake.com/en/developer-guide/snowflake-scripting/dml-status
        if (SQLFOUND >= 1) then
            call system$wait(1, 'MINUTES'); -- 次の判定まで起きている
            return 'row(s) updated.';
        else
            return 'No rows updated.';
        end if;
    end
;


create or replace task m_kajiya_frosty_friday.public.maggy_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    after m_kajiya_frosty_friday.public.root_task
as
    begin
        -- 最新のベッドの記録時間を取得して、Maggyが起きている時間か判定する。起きている時間なら "Maggy" = true に update
        update m_kajiya_frosty_friday.public.kids_out_of_bed as bed 
        set
            "Maggy" = true
        from
            ( -- 最初の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" asc
            ) as init_bed,
            ( -- 最新の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" desc
            ) as latest_bed,
        where
            bed."Time" = latest_bed."Time"
            -- 「Maggyは5分ごとにベッドから出て、1分間起きている」で、起きているか判定
            and timediff('minute', init_bed."Time", latest_bed."Time") % 6 = 5
        ;

        -- 最後の DML ステートメントによって影響を受けた行の数をとる
        if (SQLFOUND >= 1) then
            call system$wait(1, 'MINUTES');
            return 'row(s) updated.';
        else
            return 'No rows updated.';
        end if;
    end
;

create or replace task m_kajiya_frosty_friday.public.jason_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    after m_kajiya_frosty_friday.public.root_task
as
    begin
        -- 最新のベッドの記録時間を取得して、Maggyが起きている時間か判定する。起きている時間なら "Jason" = true に update
        update m_kajiya_frosty_friday.public.kids_out_of_bed as bed 
        set
            "Jason" = true
        from
            ( -- 最初の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" asc
            ) as init_bed,
            ( -- 最新の記録時間
                select top 1
                    "Time"
                from
                    m_kajiya_frosty_friday.public.kids_out_of_bed
                order by
                    "Time" desc
            ) as latest_bed,
        where
            bed."Time" = latest_bed."Time"
            -- 「Jasonは13分ごとにベッドから起き出し、1分間起きている」で、起きているか判定
            and timediff('minute', init_bed."Time", latest_bed."Time") % 14 = 13
        ;

        -- 最後の DML ステートメントによって影響を受けた行の数をとる
        if (SQLFOUND >= 1) then
            call system$wait(1, 'MINUTES');
            return 'row(s) updated.';
        else
            return 'No rows updated.';
        end if;
    end
;

-- 子どもたちが起きているかを確認する親タスク
-- そういえば Triggered task でも Serveless 設定できるようになりましたね！（https://docs.snowflake.com/en/release-notes/2025/9_02）
-- ついでに、タスクのインターバルを10秒まで短縮できるようになりましたね！（https://docs.snowflake.com/en/release-notes/2025/9_03）
create or replace task m_kajiya_frosty_friday.public.dad_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    schedule = '10 SECOND'
    -- after m_kajiya_frosty_friday.public.joan_task, -- 別解として、毎秒チェックはムリ！だけど、子供タスクを実行したチェックすることはできるよね！があります
    --     m_kajiya_frosty_friday.public.maggy_task,
    --     m_kajiya_frosty_friday.public.jason_task
as
    execute immediate $$
    declare
        res resultset default (
            select
                bed."Joan" and bed."Maggy" and bed."Jason" as is_all_out_of_bed
            from
                m_kajiya_frosty_friday.public.kids_out_of_bed as bed,
                ( -- 最新の記録時間
                    select top 1
                        "Time"
                    from
                        m_kajiya_frosty_friday.public.kids_out_of_bed
                    order by
                        "Time" desc
                ) as latest_bed
            where
                bed."Time" = latest_bed."Time"
        );
        cur1 cursor for res;
    begin
        for r in cur1 do
            if (r.is_all_out_of_bed = true) then
                alter task m_kajiya_frosty_friday.public.root_task suspend;
                alter task m_kajiya_frosty_friday.public.jason_task suspend;
                alter task m_kajiya_frosty_friday.public.maggy_task suspend;
                alter task m_kajiya_frosty_friday.public.joan_task suspend;
                alter task m_kajiya_frosty_friday.public.dad_task suspend;
                return '⚠️😡⚠️KIDS OUT OF BED!⚠️😡⚠️';
            else
                return '😪ids in bed💤';
            end if;
        end for;
    end
    $$
;


-- 動作確認
alter task dad_task resume;
alter task joan_task resume;
alter task maggy_task resume;
alter task jason_task resume;
alter task root_task resume;

table m_kajiya_frosty_friday.public.kids_out_of_bed;
-- さて、Snowsight でタスクグラフを見てみましょう！
-- 待ってるのはちょっとだるいので、image/week42/ にあるスクショを見ましょう

/*
タスクが停止した時点で kids_out_of_bed テーブルを見ると...

Time                            Joan    Maggy   Jason
2025-02-22 21:04:00.000 +0900	false	false	false
2025-02-22 21:05:00.000 +0900	false	false	false
：（中略）
2025-02-22 22:26:00.000 +0900	false	false	false
2025-02-22 22:27:00.000 +0900	true	true	true
ということで、84分で dad が怒り、全タスクが止まります。
*/

-- タスクが停止しているのを確認しましょう
show tasks;

-- 停止（念のため）
alter task root_task suspend;
alter task joan_task suspend;
alter task maggy_task suspend;
alter task jason_task suspend;
alter task dad_task suspend;


/*

さて、これ、dad が怒る時間になるまで待ってるの、ちょっと面倒ですよね？
実は計算できます。多分。
この問題って、最小公倍数を求める問題っぽいんですよね

(1) (Joan が 3分起きて2分起きたパターン) 5, 6, 14 の最小公倍数：210
(2) (Joan が 3分起きて1分起きたパターン) 5x - 1 = 6y = 14z (★) => 5x - 1 = 6y の解は x = 6*n - 1, y = 5 * n - 1. (x, y) = (5, 4), (11, 9), (17, 14) ... とわかる.（※）。
　　※ https://www.ozl.jp/unit/integer/calc_indeq.html
    （★）式から、5x - 1, 6y とも 14 で割り切れなければならない。そのような 0 より大きい値で最小の組は (x, y) = (17, 14). よって (x, y, z) = (17, 14, 6)

したがってて 84分後に dad が怒るって、タスクを実行しなくてもわかります。多分。
*/

truncate m_kajiya_frosty_friday.public.kids_out_of_bed;

-- 答え合わせ
insert into
    m_kajiya_frosty_friday.public.kids_out_of_bed (
        "Time",
        "Joan",
        "Maggy",
        "Jason"
    ) values
        -- 00:00 開始だと想定して。。。
        ('2025-01-01 00:01:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 01:23:00'::timestamp_ltz , false, false, false), 
        ('2025-01-01 01:24:00'::timestamp_ltz , false, false, false) -- 84min
;


execute task joan_task;
execute task maggy_task;
execute task jason_task;

table m_kajiya_frosty_friday.public.kids_out_of_bed;

------------------------------------------------------------
-- 
-- 解答2. Python API で解いてみよう
-- 
------------------------------------------------------------ 

------------------------------------------------------------
-- 
-- あとしまつ
-- 
------------------------------------------------------------ 

use role SYSADMIN;

------------------------------------------------------------
-- 
-- 参考
-- 
------------------------------------------------------------ 

-- - xxxx
-- - xxxx
-- - xxxx


