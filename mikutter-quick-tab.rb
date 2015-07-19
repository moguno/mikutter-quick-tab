# coding: utf-8

Plugin.create(:"mikutter-quick-tab") {
  # 単一データソース、フィルタ無しの抽出タブを作る
  def show_extract_definition!(name, datasource_slug)
    # 抽出タブ定義をでっちあげる
    id = Time.now.to_i
     
    miku = {
      :name => name,
      :sexp => nil,
      :id => id,
      :slug => :"extract_#{id}",
      :sources => [datasource_slug],
      :sound => nil,
      :popup => nil,
      :icon => nil,
    }

    # 設定に登録
    extract_tabs = UserConfig[:extract_tabs]
    UserConfig[:extract_tabs] = extract_tabs + [miku]

    # 抽出タブを表示する
    Plugin.call(:extract_tab_create, miku)
  end
   
  # ハッシュからGTKのメニューを構築する
  def build_menu(menu_map)
    result = Gtk::Menu.new

    menu_map.each { |key, value|
      item = Gtk::MenuItem.new(key)

      # サブメニュー
      if value.is_a?(Hash)
        item.set_submenu(build_menu(value))

      # メニュー項目
      else
        item.ssc(:activate) { |w|
          show_extract_definition!(key, value)
        }
      end

      result.append(item)
    }

    result
  end


  # コマンド
  command(:quick_add_tab,
         name: _('タブを追加'),
         condition: lambda{ |opt| true },
         visible: true,
         role: :tab) do |opt|

    map = {}

    # mkdir -p なノリで配列に入ったパスにそってツリー状の構造を作る
    def map.add_p(path, value)
      current = self

      path[0..-2].each { |item|
        if !current[item]
          current[item] = {}
        end

        current = current[item]
      }

      current[path[-1]] = value

      current
    end

    # データソースを取得
    datasources = Plugin.filtering(:extract_datasources, {})

    # データソースの階層構造をツリー状のハッシュに展開する
    datasources.first.each { |slug, name|
      path = if name.is_a?(Array)
        name
      else
        # maybe string
        name.split(/\//)
      end 

      map.add_p(path, slug)
    }   

    # GTKメニューを構築する
    menu = build_menu(map)

    # 使い終わったら自動的に解放される
    menu.ssc(:selection_done) {
      menu.destroy
      false
    }

    menu.ssc(:cancel) {
      menu.destroy
      false
    }

    # メニューを表示
    menu.show_all.popup(nil, nil, 0, 0)
  end
}
