# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class HeadphoneItem(scrapy.Item):	
    title = scrapy.Field()
    user_name = scrapy.Field()
    review_score = scrapy.Field()
    num_reviews = scrapy.Field()
    views = scrapy.Field()
    category = scrapy.Field()
    likes = scrapy.Field()
    date = scrapy.Field()
    description_text = scrapy.Field()
    
class HeadphoneDescriptionItem(scrapy.Item):	
    title = scrapy.Field()
    user_name = scrapy.Field()
    review_score = scrapy.Field()
    views = scrapy.Field()
    description_text = scrapy.Field()
    
class HeadphoneReviewItem(scrapy.Item):	
    review_title = scrapy.Field()
    individual_review_score = scrapy.Field()
    date = scrapy.Field()
    pros_text = scrapy.Field()
    cons_text = scrapy.Field()
    reviewer = scrapy.Field()
    remaining_text = scrapy.Field()
