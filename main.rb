# coding: utf-8
require 'elephrame'
require 'rmagick'
require 'net/http'

SaveDir = '/tmp/'
Messages = [ '😎', '🔭', '🔬', '👁️', '👀',
           '🕵️‍♂️', '🕵🏼‍♀️', '🕵️​', ]

def save_attachment filename, url
  File.write(filename, Net::HTTP.get(url))
end

def enhance_image path
  img = Magick::Image.read(path).first

  img.scale!(0.47)
  
  x, y = img.columns, img.rows
  offx, offy = rand(x), rand(y)
  
  img.crop(offx, offy, (x - offx) * 0.7, (y - offy) * 0.7)
    .scale(rand(15) + 10)
    .write(path)
end

enhance_bot = Elephrame::Bots::Reply.new

enhance_bot.run do |bot, mention|
  unless mention.media_attachments.size.zero?

    modified_images = []
    
    mention.media_attachments.each_with_index do |media, i|
      next unless media.type == 'image'
      media_uri = URI.parse(media.remote_url)
      
      modified_images.append(SaveDir + media_uri.path.split('/').last)
      save_attachment modified_images[i], media_uri
      enhance_image modified_images[i]
    end

    # to fix work around an issue with elephrame 0.3.4<~
    files = modified_images.collect {|f| f }
    bot.post("@#{mention.account.acct} #{Messages.sample}",
             reply_id: mention.id,
             visibility: mention.visibility,
             hide_media: true,
             spoiler: mention.spoiler_text,
             media: modified_images)

    File.delete(*files)
    
  end
end
