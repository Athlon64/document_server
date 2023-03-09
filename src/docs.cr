require "kemal"
require "yaml"

# private def get_local_ip
#   `hostname -i`
# end

# server = "http://#{get_local_ip()}"

# public_folder "public"
config = YAML.parse(File.read("env.yml"))
port = config["port"].as_i
nim_docs_folder = config["nim_docs_folder"].as_s
nim_lib_folder = config["nim_lib_folder"].as_s
nim_link = config["nim_link"]
crystal_docs_folder = config["crystal_docs_folder"].as_s
crystal_lib_folder = config["crystal_lib_folder"].as_s
crystal_link = config["crystal_link"]
open_with = config["open_with"].as_s
open_in_editor = config["open_in_editor"].as_bool
open_in_browser = config["open_in_browser"].as_bool

def gen_doc(file_name, line)
  line = line.to_i
  code_html = `bat -n --color=always -r :#{line - 1} '#{file_name}' | aha -n`
  code_html += "<a id=#{line}></a>"
  code_html += `bat -n --color=always -r #{line}: -H #{line} '#{file_name}' | aha -n`
  <<-HTML
    <html>
      <head>
        <title>#{file_name}</title>
      <head/>
        <body style="background-color:black;color:lightblue;">
          <pre style="font-size:30px">#{code_html}</pre>
          <script>
            location.hash = "##{line}";
          </script>
        </body>
    </html>
  HTML
end

get "/" do |env|
  env.redirect "/index.html"
end

# https://github.com/nim-lang/Nim/tree/version-1-6/lib/pure/collections/sequtils.nim#L290
get "/nim_doc/*file" do |env|
  file_name = env.params.url["file"]
  full_name = nim_docs_folder + file_name
  send_file env, full_name unless file_name[-4..] == "html"
  content = File.read full_name
  content = content.gsub(nim_link[0].as_s, nim_link[1].as_s)
  content.gsub("#L", "?line=")
end

get "/nim_doc/view_source/*file" do |env|
  file_name = env.params.url["file"]
  line = env.params.query["line"]
  file = "#{nim_lib_folder}#{file_name}"
  if open_in_editor
    `#{open_with} +#{line} '#{nim_lib_folder}#{file_name}'`
  end

  if open_in_browser
    gen_doc(file, line)
  end
end

# https://github.com/crystal-lang/crystal/blob/994c70b10/src/array.cr#L1632
get "/crystal_doc/*file" do |env|
  file_name = env.params.url["file"]
  full_name = crystal_docs_folder + file_name
  send_file env, full_name unless file_name[-4..] == "html"
  content = File.read full_name
  content = content.gsub(crystal_link[0].as_s, crystal_link[1].as_s)
  content.gsub("#L", "?line=")
end

get "/crystal_doc/view_source/*file" do |env|
  file_name = env.params.url["file"]
  line = env.params.query["line"]
  file = "#{crystal_lib_folder}#{file_name}"
  if open_in_editor
    `#{open_with} +#{line} '#{crystal_lib_folder}#{file_name}'`
  end

  if open_in_browser
    gen_doc(file, line)
  end
end

# `xdg-open #{server}:#{port}`
Kemal.run port
