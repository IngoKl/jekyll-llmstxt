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

        # List posts
        file.content += "## Posts\n\n"
        site.posts.docs.each do |post|
          post_url = site.baseurl ? File.join(site.baseurl, post.url) : post.url
          file.content += "- [#{post.data["title"]}](#{post_url}index.md)\n"
        end

        # List pages
        file.content += "\n## Pages\n\n"
        site.pages.each do |page|
          # Skip the llms.txt itself
          next if page.name == 'llms.txt'

          # Use page title if set, otherwise fall back to the URL
          title = page.data['title'] || page.url.sub(/^\//, '').sub(/\/$/, '').capitalize
          page_url = site.baseurl ? File.join(site.baseurl, page.url) : page.url

          # Link to the page’s index.md (if you’re copying pages to index.md via your hook)
          file.content += "- [#{title}](#{page_url}index.md)\n"
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
  next if page.name == 'llms.txt'

  target_dir  = File.join(page.site.dest, page.url)
  target_path = File.join(target_dir, "index.md")
  FileUtils.mkdir_p(target_dir)
  FileUtils.cp(page.path, target_path)
end
