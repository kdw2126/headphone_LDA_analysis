# -*- coding: utf-8 -*-
"""
Created on Sat Oct 26 16:48:58 2019

@author: jnaka
"""

from scrapy import Spider, Request
from headphones.items import HeadphoneItem, HeadphoneDescriptionItem, HeadphoneReviewItem
import re
import math
from bs4 import BeautifulSoup
import time

class headphone_spyder(Spider):
    name = 'headphone_spyder'
    allowed_domains = ['www.head-fi.org']
    start_urls = ['https://www.head-fi.org/showcase/category/headphones.258/']

    def parse(self, response):
        # Find the total number of pages in the result so that we can decide how many urls to scrape next
        text = response.xpath('//span[@class="contentSummary"]/text()').extract()
        _, per_page, total = map(lambda x: int(x), re.findall('\d+', re.sub(",", "", str(text))))
        number_pages = math.ceil(total / per_page)

        # List comprehension to construct all the urls
        result_urls = ['https://www.head-fi.org/showcase/category/headphones.258/?page={}'.format(x) for x in range(1,number_pages+1)]

        # Yield the requests to different search result urls, 
        # using parse_result_page function to parse the response.
        for url in result_urls:
            yield Request(url=url, callback=self.parse_description)


    def parse_description(self, response):
        # This fucntion parses the search result page.
        
        # We are looking for url of the detail page.
        detail_urls = response.xpath('.//a[@class="PreviewTooltip"]/@href').extract()   
        final_product_urls = ['https://www.head-fi.org/{}'.format(x) for x in detail_urls]
            
        names = response.xpath('.//a[@class="PreviewTooltip"]/text()').extract()
        user_names = response.xpath('.//div[@class="listBlockInner"]/div/a[@class="username"]/text()').extract()   
        dates_p1 = response.xpath('.//div[@class="listBlockInner"]/div/a/abbr/@data-datestring').extract()
        dates_p2 = response.xpath('.//div[@class="listBlockInner"]/div/a/span[@class="DateTime"]/text()').extract()
        dates = dates_p1 + dates_p2
        categories = response.xpath('.//div[@class="listBlockInner"]/div/span/a/text()').extract()
        rating_averages = response.xpath('.//dd/div/dl/dd/span[@class="RatingValue"]/span[@itemprop="average"]/text()').extract()
        views = response.xpath('.//div[@class="pairsJustified "]/dl[@class="viewStats"]/dd/text()').extract()
        likes = response.xpath('.//div[@class="pairsJustified "]/dl[@class="likeStats"]/dd/text()').extract()
        review_count = response.xpath('.//div[@class="pairsJustified "]/dl[@class="reviewStats"]/dd/a/text()').extract()
        descriptions = response.xpath('.//div[@class="listBlockInner"]/div[@class="description"]/span').extract()
        
        expanded_review_count = []
        index_of_review_count = 0
        
        for item_number in range(len(names)):
            if rating_averages[item_number] == "0":
                expanded_review_count.append("0")
            else:
                temp = review_count[index_of_review_count]
                expanded_review_count.append(temp)
                index_of_review_count += 1
                
            item = HeadphoneItem()
            item['title'] = names[item_number].strip()
            try:
                item['user_name'] = user_names[item_number].strip()
            except:
                item['user_name'] = ""
            item['category'] = categories[item_number].strip()
            item['num_reviews'] = float(expanded_review_count[item_number].strip())
            item['views'] = views[item_number].strip()
            item['likes'] = likes[item_number].strip()
            item['date'] = dates[item_number].strip()
            item['review_score'] = rating_averages[item_number].strip()
            raw_description = descriptions[item_number]
            item['description_text'] =  ' '.join(BeautifulSoup(raw_description, "html.parser").stripped_strings) 
            
            yield item
        

        for item_number in range(len(names)):
            url = final_product_urls[item_number]
            yield Request(url=url, callback=self.parse_descriptions)


    def parse_descriptions(self, response):
        # Product name
        item2 = HeadphoneDescriptionItem()
        item2['title']= response.xpath('.//div[@class="showcaseItemInfo"]/h1/text()').extract_first().strip() 
        item2['user_name']= response.xpath('.//div[@class="showcaseItemInfo"]/div[@class="byLine muted"]/span/a/text()').extract_first()  
        item2['review_score'] = float(response.xpath('.//div[@class="rating"]/dl/dd/span[@class="RatingValue"]/span/text()').extract_first().strip())  
        item2['views'] = response.xpath('.//span[@class="bylineViews"]/text()').extract_first().strip()
        raw_text = response.xpath('.//div[@class="primaryContent"]').extract_first()
        item2['description_text'] = ' '.join(BeautifulSoup(raw_text, "html.parser").stripped_strings)
        yield item2
        
        review_url = response.xpath('.//li[@class="last scTabReview"]/a/@href').extract_first()

        if item2['review_score'] != "0" and review_url is not None:
            review_txt = response.xpath('.//li[@class="last scTabReview"]/a/text()').extract_first()
            num_reviews = int(re.findall('\d+', re.sub(",", "", str(review_txt)))[0])     
            if num_reviews <= 10: 
                url = 'https://www.head-fi.org/{}'.format(review_url)
                yield Request(url=url, callback=self.parse_review_page)
            else:
                num_pages = math.ceil(num_reviews / 10)
                for page_number in range(1, num_pages):
                    url = 'https://www.head-fi.org/{0}?page{1}#reviews'.format(review_url, page_number)
                    yield Request(url=url, callback=self.parse_review_page)

        
    def parse_review_page(self, response):
        reviews = response.xpath('.//li[contains(@id, "review") and not(contains(@id,"reply"))]')

        for review in reviews:
                item3 = HeadphoneReviewItem()
                item3["review_title"] = review.xpath('.//div[@class="reviewTitle"]/span/text()').extract_first().strip()   
                item3["individual_review_score"] = float(review.xpath('.//span[@class="ratings"]/@title').extract_first().strip())
                item3["date"] = review.xpath('.//span[@class="DateTime"]/text()').extract_first() 
                if review.xpath('.//span[@class="DateTime"]/text()').extract_first() is None:
                    item3["date"] = review.xpath('.//abbr/@data-datestring').extract_first()  
                item3["reviewer"] = review.xpath('.//a[@class="username poster"]/text()').extract_first().strip()  
                item3["pros_text"] = review.xpath('.//span[@class="pros"]/article/blockquote/text()').extract_first()  
                item3["cons_text"] = review.xpath('.//span[@class="cons"]/article/blockquote/text()').extract_first()  
                raw_text = review.xpath('.//blockquote[@class="ugc baseHtml messageText"]').extract_first()
                item3["remaining_text"] =  ' '.join(BeautifulSoup(raw_text, "html.parser").stripped_strings) 

                yield item3
