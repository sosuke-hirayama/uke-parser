# TODO: unko
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


module CSVConvertible
  def to_csv(*keys)
    keys = self.map(&:keys).inject([], &:|) if keys.empty?
    CSV.generate do |csv|
      csv << keys
      self.each { |hash| csv << hash.values_at(*keys) }
    end
  end
end

module Wareki
  def to_seireki(*str)
    case self[0]
    when '4' then
      year = self[1].to_i*10 + self[2].to_i + 1988
      "#{year.to_s+self[3]+self[4]}"
    when '3' then
      year = self[1].to_i*10 + self[2].to_i + 1925
      "#{year.to_s+self[3]+self[4]}"
    end
  end
end

raws = []
ir01, ir04, ir06, ir07 = nil
re03, re05, re06, re13 = nil
ho01, ho04, ho05 = nil
ko01, ko04, ko05 = nil
sy01, sy03, sy06 = nil
si01, si02, si03, si05, si06 = nil
iy01, iy02, iy03, iy04, iy05, iy06 = nil

uke = CSV.read('uke/kokuho_201811.csv')
uke.each do |r|
  case r[0]
  when 'IR' then
    raws.push({
      gn01: 'common', 
      ir01: ir01=payers[r[1]], 
      ir04: ir04=r[4], 
      ir06: ir06=r[6], 
      ir07: ir07=r[7].extend(Wareki).to_seireki
    })
  when 'RE' then
    raws.push({
      gn01: 'patient', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03=r[3].extend(Wareki).to_seireki,
      re05: re05=danzyo[r[5]],
      re06: re06=r[6].extend(Wareki).to_seireki,
      re13: re13=r[13] 
    })
  when 'HO' then
    raws.push({
      gn01: 'payer', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03,
      re05: re05,
      re06: re06,
      re13: re13,
      ho01: ho01=r[1],
      ho04: ho04=r[4],
      ho05: ho05=r[5]
    })
  when 'KO' then
    raws.push({
      gn01: 'payer', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03,
      re05: re05,
      re06: re06,
      re13: re13,
      ko01: ko01=r[1],
      ko04: ko04=r[4],
      ko05: ko05=r[5]
    })
  when 'SY' then
    raws.push({
      gn01: 'disease', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03,
      re05: re05,
      re06: re06,
      re13: re13,
      sy01: sy01=byomei[r[1]],
      sy03: sy03=tenki[r[3]],
      sy06: sy06=shubyo[r[6]]
    })
  when 'SI' then
    raws.push({
      gn01: 'practice', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03,
      re05: re05,
      re06: re06,
      re13: re13,
      si01: si01=shinryoshikibetsu[r[1]],
      si02: si02=futan[r[2]],
      si03: si03=tensu[r[3]],
      si05: si05=r[5],
      si06: si06=r[6]
    })
  when 'IY' then
    raws.push({
      gn01: 'drug', 
      ir01: ir01,
      ir04: ir04,
      ir06: ir06,
      ir07: ir07,
      re03: re03,
      re05: re05,
      re06: re06,
      re13: re13,
      iy01: iy01=shinryoshikibetsu[r[1]],
      iy02: iy02=futan[r[2]],
      iy03: iy03=r[3],
      iy04: iy05=r[4],
      iy05: iy06=r[5],
      iy06: iy06=r[6]
    })
  end
end

IO.write 'statistics.csv', raws.extend(CSVConvertible).to_csv