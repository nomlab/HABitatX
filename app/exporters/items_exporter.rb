class ItemsExporter
  def post_items(row_data, temp_code, basename)
    data = row_data
    # テンプレートを評価して文字列を生成
    erb_template = ERB.new(temp_code)
    result = erb_template.result_with_hash(data: data)
    file_path = "#{ENV['OPENHAB_PATH']}/items/#{basename}_#{data['itemID']}.items"
    # ファイルに書き込む
    File.open(file_path, 'w') do |file|
      file.puts result
    end
  end

  def edit_items(row_data, temp_code, basename)
    data = JSON.parse(row_data)
    # テンプレートを評価して文字列を生成
    erb_template = ERB.new(temp_code)
    result = erb_template.result_with_hash(data: data)
    file_path = "#{ENV['OPENHAB_PATH']}/items/#{basename}_#{data['itemID']}.items"
    # ファイルに書き込む
    File.open(file_path, 'w') do |file|
      file.puts result
    end
  end

  def delete_items(row_data, basename)
    data = JSON.parse(row_data)
    file_path = "#{ENV['OPENHAB_PATH']}/items/#{basename}_#{data['itemID']}.items"
    File.delete(file_path)
  end
end