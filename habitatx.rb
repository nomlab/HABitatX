require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'roo'
require 'axlsx'
require 'erb'
require 'fileutils'
require 'active_record'
require 'sinatra/activerecord'
require 'pg'
require 'rake'
require 'sqlite3'

OPENHAB_PATH = '/etc/openhab'


set :database_file, 'config/database.yml'

ActiveRecord::Base.establish_connection(
  "adapter"  => "sqlite3",
  "database" => "db/habitatx.sqlite3",
  "username" => "habitatx"
)
class Template < ActiveRecord::Base
  belongs_to :datafiles
end

class Datafile < ActiveRecord::Base
  has_many :templates
end


def post_things(hash_json, template_code, template_basename)
  for code in hash_json['data']
    erb_template = ERB.new(template_code) # テンプレート文字列を使用する
    output = erb_template.result(binding) # erbファイルを書き換える
    File.open("#{__dir__}/db/created_thing.erb", 'w') { |file| file.write(output) } # 新しいファイルにoutputでの変更を書き換える
    File.open("#{__dir__}/db/created_thing.erb", "r") do |input_file|
      File.open("#{__dir__}/db/fixed_thing.erb", "w") do |output_file|
        input_file.each_line do |line|
          output_file.write(line) unless line.strip.empty? # 空行以外を書き込み
        end
      end
    end
    FileUtils.cp("#{__dir__}/db/fixed_thing.erb", "#{OPENHAB_PATH}/things/#{template_basename}_#{code['thingID']}.things")
  end
  File.delete("#{__dir__}/db/created_thing.erb")
  File.delete("#{__dir__}/db/fixed_thing.erb")
end

def delete_things(hash_json, template_basename)
  for code in hash_json['data']
    File.delete("#{OPENHAB_PATH}/things/#{template_basename}_#{code['thingID']}.things")
  end
end


def post_items(hash_json, template_code, template_basename)
  for code in hash_json['data']
    erb_template = ERB.new(template_code) # テンプレート文字列を使用する
    output = erb_template.result(binding) # erbファイルを書き換える
    File.open("#{OPENHAB_PATH}/items/#{template_basename}_#{code['itemID']}.items", 'w') { |file| file.write(output) } # 新しいファイルにoutputでの変更を書き換える
  end
end

def delete_items(hash_json, template_basename)
  for code in hash_json['data']
    File.delete("#{OPENHAB_PATH}/items/#{template_basename}_#{code['itemID']}.items")
  end
end


def json_to_excel(json_data, output_file)
  workbook = Axlsx::Package.new
  workbook.workbook.add_worksheet(name: 'Sheet1') do |sheet|
    add_json_data_to_sheet(sheet, json_data)
  end
  count = 0
  new_output_file = output_file
  while File.exist?(new_output_file)
    count += 1
    new_output_file = output_file.gsub(/\.xlsx$/, "_#{count}.xlsx")
  end
  workbook.serialize(new_output_file)
  new_output_file
end


def add_json_data_to_sheet(sheet, json_data)
  data_array = json_data["data"]
  headers = data_array.first.keys
  sheet.add_row(headers)
  data_array.each do |data|
    row_data = headers.map { |header| data[header] }
    sheet.add_row(row_data)
  end
end


get '/' do
  erb :index
end

get '/doc/habitatx.pdf' do
  send_file File.join(settings.root, 'doc', 'habitatx.pdf'), type: 'application/pdf'
end



# get '/template' do
get '/template' do
  @template = Template.all
  erb :'template/index'
end

get '/template/new' do
  template_things = File.join(settings.views, '_form_things.erb')
  template_items = File.join(settings.views, '_form_items.erb')
  @template_things_content = File.read(template_things)
  @template_items_content = File.read(template_items)
  puts @template_things_content
  puts @template_items_content
  erb :'template/new'
end

# get '/template/:id' do
post '/template' do
  title_template = params[:title_template]
  content = params[:content]
  basename = params[:basename]
  file_type = params[:file_type]
  Template.create(title_template: title_template, content: content, basename: basename, file_type: file_type)

  redirect '/template'
end


get '/template/:id' do
  template = Template.find_by(id: params[:id])
  @title_template = template["title_template"]
  @content = template["content"]
  @basename = template["basename"]
  @file_type = template["file_type"]
  erb :'template/show'
end

get '/template/:id/edit' do
  template = Template.find_by(id: params[:id])
  @title_template = template["title_template"]
  @content = template["content"]
  @basename = template["basename"]
  @file_type = template["file_type"]
  erb :'/template/edit'
end

patch '/template/:id' do
  title_template = params[:title_template]
  content = params[:content]
  basename = params[:basename]
  file_type = params[:file_type]
  template = Template.find_by(id: params[:id])
  return unless template
  template.update(title_template: title_template, content: content, basename: basename, file_type: file_type)

  redirect "/template/#{params[:id]}"
end


delete '/template/:id' do
  template = Template.find_by(id: params[:id])
  return unless template

  template.destroy
  redirect '/template'
end



# get '/datafile' do
get '/datafile' do
  @datafile = Datafile.all
  erb :'datafile/index'
end

get '/datafile/new' do
  @template = Template.all
  erb :'datafile/new'
end

# get '/datafile/:id' do
post '/datafile' do
  @template = Template.all
  title_datafile = params[:title_datafile]
  table = params[:table]
  title_template = params[:title_template]
  
  doc = Roo::Excelx.new("#{__dir__}/db/excel/#{table}")
  doc.default_sheet = doc.sheets.first

  headers = {}
  (doc.first_column..doc.last_column).each do |col|
    headers[col] = doc.cell(doc.first_row, col)
  end

  hash = {}
  hash[:data] = []
  ((doc.first_row + 1)..doc.last_row).each do |row|
    row_data = {}
    headers.keys.each do |col|
      value = doc.cell(row, col)
      value = value.to_i if doc.celltype(row, col) == :float && value.modulo(1) == 0.0
      row_data[headers[col]] = value
    end
    hash[:data] << row_data
  end

  selected_template = Template.find_by(title_template: title_template)
  template_id = selected_template["id"]
  template_code = selected_template["content"]
  template_basename = selected_template["basename"]

  
  Datafile.create(title_datafile: title_datafile, table: hash, template_id: template_id)
  hash_to_json = hash.to_json
  hash_json = JSON.parse(hash_to_json)
  puts "kkkkkkkkk:#{hash_json.inspect}"
  if selected_template["file_type"] == "things"
    post_things(hash_json, template_code, template_basename)
  else
    post_items(hash_json, template_code, template_basename)
  end
  redirect '/datafile'
end

get '/datafile/:id/download' do
  datafile = Datafile.find_by(id: params[:id])
  table = datafile["table"]
  table_to_json = table.to_json
  json_data = JSON.parse(table_to_json)
  output_file = "#{__dir__}/db/excel/download.xlsx"
  json_to_excel(json_data, output_file)
  redirect "/datafile/#{params[:id]}"
end

get '/datafile/:id' do
  datafile = Datafile.find_by(id: params[:id])
  @title_datafile = datafile["title_datafile"]
  @table = datafile["table"]
  template_id = datafile["template_id"]
  template_table_id = Template.find_by(id: template_id)
  @id_template=template_table_id["id"]
  @title_template = template_table_id["title_template"]
  @content = template_table_id["content"]
  @basename = template_table_id["basename"]
  @file_type = template_table_id["file_type"]
  erb :'datafile/show'
end

get '/datafile/:id/edit' do
  @template = Template.all
  datafile = Datafile.find_by(id: params[:id])
  @title_datafile = datafile["title_datafile"]
  @table = datafile["table"]
  template_id = datafile["template_id"]

  template_table = Template.find_by(id: template_id)
  @id_template = template_table["id"] if template_table

  @title_template = template_table["title_template"]
  @content = template_table["content"]
  @basename = template_table["basename"]
  @file_type = template_table["file_type"]
  erb :'/datafile/edit'
end


patch '/datafile/:id' do
  @template = Template.all
  datafile = Datafile.find_by(id: params[:id])
  title_datafile = params[:title_datafile]

  table = params[:table]

  table_json = table.gsub('=>', ':')

  table_data = JSON.parse(table_json)

  title_template = params[:title_template]

  content = params[:content]
  basename = params[:basename]
  file_type = params[:file_type]
  
  selected_template = Template.find_by(title_template: title_template)
  template_id = selected_template["id"]
  template_code = selected_template["content"]
  template_basename = selected_template["basename"]

  return unless datafile
  datafile.update(title_datafile: title_datafile, table: table_data, template_id: template_id)

  hash_json = table_data
  puts "dedededede:#{hash_json.class}"
  puts hash_json.class
  if selected_template["file_type"] == "things"
    post_things(hash_json, template_code, template_basename)
  else
    post_items(hash_json, template_code, template_basename)
  end
  redirect "/datafile/#{params[:id]}"
end


delete '/datafile/:id' do
  @template = Template.all
  datafile = Datafile.find_by(id: params[:id])
  template_id = datafile["template_id"]
  selected_template = Template.find_by(id: template_id)
  template_basename = selected_template["basename"]
  return unless datafile

  datafile.destroy

  hash_json = datafile["table"]
  if selected_template["file_type"] == "things"
    delete_things(hash_json, template_basename)
  else
    delete_items(hash_json, template_basename)
  end
  redirect '/datafile'
end
