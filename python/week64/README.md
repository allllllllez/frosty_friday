# Week64 別解

## 1. ローカルで Python を実行

```bash
pip install -r ./requirements.txt 
python ./parse_monarchs_from_table.py 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|"DYNASTY"                      |"NAME"                   |"REIGN"          |"SUCCESSION"                                        |"LIFE_DETAILS"                                      |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|Carolingian dynasty (843–887)  |Charles II"the Bald"     |c.10 August 843  |Son ofLouis the Piousand grandson ofCharlemagne...  |13 June 823– 6 October 877King of Aquitainesinc...  |
|Carolingian dynasty (843–887)  |Louis II"the Stammerer"  |6 October 877    |Son of Charles the Bald                             |1 November 846 – 10 April 879King of Aquitaines...  |
|Carolingian dynasty (843–887)  |Louis III                |10 April 879     |Son of Louis the Stammerer                          |863 – 5 August 882Ruled the North; died after h...  |
|Carolingian dynasty (843–887)  |Carloman II              |10 April 879     |Son of Louis the Stammerer                          |866 – 6 December 884Ruled the South; died after...  |
|Carolingian dynasty (843–887)  |Charles(III)"the Fat"    |6 December 884   |Son ofLouis II the German, king ofEast Francia,...  |839– 13 January 888King of East Franciasince 87...  |
|Robertiandynasty (888–898)     |Odo/Eudes                |29 February 888  |Son ofRobert the Strong; elected king by the Fr...  |c.858 – 3 January 898Defended Paris from theVik...  |
|Carolingian dynasty (898–922)  |Charles III"the Simple"  |3 January 898    |Posthumous son ofLouis II the Stammerer; procla...  |17 September 879 – 7 October 929Deposed by Robe...  |
|Robertiandynasty (922–923)     |Robert I                 |29 June 922      |Son ofRobert the Strongand younger brother of Odo   |865 – 15 June 923Killed at theBattle of Soisson...  |
|Bosoniddynasty (923–936)       |Rodolph/Raoul            |15 June 923      |Son ofRichard, Duke of Burgundyand son-in-law o...  |Duke of Burgundysince 921. Died of illness afte...  |
|Carolingian dynasty (936–987)  |Louis IV"from Overseas"  |19 June 936      |Son ofCharles the Simple, recalled to France af...  |921 – 10 September 954Died afterfalling off his...  |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```

## 2. Stored Procedure として実行

```bash
python ./create_procedure.py 

snow sql --query "CALL M_KAJIYA_FROSTY_FRIDAY.WEEK64.PARSE_MONARCHS_FROM_TABLE(table_name => 'WEEK64'::VARCHAR)"

+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DYNASTY                           | NAME                              | REIGN                             | SUCCESSION                       | LIFE_DETAILS                      |
|-----------------------------------+-----------------------------------+-----------------------------------+----------------------------------+-----------------------------------|
| Carolingian dynasty (843–887)     | Charles II"the Bald"              | c.10 August 843                   | Son ofLouis the Piousand         | 13 June 823– 6 October 877King of |
|                                   |                                   |                                   | grandson ofCharlemagne;          | Aquitainesince 838. Crowned       |
|                                   |                                   |                                   | recognized as king after         | "Emperor of the Romans" on        |
|                                   |                                   |                                   | theTreaty of Verdun              | Christmas 875. Died of natural    |
|                                   |                                   |                                   |                                  | causes                            |
| Carolingian dynasty (843–887)     | Louis II"the Stammerer"           | 6 October 877                     | Son of Charles the Bald          | 1 November 846 – 10 April 879King |
|                                   |                                   |                                   |                                  | of Aquitainesince 867. Died of    |
|                                   |                                   |                                   |                                  | natural causes.                   |
| Carolingian dynasty (843–887)     | Louis III                         | 10 April 879                      | Son of Louis the Stammerer       | 863 – 5 August 882Ruled the       |
|                                   |                                   |                                   |                                  | North; died after hitting his     |
|                                   |                                   |                                   |                                  | head with alintelwhile riding his |
:（以下略）
```
