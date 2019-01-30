# TODO: refactor
# http://www.ssk.or.jp/seikyushiharai/rezept/iryokikan/iryokikan_02.files/jiki_s01.pdf

require 'yaml'
require 'csv'

payers = YAML.load_file('db/01_payers.yml')
prefectures = YAML.load_file('db/02_prefectures.yml')
tensuhyo = YAML.load_file('db/03_tensuhyo.yml')

uke = CSV.read('uke/shika_shaho.csv')
uke.each do |r|
  case r[0]
  when 'IR' then
    p "--- IR: 医療機関情報レコード ---"
    p "審査支払機関:#{payers[r[1]]}"
    p "都道府県:#{prefectures[r[2]]}"
    p "点数表:#{tensuhyo[r[3]]}"
    p "医療機関コード:#{r[4]}"
    p "予備:#{r[5]}"
    p "請求年月:#{r[6]}"
    p "電話番号:#{r[7]}"
    p "届出:#{r[8]}"
  when 'RE' then
    p "--- RE: レセプト共通レコード --- "
  when 'HO' then
    p "--- HO: 保険者レコード --- "
  when 'KO' then
    p "--- KO: 公費レコード --- "
  when 'HS' then
    p "--- HS: 傷病名部位レコード --- "
  when 'SS' then
    p "--- SS: 歯科診療行為レコード --- "
  when 'SI' then
    p "--- SI: 医科診療行為レコード --- "
  when 'IY' then
    p "--- IY: 医薬品レコード --- "
  when 'TO' then
    p "--- TO: 特定器材レコード --- "
  when 'CO' then
    p "--- CO: コメントレコード --- "
  when 'GO' then
    p "--- GO: 診療報酬請求書レコード ---"
    p "総件数:#{r[1]}"
    p "総合計点数:#{r[2]}"
    p "マルチボリューム識別:#{r[3]}"
  end
end