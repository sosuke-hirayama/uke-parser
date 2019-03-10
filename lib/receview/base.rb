# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceView_Base
  SIGNER = "/C=JP/ST=Tokyo/L=Bunkyo/O=Japan Medical Association/OU=ORCA Project/CN=Japan Medical Association"
  REG_KEY = 'Software\JMA\jma-receview'
  LOCK_FILE = "jma-receview.lock"
  DIRECTORY_FLOPPY = "/floppy"
  DIRECTORY_CDROM = "/cdrom"

  @@reg  = true

  def initialize
    require 'rbconfig'
    require 'pathname'
    require 'kconv'
    if File::ALT_SEPARATOR == nil
      @path_char = File::SEPARATOR
    else
      @path_char = File::ALT_SEPARATOR
    end

    @path_fstab = "/etc/fstab"
    @path_group = "/etc/group"

    @nkf_version = {
      "2.0.4 (2005-03-05)" => true,
      "2.0.7 (2006-06-13)" => true,
      "2.0.8 (2007-01-28)" => false
    }

    @panda_version = "1.4.3"
    @db_version = "030500-1"
    # 合計点数 排除 識別番号
    # 入院食事等 97
    @haijo_sum_tensu = [
      "97"
    ]
    @haijo_syukei_sort = [
      "3"
    ]
    @haijo_syukei_tougou = [
      "67"
    ]
    # 広域連合先頭識別
    @wau_no = "39"
    @wau_name = "後期高齢者医療広域連合"

    @window_tabs = {
      "basic" => "患者情報",
      "preview" => "レセプトプレビュー",
      "code" => "レセ電コード[個別]",
      "days" => "算定日",
    }

    @printspool_tabs = {
      "print" => "現在の印刷情報",
      "pdf" => "現在のPDF情報",
      "history" => "過去の印刷履歴",
    }

    @printspool_column = [
      "レセ番号",
      "患者番号",
      "診療年月",
      "項目",
      "状態",
      "実行時間"
    ]

    @printspool_message = {
      "title"    => "印刷スプール",
      "preview"  => "プレビュー",
      "pdf"      => "PDF出力",
      "csv"      => "レセ電CSV",
      "csv_all"  => "全レセCSV",
      "print_ok" => "印刷完了",
      "print_ap" => "印刷予約",
      "output"  => "出力完了",
    }

    @printspool_message_fix = [
      "印刷予約",
      "PDF出力",
      "印刷完了",
      "出力完了"
    ]

    @message = {
      "Next_dev" => "現在の媒体を取り出して,\n" +
        "続きの媒体をセットしてください。\n" +
        "準備が出来たらOKを選択してください。",

      "Other_Volme" => "マルチボリュームファイル展開時に、\n" +
        "他のボリュームファイルが選択されました。",

      "Repetition_dev" => "すでに読み込み済です。\n" +
        "次のファイルを選択してください。",

      "Old_ghosp" => "旧総合病院データです。",
      "Not_old_ghosp" => "旧総合病院データではありません。",
      "Other_Error" => "ファイルが存在しない、または壊れているか、\n" + 
                  "その他のエラーでファイルが読み込めません。",
      "Rece_No_File" => "レセ電ファイルではありません。",
      "Can_Not_Access" => "アクセス許可がありません。",
      "Not_Found_Record_GO" => "GOレコードがありません。\nファイルが壊れています。",
      "Broken_Record_GO" => "GOレコードが読めません。\nレコードが破損しています。",
      "File_Not_Found" => "ファイルが存在しません。",
      "OverSize" => "ファイルサイズが上限値以上です。",
      "NotISO9660" => "ISO9660イメージファイルではありません。",
      "OkISO9660_ReceFileNotFound" => "ISO9660イメージ上を検索しました。\n"+\
        "receiptc.ukeファイルがありませんでした。\n\n別名で保存されているか、\n"+\
        "または、ISO9660イメージ上にありません。",
    }

    @message_tab = {
      "none" => "",
      "read" => "処理中です",
    }

    @message_dbfile = {
      "title" => "接続設定",
      "normal_title" => "DBFile 設定",
      "format_title" => "DBFile 初期化中",
      "select_title" => "DBFileのディレクトリを選択してください。",
      "wait" => "DBfileを読み込み中です。\nしばらくお待ちください..",
      "day" => "日付範囲",
      "number" => "件",
      "error_a" => "読み込み時いずれかのエラーが発生しました\n" +
                   " * DBFileが正常なファイルでない\n" +
                   " * パスが正しくない\n" +
                   " * パーミッション等が適切でない",
      "error_b" => "ディレクトリではありません\n" +
                   "選択先はディレクトリを指定してください",
      "error_c" => "ディレクトリがありません\n" +
                   "選択先はディレクトリを指定してください",
    }
    @msg_etc = {
      "r_title" => "のデータ表示中..",
      "r_title_" => "のデータ表示中..",
      "ckb_all_clear" => "患者情報のチェックをすべて戻しますが、\n" +
                         "よろしいでしょうか？"
    }
    @msg_prog = {
      "situation" =>   "進行状況...",
      "file_read" =>   "[ファイル読み込み中]",
      "file_deploy" => "[ファイル展開中]",
      "file_total" =>  "[データ集計中]",
      "raw_code" =>    "[レセ電コード表示中]",
      "code_recal" =>  "[再集計処理中]",
    }
    @msg_update = {
      "tag_no_return" => %Q{<span foreground="blue" size="large">BODY</span>},
      "tag" => %Q{<span foreground="blue" size="large">BODY</span>\n},
      "mark" => "■",
      "client_package_msg1" => "クライアントパッケージ",
      "server_package_msg1" => "サーバパッケージ",
      "client_package_msg2" => "レセ電ビューア: クライアント",
      "server_package_msg2" => "レセ電ビューア: サーバ",
      "update_gksu" => "のアップデートを確認します。\nユーザのパスワードを入力してください。",
      "start" => "最新版を確認中です。\n",
      "update" => "パッケージリストの更新中です。\n",
      "update_success" => "  正常にアップデートされました。\n",
      "update_fail" => "パッケージリストの更新に失敗しました。\n",
      "client_new" => "クライアントは最新版です。\n",
      "server_new" => "サーバは最新版です。\n",
      "update_exist" => "アップデート版が存在します。\n",
      "present_version" => %Q{  現在のバージョン: <span foreground="blue">VERSION</span>\n},
      "new_version" => %Q{  最新のバージョン: <span foreground="blue">VERSION</span>\n},
      "package_fail" => "パッケージを認識できません。\n",
      "server_package_no" => "サーバパッケージがインストールされていません。\n",
      "old_version" => %Q{  旧バージョン: <span foreground="blue">VERSION</span>\n},
      "pre_version" => %Q{  現バージョン: <span foreground="blue">VERSION</span>\n},
      "win_update_signcode" => "署名の確認... [OK]\n",
      "win_update_program" => "アップデートプログラムの起動... [OK]\n",
      "win_update_download" => "アップデートプログラムのダウンロード... [OK]\n",
      "win_checksum_ok" => "アップデートプログラムのハッシュ値確認... [OK]\n",
      "win_restart" => "アップデート後に自動で\nレセ電ビューアが再起動されます。",
      "linux_restart" => "アップデート後にレセ電ビューアの\n再起動が必要です。",
      "upgrade" => "アップデート中です...\n",
      "download" => "ダウンロード中です...\n",
      "md5_error" => "アップデートプログラムのmd5ハッシュ値が一致しません。\n",
      "sha256_error" => "アップデートプログラムのsha256ハッシュ値が一致しません。\n",
      "checksum_error" => "アップデートプログラムのハッシュ値が一致しません。\n",
      "installer_error" => "インストーラ起動に失敗しました。\n",
      "sign_error" => "署名の検証に失敗しました。\n",
      "error" => "  エラーが発生しました。\n",
      "url_http_error" => "HTTPでの接続を試みました。\nHTTPSでの接続を行なってください。\n",
      "url_ftp_error" => "FTPでの接続を試みました。\nHTTPSでの接続を行なってください。\n",
      "url_other_error" => "その他のプロトコルでの接続を試みました。\nHTTPSでの接続を行なってください。\n",
      "url_https_error" => "HTTPSでの接続を試みましたが、エラーが発生しました。\n",
      "timeout_error" => "接続がタイムアウトしました。\n",
    }
    @menu_tab = {
      "tab1" => "種別点数情報",
      "tab2" => "医療機関 / 患者情報",
      "tab3" => "レセ電コード"
    }
    @menu_ir = [
      "",
      "審査支払機関",
      "都道府県",
      "医療機関コード",
      "診療科",
      "医療機関名称",
      "請求年月",
      "VOL"
    ]
    @menu_re = [
      "保険者番号",
      "レセプト種別",
      "公費種別",
      "診療年月",
      "  件数",
      "    合計点数",
      "        内訳",
      ""
    ]
    @menu_rr = [
      "労働基準監督署",
      "帳票種別",
      "診療年月",
      "  件数",
      "    合計金額",
      "        内訳",
      ""
    ]
    @menu_sick = [
      "主",
      "傷病名",
      "診療開始日",
      "転帰"
    ]
    @menu_rrsick = [
      "主",
      "傷病名",
      "診療開始日",
      ""
    ]
    @menu_teki = [
      "識別",
      "負",
      "診療行為",
      "数量",
      "点数x回数"
    ]
    @menu_rrteki = [
      "識別",
      "　",
      "診療行為",
      "数量",
      "点数x回数"
    ]
    @menu_santei = [
      "識別",
      "負",
      "診療行為",
      "数量",
      "点数x回数",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25",
      "26",
      "27",
      "28",
      "29",
      "30",
      "31"
    ]
    @menu_rrsantei = [
      "識別",
      "　",
      "診療行為",
      "数量",
      "点数x回数",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25",
      "26",
      "27",
      "28",
      "29",
      "30",
      "31"
    ]
    @kanja_object = {
      "henrei_data" => "返戻理由",
      "sinryo_ymd" => "診療年月日",
      "receipt_syubetu" => "レセプト種別",
      "kanja_status" => " - ",
      "kanja_no" => "患者番号",
      "kanja_no_space" => " - ",
      "hosp_day" => "入院年月日",
      "hosp_day_space" => " - ",
      "receipt_no" => "レセプト番号",
      "receipt_no_space" => " - ",
      "name" => "名前",
      "name_space" => " - ",
      "sex" => "性別",
      "sex_space" => " - ",
      "age" => "年齢",
      "age_space" => " - ",
      "birthday" => "生年月日",
      "birthday_space" => " - ",
      "hoken_no" => "保険者番号",
      "hoken_no_space" => " - ",
      "sign" => "記号",
      "sign_space" => " - ",
      "bango" => "番号",
      "bango_space" => " - ",
      "roujin_iryou_no_space" => " - ",
      "towns_no_space" => " - ",
      "kouhi_hutan_1_space" => " - ",
      "kouhi_uke_1_space" => " - ",
      "kouhi_hutan_2_space" => " - ",
      "kouhi_uke_2_space" => " - ",
      "kouhi_hutan_3_space" => " - ",
      "kouhi_uke_3_space" => " - ",
      "kouhi_hutan_4_space" => " - ",
      "kouhi_uke_4_space" => " - ",
      "space_space_1" => "",
      "real_days" => "実日数",
      "seikyu_tensu" => "請求点",
      "hutan_money" => "一部負担金",
      "hoken_space_r" => " - ",
      "hoken_space_s" => " - ",
      "hoken_space_h" => " - ",
      "kouhi_1_space_r" => " - ",
      "kouhi_1_space_s" => " - ",
      "kouhi_1_space_h" => " - ",
      "kouhi_2_space_r" => " - ",
      "kouhi_2_space_s" => " - ",
      "kouhi_2_space_h" => " - ",
      "kouhi_3_space_r" => " - ",
      "kouhi_3_space_s" => " - ",
      "kouhi_3_space_h" => " - ",
      "kouhi_4_space_r" => " - ",
      "kouhi_4_space_s" => " - ",
      "kouhi_4_space_h" => " - ",
      "roujin_iryou_no" => "市町村",
      "kouhi_hutan_1" => "公負１",
      "kouhi_uke_1" => "公受１",
      "towns_no" => "老人受",
      "kouhi_hutan_2" => "公負２",
      "kouhi_uke_2" => "公受２",
      "kouhi_hutan_3" => "公負３",
      "kouhi_uke_3" => "公受３",
      "kouhi_hutan_4" => "公負４",
      "kouhi_uke_4" => "公受４",
      "rr_sick_ymd" => "傷病年月日",
      "rr_sick_ymd_space" => " - ",
      "rr_sinkei" => "新継再別",
      "rr_sinkei_space" => " - ",
      "rr_tenki" => "転帰事由",
      "rr_tenki_space" => " - ",
      "rr_ryoyo_ymd" => "療養期間",
      "rr_ryoyo_ymd_space" => " - ",
      "rr_sinryo_ymd" => "診療実日数",
      "rr_sinryo_ymd_space" => " - ",
      "rr_sum_money" => "合計金額【イ】+【ロ】+【ハ】",
      "rr_sum_money_space" => " - ",
      "rr_subtotal_tensu" => "小計点数",
      "rr_subtotal_tensu_space" => " - ",
      "rr_subtotal_tensu2money" => "小計点数金額【イ】",
      "rr_subtotal_tensu2money_space" => " - ",
      "rr_subtotal_money" => "小計金額【ロ】",
      "rr_subtotal_money_space" => " - ",
      "rr_subtotal_lunchmoney" => "食事金額【ハ】",
      "rr_subtotal_lunchmoney_space" => " - ",
      "rr_subtotal_lunchnumber" => "食事回数",
      "rr_subtotal_lunchnumber_space" => " - ",
      "rr_enterprise_name" => "事業の名称",
      "rr_enterprise_name_space" => " - ",
      "rr_enterprise_addr" => "事業場の所在地",
      "rr_enterprise_addr_space" => " - ",
      "rr_sickname_after" => "傷病の経過",
      "rr_sickname_after_space" => " - ",
    }
    @kanja_button = {
      "hoken" => "保険",
      "kouhi_1" => "公１",
      "kouhi_2" => "公２",
      "kouhi_3" => "公３",
      "kouhi_4" => "公４",
    }
    @find_keyword_radio_name = [
      "名前",
      "患者番号",
      "レセプト番号",
      "傷病名",
      "医療品",
      "診療行為",
      "点数",
      "診療年月",
      "チェック済",
      "要チェック",
      "チェックなし",
      "公費",
      "診療科",
      "特記事項",
      "保険者、負担者番号",
      "入外区分",
      "フリーコメント内容",
    ]
    @find_keyword_radio_val = [
      "name",
      "no",
      "rece",
      "sick",
      "iy",
      "si",
      "ten",
      "ymd",
      "check",
      "recheck",
      "nocheck",
      "kouhi",
      "sy_ka",
      "tokki",
      "hokenja",
      "nyugai_kbn",
      "comment",
    ]
    @find_keyword_colm = [
      "患者番号",
      "レセプト番号",
      "名前",
      "一致項目"
    ]
    @find_option = {
      "si" => 
        [
          "重複患者の非表示",
          "重複患者の表示",
        ],
      "comparison" => 
        [
          "以上",
          "以下",
          "一致",
        ],
      "dtd" => 
        [
          "診療科あり",
          "診療科なし",
        ],
      "sickname" => 
        [
          "傷病名あり",
          "傷病名なし",
          "主病名あり",
          "主病名なし",
          "転帰",
        ],
      "nyugai_kbn" => 
        [
          "入院",
          "入院外",
        ],
      "comment" => 
        [
          "重複患者の非表示",
          "重複患者の表示",
        ],
    }
    @icon = [
      "/usr/share/pixmaps/jma-receview-icon.png",
      "/usr/local/share/pixmaps/jma-receview-icon.png",
      "./jma-receview-icon.png",
      "/usr/share/pixmaps/jma-receview-icon-48.png",
      "/usr/local/share/pixmaps/jma-receview-icon-48.png",
      "./jma-receview-icon-48.png",
      "/usr/share/pixmaps/jma-receview-icon.xpm",
      "/usr/local/share/pixmaps/jma-receview-icon.xpm",
      "./jma-receview-icon.xpm"
    ]

    @about = {
      "web_client" => [["/usr/bin/iceweasel", "iceweasel"],
        ["/usr/bin/firefox3", "firefox3"],
        ["/usr/bin/firefox", "firefox"],
        ["/usr/bin/mozilla-firefox", "mozilla-firefox"],
        ["/usr/bin/mozilla", "mozilla"],
        ["C:\\Program Files\\Mozilla Firefox\\firefox.exe", "firefox"],
        ["C:\\Program Files\\Internet Explorer\\IEXPLORE.EXE", "iexplore"]
      ],
      "artists" => "ORCA Support Center <support@orca.med.or.jp>",
      "name" => "Jma-ReceView",
      "comments" => "レセ電データ表示ツール (Gtk2+Ruby#{RUBY_VERSION.to_s})",
      "copyright" => "Copyright (C) 2014 ORCA Project",
      "license" => "JMA OpenSource License. See license.html or doc/licence.txt",
      "website" => "http://www.orca.med.or.jp",
      "website_label" => "ORCA Project Website"
    }
    @db_check_table = {
      "test" => "接続テスト中..",
      "test_tbls" => "テーブルリスト,取得中",
      "test_syskanri" => "tbl_syskanri,取得中",
      "test_tensu"    => "tbl_tensu,取得中",
      "test_byomei"   => "tbl_byomei,取得中",
      "test_labor_sio"   => "tbl_labor_sio,取得中",
      "pt_error" => "Protocol error Possibility [1.4.3 or more]",
      "found_dbfile" => "DBFileが見つかりました。",
      "not_found_error" => "DBFileが見つかりませんでした。サーバの経路を確認してください。",
      "store_error" => "CA証明書が読み込めませんでした。CA証明書の設定を確認してください。",
      "verify_error" => "署名検証に失敗しました。正しいCA証明書が設定されているか確認してください。",
      "storage_error" => "ローカルのDBFileのディレクトリが存在しませんでした。\nサーバからのDBFileの取得を中止しました。",
      "proxy_url_error" => "プロキシ経由でのDBFile取得に失敗しました。プロキシの設定を確認してください。",
      "proxy_user_error" => "プロキシの認証に失敗しました。プロキシの設定を確認してください。",
      0 => "接続成功",
      1 => "hospnum get NG",
      2 => "tensu get NG",
      3 => "hospnum,tensu get NG",
      4 => "byomei get NG",
      5 => "hospnum,byomei get NG",
      6 => "tensu,byomei get NG",
      7 => "hospnum,tensu,byomei get NG",
      8 => "labor get NG",
      9 => "hospnum,labor get NG",
      10 => "tensu,labor get NG",
      11 => "hospnum,tensu,labor get NG",
      12 => "byomei,labor get NG",
      13 => "hospnum,byomei,labor get NG",
      14 => "tensu,byomei,labor get NG",
      15 => "hospnum,tensu,byomei,labor get NG",
      64 => "receview-serverの起動,ホストへの経路を確認してください",
      128 => "接続先のポート番号を確認してください",
      256 => "panda version error",
      512 => "authentication error",
      1024 => "不明なエラーが発生しました",
      2048 => "DBFILEのパス,アクセス権限を確認してください",
      4096 => "DBFILEがありません",
      8192 => "アクセス権限がありません",
    }
    @dc = {
      "auto" => "自動設定",
      "fstab_ok" => "Floppy設定 0に設定しました",
      "fstab_err" => "Floppy設定 [fstab error]",
      "dir_errf" => "Floppy設定 [It is not a directory]",
      "dir_errd" => "Floppy設定 [Not found directory]",
      "fs_ok" => "Floppy設定 設定できます",
      "fs_err" => "Floppy設定 設定できません"
    }
    @popup_name = {
      "ckb_na" => "要チェックマーク",
      "ckb_ok" => "チェックを入れる",
      "ckb" => "チェックを外す",
      "ckb_all" => "すべてチェックを外す",
      "sort_name" => "並び替え[名前]",
      "sort_rece_no" => "並び替え[レセ番号]",
      "sort_image_stat" => "並び替え[チェック状態]",
      "find" => "検索",
      "recal" => "点数チェック",
      "edit" => "頭書きの編集",
      "exit" => "閉じる"
    }
    @popup_sick_name = {
      "sick_edit" => "病名の編集",
      "exit" => "閉じる"
    }
    @popup_search_name = {
      "add_print_spool" => "印刷スプールに追加",
      "all_add_print_spool" => "すべて印刷スプールに追加",
      "add_pdf_spool" => "印刷スプールに追加(PDF)",
      "all_add_pdf_spool" => "すべて印刷スプールに追加(PDF)",
      "exit" => "閉じる"
    }
    @popup_preview_name = {
      "next_page" => "次のページ",
      "prev_page" => "前のページ",
      "fit_scale" => "フィットサイズ",
      "nml_scale" => "標準サイズ",
      "050_scale" => "50％",
      "075_scale" => "75％",
      "100_scale" => "100％",
      "120_scale" => "120％",
      "150_scale" => "150％",
      "170_scale" => "170％",
      "230_scale" => "230％",
      "300_scale" => "300％",
      "print" => "印刷",
      "output" => "出力",
      "exit" => "閉じる"
    }
    @update_ui = {
      "refresh" => "アップデート開始",
      "upstart" => "レセ電ビューアの再起動",
      "check" => "アップデート確認",
    }
    @print_spool_ui = {
      "print" => "印刷",
      "pdf" => "PDF出力",
      "select_sub" => "予約のみ選択",
      "select_all" => "すべて選択",
      "cancel" => "予約削除",
      "close" => "閉じる",
    }
    @toolbox_ui= {
      "title" => "ツール",
      "next" => "次の患者\n",
      "pext" => "前の患者\n",
      "preview_next" => "プレビュー\n次項",
      "preview_pext" => "プレビュー\n前項",
    }
    @sick_ui = {
      "yes" => "YES",
      "uniq-edit" => "編集病名",
      "quo-edit" => "変更しない",
    }
    @find_ui = {
      "search_ex" => "拡大検索",
      "search"    => "検索",
      "close" => "閉じる",
      "stop"  => "中止",
      "clear" => "クリア",
      "csv" => "CSV出力",
      "comp_int"  => "検索 0件一致...",
      "non_check" => "チェックなし",
      "searchs_title" => "検索 検索中...",
      "stop_search_t" => "検索 中止しました",
      "not_agment_t"  => "検索 一致する項目がありませんでした",
      "not_agment_c"  => "一致する項目がありません",
      "tips_entry" => "検索キーワード",
      "tips_radio" => "検索項目",
      "tips_do_search" => "検索結果",
      "tips_option_search" => "検索オプション",
    }
    @find_message = {
      "csv" => "CSV出力",
      "csv_ex" => "検索結果をCSV出力しました。",
    }

    @find_str = {
      "kouhi" => "つの公費",
      "ten_h" => "点(保  険)",
      "ten_k1" => "点(公費１)",
      "ten_k2" => "点(公費２)",
      "ten_k3" => "点(公費３)",
      "ten_k4" => "点(公費４)",
      "MainSick_OKfound" => "(主病名あり)",
      "MainSick_NGfound" => "(主病名なし)",
      "SinryoKBN_NGfound" => "診療科が未設定",
      "hoken_tag" => "保険:",
      "kouhi_tag" => "公費:",
      "rosai_no_tag" => "労働保険番号:",
      "hosp_in" => "入院",
      "hosp_out" => "入院外",
    }
    @find_str_rosai_money = ["円(小計点数金額換算)", "円(小計金額)", "円(食事療養合計金額)"] 
    @hoken_list = ["医保", "公費1", "公費2", "公費3", "公費4"]
    @code_view_ui = {
      "tips_entry"    => "レセ電コードを編集できます"
    }
    @layout_combo = [
      "県単位で広域連合をまとめる",
      "広域連合をまとめない (保険者単位)",
      "自県の広域連合はまとめ、他県はまとめない"
    ]
    @mount_combo = [
      "常にマウント アンマウント",
      "マウントされていた場合はアンマウントしない",
      "マウント アンマウントしない",
    ]
    @edit_mode = {
      "view" => "ビューアモードに切替えます",
      "edit" => "編集モードに切替えます",
      "attention" => "患者を選択してください",
      "sick_select" => "病名を選択してください",
      "error_rosai" => "労災レセ電ファイルです。\n編集モードには切り替えできません。"
    }
    @headline_edit = {
      "title" => "頭書き修正",
      "name" => "氏名",
      "sex" =>  "性別",
      "hkno" => "保険者番号",
      "hkno_k" => "　　　記号",
      "hkno_b" => "　　　番号",
      "htno" => "負担者番号",
      "juno" => "受給者番号"
    }
    @sex = {
      "1" => "男",
      "2" => "女"
    }
    @database = {
      "dbfile_mode" => ["DBをメモリ内に読み込む", "DBを毎回ファイルから読み込む"],
      "api_mode" => ["Basic認証", "SSLクライアント認証"]
    }
    @name        = "レセ電ビューア"
    @file_title  = "レセ電ファイルセレクト"
    @total_label = "合計人数：0  合計件数：0  合計点数：0"
    @total_label_rosai = "合計件数：0  合計金額：0"
    @title       = "#{@name}    #{@total_label}"
    @file_title_edit  = "レセ電ファイル出力"

    @home = [
      "Desktop",
      "デスクトップ"
    ]

    @document_home = [
      "Documents",
      "ドキュメント"
    ]

    @preview_message = {
      "all_preview_pdfs_t" => "プレビューイメージ出力(すべての患者)",
      "all_preview_pdfs_ot" => "プレビューイメージ出力中(全患者)",
      "all_preview_pdfs_b" => "件のデータをPDFに出力完了",
      "all_preview_pdfs_ob" => "0000/9999 処理",
      "search_preview_pdfs_t" => "プレビューイメージ出力(検索結果)",
      "search_preview_pdfs_ot" => "プレビューイメージ出力中(検索結果)",
      "spool_preview_pdfs_t" => "プレビューイメージ出力(PDFスプール)",
      "spool_preview_pdfs_ot" => "プレビューイメージ出力(PDFスプール)",
    }

    @file_message = {
      "exist_b" => "指定した保存先に既にファイルがあります。\n" +
        "上書きしますか？",
      "exist_t" => "指定先に同名ファイル",
      "access_b" => "書き込み先にアクセス権限がありません。",
      "access_t" => "指定先にアクセス権限エラー",
      "overwrite_b" => "ファイルの上書き保存は出来ません。\n" + 
        "\n" +
        "必ず新しいファイル名(別名)で、保存してください。",
      "overwrite_t" => "保存先のエラー",
      "print_t" => "プレビューイメージの印刷",
      "print_b" => "表示中のプレビューイメージの印刷を行いますか？",
      "print_nodev" => "印刷可能なプリンタがありません。",
      "print_ttext" => "CSVデータの印刷",
      "print_btext" => "表示中のレセ電情報の印刷を行いますか？",
    }

    @sickname_edit_message = {
      "move_title" => "あなたの入力された病名はマスター上で"+
        "移行病名の扱いとなっています。",
      "move_timelimit" => "入力された病名は[#time]です。",
      "move_in_name" => "入力された病名",
      "move_out_name" => "推奨する病名",
      "move_message" => "推奨する病名に置き換えますか？"
    }

    @output_message = {
      "no_read_file" => "出力元のレセ電データが読み込まれていません。\n"+
        "レセ電データ読み込み後、選択してください。",
      "no_read_search" => "対象の検索結果がありません。\n"+
        "検索結果の表示を確認後、選択してください。",
    }

    @print_method_name = {
      "local" => "１.内部印刷モジュール(GnomePrint)",
      "outside" => "２.外部印刷モジュール(OhterViewer)",
    }

    @print_method = [
      "１.内部印刷モジュール(GnomePrint)",
      "２.外部印刷モジュール(OhterViewer)",
    ]

    @etc_directory_method = [
      "最終ディレクトリを保存する",
      "最終ディレクトリを保存しない",
      "ディレクトリを常に固定する",
    ]

    @etc_fileselect_method = [
      "GTKを利用する(デフォルト)",
      "ネイティブダイアログを利用する",
      "ネイティブダイアログを利用する(別スレッド)",
    ]

    @dev_floppy = 'floppy'
    @dev_cdrom = 'cdrom'

    @xdg_user_dirs_path = [
      "#{ENV['HOME']}/.config/user-dirs.dirs",
      "/etc/xdg/user-dirs.defaults"
    ]

    @version_check_url = "https://ftp.orca.med.or.jp/pub/receview/win/version"
    @version_md5_url = "https://ftp.orca.med.or.jp/pub/receview/win/md5"
    @version_sha256_url = "https://ftp.orca.med.or.jp/pub/receview/win/sha256"
    @version_base_url = "https://ftp.orca.med.or.jp/pub/receview/win/"

    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      @secure_ca_file = [self.get_path, 'etc', 'cert.pem'].join(@path_char)
    else
      @secure_ca_file = "/usr/lib/ssl/cert.pem"
    end
    @signcode_bin = [self.get_path, "lib", "GTK", "bin", "osslsigncode.exe"].join(@path_char)
    @signcode_bat = [self.get_path, "share", "scripts", "verify.bat"].join(@path_char)
  end

  def progress_string(string)
    bt = @msg_prog['situation']
    pt = @msg_prog[string]
    if bt != pt
      sprintf("#{bt}%-8s#{pt}", "")
    else
      bt
    end
  end

  def up_scripts
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      base_path = self.get_path + @path_char
      scripts = [
        base_path + "lib/ruby/site_ruby/1.8/jma/receview/upstart.rb",
        base_path + "lib/ruby/site_ruby/1.9.1/jma/receview/upstart.rb",
      ]
    else
      scripts = [
        "/usr/lib/ruby/1.8/jma/receview/upstart.rb",
        "/usr/lib/ruby/1.9.1/jma/receview/upstart.rb",
        "/usr/lib/ruby/2.3.0/jma/receview/upstart.rb",
        "/usr/lib/ruby/vendor_ruby/2.5.0/jma/receview/upstart.rb",
        "/home/yasumi/work/ruby+gtk/receview/trunk/jma/receview/upstart.rb",
      ]
    end
    return scripts
  end

  def rb_ld_path(module_name)
    $LOAD_PATH.each do |ld_path|
      native_path_rb = "#{ld_path}/#{module_name}"
      if File.exist?(native_path_rb)
        return native_path_rb
      elsif File.exist?(native_path_rb+".rb")
        return native_path_rb + ".rb"
      end
    end
  end

  def lockfile_path
    return [ENV['TEMP'], LOCK_FILE].join(@path_char)
  end

  def home_native
    if /linux/ =~ RUBY_PLATFORM.downcase
      home = ENV["HOME"].to_s
    else
      home = (ENV['USERPROFILE'].to_s).toutf8
    end
    return home
  end

  def xdg_user_dirs
    config_data = {}
    @xdg_user_dirs_path.each do |xdg_config|
      if File.exist?(xdg_config)
        begin
          file_data = File.open(xdg_config).read
          file_data.split(/\n/).each do |text|
            unless /^#/ =~ text
              key, value = text.split(/=/)
              config_data[key] = xdg_user_home_replace(value)
            end
          end
          break
        rescue
          break
        end
      end
    end
    return config_data
  end

  def xdg_user_home_replace(value)
    return value.gsub(/\$HOME/, ENV['HOME']).gsub(/"/, "")
  end

  def desktop_native
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      home = home_native
      @home.each do |hmt|
        desktop_dir = [home, hmt].join(@path_char).tosjis
        if File.exist?(desktop_dir)
          if File.ftype(desktop_dir) == "directory"
            home = desktop_dir
            break
          end
        end
      end
      return home.toutf8
    else
      return self.xdg_user_dirs['XDG_DESKTOP_DIR']
    end
  end

  def doc_native
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      home = home_native
      @document_home.each do |hmt|
        desktop_dir = [home, hmt].join(@path_char).tosjis
        if File.exist?(desktop_dir)
          if File.ftype(desktop_dir) == "directory"
            home = desktop_dir
            break
          end
        end
      end
      return home.toutf8
    else
      return self.xdg_user_dirs['XDG_DOCUMENTS_DIR']
    end
  end

  def image_path(key="")
    image_path = Hash.new
    ref = ""

    if /linux/ =~ RUBY_PLATFORM.downcase
      image_path["folder"] = ''
      image_path["directory"] = ''
      image_path["file"] = ''
      image_path["desktop"] = ''
    else
      image_path["folder"] = 'C:\ruby/samples/ruby-gnome2/' + \
        'gtk/gtk-demo/gnome-fs-directory.png'
      image_path["directory"] = 'C:\ruby/samples/ruby-gnome2/' + \
        'gtk/gtk-demo/gnome-fs-directory.png'
      image_path["file"] = 'C:\ruby/samples/ruby-gnome2/' + \
        'gtk/gtk-demo/gnome-fs-regular.png'
      image_path["desktop"] = 'C:\ruby/samples/ruby-gnome2/' + \
        'gtk/gtk-demo/gnome-calendar.png'
    end
    if !key.to_s.empty?
      ref = image_path[key].to_s
      if !File.exist?(image_path[key].to_s)
        ref = ""
      end
    else
      ref = image_path
    end
    return ref
  end

  def rb_config
    conf = begin; ::RbConfig::CONFIG; rescue NameError; ::Config::CONFIG; end
    return conf
  end

  def rb_path
    c = self.rb_config
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      ruby = ('"' + File.join(c['bindir'], c['rubyw_install_name']) << c['EXEEXT'] + '"').tosjis
    else
      ruby = File.join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
    end
    return ruby
  end

  def get_path
    path = self.get_path_reg
    if path.empty?
      path = get_path_local
    end
    return path
  end

  def get_path_reg
    path = ""
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase && @@reg
      begin
        reg = Win32::Registry::HKEY_LOCAL_MACHINE.open(REG_KEY)
      rescue Win32::Registry::Error
        reg = ""
        @@reg = false
      rescue
        reg = ""
        @@reg = false
      end
      if !reg.to_s.empty?
        if !reg["PATH"].to_s.empty? and File.exist?(reg["PATH"].to_s)
          path = reg["PATH"].to_s
        end
      else
        path = ""
      end
    end
    return path
  end

  def get_path_local
    File.expand_path(Dir::getwd)
  end

  def get_path_local2
    if __FILE__ == $0
      File.expand_path(File.dirname(__FILE__))
    else
      File.expand_path(Dir::getwd)
    end
  end

  def os_type_udisks(os_string=nil)
    if /linux/ =~ RUBY_PLATFORM.downcase
      if os_string.nil? 
        if File.exist?("/usr/bin/lsb_release")
          os_string = `lsb_release -d`.sub(/Description:\s+/, "").strip
        elsif File.exist?("/etc/debian_version")
          os_string = open("/etc/debian_version").read.gsub(/\n/, "")
        else
          os_string = ""
        end
      end
      version_list = {}

      version_list["ubuntu"] = [
        "lenny/sid",
        "squeeze/sid",
        "wheezy/sid",
        "Ubuntu 8.04.4 LTS",
        "Ubuntu 10.04.4 LTS",
        "Ubuntu 12.04 LTS",
      ]

      version_list["debian"] = [
        "3.0",
        "3.1",
        "4.0",
        "Debian GNU/Linux 3.0 (woddy)",
        "Debian GNU/Linux 3.1 (sarge)",
        "Debian GNU/Linux 4.0 (etch)",
      ]

      version_list["udisks"] = [
        "squeeze/sid",
        "wheezy/sid",
        "Ubuntu 10.04",
        "Ubuntu lucid",
        "Ubuntu 12.04",
        "Ubuntu precise",
      ]

      version_list["mount"] = [
        "3.0",
        "3.1",
        "4.0",
        "Debian GNU/Linux 3.0 (woddy)",
        "Debian GNU/Linux 3.1 (sarge)",
        "Debian GNU/Linux 4.0 (etch)",
        "lenny/sid",
        "Ubuntu 8.04",
      ]

      udisks = false
      version_list["udisks"].each do |ul|
        if /#{ul}/ =~ os_string.to_s
          udisks = true
          break
        end
      end
      udisks
    else
      false
    end
  end

  def get_device_fstab(mount_directory=nil, type="all")
    slink_mount_directory = nil
    if mount_directory.nil? 
      [DIRECTORY_FLOPPY, DIRECTORY_CDROM].each do |dev|
        if File.exist?(dev) && File::ftype(dev) == "directory"
          mount_directory = dev
        else
          mount_directory = ""
        end
      end
    else
      if !File.exist?(mount_directory)
        mount_directory = ""
      else
        ftype = File::ftype(mount_directory).to_s
        if ftype == "link"
          slink_mount_directory = mount_directory
          mount_directory = Pathname.new(mount_directory).realpath.to_s
        elsif ftype != "directory"
          mount_directory = ""
        end
      end
    end

    dev_list = self.search_device_fstab(mount_directory)

    if !slink_mount_directory.nil? && dev_list.empty?
      dev_list = self.search_device_fstab(slink_mount_directory)
    end

    case type
    when "all"
      dev_list
    when "dev"
      dev_list["dev"]
    when "dir"
      dev_list["dir"]
    end
  end

  def search_device_fstab(mount_directory)
    dev_list = {}
    open("/etc/fstab").read.split(/\n/).each do |fline|
      if /\s*#+/ !~ fline && fline.size != 0
        if /#{mount_directory}/ =~ fline
          device, directory = fline.gsub(/\s+/, " ").sub(/^\s+/, "").split(/\s/, 3)
          if directory == mount_directory
            dev_list["dev"] = device
            dev_list["dir"] = directory
          end
        end
      end
    end
    dev_list
  end

  def fdd_device_build_in?(dev)
    if /^\/dev\/fd\d+u\d+$/ =~ dev
      true
    else
      false
    end
  end

  def replace_non_line_path_char(org_string)
    return org_string.gsub(/#{@path_char*2}+/, "/")
  end

  def replace_on_line_path_char(org_string)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      return org_string.gsub(/\//, @path_char*2)
    else
      return org_string
    end
  end

  def signcode_bin
    @signcode_bin
  end

  def signcode_bat
    @signcode_bat
  end

  def signer
    SIGNER
  end

  attr_reader :path_char
  attr_reader :path_fstab
  attr_reader :path_group
  attr_reader :nkf_version
  attr_reader :panda_version
  attr_reader :db_version
  attr_reader :haijo_sum_tensu
  attr_reader :haijo_syukei_sort
  attr_reader :haijo_syukei_tougou
  attr_reader :menu_list
  attr_reader :menu_list_call
  attr_reader :menu_list_file
  attr_reader :menu_list_file_call
  attr_reader :menu_list_view
  attr_reader :menu_list_view_call
  attr_reader :menu_list_dev
  attr_reader :menu_list_dev_call
  attr_reader :menu_list_setting
  attr_reader :menu_list_setting_call
  attr_reader :menu_list_help
  attr_reader :menu_list_help_call
  attr_reader :window_tabs
  attr_reader :printspool_tabs
  attr_reader :printspool_column
  attr_reader :printspool_message
  attr_reader :printspool_message_fix
  attr_reader :message
  attr_reader :message_tab
  attr_reader :message_dbfile
  attr_reader :msg_etc
  attr_reader :msg_prog
  attr_reader :msg_update
  attr_reader :menu_tab
  attr_reader :menu_ir
  attr_reader :menu_re
  attr_reader :menu_rr
  attr_reader :menu_sick
  attr_reader :menu_rrsick
  attr_reader :menu_teki
  attr_reader :menu_rrteki
  attr_reader :menu_santei
  attr_reader :menu_rrsantei
  attr_reader :title
  attr_reader :file_title
  attr_reader :file_title_edit
  attr_reader :total_label
  attr_reader :total_label_rosai
  attr_reader :db_check_table
  attr_reader :kanja_object
  attr_reader :kanja_button
  attr_reader :kanja_out_object
  attr_reader :kanja_out_object_call
  attr_reader :find_keyword_radio_name
  attr_reader :find_keyword_radio_val
  attr_reader :find_keyword_colm
  attr_reader :find_option
  attr_reader :find_str
  attr_reader :find_str_rosai_money
  attr_reader :icon
  attr_reader :about
  attr_reader :dc
  attr_reader :print_method
  attr_reader :etc_directory_method
  attr_reader :etc_fileselect_method
  attr_reader :popup_name
  attr_reader :popup_sick_name
  attr_reader :popup_search_name
  attr_reader :popup_preview_name
  attr_reader :sick_ui
  attr_reader :find_ui
  attr_reader :update_ui
  attr_reader :print_spool_ui
  attr_reader :toolbox_ui
  attr_reader :layout_combo
  attr_reader :mount_combo
  attr_reader :code_view_ui
  attr_reader :name
  attr_reader :wau_no
  attr_reader :wau_name
  attr_reader :edit_mode
  attr_reader :headline_edit
  attr_reader :sex
  attr_reader :database
  attr_reader :home
  attr_reader :document_home
  attr_reader :preview_message
  attr_reader :file_message
  attr_reader :sickname_edit_message
  attr_reader :output_message
  attr_reader :find_message
  attr_reader :hoken_list
  attr_reader :dev_floppy
  attr_reader :dev_cdrom
  attr_accessor :version_check_url
  attr_accessor :version_md5_url
  attr_accessor :version_sha256_url
  attr_accessor :version_base_url
  attr_reader :secure_ca_file
end

class ReceView_FindINT
  FIND_KANJA_NAME = 0
  FIND_KANJA_NO = 1
  FIND_RECE_NO = 2
  FIND_SICKNAME = 3
  FIND_IY_ITEM = 4
  FIND_DIAGNOSIS = 5
  FIND_REWARD_POINT = 6
  FIND_REWARD_YM = 7
  FIND_CHECK_NO = 8
  FIND_NEO_CHECK_NO = 9
  FIND_NON_CHECK_NO = 10
  FIND_PE = 11
  FIND_KOUHI = 11
  FIND_DIAGNOSIS_TMDM = 12
  FIND_SPECIAL_NOTE = 13
  FIND_TOKKI = 13
end

class ReceView_Data
  # Santei days
  SANTEI_MINDAYS = 1
  SANTEI_MAXDAYS = 31

  # 9CODE
  SI_CODE_TABLE = 3
  IY_CODE_TABLE = 3
  TO_CODE_TABLE = 3

  # CSV start point + maxint
  SI_SANTEI_TABLE = [12, 44]
  IY_SANTEI_TABLE = [12, 44]
  TO_SANTEI_TABLE = [16, 48]

  # CSV point
  SI_COMMENT_TABLE = [[7,8], [9,10], [11,12]]
  IY_COMMENT_TABLE = [[7,8], [9,10], [11,12]]
  TO_COMMENT_TABLE = [[11,12], [13,14], [15,16]]
end

if not defined?(ReceViewBase)
class ReceViewBase < ReceView_Base
  def initialize
    super
  end
end
end

if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
  if RUBY_VERSION.to_s >= "2.0.0"
    require "fiddle/import"
  else
    require 'Win32API'
  end
  require "win32ole"
  require 'win32/registry'
end
