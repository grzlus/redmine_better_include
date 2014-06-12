require 'pry'

Redmine::Plugin.register :redmine_better_include do
  name 'Better Include'
  author 'Grzegorz Łuszczek'
  description 'This plugin overrides default include in Wiki'
  version '1.0.0'

  module WikiMacros
    Redmine::WikiFormatting::Macros.register do
      desc "Ovverrides default include macro"
      macro :include do |obj, args|
        page_name, chapter = args.first.to_s.split("#")
        page = Wiki.find_page(page_name, :project => @project)
        raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
        @included_wiki_pages ||= []
        raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
        @included_wiki_pages << page.title
        content = page.content
        if chapter.present?
          chapter = chapter.gsub("-", ' ')
          lines = content.text.lines
          from = lines.drop_while { |line| not line =~ /^h\d\. #{ chapter }/ }
          raise "Chapter not found" if from.empty?
          first = from.first
          to = from.take_while { |line| line == first || !(line =~ /^h\d\./) || line[1] > first[1] }
          content.text = to.join("\n")
        end
        out = textilizable(content, :text, :attachments => page.attachments, :headings => false)
        @included_wiki_pages.pop
        out
      end
    end
  end
end
