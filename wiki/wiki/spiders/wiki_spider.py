import time
from pathlib import Path

import scrapy
from numpy.ma.core import less_equal
from scrapy.spiders import Rule, CrawlSpider
from scrapy.linkextractors import LinkExtractor


class WikiSpider(CrawlSpider):
    name = "wiki_spider"
    #"https://www.scrapingcourse.com/cloudflare-challenge/",
    #"https://abrahamjuliot.github.io/creepjs/",

    allowed_domains = ["en.touhouwiki.net", "www.thpatch.net"]
    start_urls = [
        'https://en.touhouwiki.net/wiki/Embodiment_of_Scarlet_Devil/Story',
        'https://en.touhouwiki.net/wiki/Perfect_Cherry_Blossom/Story',
        'https://en.touhouwiki.net/wiki/Imperishable_Night/Story',
        'https://en.touhouwiki.net/wiki/Mountain_of_Faith/Story',
        'https://en.touhouwiki.net/wiki/Subterranean_Animism/Story',
        'https://en.touhouwiki.net/wiki/Undefined_Fantastic_Object/Story',
        'https://en.touhouwiki.net/wiki/Ten_Desires/Story',
        'https://en.touhouwiki.net/wiki/Double_Dealing_Character/Story',
        'https://en.touhouwiki.net/wiki/Legacy_of_Lunatic_Kingdom/Story',
        'https://en.touhouwiki.net/wiki/Hidden_Star_in_Four_Seasons/Story',
        'https://en.touhouwiki.net/wiki/Wily_Beast_and_Weakest_Creature/Story',
        'https://en.touhouwiki.net/wiki/Unconnected_Marketeers/Story',
    ]

    # Normally start_requests isn't overwritten, but we will need to do so
    # such that playwright launches with start_urls.
    def start_requests(self):
        for url in self.start_urls:
            yield scrapy.Request(
                url,
                dont_filter=True,
                meta={"playwright": True},
            )

    # Each request requires an explicit playwright value as well as the dont_filter flag,
    # hence, this function is added.
    # See https://stackoverflow.com/a/71462253 for more information.
    def modify_request(request, response):
        request.dont_filter = True
        request.meta["playwright"] = True
        return request

    rules = (
        Rule(LinkExtractor(allow=r"^.*%27s_Scenario.*$"), callback='parse_item', follow=False,
             process_request=modify_request),
        Rule(LinkExtractor(allow=r"^.*%27s_Endings.*$"), callback='parse_item', follow=False,
             process_request=modify_request),
        Rule(LinkExtractor(allow=r"^.*%27s_Extra.*$"), callback='parse_item', follow=False,
             process_request=modify_request),
    )

    # Change to async if needing to debug with playwright
    def parse_item(self, response):
        # BRs are not transferred over into text. Hence, they must be replaced for our purposes.
        # See https://stackoverflow.com/a/8748836
        for table in response.xpath("//table[@cellpadding = '5']"):
                # Explanation: because our table's rows alternate between th,tr,tr and tr, tr, tr
                # we need an agnostic solution. The below will select from the tables on the page,
                # and then use the child selector (/*) to select each respective part of the row.
                # tbody -> tr -> columns of tr

                for row in table.xpath('./*/*'):
                    domain = response.url.split("//")[1].split("/")[0]

                    if domain == "en.touhouwiki.net":
                        game = response.request.url.split('/')[-3]
                        route = response.request.url.split('/')[-1].split('%27s_')[0]
                        act = response.request.url.split('/')[-1].split('%27s_')[1]
                    else:
                        game = response.request.url.split('/')[-3]
                        route = response.request.url.split('/')[-2].split('%27s_')[0]
                        act = response.request.url.split('/')[-2].split('%27s_')[1]

                    # Example of the URL : https://en.touhouwiki.net/wiki/Perfect_Cherry_Blossom/Story/Reimu%27s_Scenario
                    # Generally holds true for all pages to my knowledge, with the following exception of one game:
                    # https://en.touhouwiki.net/wiki/Wily_Beast_and_Weakest_Creature/Story/Reimu%27s_Scenario_(Wolf)
                    if game== "Wily_Beast_and_Weakest_Creature":
                        route += " " + response.request.url.split('_')[-1]
                        if not "Ending" in act:
                            act = act.split('_')[0]
                    yield {
                        # Get all text from the specific column of the row, whilst discarding extra newlines.
                        #'character': ''.join(row.xpath('./*[1]//text()').extract()),
                        #'jp_dialogue': ''.join(row.xpath('./*[2]//text()').extract()),
                        #'en_dialogue': ''.join(row.xpath('./*[3]//text()').extract()),
                        'character': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[1]//text()[not(ancestor::code)] | ./*[1]//br').extract()),
                        'jp_dialogue': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[2]//text()[not(ancestor::code)] | ./*[2]//br').extract()),
                        'en_dialogue': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[3]//text()[not(ancestor::code)] | ./*[3]//br').extract()),
                        'route': route,
                        'act': act,
                        'game': game

                    }
    # page = response.meta['playwright_page']
        # yield await page.screenshot(path=f'example.png')
        # yield Path("quotes-1.html").write_bytes(response.body)

    """
    Rule(LinkExtractor(allow=r"^.*%27s_Scenario.*$"), callback='parse_item', follow=False,
             process_request=modify_request),
    Rule(LinkExtractor(allow=r"^.*%27s_Endings.*$"), callback='parse_item', follow=False,
         process_request=modify_request),
    Rule(LinkExtractor(allow=r"^.*%27s_Extra.*$"), callback = 'parse_item', follow = False,
process_request = modify_request),
    """

