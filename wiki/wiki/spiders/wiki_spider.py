import scrapy
from scrapy.spiders import Rule, CrawlSpider
from scrapy.linkextractors import LinkExtractor


class WikiSpider(CrawlSpider):
    name = "wiki_spider"
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

    def parse_item(self, response):
        # All the tables that contain dialogue all have cellpadding set to 5.
        for table in response.xpath("//table[@cellpadding = '5']"):
                # The below will select from the tables on the page and then use the child selector (/*)
                # to select each respective row (i.e. table-> tbody -> tr)
                for row in table.xpath('./*/*'):
                    domain = response.url.split("//")[1].split("/")[0]

                    # Scenarios and Extra Stories are stored under the "en.touhouwiki.net" domain,
                    # Endings in the 'www.thpatch.net' directory.
                    # Normally, we would put an elif to ensure we are only on 'www.thpatch.net', but as I understand it,
                    # allowed_domains takes care of this for us already.
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
                    # in which case we need to edit our extraction method to get the correct route/scenario.
                    if game== "Wily_Beast_and_Weakest_Creature":
                        route += " " + response.request.url.split('_')[-1]
                        if not "Ending" in act:
                            act = act.split('_')[0]
                    yield {
                        # Many niceties in extraction:
                        # 1. Because the elements of each row alternate between any combination of td/td/td or th/td/td,
                        # we need to use the xpath selector agnostic of a single element.
                        # 2. //text() will extract text in a staggered format via a list, hence we need to combine the
                        # extracted texts into a single string.
                        # 3. BRs are not natively rendered as newlines in our default xpath, hence, we need to manually
                        # extract them and change them to be as such. This will make sanitization easier for us later.
                        # 4. For whatever reason, the 'Endings' section is broken and contains garbage text enclosed
                        # within the 'code' HTML element (i.e. <code> </code>)
                        'character': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[1]// text()[not(ancestor::code)] | ./*[1]//br').extract()),
                        'jp_dialogue': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[2]//text()[not(ancestor::code)] | ./*[2]//br').extract()),
                        'en_dialogue': ''.join("\n" if text == "<br>" else text for text in row.xpath('./*[3]//text()[not(ancestor::code)] | ./*[3]//br').extract()),
                        'route': route,
                        'act': act,
                        'game': game
                    }

