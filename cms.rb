require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  erb markdown.render(text), layout: :layout
end

def create_document(name)
  File.open(File.join(data_path, name), "w")
end

def error_for_filename(filename)
  if filename.strip.empty?
    "A name is required."
  elsif File.extname(filename).empty?
    "A file extension is required."
  end
end

# Load the home page
get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

# New document page
get "/new" do
  erb :new
end

# Create a new document
post "/create" do
  error = error_for_filename(params[:filename])
  if error
    session[:message] = error
    status 422
    erb :new
  else
    create_document(params[:filename])
    session[:message] = "#{params[:filename]} has been created"
    redirect "/"
  end
end

# View a single file
get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Edit a single file
get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  
  @content = File.read(file_path)
  erb :edit, layout: :layout
end

# Update a single file
post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

