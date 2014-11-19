# cp.shanked.me

This is a score scraper for CyberPatriot 6, and has since been replaced by The Magi. It was thought to be deleted, but was found and uploaded for historical purposes.

## Setup

1. ````bundle install````
2. Start a [Redis](http://redis.io) server.
3. Run the Redis server.
4. ````export REDISTOGO_URL=[your-redis-info-here]````
5. ````rackup````

## Usage

There are several routes. Right now, all are commented out and replaced with an 'indefinite shutdown' notice. This is probably because of people contacting CPOC with help with the website, and me pulling it down out of fear. Anyway, here's the route table:

* ````/```` - Displays the national finalist data based on live data. Unfortunately, this data was not exported, and is not functional.
* ````/semis```` - Displays score data calculated to determine who goes to CyberPatriot 6's semifinal competition.
* ````/semis/rhs```` - Displays current information about Rangeview High School's Any Key team (06-0264).
* ````/rhs```` - Displays a calculation for Rangeview High School's Any Key team in relation to progression towards the National Finals competition. Displays the national finalist data based on live data. Unfortunately, this data was not exported, and is not functional.
* ````/allservice```` - Displays the national finalist data for the all service division based on live data. Unfortunately, this data was not exported, and is not functional.

## Screenshots

![](http://puu.sh/cX06V/19233abfd4.png)
![](http://puu.sh/cX09c/a1f1fda926.png)

## Caveats and more

This is very old. It's hard coded to look for scores at the old score system URL, and does a lot of bad parsing that you shouldn't ever, ever do when you have XPath. It crawled on every page visit, or, if the server was unreachable, pulled data from Redis as a cache.

This is mostly here for historical purposes.

Any Key, Team 06-0264, was projected by this script to go to the National Finals Competition in Washington D.C. And we did.

![Any Key Team Photo](http://puu.sh/cWZQ8/8edd210b0d.jpeg)
![Any Key Team Photo](http://puu.sh/cWZOL/6b2b6df095.jpg)
