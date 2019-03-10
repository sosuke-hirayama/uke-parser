# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

if __FILE__ == $0
  require 'jma/receview/gtk2_fix'
  require 'jma/receview/gui'
end

class ReceViewGUI::Menu
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    @ui = ReceViewGUI::MenuUI::BODY
    @uimanager = Gtk::UIManager.new
    @callback = nil
    @user_event = ReceViewGUI::MenuUI::EVENT
  end

  def ui
    @ui
  end

  def uimanager
    @uimanager
  end

  def user_event
    @user_event
  end

  def get_callback
    @callback
  end

  def set_callback(callback)
    @callback = callback
  end
  
  def create(event, history_list)
    set_callback(event)
    menu_action_history(history_list)
    uimanager.add_ui(ui)
    menu_platform
    menu_file_history(history_list)
    yield
  end

  def menu_action_history_callback(action, history_list="")
    hfname = history_list.split(/#{"\\"+@base.path_char}/).last
    action.push(["History.File.A", nil, hfname, nil, "History.File.A", get_callback])
    return action
  end

  def menu_action_history(history_list)
    action = menu_action_history_callback(action_list, history_list)
    actiongroup = Gtk::ActionGroup.new("Actions")
    actiongroup.add_actions(action)
    actiongroup.add_toggle_actions(toggle_action_list)
    @uimanager.insert_action_group(actiongroup, 0)
  end

  def menu_file_history(history_list)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      hfname = history_list.split(/#{"\\"+@base.path_char}/).last.to_s.tosjis
    else
      hfname = history_list.split(/#{"\\"+@base.path_char}/).last.to_s
    end

    path = "/MenuBar/FileMenu/History"
    item = Gtk::UIManager::ItemType::MENUITEM
    action = "History.File.A"

    @uimanager.add_ui(@uimanager.new_merge_id, path, hfname, action, item, nil)
    @uimanager.ensure_update
  end

  # etc PLATFORMS 
  def menu_platform(uimanager=@uimanager)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      uimanager.get_widget("/MenuBar/SettingMenu/FddSetting").set_sensitive(false)
      uimanager.get_widget("/MenuBar/DeviceMenu/Mount").set_sensitive(false)
      uimanager.get_widget("/MenuBar/DeviceMenu/UnMount").set_sensitive(false)
    end

    uimanager.get_widget("/MenuBar/EditMenu/HeadEdit").set_sensitive(false)
    uimanager.get_widget("/MenuBar/EditMenu/SickEdit").set_sensitive(false)
  end

  def action_list
    [
      ["FileMenu", nil, "ファイル(_F)", "<alt>F", "FileMenu", @callback],
      ["EditMenu", nil, "編集(_E)", "<alt>E", "EditMenu", @callback],
      ["ViewMenu", nil, "表示(_V)", "<alt>V", "ViewMenu", @callback],
      ["DeviceMenu", nil, "デバイス(_D)", "<alt>D", "DeviceMenu", @callback],
      ["SettingMenu", nil, "設定(_S)", "<alt>S", "SettingMenu", @callback],
      ["HelpMenu", nil, "ヘルプ", "", "HelpMenu", @callback],

      ["Open", Gtk::Stock::OPEN, "_開く", "<control>O", "Open", @callback],
      ["Clear", Gtk::Stock::CLEAR, "_クリア", "<control><alt>C", "Clear", @callback],
      ["History", nil, "_履歴", nil, "History", @callback],
      ["History.File", nil, "_履歴", nil, "History.File", @callback],
      ["Mode", Gtk::Stock::EDIT, "_編集モード", "<control>E", "Mode", @callback],
      ["Save.UKE", Gtk::Stock::CONVERT, "_レセ電出力", "", "Save.UKE", @callback],
      ["Save.PDFs", Gtk::Stock::DND_MULTIPLE, "_全患者PDF出力", "", "Save.PDFs", @callback],
      ["Save.PDFs+Search", Gtk::Stock::DND_MULTIPLE, "_検索患者PDF出力", "", "Save.PDFs+Search", @callback],
      ["Quit", Gtk::Stock::QUIT, "_終了", "<control>Q", "Quit", @callback],

      ["HeadEdit", Gtk::Stock::DND, "_頭書きの編集", "", "HeadEdit", @callback],
      ["SickEdit", Gtk::Stock::DND_MULTIPLE, "_病名の編集", "", "SickEdit", @callback],

      ["Find", Gtk::Stock::FIND, "_検索", "<control>F", "Find", @callback],
      ["RecalCheck", Gtk::Stock::INDEX, "_点数チェック", "<control>T", "RecalCheck", @callback],
      ["SortName", Gtk::Stock::SORT_ASCENDING, "_並び替え[名前]", "<control>1", "SortName", @callback],
      ["SortRece", Gtk::Stock::SORT_DESCENDING, "_並び替え[レセ番号]", "<control>2", "SortRece", @callback],
      ["SortCheck", Gtk::Stock::SORT_DESCENDING, "_並び替え[チェック状態]", "<control>3", "SortCheck", @callback],
      ["CopyClip", Gtk::Stock::COPY, "_クリップボードへコピー", "<control>W", "CopyClip", @callback],
      ["CheckPath", Gtk::Stock::OK, "_チェックファイル", "<control>R", "CheckPath", @callback],
      ["PrintSpool", Gtk::Stock::PRINT, "_印刷スプール", "<control>N", "PrintSpool", @callback],
      ["ToolBox", Gtk::Stock::OK, "_ツールボックス", "<control>B", "ToolBox", @callback],

      ["Mount", Gtk::Stock::YES, "_Mount", "<control>M", "Mount", @callback],
      ["UnMount", Gtk::Stock::NO, "_Unmount", "<control>U", "UnMount", @callback],

      ["ViewSetting", Gtk::Stock::HOME, "_表示設定", "<control>L", "ViewSetting", @callback],
      ["DataBaseSetting", Gtk::Stock::PROPERTIES, "_接続設定", "<control>D", "DataBaseSetting", @callback],
      ["FddSetting", Gtk::Stock::FLOPPY, "_Floppy設定", "<control>I", "FddSetting", @callback],
      ["FontSetting", Gtk::Stock::ITALIC, "_フォント設定", "<control>H", "FontSetting", @callback],
      ["PrintSetting", Gtk::Stock::PRINT, "_印刷設定", "<control>P", "PrintSetting", @callback],
      ["EtcSetting", Gtk::Stock::ADD, "_その他の設定", "", "EtcSetting", @callback],

      ["About", Gtk::Stock::ABOUT, "_About", "<control>A", "About", @callback],
      ["Update", Gtk::Stock::REFRESH, "_アップデートのチェック", "", "Update", @callback],
    ]
  end

  def toggle_action_list
    [
      ["UserList", Gtk::Stock::OK, "_患者一覧の表示", "<control>V", "UserList", @callback, true],
    ]
  end
end

class ReceViewGUI::MenuUI
  BODY = %Q[
  <ui>
    <menubar name='MenuBar'>
      <menu action='FileMenu'>
        <menuitem action='Open'/>
        <menuitem action='Clear'/>
        <menu action='History'>
        </menu>
        <separator/>
        <menuitem action='Mode'/>
        <menuitem action='Save.UKE'/>
        <separator/>
        <menuitem action='Save.PDFs'/>
        <menuitem action='Save.PDFs+Search'/>
        <separator/>
        <menuitem action='Quit'/>
      </menu>
      <menu action='EditMenu'>
        <menuitem action='HeadEdit'/>
        <menuitem action='SickEdit'/>
      </menu>
      <menu action='ViewMenu'>
        <menuitem action='Find'/>
        <menuitem action='RecalCheck'/>
        <separator/>
        <menuitem action='SortName'/>
        <menuitem action='SortRece'/>
        <menuitem action='SortCheck'/>
        <separator/>
        <menuitem action='CopyClip'/>
        <separator/>
        <menuitem action='CheckPath'/>
        <menuitem action='PrintSpool'/>
        <menuitem action='ToolBox'/>
        <separator/>
        <menuitem action='UserList'/>
      </menu>
      <menu action='DeviceMenu'>
        <menuitem action='Mount'/>
        <menuitem action='UnMount'/>
      </menu>
      <menu action='SettingMenu'>
        <menuitem action='ViewSetting'/>
        <menuitem action='DataBaseSetting'/>
        <menuitem action='FddSetting'/>
        <menuitem action='FontSetting'/>
        <menuitem action='PrintSetting'/>
        <menuitem action='EtcSetting'/>
      </menu>
      <menu action='HelpMenu'>
        <menuitem action='About'/>
        <menuitem action='Update'/>
      </menu>
    </menubar>
  </ui>]

  HISTORY = %Q[
  <ui>
    <menubar name='MenuBar'>
      <menu action='FileMenu'>
        <menu action='History'>
          <menuitem action='History'/>
        </menu>
      </menu>
    </menubar>
  </ui>]

  EVENT = ["FileMenu", "EditMenu", "ViewMenu", "DeviceMenu", "SettingMenu", "HelpMenu", "History"]
end

if __FILE__ == $0
  window = Gtk::Window.new

  menu = ReceViewGUI::Menu.new
  actiongroup = Gtk::ActionGroup.new("Actions")
  actiongroup.add_actions(menu.action_list)
  actiongroup.add_toggle_actions(menu.toggle_action_list)

  uimanager = Gtk::UIManager.new
  uimanager.insert_action_group(actiongroup, 0)
  window.add_accel_group(uimanager.accel_group)

  uimanager.add_ui(menu.ui)

  vbox = Gtk::VBox.new
  vbox.pack_start(uimanager.get_widget("/MenuBar"), false, false)
  window.add(vbox)
  window.set_default_size(100, 100).show_all
  Gtk.main_with_queue(100)
end
