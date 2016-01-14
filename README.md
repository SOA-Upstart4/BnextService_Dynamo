# BnextRobot Webservice(Using AWS DynamoDB)

## Overview
A web service(with DynamoDB integration) that scrapes [BNext](http://www.bnext.com.tw/) data using the [bnext_robot](https://rubygems.org/gems/bnext_robot) gem.

※Refactor from repo [bnext_service](https://github.com/SOA-Upstart4/bnext_service)

## Repository structure
```
├── Gemfile
├── Gemfile.lock
├── LICENSE
├── Procfile
├── README.md
├── Rakefile
├── config
│   ├── config_env.rb
│   ├── database.rb
│   └── init.rb
├── config.ru
├── controllers
│   ├── api_controller.rb
│   ├── base.rb
│   ├── bnext_helper.rb
│   ├── init.rb
│   └── trend_helper.rb
├── models
│   ├── article.rb
│   ├── init.rb
│   └── trend.rb
├── services
│   ├── bnext_feeds.rb
│   └── init.rb
└── spec
    ├── app_spec.rb
    ├── article_spec.rb
    ├── bnext_spec.rb
    ├── fixtures
    │   └── vcr_cassettes
    │       ├── day_rank.yml
    │       ├── default_feed.yml
    │       ├── get_specific_article.yml
    │       ├── internet_page_4.yml
    │       ├── post_random.yml
    │       ├── post_recent.yml
    │       ├── post_trend.yml
    │       ├── week_rank.yml
    │       └── wrong_ranktype.yml
    ├── spec_answers.rb
    ├── spec_helper.rb
    └── trend_spec.rb
```

## Quick Start

- `GET /`
returns the current API version and Github homepage

- `GET /api/v1/weekrank`
returns JSON of most popular weekly feeds info: *title*, *link*

- `GET /api/v1/dayrank`
returns JSON of most popular daily feeds info: *title*, *link*

- `GET /api/v1/feed?cat=[cat]&page=[page_no]`
returns JSON of feeds info under a specific category and page number: *title*, *author*, *date*, *content*, *tags*, *imgs*. Available categories include: `internet`, `tech`, `marketing`, `startup`, `people`, and `skill`.

	- E.g.
		- `http://localhost:9292/api/v1/feed?cat=marketing`
		- `http://localhost:9292/api/v1/feed?cat=marketing&page=2`
	- Note that if the request parameters are invalid for crawling data, the service will return error message to notify users and suggest a normal use of queries.

	```
	[Bad request] please check the category and the page no is rational


	Page no   : should be a natural number, a.k.a. POSITIVE INTEGER, and cannot be too large.
	Categories:
			"internet", for searching "網路"
			"tech", for searching "科技"
			"marketing", for searching "行銷"
			"startup", for searching "創業"
			"people", for searching "人物"
			"skill", for searching "技能"
	```

- `POST /api/v1/trend`
	- takes JSON: array of 'categories'
	- returns: array of categories and the newest feed in that category
		- Command line connetction example:
		```
		curl -v -H "Accept: application/json" -H "Content-type: application/json" \
		-X POST -d "{\"categories\":[\"tech\",\"marketing\"]}" \
		http://localhost:9292/api/v1/trend
		```


## Project Architecture

### Overview

<table>
	<tr>
		<td><b>FOLDER</b></td>
		<td><b>FILE</b></td>
		<td><b>DESCRIPTION</b></td>
	</tr>

	<!-- Controllers -->
	<tr>
		<td rowspan="4"><a href="#controllers">/controllers/</a></td>
		<td>application_controller.rb</td>
		<td>main control of the app</td>
	</tr>
  	<tr>
    	<td>base.rb</td>
    	<td>configuration setting: production, development and testing</td>
  	</tr>
  	<tr>
    <td>bnext_helper.rb</td>
    <td>functions related to "Business Next"</td>
  </tr>
  <tr>
    <td>trend_helper.rb</td>
    <td>functions related to keywords trend extraction/td>
  </tr>

	<!-- Models -->
	<tr>
		<td rowspan="2"><a href="#models">/models/</a></td>
		<td>article.rb</td>
		<td>Dynamoid schema for table building: articles & tags</td>
	</tr>
	<tr>
		<td>trend.rb</td>
		<td>Dynamoid schema for table building: trend</td>
	</tr>

  <!-- Services -->
	<tr>
		<td rowspan="2"><a href="#services">/services/</a></td>
		<td>bnext_feeds.rb</td>
		<td>Processing the data retrieving from BNextRobot into a format the app accepts</td>
	</tr>
</table>

<h1 id="controllers" />
### Controllers

- application_controller.rb (ApplicationController)

	| API ROUTE | TYPE | METHOD | PARAMS | DESCRIPTION
	|:----:|:----:|:----:|:----:|:----
	| `/api/v1` | API | `GET` | N/A | Root directory
	| `/api/v1/dayrank` | API | `GET` | N/A | Getting daily hot feeds
	| `/api/v1/weekrank` | API | `GET` | N/A | Getting weekly hot feeds
	| `/api/v1/feed` | API | `GET` | `cat={CATEGORY}&page={PAGENO}` | Getting feeds under a specific category at specific page number
	| `/api/v1/trend/{ID}` | API | `GET` | N/A | Finding trend information with specific ID
	| `/api/v1/trend` | API | `POST` | `{ description: "{DESC}", categories: ["{CAT1}", "{CAT2}"] }` | TBD
	| `/api/v1/trend/{ID}` | API | `DELETE` | N/A | Deleting trend information with specific ID
	| `/api/v1/article` | API | `POST` | `{ body: FEED.to_json }` | Posting article to the database
	| `/api/v1/article` | API | `GET` | `viewid=` | Getting article meta data in json format
	| `/api/v1/article/filter` | API | `GET` | `tags=&author=&title=&date_from=&date_to=` | Retrieving articles that match ALL the given conditions
	| `/` | GUI | `GET` | N/A |
	| `/feed/` | GUI | `GET` | N/A |

  - bnext_helper.rb

  	| MODULE | FIELD | TYPE | ACCESS | PARAMS | DESCRIPTION
  	|:----:|:----:|:----:|:----:|:----:|:----
  	| `BNextHelpers` | `get_rank` | func returns `RankList` | public | `type: category: page: ` | retrieve `Feed`'s

  - trend_helper.rb

  	| MODULE | FIELD | TYPE | ACCESS | PARAMS | DESCRIPTION
  	|:----:|:----:|:----:|:----:|:----:|:----
  	| `TrendHelpers` | `get_popular_words` | func returns `Hash` | public | `max_num: cat: ` | get top `max_num` words that are puplar used so far with specific category

### Resources (temporary solution)

<p>
To gather the data we want to analyze, a database holding all needed information of articles is applied. However, the regularly fetching worker cannot be implemented so far, the solution we can approach currently is writing lines of code that manually posts all articles to the database.
</p>

```ruby
require 'json'
require 'bnext_robot'
require 'httparty'

URL = 'http://bnext-dynamo.herokuapp.com/api/v1/article'

cats = ['internet', 'tech', 'marketing', 'startup', 'people', 'skill']

bot = BNextRobot.new

cats.map do |cat|
  (1..100).map do |pageno|
    print "\rPosting aritcles of '#{cat}' at page #{pageno}"
    feeds = bot.get_feeds(cat, pageno)
    feeds.each do |feed|
      h = Hash.new
      h['title'] = feed.title
      h['author'] = feed.author
      h['date'] = feed.date
      h['link'] = feed.link
      h['tags'] = feed.tags
      options = {
        body: h.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
      result = HTTParty.post(URL, options)
    end
  end
  print "\n"
end
```

<h1 id="services" />
### Models (Deprecated)

- bnext_feed.rb

	| CLASS | FIELD | TYPE | ACCESS | PARAMS | DESCRIPTION
	|:----:|:----:|:----:|:----:|:----:|:----
	| `RankFeeds` | `fetch` | func returns `RankList` | static public | `type: category: page: ` | returns an array of `Feed` that is JSON-parsable with specific configuration
	| `RankFeeds` | `type` | var | read | N/A | `dayrank`<br/>\|`weekrank` <br/>\|`feed`
	| `RankFeeds` | `category` | var | read | N/A | see Quick Start
	| `RankFeeds` | `page` | var | read | N/A | see Quick Start
	| `RankList` | `to_json` | func returns string | public | N/A | parse to JSON string
