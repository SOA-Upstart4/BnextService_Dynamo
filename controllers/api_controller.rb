$KCODE = 'u' if RUBY_VERSION < '1.9'

require_relative 'bnext_helper'
require_relative 'trend_helper'

##
# Simple web service to crawl Bnext webpages
# - requires config:
#   - create ENV vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION
class BnextDynamo < Sinatra::Base
  helpers BNextHelpers, TrendHelpers

  helpers do
    def current_page?(path = ' ')
      path_info = request.path_info
      path_info += ' ' if path_info == '/'
      request_path = path_info.split '/'
      request_path[1] == path
    end
  end

  ######################################################################################
  #                                                                                    #
  #                                   WEB APIs                                         #
  #                                                                                    #
  ######################################################################################

  ROOT_MSG = 'This is version 0.0.1. See documentation at its ' \
      '<a href="https://github.com/SOA-Upstart4/bnext_service">' \
      'Github repo</a>'

  ###   GET /api/v1/
  get_root = lambda do
    ROOT_MSG
  end

  ###   GET /api/v1/:ranktype/
  get_feed_ranktype = lambda do
    content_type :json, 'charset' => 'utf-8'
    cat = 'tech'
    page_no = 1

    cat = params['cat'] if params.has_key? 'cat'
    page_no = params['page'] if params.has_key? 'page'
    get_ranks(params[:ranktype], cat, page_no).to_json
  end

  ### POST /api/v1/trend/
  post_trend = lambda do
    content_type :json, 'charset' => 'utf-8'
    begin
      req = JSON.parse(request.body.read)
      logger.info req
    rescue
      halt 400
    end

    trend = Trend.new(
      description: req['description'],
      categories: req['categories'].to_json)

    if trend.save
      status 201
      redirect "api/v1/trend/#{trend.id}", 303
    else
      halt 500, 'Error saving trend request to the database'
    end
  end

  ### GET /api/v1/trend/:id/
  get_trend = lambda do
    content_type :json, 'charset' => 'utf-8'
    begin
      trend = Trend.find(params[:id])
      description = trend.description
      categories = JSON.parse(trend.categories)
      logger.info({ id: trend.id, description: description }.to_json)
    rescue
      halt 400
    end

    begin
      feeds_dict = newest_feeds(categories)
      results = Hash.new
      feeds_dict.map { |k, v| results[k] = v }
      results = results.to_json
    rescue
      halt 500, 'Lookup of BNext failed'
    end

  end

  ### DELETE /api/v1/trend/:id/
  delete_trend = lambda do
    trend = Trend.delete(params[:id])
    status(trend 0 ? 200 : 404)
  end

  ### POST /api/v1/article/
  post_article = lambda do
    content_type :json, 'charset' => 'utf-8'
    begin
      req = JSON.parse(request.body.read)
      logger.info req
    rescue
      halt 400
    end

    if Article.where(:link => "#{req['link']}").all.length == 0
      ###Create article table
      article = Article.new(
          title: req['title'],
          author: req['author'],
          date: req['date'],
          #tags: req['tags'],
          link: req['link']
        )
      if article.save
        status 201
      else
        halt 500, 'Error saving article request to the database'
      end

      ###Association between tag table
      req['tags'].each do |t|
        word_tag = Tag.where(:word => "#{t}").first
        unless word_tag
          word_tag = Tag.new(:word => "#{t}").save
        end
        article.tags << word_tag
      end

      ###Count the keyword numbers
      #found = Tag.find_by_word('Certain Keyword')
      #found.count

    else
      status 208
    end

  end

  ### GET /api/v1/article/
  get_article_by_viewid = lambda do
    content_type :json, 'charset' => 'utf-8'

    begin
      if params.has_key? 'viewid'
        BNextRobot.new._extract_feed("/article/view/id/#{params['viewid']}").to_hash.to_json
      else
        {}.to_json
      end
    rescue
      halt 404
    end
  end

  ### GET /api/v1/article/:id/
  get_article_id = lambda do
    content_type :json, 'charset' => 'utf-8'
    begin
      article = Article.find(params[:id])
      resp = Hash.new
      resp['title'] = article.title
      resp['author'] = article.author
      resp['date'] = article.date
      resp['tags'] = JSON.parse(article.tags)
      resp['link'] = article.link
      resp.to_json
    rescue
      halt 500, 'Lookup of Articles failed'
    end
  end

  ### DELETE /api/v1/article/:id/
  delete_article = lambda do
    article_cnt = Article.delete(params[:id])
    status(article_cnt > 0 ? 200 : 404)
  end

  ### GET /api/v1/article/filter?tags=&author=&title=
  find_articles = lambda do
    content_type :json, 'charset' => 'utf-8'
    attrs = ['tags', 'title', 'author']
    begin
      h = Hash.new
      attrs.each do |x|
        if params.has_key? x
          Article.where("#{x} LIKE ?", "%#{params[x]}%").all.each do |article|
            h[article.id] = article
          end
        end
      end
      h.values.to_json
    rescue
      halt 400
    end
  end


  ######################################################################################
  #                                                                                    #
  #                                DECLARATIONS                                        #
  #                                                                                    #
  ######################################################################################

  # Web API Routes
  get '/api/v1/?', &get_root
  post '/api/v1/article/?', &post_article
  get '/api/v1/article/?', &get_article_by_viewid
  get '/api/v1/article/filter?', &find_articles
  get '/api/v1/article/:id/?', &get_article_id
  delete '/api/v1/article/:id/?', &delete_article

  # unused functions
  get '/api/v1/:ranktype/?', &get_feed_ranktype
  get '/api/v1/trend/:id/?', &get_trend
  post '/api/v1/trend/?', &post_trend
  delete '/api/v1/trend/:id/?', &delete_trend
end
