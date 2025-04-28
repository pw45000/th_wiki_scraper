# Scrapy settings for wiki project
#
# For simplicity, this file contains only settings considered important or
# commonly used. You can find more settings consulting the documentation:
#
#     https://docs.scrapy.org/en/latest/topics/settings.html
#     https://docs.scrapy.org/en/latest/topics/downloader-middleware.html
#     https://docs.scrapy.org/en/latest/topics/spider-middleware.html

BOT_NAME = "wiki"

SPIDER_MODULES = ["wiki.spiders"]
NEWSPIDER_MODULE = "wiki.spiders"

LOG_LEVEL = 'INFO'

# Spoofed User Agent
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"

ROBOTSTXT_OBEY = False

# All of the settings below are set in order to be very 'gentle' on the hosting server
# and so as not to get noticed by cloudflare. In particular, AUTOTHROTTLE_TARGET_CONCURRENCY
# is half of what the scrapy docs consider a 'gentle' value (0.50).
# https://docs.scrapy.org/en/latest/topics/autothrottle.html#autothrottle-target-concurrency
AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 10
AUTOTHROTTLE_MAX_DELAY = 60
AUTOTHROTTLE_TARGET_CONCURRENCY = 0.25
# Enable showing throttling stats for every response received if necessary:
#AUTOTHROTTLE_DEBUG = False

# Set settings whose default value is deprecated to a future-proof value
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"
FEED_EXPORT_ENCODING = "utf-8"

DOWNLOAD_HANDLERS =  {
    "http": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
    "https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
}
# For whatever reason, chrome does not work but 'chromium does', scrapy stating that it did not find 'chrome' in
# a specific channel.
PLAYWRIGHT_BROWSER_TYPE =  "chromium"
PLAYWRIGHT_LAUNCH_OPTIONS = {
    # Most headless clients are easily detected, hence, we use our scraper in a virtual display to effectively make a
    # headful client headless via xfvb.
    "headless" : False,
    # The disabled automation Chrome flag will lower our chances of being detected as headless.
    # The latter I'm not so sure how per se it does lower our score from 38% headless-like to 31%,
    # based off of the following website which is meant to benchmark our client's resilience against bot detection:
    # https://abrahamjuliot.github.io/creepjs/
    "args" : [
        "--disable-blink-features=AutomationControlled",
        "--enable-experimental-web-platform-features",
    ],
}