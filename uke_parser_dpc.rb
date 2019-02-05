# TODO: refactor
# http://www.ssk.or.jp/seikyushiharai/rezept/iryokikan/iryokikan_02.files/jiki_d01.pdf

require 'yaml'
require 'csv'

uke = CSV.read('uke/dpc.csv')
uke.each do |r|
  case r[0]
  when 'IR' then
    p "--- IR: 医療機関情報レコード ---"
  when 'RE' then
    p "レセプト共通レコード"
  when 'HO' then
    p "保険者レコード"
  when 'KO' then
    p "公費レコード"
  when 'GR' then
    p "包括評価対象外理由レコード"
  when 'CO' then
    p "コメントレコード"
  when 'SJ' then
    p "症状詳記レコード"
  when 'BU' then
    p "診断群分類レコード"
  when 'SB' then
    p "傷病レコード"
  when 'SY' then
    p "傷病名レコード"
  when 'KK' then
    p "患者基礎レコード"
  when 'SK' then
    p "診療関連レコード"
  when 'GA' then
    p "外泊レコード"
  when 'HH' then
    p "包括評価レコード"
  when 'GT' then
    p "合計調整レコード"
  when 'GO' then
    p "診療報酬請求書レコード"
  end
end