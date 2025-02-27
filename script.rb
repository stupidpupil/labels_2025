require 'yaml'
require 'sinatra'
require 'nokogiri'
require 'rqrcode'

set :public_folder, __dir__

get '/page.svg' do
  page = Nokogiri::XML(File.open("page-template.svg"))

  offset = params['offset'].to_i || 0

	labels = page.css("g.label")

	label_definitions = YAML.load_file("defs.yaml")

	label_definitions = label_definitions[offset..offset+9]

	label_definitions.each_with_index do |ld, li|
		if ld["svg"] then
			label = Nokogiri::XML(File.open(ld["svg"]))
			label.remove_namespaces!
		  labels[li].inner_html = label.at_css("g.label").inner_html
		  page.at_css("defs").inner_html = 
		  	page.at_css("defs").inner_html + (label.at_css("defs")&.inner_html).to_s

		  # HACK
		  labels[li].inner_html = labels[li].inner_html.gsub("<div", "<div xmlns=\"http://www.w3.org/1999/xhtml\"")
			next
		end


		label = Nokogiri::XML(File.open("label-template.svg"))
	  
	  title = label.at_css(".label-title")
	  title.content = ld["title"] || ""

	  subtitle = label.at_css(".label-subtitle")
	  subtitle.content = ld["subtitle"] || ""

	  subsubtitle = label.at_css(".label-subsubtitle")
	  subsubtitle.content = ld["subsubtitle"] || ""

	  timestamp = label.at_css(".timestamp")
	  timestamp.content = Time.now.strftime("%Y-%b-%d T %H:%M")

	  label_hue = ld['hue'] || (title.content + subtitle.content).hash % 360
	  borders = label.css(".label-border")
	  borders.each {|b| b['style'] = "fill:oklch(85% 20% #{label_hue})"}

	  if ld['qr'] then
	  	qr = RQRCode::QRCode.new(ld['qr'], {level: 'm'})

	  	qr_version = qr.qrcode.send :minimum_version
	  	qr_width = (4*qr_version+17)
	  	scale_factor = 143.5/qr_width #HACK

	  	puts qr_width
	  	qr_svg = qr.as_svg(
	  		color: "oklch(45% 15% #{label_hue})",
	  		standalone: false,
	  		use_path: true,
	  		module_size: 1
	  	).gsub("#oklch", "oklch") #HACK

	  	unless ld['qr_small']
		  	label.at_css("g.label").add_child("<g transform='translate(209, 19) scale(#{scale_factor} #{scale_factor})'>#{qr_svg}</g>")
		  else
		  	label.at_css("g.label").add_child("<g transform='translate(280, 100) scale(#{scale_factor/2} #{scale_factor/2})'>#{qr_svg}</g>")
		  end
	  end

	  icons = label.css("image.icon")

	  icon_defs = ld["icons"] || []

	  icon_defs.each_with_index do |ic, ii|
	  	icons[ii]["href"] = "icons/#{ic}.svg"
	  end

	  while icons.length > icon_defs.length
	  	icons.last.remove
	  	icons.pop
	  end

	  labels[li].inner_html = label.at_css("g.label").inner_html
	end

  content_type :svg
  page.to_xml
end