require 'yaml'
require 'sinatra'
require 'nokogiri'

set :public_folder, __dir__

get '/page.svg' do
  page = Nokogiri::XML(File.open("page-template.svg"))

  offset = params['offset'].to_i || 0

	labels = page.css("g.label")

	label_definitions = YAML.load_file("defs.yaml")

	label_definitions = label_definitions[offset, offset+10]

	label_definitions.each_with_index do |ld, li|
		label = Nokogiri::XML(File.open("label-template.svg"))
	  title = label.at_css(".label-title")
	  title.content = ld["title"]

	  subtitle = label.at_css(".label-subtitle")
	  subtitle.content = ld["subtitle"]

	  timestamp = label.at_css(".timestamp")
	  timestamp.content = Time.now.strftime("%Y-%b-%d T %H:%M")

	  border_colour = (title.content + subtitle.content).hash % 360
	  borders = label.css(".label-border")
	  borders.each {|b| b['style'] = "fill:oklch(85% 20% #{border_colour})"}

	  icons = label.css("image.icon")

	  ld["icons"].each_with_index do |ic, ii|
	  	icons[ii]["href"] = "icons/#{ic}.svg"
	  end

	  while icons.length > ld["icons"].length
	  	icons.last.remove
	  	icons.pop
	  end

	  labels[li].inner_html = label.at_css("g.label").inner_html
	end

  content_type :svg
  page.to_xml
end