require 'sinatra/base'
require 'slim'
require 'yaml'

CREDENTIAL_FILE   = './credentials.yml'
AUTHORIZED_USERS  = YAML.load(File.open(CREDENTIAL_FILE))

class FileUpload < Sinatra::Base
  use Rack::Auth::Basic do |username, password|
    AUTHORIZED_USERS.include?([username, password])
  end

  configure do
    enable :static

    set :views, File.join(File.dirname(__FILE__), 'views')
    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :files, File.join(settings.public_folder, 'files')
    set :unallowed_paths, ['.', '..']
  end

  helpers do
    def flash(message = '')
      session[:flash] = message
    end
  end

  before do
    @flash = session.delete(:flash)
  end

  not_found do
    slim 'h1 404'
  end

  error do
    slim "Error (#{request.env['sinatra.error']})"
  end

  get '/' do
    @files = Dir.entries(settings.files) - settings.unallowed_paths

    slim :index
  end
  
  post '/upload' do
    if params[:file]
      filename = params[:file][:filename]
      file = params[:file][:tempfile]

      File.open(File.join(settings.files, filename), 'wb') do |f|
        f.write file.read
      end

      flash 'Upload successful'
    else
      flash 'You have to choose a file'
    end

    redirect '/'
  end
end