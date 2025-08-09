/*
Bienvenue à tous, it’s a pleasure to announce that on 5th October, at the Data Cloud World Tour Paris, thanks to the amazing hard work of Jade Le Van & Maxime Simon we’ll be launching Jeudis Givrés !
All of the Frosty Friday challenges will be translated into French and released on the following Thursday (for the sake of alliteration), followed by lots of community events to help boost those Parisian (and wider French) Snowflake skills!
To celebrate, we’re revisiting our Week 4 challenge on Spanish monarchs, but this time, in XML (which was partly invented by a Frenchman). Can you parse out the French monarchs?

Start Up Code >

```sql
create or replace file format frosty_parquet
type = 'parquet';

create or replace stage s3_stage
    url = 's3://frostyfridaychallenges'

create or replace table week64 as
select parse_xml($1:"DATA") as data
from @s3_stage/challenge_64/french_monarchs.parquet
    (file_format => frosty_parquet);
```

---

皆様、こんにちは。10月5日にパリで開催される「Data Cloud World Tour Paris」において、Jade Le VanとMaxime Simonの素晴らしいご尽力により、「Jeudis Givrés」をリリースすることをお知らせでき、大変嬉しく思います！
すべてのFrosty Fridayチャレンジはフランス語に翻訳され、次の木曜日にリリースされます（語呂合わせのため）。
その後、パリ（およびフランス全土）のSnowflakeスキル向上を支援する多くのコミュニティイベントが開催されます！
記念として、スペイン国王をテーマにした Week 4 のチャレンジを再訪しますが、今回はXML形式（一部をフランス人が考案した言語）で挑戦します。フランス王朝の君主を抽出できますか？

Start Up Code >

```sql
create or replace file format frosty_parquet
type = 'parquet';

create or replace stage s3_stage
    url = 's3://frostyfridaychallenges'

create or replace table week64 as
select parse_xml($1:"DATA") as data
from @s3_stage/challenge_64/french_monarchs.parquet
    (file_format => frosty_parquet);
```

--- 小噺

  1. Jean Paoli - Wikipedia

  https://en.wikipedia.org/wiki/Jean_Paoli
  - Jean PaoliのXML共同発明者としての経歴
  - INRIAでの10年間の研究活動
  - 1996年のMicrosoft入社とXML開発への貢献

  2. Docugami創業者インタビュー（フランス語）

  https://www.journaldunet.com/intelligence-artificielle/1542383-ce-ponte-du-xml-issu-de-l-excellence-francaise-implante-sa-start-up-en-france/
  - XMLの起源がINRIA時代の研究に基づくこと
  - SGMLからXMLへの進化の経緯
  - フランスの研究機関での基礎研究の重要性

  3. W3C XML 10周年記念ページ

  https://www.w3.org/press-releases/2008/xml10/
  - XML Working Groupの公式メンバーリスト
  - Jean Paoliが共同編集者として参加した経緯
  - XML 1.0仕様の制定プロセス

  Jean Paoliは、フランスのINRIAで10年間SGMLの研究を行い、その知見を基にXMLを共同発明しました。


*/

--- Week 4 の XML版チャレンジです。なので今一度 Week 4 の内容を確認しておきましょうか。

------------------------------------------------------------
-- 
-- 準備
-- いつもの Frosty_friday 環境設定 ＋ Start Up Code 実行
-- 
------------------------------------------------------------
 
use role sysadmin;
use database M_KAJIYA_FROSTY_FRIDAY;
create schema if not exists week64;
use schema week64;

create or replace temporary file format frosty_parquet
type = 'parquet';

create or replace temporary stage s3_stage
    url = 's3://frostyfridaychallenges'
;

-- まずは中身を見てみよう
select
    $1 as data
from
    @s3_stage/challenge_64/french_monarchs.parquet
    (file_format => frosty_parquet)
;

-- 同じ内容かな........？
-- 全然わからないので AI に整形してもらう → week64.xml, week-4.sql

create or replace temporary table week64 as
select
    parse_xml($1:"DATA") as data
from
    @s3_stage/challenge_64/french_monarchs.parquet
    (file_format => frosty_parquet)
;

table week64;
-- Monarchs 単位で XML データが格納されているところなど、 Week 4 の内容と若干異なる

------------------------------------------------------------
-- 
-- 課題1. XMLデータからフランス君主の情報を抽出しよう
-- 
------------------------------------------------------------ 

-- 
-- https://docs.snowflake.com/en/user-guide/semistructured-data-formats#xml
-- まずは XML のおさらいをしましょう。要素の値を "$"、 名前を "@"で取得（Week 45 も思い出そう！）
select 
    data,
    data:"$",
    data:"@",
from
    week64
;

-- まずは Dynasty（王朝）を抽出してみましょう
-- week 4 では House で表記されていましたね
select 
    dynasties.value:"@name" as dynasty, -- 王朝名
from
    week64,
    lateral flatten (input => data:"$") as dynasties
;

-- Monarchs（君主）を展開したい
select
    dynasties.value,
    dynasties.value:"@name"::varchar as dynasty, -- 王朝名。variant になっているので varchar にキャストする
    monarchs.value as monarch
from
    week64,
    lateral flatten (input => data:"$") as dynasties,
    lateral flatten (input => to_array(dynasties.value:"$")) as monarchs
;
-- to_array() がないと、、、
-- Monarch が ARRAY の場合と VARIANT の場合があり、VARIANT のときにキーと値が展開されちゃうので、ARRAYに統一する
-- 例）DYNASTY: Robertiandynasty (888–898) の Monarch

-- さて、君主の情報を抽出していきます
-- Monarchs の値を展開するのに XMLGET を使います
-- cf. https://docs.snowflake.com/ja/sql-reference/functions/xmlget
select 
    dynasties.value:"@name"::varchar as dynasty, -- 王朝名
    monarchs.value as monarch, -- 君主の情報
    monarch::varchar, -- XML 要素なので...（varcharにするとわかりやすい）
    monarch:"Monarch":"Name", -- これじゃあ中身を取れない
    xmlget(monarchs.value, 'Name'):"$"::varchar as name -- 君主名 -- タグを取得して値を取得して文字列型に変える
from
    week64,
    lateral flatten (data:"$") as dynasties,
    lateral flatten (to_array(dynasties.value:"$"::variant)) as monarchs
;

-- ここまで来れば、、、
select 
    dynasties.value:"@name"::varchar as dynasty, -- 王朝名
    xmlget(monarchs.value, 'Name'):"$"::varchar as name, -- 君主名
    xmlget(monarchs.value, 'Reign'):"$"::varchar as reign, -- 君主の治世
    xmlget(monarchs.value, 'Succession'):"$"::varchar as succession, -- 君主の継承
    xmlget(monarchs.value, 'LifeDetails'):"$"::varchar as life_details -- 君主の生涯
from
    week64,
    lateral flatten (data:"$") as dynasties,
    lateral flatten (to_array(dynasties.value:"$"::variant)) as monarchs
;

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



