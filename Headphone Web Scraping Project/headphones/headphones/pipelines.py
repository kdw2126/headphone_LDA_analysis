# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html
from scrapy.exporters import CsvItemExporter
from scrapy import signals
from scrapy.xlib.pydispatch import dispatcher

def item_type(item):
    return type(item).__name__.replace('Item','')  # TeamItem => team

class WriteItemPipeline(object):
    SaveTypes = ['Headphone','HeadphoneDescription','HeadphoneReview']
    
    def __init__(self):
        dispatcher.connect(self.open_spider, signal=signals.spider_opened)
        dispatcher.connect(self.close_spider, signal=signals.spider_closed)

    def open_spider(self, spider):
        self.files = dict([ (name, open(name+'.csv','w+b')) for name in self.SaveTypes ])
        self.exporters = dict([ (name,CsvItemExporter(self.files[name])) for name in self.SaveTypes])
        [e.start_exporting() for e in self.exporters.values()]

    def close_spider(self, spider):
        [e.finish_exporting() for e in self.exporters.values()]
        [f.close() for f in self.files.values()]

    def process_item(self, item, spider):
        what = item_type(item)
        self.exporters[what].export_item(item)
        return item

        
