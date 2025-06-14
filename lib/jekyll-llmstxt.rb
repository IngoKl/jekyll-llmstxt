require 'jekyll'

module Jekyll
  class LLMSGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Create llms.txt file at site root
      site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "", "llms.txt").tap do |file|
        file.content = site.config["title"] ? "# #{site.config["title"]}\n\n" : ""
        file.content += site.config["description"] ? "#{site.config["description"]}\n\n" : ""

        # List pages
        if site.config["llmspages"].is_a?(Array) && !site.config["llmspages"].empty?
          file.content += "## Pages\n\n"
          site.config["llmspages"].each do |p|
            title = p["title"] || p["url"]
            url   = p["url"].to_s
            # ensure trailing slash
            url += "/" unless url.end_with?("/")
            link = site.baseurl ? File.join(site.baseurl, url, "index.md") : File.join(url, "index.md")
            file.content += "- [#{title}](#{site.config["url"]}#{link})\n"
          end
          file.content += "\n\n"
        end


        # List posts
        file.content += "## Posts\n\n"
        site.posts.docs.each do |post|
          post_url = site.baseurl ? File.join(site.baseurl, post.url) : post.url
          file.content += "- [Title: #{post.data["title"]} Description: #{post.data["description"]}](#{site.config["url"]}#{post_url}index.md)\n"
        end

        file.data["layout"] = nil
      end

    end
  end

  class MarkdownPage < Page
    def initialize(site, base, dir, name, content)
      @site = site
      @base = base
      @dir  = dir
      @name = name

      self.process(name)
      self.content = content
      self.data = {
        "layout" => nil, # Set layout if needed, or leave nil
        "title" => "Generated Markdown File",
      }
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  site.posts.docs.each do |post|
    target_dir = File.join(site.dest, post.url)
    target_path = File.join(target_dir, "index.md")
    FileUtils.cp(post.path, target_path)
  end
end

Jekyll::Hooks.register :pages, :post_write do |page|
  config_pages = Array(page.site.config['llmspages'])

  # see if this page's URL matches one of the entries
  config_pages.each do |entry|
    desired = entry['url'].to_s
    desired << "/" unless desired.end_with?("/")

    next unless page.url == desired

    src = File.join(page.site.source, page.path)
    next unless File.file?(src)

    dest_dir = File.join(page.site.dest, desired)
    FileUtils.mkdir_p(dest_dir)

    FileUtils.cp(src, File.join(dest_dir, "index.md"))
  end
end
