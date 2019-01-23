# TODO: refactor
# http://www.ssk.or.jp/seikyushiharai/rezept/iryokikan/iryokikan_02.files/jiki_i01.pdf

require 'yaml'
require 'csv'

payers = YAML.load_file('db/01_payers.yml')
prefectures = YAML.load_file('db/02_prefectures.yml')
tensuhyo = YAML.load_file('db/03_tensuhyo.yml')
era = YAML.load_file('db/04_era.yml')
receipt = YAML.load_file('db/05_receipt.yml')
danzyo = YAML.load_file('db/06_danzyo.yml')
byoto = YAML.load_file('db/07_byoto.yml')
futan = YAML.load_file('db/08_futan.yml')
tokki = YAML.load_file('db/09_tokki.yml')
shinryoka = YAML.load_file('db/10_shinryoka.yml')
bui = YAML.load_file('db/11_bui.yml')
seibetsu = YAML.load_file('db/12_seibetsu.yml')
igakushochi = YAML.load_file('db/13_igakushochi.yml')
tokuteishippei = YAML.load_file('db/14_tokuteshippei.yml')
shokumujiyu = YAML.load_file('db/15_shokumujiyu.yml')
genmen = YAML.load_file('db/16_genmen.yml')
santeriyu = YAML.load_file('db/17_santeriyu.yml')
tenki = YAML.load_file('db/18_tenki.yml')
shubyo = YAML.load_file('db/19_shubyo.yml')
shinryoshikibetsu = YAML.load_file('db/20_shinryoshikibetsu.yml')
futan = YAML.load_file('db/21_futan.yml')
tokutekizai = YAML.load_file('db/22_tokutekizai.yml')
shojoshoki = YAML.load_file('db/23_shojoshoki.yml')
zoki = YAML.load_file('db/24_zoki.yml')
zokiiryokikan = YAML.load_file('db/25_zokiiryokikan.yml')
zokireceipt = YAML.load_file('db/26_zokireceipt.yml')
status = YAML.load_file('db/27_status.yml')
byomei = YAML.load_file('db/98_byomei.yml')
tensu = YAML.load_file('db/99_tensu.yml')

uke = CSV.read('uke/06.csv')
uke.each do |r|
  case r[0]
  when 'IR' then
    p "--- IR: 医療機関情報レコード ---"
    p "審査支払機関:#{payers[r[1]]}"
    p "都道府県:#{prefectures[r[2]]}"
    p "点数表:#{tensuhyo[r[3]]}"
    p "医療機関コード:#{r[4]}"
    p "予備:#{r[5]}"
    p "医療機関名称:#{r[6]}"
    p "請求年月:#{r[7]}"
    p "マルチボリューム識別情報:#{r[8]}"
    p "電話番号:#{r[9]}"
  when 'RE' then
    p "--- RE: レセプト共通レコード --- "
    p "レセプト番号:#{r[1]}"
    p "レセプト種別:#{receipt[r[2]]}"
    p "診療年月:#{r[3]}"
    p "氏名:#{r[4]}"
    p "男女区分:#{danzyo[r[5]]}"
    p "生年月日:#{r[6]}"
    p "給付割合:#{r[7]}"
    p "入院年月日:#{r[8]}"
    p "病棟区分:#{byoto[r[9]]}"
    p "一部負担金・食事療養費・生活療養費標準負担額区分:#{futan[r[10]]}"
    p "レセプト特記事項:#{tokki[r[11]]}"
    p "病床数:#{r[12]}"
    p "カルテ番号等:#{r[13]}"
    p "割引点数単価:#{r[14]}"
    p "予備:#{r[15]}"
    p "予備:#{r[16]}"
    p "予備:#{r[17]}"
    p "検索番号:#{r[18]}"
    p "記録条件仕様年月情報:#{r[19]}"
    p "請求情報:#{r[20]}"
    p "診療科名:#{shinryoka[r[21]]}"
    p "人体の部位等:#{bui[r[22]]}"
    p "性別等:#{seibetsu[r[23]]}"
    p "医学的処置:#{igakushochi[r[24]]}"
    p "特定疾病:#{tokuteishippei[r[25]]}"
    p "診療科名:#{shinryoka[r[26]]}"
    p "人体の部位等:#{bui[r[27]]}"
    p "性別等:#{seibetsu[r[28]]}"
    p "医学的処置:#{igakushochi[r[29]]}"
    p "特定疾病:#{tokuteishippei[r[30]]}"
    p "診療科名:#{shinryoka[r[31]]}"
    p "人体の部位等:#{bui[r[32]]}"
    p "性別等:#{seibetsu[r[33]]}"
    p "医学的処置:#{igakushochi[r[34]]}"
    p "特定疾病:#{tokuteishippei[r[35]]}"
    p "カタカナ(氏名):#{r[36]}"
    p "患者の状態:#{status[r[37]]}"
  when 'HO' then
    p "--- HO: 保険者レコード --- "
    p "保険者番号:#{r[1]}"
    p "被保険者証(手帳)等の記号:#{r[2]}"
    p "被保険者証(手帳)等の番号:#{r[3]}"
    p "診療実日数:#{r[4]}"
    p "合計点数:#{r[5]}"
    p "予備:#{r[6]}"
    p "食事療養回数:#{r[7]}"
    p "食事療養合計金額:#{r[8]}"
    p "職務上の事由:#{shokumujiyu[r[9]]}"
    p "証明書番号:#{r[10]}"
    p "負担金額医療保険:#{r[11]}"
    p "減免区分:#{genmen[r[12]]}"
    p "減額割合:#{r[13]}%"
  when 'KO' then
    p "--- KO: 公費レコード --- "
    p "公費負担者番号:#{r[1]}"
    p "公費受給者番号:#{r[2]}"
    p "任意給付区分:#{r[3]}"
    p "診療実日数:#{r[4]}"
    p "合計点数:#{r[5]}"
    p "公費負担金額:#{r[6]}"
    p "公費給付対象外来一部負担金:#{r[7]}"
    p "公費給付対象入院一部負担金:#{r[8]}"
    p "予備:#{r[9]}"
    p "食事療養・生活療養回数:#{r[10]}"
    p "食事療養・生活療養合計金額:#{r[11]}"
  when 'GR' then
    p "--- GR: 包括評価対象外理由レコード --- "
    p "医科点数表算定理由:#{santeriyu[r[1]]}"
    p "DPCコード:#{r[1]}"
  when 'SY' then
    p "--- SY: 傷病名レコード --- "
    p "傷病名コード:#{byomei[r[1]]}"
    p "診療開始日:#{r[2]}"
    p "転帰区分:#{tenki[r[3]]}"
    p "修飾語コード:#{r[4]}"
    p "傷病名称:#{r[5]}"
    p "主傷病:#{shubyo[r[6]]}"
    p "補足コメント:#{r[7]}"
  when 'SI' then
    p "--- SI: 診療行為レコード --- "
    p "診療識別:#{shinryoshikibetsu[r[1]]}"
    p "負担区分:#{futan[r[2]]}"
    p "診療行為コード:#{tensu[r[3]]}"
    p "数量データ:#{r[4]}"
    p "点数:#{r[5]}"
    p "回数:#{r[6]}"
    p "コメントコード1:#{r[7]}"
    p "文字データ1:#{r[8]}"
    p "コメントコード2:#{r[9]}"
    p "文字データ2:#{r[10]}"
    p "コメントコード3:#{r[11]}"
    p "文字データ3:#{r[12]}"    
    # (14)~(44) 算定日情報1日の情報~算定日情報31日の情報
    days = ''
    r[13..43].map.with_index { |d, i| days += "#{i} " if d == '1'}
    p "算定日: #{days}"
  when 'IY' then
    p "--- IY: 医薬品レコード --- "
    p "診療識別:#{shinryoshikibetsu[r[1]]}"
    p "負担区分:#{futan[r[2]]}"
    p "医薬品コード:#{r[3]}"
    p "使用量:#{r[4]}"
    p "点数:#{r[5]}"
    p "回数:#{r[6]}"
    p "コメントコード1:#{r[7]}"
    p "文字コード1:#{r[8]}"
    p "コメントコード2:#{r[9]}"
    p "文字コード2:#{r[10]}"
    p "コメントコード3:#{r[11]}"
    p "文字コード3:#{r[12]}"
    # (14)~(44) 算定日情報1日の情報~算定日情報31日の情報
    days = ''
    r[13..43].map.with_index { |d, i| days += "#{i} " if d == '1'}
    p "算定日: #{days}"
  when 'TO' then
    p "--- TO: 特定器材レコード --- "
    p "診療識別:#{shinryoshikibetsu[r[1]]}"
    p "負担区分:#{futan[r[2]]}"
    p "特定器材コード:#{r[3]}"
    p "使用量:#{r[4]}"
    p "点数:#{r[5]}"
    p "回数:#{r[6]}"
    p "単位コード:#{r[7]}"
    p "単価:#{r[8]}"
    p "予備:#{r[9]}"
    p "商品名及び規格又はサイズ:#{r[10]}"
    p "コメントコード1:#{r[11]}"
    p "文字データ1:#{r[12]}"
    p "コメントコード2:#{r[13]}"
    p "文字データ2:#{r[14]}"
    p "コメントコード3:#{r[15]}"
    p "文字データ3:#{r[16]}"
    # (18)~(48) 1日の情報~31日の情報
    days = ''
    r[17..47].map.with_index { |d, i| days += "#{i} " if d == '1'}
    p "算定日: #{days}"
  when 'CO' then
    p "--- CO: コメントレコード --- "
    p "診療識別:#{shinryoshikibetsu[r[1]]}"
    p "負担区分:#{futan[r[2]]}"
    p "コメントコード:#{r[3]}"
    p "文字データ:#{r[4]}"
  when 'SJ' then
    p "--- SJ: 症状詳記レコード --- "
    p "症状詳記区分:#{r[1]}"
    p "症状詳記データ:#{shojoshoki[r[2]]}"
  when 'TI' then
    p "--- TI: 臓器提供医療機関情報レコード --- "
    p "臓器提供区分:#{r[1]}"
    p "臓器提供医療機関区分:#{r[2]}"
    p "都道府県:#{prefectures[r[3]]}"
    p "点数表:#{tensuhyo[r[4]]}"
    p "医療機関コード:#{r[5]}"
    p "予備:#{r[6]}"
    p "医療機関名称:#{r[7]}"
    p "医療機関所在地:#{r[8]}"
    p "電話番号:#{r[9]}"
  when 'TR' then
    p "--- TR: 臓器提供者レセプト情報レコード --- "
    p "レセプト番号:#{r[1]}"
    p "臓器提供者レセプト種別:#{r[2]}"
    p "診療年月:#{r[3]}"
    p "予備:#{r[4]}"
    p "男女区分:#{danzyo[r[5]]}"
    p "生年月日:#{r[6]}"
    p "予備:#{r[7]}"
    p "入院年月日:#{r[8]}"
    p "病棟区分:#{byoto[r[9]]}"
    p "予備:#{r[10]}"
    p "レセプト特記事項:#{tokki[r[11]]}"
    p "予備:#{r[12]}"
    p "カルテ番号等:#{r[13]}"
    p "割引点数単価:#{r[14]}"
    p "予備:#{r[15]}"
    p "予備:#{r[16]}"
    p "予備:#{r[17]}"
  when 'TS' then
    p "--- TS: 臓器提供者請求情報レコード --- "
    p "診療実日数:#{r[1]}"
    p "合計点数:#{r[2]}"
    p "食事療養・生活療養回数:#{r[3]}"
    p "食事療養・生活療養合計金額:#{r[4]}"
  when 'GO' then
    p "--- GO: 診療報酬請求書レコード ---"
    p "総件数:#{r[1]}"
    p "総合計点数:#{r[2]}"
    p "マルチボリューム識別:#{r[3]}"
  end
end